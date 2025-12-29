import { Server as SocketServer, Socket } from 'socket.io';
import { Server } from 'http';
import jwt from 'jsonwebtoken';
import { Bus, Trip, User } from '../models';
import { logger } from '../utils/logger';
import { IoTEdgeHandler } from './iot.handler';

interface AuthenticatedSocket extends Socket {
  userId?: string;
  userRole?: string;
}

interface LocationUpdate {
  busId: string;
  latitude: number;
  longitude: number;
  heading?: number;
  speed?: number;
}

interface WebRTCSignal {
  tripId: string;
  signal: any;
  targetUserId?: string;
}

export const initializeSocketServer = (server: Server): SocketServer => {
  const io = new SocketServer(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST']
    }
  });

  // Initialize IoT Edge Handler
  const iotHandler = new IoTEdgeHandler(io);

  // Authentication middleware
  io.use(async (socket: AuthenticatedSocket, next) => {
    try {
      const token = socket.handshake.auth.token || socket.handshake.query.token;
      
      if (!token) {
        return next(new Error('Authentication required'));
      }

      const decoded = jwt.verify(
        token as string,
        process.env.JWT_SECRET || 'default-secret'
      ) as { userId: string; role: string };

      socket.userId = decoded.userId;
      socket.userRole = decoded.role;
      next();
    } catch (error) {
      next(new Error('Invalid token'));
    }
  });

  io.on('connection', (socket: AuthenticatedSocket) => {
    logger.info(`Socket connected: ${socket.id} (User: ${socket.userId}, Role: ${socket.userRole})`);

    // Initialize IoT Edge handlers for this socket
    iotHandler.initializeHandlers(socket);

    // Join role-based rooms
    if (socket.userRole) {
      socket.join(`role:${socket.userRole}`);
    }
    if (socket.userId) {
      socket.join(`user:${socket.userId}`);
    }

    // ==================== LOCATION TRACKING ====================

    // Driver sends location update
    socket.on('location:update', async (data: LocationUpdate) => {
      try {
        if (socket.userRole !== 'driver') return;

        const { busId, latitude, longitude, heading, speed } = data;

        // Update bus location in database
        await Bus.findByIdAndUpdate(busId, {
          currentLocation: {
            latitude,
            longitude,
            heading,
            speed,
            timestamp: new Date()
          }
        });

        // Broadcast to all subscribers of this bus
        io.to(`bus:${busId}`).emit('location:updated', {
          busId,
          latitude,
          longitude,
          heading,
          speed,
          timestamp: new Date()
        });

        // Also broadcast to admins
        io.to('role:admin').emit('location:updated', {
          busId,
          latitude,
          longitude,
          heading,
          speed,
          timestamp: new Date()
        });

      } catch (error) {
        logger.error('Location update error:', error);
      }
    });

    // Subscribe to bus location updates
    socket.on('location:subscribe', (busId: string) => {
      socket.join(`bus:${busId}`);
      logger.info(`Socket ${socket.id} subscribed to bus:${busId}`);
    });

    // Unsubscribe from bus location updates
    socket.on('location:unsubscribe', (busId: string) => {
      socket.leave(`bus:${busId}`);
      logger.info(`Socket ${socket.id} unsubscribed from bus:${busId}`);
    });

    // ==================== WEBRTC SIGNALING ====================

    // Join a trip room for video streaming
    socket.on('stream:join', async (tripId: string) => {
      try {
        const trip = await Trip.findById(tripId);
        if (!trip || trip.status !== 'in_progress') {
          socket.emit('stream:error', { message: 'Trip not found or not active' });
          return;
        }

        socket.join(`stream:${tripId}`);
        logger.info(`Socket ${socket.id} joined stream:${tripId}`);

        // Notify driver that a viewer joined (if not the driver)
        if (socket.userRole === 'parent' || socket.userRole === 'admin') {
          io.to(`stream:${tripId}`).emit('stream:viewer-joined', {
            viewerId: socket.userId,
            role: socket.userRole
          });
        }
      } catch (error) {
        logger.error('Stream join error:', error);
      }
    });

    // Leave stream room
    socket.on('stream:leave', (tripId: string) => {
      socket.leave(`stream:${tripId}`);
      io.to(`stream:${tripId}`).emit('stream:viewer-left', {
        viewerId: socket.userId
      });
    });

    // WebRTC offer from driver
    socket.on('webrtc:offer', (data: WebRTCSignal) => {
      if (socket.userRole !== 'driver') return;
      
      // Broadcast offer to all viewers in the stream room
      socket.to(`stream:${data.tripId}`).emit('webrtc:offer', {
        tripId: data.tripId,
        signal: data.signal,
        driverId: socket.userId
      });
    });

    // WebRTC answer from viewer
    socket.on('webrtc:answer', (data: WebRTCSignal) => {
      // Send answer to the driver
      io.to(`stream:${data.tripId}`).emit('webrtc:answer', {
        tripId: data.tripId,
        signal: data.signal,
        viewerId: socket.userId
      });
    });

    // ICE candidate exchange
    socket.on('webrtc:ice-candidate', (data: WebRTCSignal) => {
      socket.to(`stream:${data.tripId}`).emit('webrtc:ice-candidate', {
        tripId: data.tripId,
        signal: data.signal,
        from: socket.userId
      });
    });

    // Stream started by driver
    socket.on('stream:started', (tripId: string) => {
      if (socket.userRole !== 'driver') return;
      
      io.to(`stream:${tripId}`).emit('stream:started', {
        tripId,
        driverId: socket.userId
      });
    });

    // Stream stopped by driver
    socket.on('stream:stopped', (tripId: string) => {
      if (socket.userRole !== 'driver') return;
      
      io.to(`stream:${tripId}`).emit('stream:stopped', {
        tripId
      });
    });

    // ==================== EMERGENCY ALERTS ====================

    // Emergency alert from driver
    socket.on('emergency:alert', async (data: { tripId: string; type: string; location: any }) => {
      if (socket.userRole !== 'driver') return;

      // Broadcast to admins immediately
      io.to('role:admin').emit('emergency:alert', {
        ...data,
        driverId: socket.userId,
        timestamp: new Date()
      });

      logger.warn(`Emergency alert from driver ${socket.userId}:`, data);
    });

    // ==================== TRIP EVENTS ====================

    // Trip started
    socket.on('trip:started', async (data: { tripId: string; busId: string }) => {
      if (socket.userRole !== 'driver') return;

      io.to('role:admin').emit('trip:started', {
        ...data,
        driverId: socket.userId,
        timestamp: new Date()
      });
    });

    // Trip ended
    socket.on('trip:ended', async (data: { tripId: string; busId: string }) => {
      if (socket.userRole !== 'driver') return;

      io.to('role:admin').emit('trip:ended', {
        ...data,
        driverId: socket.userId,
        timestamp: new Date()
      });

      // Close all stream connections for this trip
      io.to(`stream:${data.tripId}`).emit('stream:ended');
    });

    // Student pickup/drop events
    socket.on('student:pickup', (data: { tripId: string; studentId: string; busNumber: string }) => {
      io.to(`user:${data.studentId}`).emit('student:pickup', data);
    });

    socket.on('student:drop', (data: { tripId: string; studentId: string; busNumber: string }) => {
      io.to(`user:${data.studentId}`).emit('student:drop', data);
    });

    // ==================== DISCONNECT ====================

    socket.on('disconnect', () => {
      logger.info(`Socket disconnected: ${socket.id}`);
    });
  });

  return io;
};
