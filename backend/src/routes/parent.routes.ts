import { Router, Response } from 'express';
import { Bus, Trip, Student, Notification } from '../models';
import { AuthRequest, authenticateToken, authorizeRoles } from '../middleware/auth';
import { calculateDistance, calculateETA } from '../services/alert.service';

const router = Router();

// Get parent's children
router.get('/children', authenticateToken, authorizeRoles('parent'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const children = await Student.find({ 
      parentId: req.user?._id, 
      isActive: true 
    })
      .populate('busId')
      .populate('stopId')
      .populate({
        path: 'routeId',
        populate: { path: 'stops' }
      });

    res.json(children);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get bus location for a child
router.get('/bus-location/:childId', authenticateToken, authorizeRoles('parent'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const child = await Student.findOne({
      _id: req.params.childId,
      parentId: req.user?._id
    }).populate('busId stopId');

    if (!child) {
      res.status(404).json({ error: 'Child not found' });
      return;
    }

    if (!child.busId) {
      res.status(404).json({ error: 'No bus assigned to this child' });
      return;
    }

    const bus = child.busId as any;
    const stop = child.stopId as any;

    let distance = null;
    let eta = null;

    if (bus.currentLocation && stop?.location) {
      distance = calculateDistance(
        { latitude: bus.currentLocation.latitude, longitude: bus.currentLocation.longitude },
        { latitude: stop.location.latitude, longitude: stop.location.longitude }
      );
      eta = calculateETA(distance, bus.currentLocation.speed || 30);
    }

    res.json({
      bus: {
        id: bus._id,
        busNumber: bus.busNumber,
        currentLocation: bus.currentLocation
      },
      stop: stop ? {
        id: stop._id,
        name: stop.name,
        location: stop.location
      } : null,
      tracking: {
        distance,
        eta,
        unit: 'meters'
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get active trip for child's bus
router.get('/active-trip/:childId', authenticateToken, authorizeRoles('parent'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const child = await Student.findOne({
      _id: req.params.childId,
      parentId: req.user?._id
    });

    if (!child || !child.busId) {
      res.status(404).json({ error: 'Child or bus not found' });
      return;
    }

    const trip = await Trip.findOne({
      busId: child.busId,
      status: 'in_progress'
    })
      .populate('busId')
      .populate({
        path: 'routeId',
        populate: { path: 'stops' }
      });

    if (!trip) {
      res.json({ active: false, trip: null });
      return;
    }

    // Find child's pickup status
    const childPickup = trip.studentPickups.find(
      p => p.studentId.toString() === child._id.toString()
    );

    res.json({
      active: true,
      trip: {
        id: trip._id,
        type: trip.type,
        status: trip.status,
        startTime: trip.startTime,
        isLiveStreamActive: trip.isLiveStreamActive,
        bus: trip.busId,
        route: trip.routeId
      },
      childStatus: childPickup?.status || 'pending'
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Check if live stream is available
router.get('/stream-available/:childId', authenticateToken, authorizeRoles('parent'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const child = await Student.findOne({
      _id: req.params.childId,
      parentId: req.user?._id
    });

    if (!child || !child.busId) {
      res.status(404).json({ error: 'Child or bus not found' });
      return;
    }

    const trip = await Trip.findOne({
      busId: child.busId,
      status: 'in_progress',
      isLiveStreamActive: true
    }).populate('busId');

    if (!trip) {
      res.json({ available: false });
      return;
    }

    const bus = trip.busId as any;
    res.json({
      available: true,
      tripId: trip._id,
      busId: bus._id,
      busNumber: bus.busNumber
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get trip history
router.get('/trip-history/:childId', authenticateToken, authorizeRoles('parent'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { childId } = req.params;
    const { page = 1, limit = 10 } = req.query;

    const child = await Student.findOne({
      _id: childId,
      parentId: req.user?._id
    });

    if (!child) {
      res.status(404).json({ error: 'Child not found' });
      return;
    }

    const trips = await Trip.find({
      'studentPickups.studentId': child._id,
      status: 'completed'
    })
      .populate('busId')
      .sort({ endTime: -1 })
      .skip((Number(page) - 1) * Number(limit))
      .limit(Number(limit));

    const total = await Trip.countDocuments({
      'studentPickups.studentId': child._id,
      status: 'completed'
    });

    res.json({
      trips,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total,
        pages: Math.ceil(total / Number(limit))
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get notifications
router.get('/notifications', authenticateToken, authorizeRoles('parent'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { page = 1, limit = 20 } = req.query;

    const notifications = await Notification.find({ userId: req.user?._id })
      .sort({ createdAt: -1 })
      .skip((Number(page) - 1) * Number(limit))
      .limit(Number(limit));

    const total = await Notification.countDocuments({ userId: req.user?._id });
    const unreadCount = await Notification.countDocuments({ 
      userId: req.user?._id, 
      isRead: false 
    });

    res.json({
      notifications,
      unreadCount,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total,
        pages: Math.ceil(total / Number(limit))
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Mark notification as read
router.put('/notifications/:id/read', authenticateToken, authorizeRoles('parent'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    await Notification.findOneAndUpdate(
      { _id: req.params.id, userId: req.user?._id },
      { isRead: true }
    );

    res.json({ message: 'Notification marked as read' });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Mark all notifications as read
router.put('/notifications/read-all', authenticateToken, authorizeRoles('parent'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    await Notification.updateMany(
      { userId: req.user?._id, isRead: false },
      { isRead: true }
    );

    res.json({ message: 'All notifications marked as read' });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
