import { Server, Socket } from 'socket.io';
import { Bus } from '../models';

interface TelemetryData {
  type: 'location' | 'driving_event';
  tripId: string;
  busId: string;
  timestamp: string;
  location?: {
    latitude: number;
    longitude: number;
    altitude?: number;
    accuracy?: number;
    speed?: number;
    heading?: number;
  };
  eventType?: string;
  data?: Record<string, any>;
  deviceInfo?: {
    batteryLevel: number;
    isOnline: boolean;
  };
}

interface StreamData {
  tripId: string;
  busId: string;
  streamType: string;
}

/**
 * IoT Edge Handler
 * Handles telemetry data from driver mobile devices acting as IoT edge devices
 * Capabilities:
 * - Real-time GPS location processing
 * - Driving event detection and alerting
 * - Live video stream signaling
 * - Device health monitoring
 */
export class IoTEdgeHandler {
  private io: Server;
  private activeStreams: Map<string, Set<string>> = new Map(); // busId -> Set of viewerIds

  constructor(io: Server) {
    this.io = io;
  }

  /**
   * Initialize IoT edge handlers for a socket connection
   */
  initializeHandlers(socket: Socket): void {
    // Handle incoming telemetry data
    socket.on('iot:telemetry', (data: TelemetryData) => {
      this.handleTelemetry(socket, data);
    });

    // Live streaming handlers
    socket.on('stream:available', (data: StreamData) => {
      this.handleStreamAvailable(socket, data);
    });

    socket.on('stream:stopped', (data: StreamData) => {
      this.handleStreamStopped(socket, data);
    });

    socket.on('stream:offer', (data: any) => {
      this.handleStreamOffer(socket, data);
    });

    socket.on('stream:answer', (data: any) => {
      this.handleStreamAnswer(socket, data);
    });

    socket.on('stream:ice-candidate', (data: any) => {
      this.handleIceCandidate(socket, data);
    });

    // Viewer handlers
    socket.on('stream:request-join', (data: any) => {
      this.handleViewerJoinRequest(socket, data);
    });

    socket.on('stream:leave', (data: any) => {
      this.handleViewerLeave(socket, data);
    });
  }

  /**
   * Process incoming telemetry data from IoT edge device
   */
  private async handleTelemetry(socket: Socket, data: TelemetryData): Promise<void> {
    try {
      const { type, tripId, busId, timestamp } = data;

      if (type === 'location' && data.location) {
        // Update bus location in database
        await Bus.findByIdAndUpdate(busId, {
          currentLocation: {
            type: 'Point',
            coordinates: [data.location.longitude, data.location.latitude],
          },
          speed: data.location.speed,
          heading: data.location.heading,
          lastLocationUpdate: new Date(timestamp),
        });

        // Broadcast location to subscribers (parents, admins)
        this.io.to(`trip:${tripId}`).emit('bus:location', {
          busId,
          tripId,
          location: data.location,
          timestamp,
          deviceInfo: data.deviceInfo,
        });

        // Log for analytics
        console.log(`📍 IoT Telemetry [${busId}]: ${data.location.latitude}, ${data.location.longitude}`);
      }

      if (type === 'driving_event' && data.eventType) {
        // Handle driving events (harsh braking, speeding, etc.)
        await this.processDrivingEvent(socket, data);
      }
    } catch (error) {
      console.error('❌ IoT Telemetry Error:', error);
    }
  }

  /**
   * Process driving events for safety monitoring
   */
  private async processDrivingEvent(socket: Socket, data: TelemetryData): Promise<void> {
    const { tripId, busId, eventType, data: eventData, timestamp } = data;

    // Create alert for severe events
    const severeEvents = ['harsh_braking', 'speeding', 'sharp_turn'];
    
    if (severeEvents.includes(eventType || '')) {
      // Broadcast to admins
      this.io.to('role:admin').emit('driving:alert', {
        type: eventType,
        tripId,
        busId,
        data: eventData,
        timestamp,
        severity: this.getEventSeverity(eventType || '', eventData),
      });

      console.log(`🚨 Driving Event [${busId}]: ${eventType} - ${JSON.stringify(eventData)}`);
    }

    // Store event for trip analytics
    // Could be stored in a separate analytics collection
  }

