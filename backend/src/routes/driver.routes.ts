import { Router, Response } from 'express';
import { Bus, Trip, Student, Route, Stop, User } from '../models';
import { AuthRequest, authenticateToken, authorizeRoles } from '../middleware/auth';
import { checkAndSendProximityAlerts, resetAlertStates, sendPickupConfirmation, sendDropConfirmation } from '../services/alert.service';
import { sendEmergencyAlert } from '../services/notification.service';
import { EmergencyAlert } from '../models';

const router = Router();

// Get driver's assigned bus
router.get('/my-bus', authenticateToken, authorizeRoles('driver'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const bus = await Bus.findOne({ driverId: req.user?._id })
      .populate('routeId');
    
    if (!bus) {
      res.status(404).json({ error: 'No bus assigned to this driver' });
      return;
    }

    res.json(bus);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get active trip for driver
router.get('/active-trip', authenticateToken, authorizeRoles('driver'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const trip = await Trip.findOne({
      driverId: req.user?._id,
      status: 'in_progress'
    })
      .populate('busId')
      .populate('routeId')
      .populate({
        path: 'studentPickups.studentId',
        populate: { path: 'stopId' }
      });

    res.json(trip);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Start a trip
router.post('/start-trip', authenticateToken, authorizeRoles('driver'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { type } = req.body; // 'pickup' or 'drop'

    // Check for existing active trip
    const existingTrip = await Trip.findOne({
      driverId: req.user?._id,
      status: 'in_progress'
    });

    if (existingTrip) {
      res.status(400).json({ error: 'You already have an active trip' });
      return;
    }

    // Get driver's bus
    const bus = await Bus.findOne({ driverId: req.user?._id });
    if (!bus || !bus.routeId) {
      res.status(400).json({ error: 'No bus or route assigned' });
      return;
    }

    // Get students assigned to this bus
    const students = await Student.find({ busId: bus._id, isActive: true });
    
    const studentPickups = students.map(student => ({
      studentId: student._id,
      stopId: student.stopId,
      status: 'pending' as const
    }));

    const trip = await Trip.create({
      busId: bus._id,
      driverId: req.user?._id,
      routeId: bus.routeId,
      type,
      status: 'in_progress',
      startTime: new Date(),
      studentPickups,
      isLiveStreamActive: false
    });

    await trip.populate('busId');
    await trip.populate('routeId');

    res.status(201).json({
      message: 'Trip started successfully',
      trip
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// End a trip
router.post('/end-trip/:tripId', authenticateToken, authorizeRoles('driver'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const trip = await Trip.findOne({
      _id: req.params.tripId,
      driverId: req.user?._id,
      status: 'in_progress'
    });

    if (!trip) {
      res.status(404).json({ error: 'Active trip not found' });
      return;
    }

    trip.status = 'completed';
    trip.endTime = new Date();
    trip.isLiveStreamActive = false;
    await trip.save();

    // Reset alert states
    resetAlertStates(trip._id.toString());

    res.json({
      message: 'Trip ended successfully',
      trip
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Update location
router.post('/update-location', authenticateToken, authorizeRoles('driver'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { latitude, longitude, heading, speed } = req.body;

    // Update bus location
    const bus = await Bus.findOneAndUpdate(
      { driverId: req.user?._id },
      {
        currentLocation: {
          latitude,
          longitude,
          heading,
          speed,
          timestamp: new Date()
        }
      },
      { new: true }
    );

    if (!bus) {
      res.status(404).json({ error: 'Bus not found' });
      return;
    }

    // Update trip location history
    const trip = await Trip.findOne({
      driverId: req.user?._id,
      status: 'in_progress'
    });

    if (trip) {
      trip.locationHistory.push({
        latitude,
        longitude,
        timestamp: new Date()
      });
      await trip.save();

      // Check and send proximity alerts
      await checkAndSendProximityAlerts(
        trip._id.toString(),
        { latitude, longitude },
        speed || 0
      );
    }

    res.json({ message: 'Location updated', bus });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Confirm student pickup
router.post('/confirm-pickup/:tripId/:studentId', authenticateToken, authorizeRoles('driver'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { tripId, studentId } = req.params;

    const trip = await Trip.findOne({
      _id: tripId,
      driverId: req.user?._id,
      status: 'in_progress'
    }).populate('busId');

    if (!trip) {
      res.status(404).json({ error: 'Active trip not found' });
      return;
    }

    const pickup = trip.studentPickups.find(
      p => p.studentId.toString() === studentId
    );

    if (!pickup) {
      res.status(404).json({ error: 'Student not found in this trip' });
      return;
    }

    pickup.status = 'picked_up';
    pickup.timestamp = new Date();
    await trip.save();

    // Send notification to parent
    const bus = trip.busId as any;
    await sendPickupConfirmation(studentId, bus.busNumber);

    res.json({ message: 'Pickup confirmed', trip });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Confirm student drop
router.post('/confirm-drop/:tripId/:studentId', authenticateToken, authorizeRoles('driver'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { tripId, studentId } = req.params;

    const trip = await Trip.findOne({
      _id: tripId,
      driverId: req.user?._id,
      status: 'in_progress'
    }).populate('busId');

    if (!trip) {
      res.status(404).json({ error: 'Active trip not found' });
      return;
    }

    const pickup = trip.studentPickups.find(
      p => p.studentId.toString() === studentId
    );

    if (!pickup) {
      res.status(404).json({ error: 'Student not found in this trip' });
      return;
    }

    pickup.status = 'dropped';
    pickup.timestamp = new Date();
    await trip.save();

    // Send notification to parent
    const bus = trip.busId as any;
    await sendDropConfirmation(studentId, bus.busNumber);

    res.json({ message: 'Drop confirmed', trip });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Mark student absent
router.post('/mark-absent/:tripId/:studentId', authenticateToken, authorizeRoles('driver'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { tripId, studentId } = req.params;

    const trip = await Trip.findOne({
      _id: tripId,
      driverId: req.user?._id,
      status: 'in_progress'
    });

    if (!trip) {
      res.status(404).json({ error: 'Active trip not found' });
      return;
    }

    const pickup = trip.studentPickups.find(
      p => p.studentId.toString() === studentId
    );

    if (!pickup) {
      res.status(404).json({ error: 'Student not found in this trip' });
      return;
    }

    pickup.status = 'absent';
    pickup.timestamp = new Date();
    await trip.save();

    res.json({ message: 'Student marked absent', trip });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Toggle live stream
router.post('/toggle-stream/:tripId', authenticateToken, authorizeRoles('driver'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { tripId } = req.params;
    const { isActive } = req.body;

    const trip = await Trip.findOneAndUpdate(
      {
        _id: tripId,
        driverId: req.user?._id,
        status: 'in_progress'
      },
      { isLiveStreamActive: isActive },
      { new: true }
    );

    if (!trip) {
      res.status(404).json({ error: 'Active trip not found' });
      return;
    }

    res.json({
      message: `Live stream ${isActive ? 'started' : 'stopped'}`,
      trip
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Emergency panic button
router.post('/emergency', authenticateToken, authorizeRoles('driver'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { type, description, latitude, longitude } = req.body;

    const bus = await Bus.findOne({ driverId: req.user?._id });
    if (!bus) {
      res.status(404).json({ error: 'Bus not found' });
      return;
    }

    const trip = await Trip.findOne({
      driverId: req.user?._id,
      status: 'in_progress'
    });

    if (!trip) {
      res.status(404).json({ error: 'No active trip' });
      return;
    }

    // Create emergency alert
    const alert = await EmergencyAlert.create({
      tripId: trip._id,
      busId: bus._id,
      driverId: req.user?._id,
      location: { latitude, longitude },
      type,
      description,
      status: 'active'
    });

    // Get all admin users
    const admins = await User.find({ role: 'admin', isActive: true });
    const adminIds = admins.map(a => a._id.toString());

    // Get parents of students on this bus
    const students = await Student.find({ busId: bus._id }).populate('parentId');
    const parentIds = students
      .map(s => (s.parentId as any)?._id?.toString())
      .filter(Boolean);

    // Send emergency alerts
    await sendEmergencyAlert(
      [...adminIds, ...parentIds],
      bus.busNumber,
      { latitude, longitude },
      type
    );

    res.status(201).json({
      message: 'Emergency alert sent',
      alert
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get route stops
router.get('/route-stops', authenticateToken, authorizeRoles('driver'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const bus = await Bus.findOne({ driverId: req.user?._id }).populate({
      path: 'routeId',
      populate: { path: 'stops' }
    });

    if (!bus || !bus.routeId) {
      res.status(404).json({ error: 'No route assigned' });
      return;
    }

    const route = bus.routeId as any;
    res.json(route.stops);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