  /**
   * Determine event severity for alerting
   */
  private getEventSeverity(eventType: string, data: any): 'low' | 'medium' | 'high' {
    switch (eventType) {
      case 'speeding':
        const speedOver = (data?.speed || 0) - (data?.limit || 60);
        if (speedOver > 30) return 'high';
        if (speedOver > 15) return 'medium';
        return 'low';
      case 'harsh_braking':
        if (data?.intensity > 20) return 'high';
        if (data?.intensity > 15) return 'medium';
        return 'low';
      case 'sharp_turn':
        if (data?.intensity > 12) return 'high';
        return 'medium';
      default:
        return 'low';
    }
  }

  /**
   * Handle stream becoming available
   */
  private handleStreamAvailable(socket: Socket, data: StreamData): void {
    const { busId, tripId, streamType } = data;
    
    // Join stream room
    socket.join(`stream:${busId}`);
    
    // Notify subscribers that stream is available
    this.io.to(`trip:${tripId}`).emit('stream:available', {
      busId,
      tripId,
      streamType,
    });

    console.log(`🎥 Stream available for bus: ${busId}`);
  }

  /**
   * Handle stream stopped
   */
  private handleStreamStopped(socket: Socket, data: StreamData): void {
    const { busId, tripId } = data;
    
    socket.leave(`stream:${busId}`);
    this.activeStreams.delete(busId);
    
    // Notify viewers that stream ended
    this.io.to(`stream:${busId}:viewers`).emit('stream:ended', { busId });

    console.log(`🛑 Stream stopped for bus: ${busId}`);
  }

  /**
   * Handle viewer requesting to join stream
   */
  private handleViewerJoinRequest(socket: Socket, data: any): void {
    const { busId, tripId } = data;
    const viewerId = socket.id;
    
    // Track viewer
    if (!this.activeStreams.has(busId)) {
      this.activeStreams.set(busId, new Set());
    }
    this.activeStreams.get(busId)?.add(viewerId);
    
    // Join viewer room
    socket.join(`stream:${busId}:viewers`);
    
    // Notify driver to create offer
    this.io.to(`stream:${busId}`).emit('stream:viewer-join', {
      viewerId,
      tripId,
    });

    console.log(`👀 Viewer ${viewerId} joining stream for bus: ${busId}`);
  }

  /**
   * Handle viewer leaving stream
   */
  private handleViewerLeave(socket: Socket, data: any): void {
    const { busId } = data;
    const viewerId = socket.id;
    
    this.activeStreams.get(busId)?.delete(viewerId);
    socket.leave(`stream:${busId}:viewers`);
    
    // Notify driver
    this.io.to(`stream:${busId}`).emit('stream:viewer-left', { viewerId });

    console.log(`👋 Viewer ${viewerId} left stream for bus: ${busId}`);
  }

  /**
   * Forward WebRTC offer from driver to viewer
   */
  private handleStreamOffer(socket: Socket, data: any): void {
    const { viewerId, offer, tripId } = data;
    
    this.io.to(viewerId).emit('stream:offer', {
      offer,
      tripId,
    });
  }

  /**
   * Forward WebRTC answer from viewer to driver
   */
  private handleStreamAnswer(socket: Socket, data: any): void {
    const { tripId, answer } = data;
    const viewerId = socket.id;
    
    // Find driver socket and forward
    this.io.to(`stream:${data.busId}`).emit('stream:answer', {
      viewerId,
      answer,
    });
  }

  /**
   * Forward ICE candidates between peers
   */
  private handleIceCandidate(socket: Socket, data: any): void {
    const { viewerId, candidate, tripId } = data;
    
    if (viewerId) {
      // From driver to viewer
      this.io.to(viewerId).emit('stream:ice-candidate', {
        candidate,
        tripId,
      });
    } else {
      // From viewer to driver
      this.io.to(`stream:${data.busId}`).emit('stream:ice-candidate', {
        viewerId: socket.id,
        candidate,
      });
    }
  }

  /**
   * Get active streams info
   */
  getActiveStreams(): Map<string, number> {
    const result = new Map<string, number>();
    this.activeStreams.forEach((viewers, busId) => {
      result.set(busId, viewers.size);
    });
    return result;
  }
}
