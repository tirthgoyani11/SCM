import { Router, Response } from 'express';
import bcrypt from 'bcryptjs';
import { User, Bus, Route, Stop, Student, Trip, EmergencyAlert } from '../models';
import { AuthRequest, authenticateToken, authorizeRoles } from '../middleware/auth';

const router = Router();

// ==================== USER MANAGEMENT ====================

// Get all users
router.get('/users', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { role, page = 1, limit = 20 } = req.query;
    
    const filter: any = {};
    if (role) filter.role = role;

    const users = await User.find(filter)
      .select('-password')
      .skip((Number(page) - 1) * Number(limit))
      .limit(Number(limit))
      .sort({ createdAt: -1 });

    const total = await User.countDocuments(filter);

    res.json({
      users,
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

// Create user
router.post('/users', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { email, password, name, phone, role } = req.body;

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      res.status(400).json({ error: 'User already exists' });
      return;
    }

    const hashedPassword = await bcrypt.hash(password, 12);
    const user = await User.create({
      email,
      password: hashedPassword,
      name,
      phone,
      role
    });

    res.status(201).json({
      message: 'User created successfully',
      user: {
        id: user._id,
        email: user.email,
        name: user.name,
        role: user.role
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Update user
router.put('/users/:id', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { name, phone, isActive } = req.body;

    const user = await User.findByIdAndUpdate(
      req.params.id,
      { name, phone, isActive },
      { new: true }
    ).select('-password');

    if (!user) {
      res.status(404).json({ error: 'User not found' });
      return;
    }

    res.json(user);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Delete user
router.delete('/users/:id', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    await User.findByIdAndUpdate(req.params.id, { isActive: false });
    res.json({ message: 'User deactivated successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ==================== BUS MANAGEMENT ====================

// Get all buses
router.get('/buses', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const buses = await Bus.find()
      .populate('driverId', 'name email phone')
      .populate('routeId', 'name');

    res.json(buses);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Create bus
router.post('/buses', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { busNumber, licensePlate, capacity, driverId, routeId } = req.body;

    const bus = await Bus.create({
      busNumber,
      licensePlate,
      capacity,
      driverId,
      routeId
    });

    res.status(201).json(bus);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Update bus
router.put('/buses/:id', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { busNumber, licensePlate, capacity, driverId, routeId, isActive } = req.body;

    const bus = await Bus.findByIdAndUpdate(
      req.params.id,
      { busNumber, licensePlate, capacity, driverId, routeId, isActive },
      { new: true }
    )
      .populate('driverId', 'name email phone')
      .populate('routeId', 'name');

    if (!bus) {
      res.status(404).json({ error: 'Bus not found' });
      return;
    }

    res.json(bus);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Delete bus
router.delete('/buses/:id', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    await Bus.findByIdAndUpdate(req.params.id, { isActive: false });
    res.json({ message: 'Bus deactivated successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ==================== ROUTE MANAGEMENT ====================

// Get all routes
router.get('/routes', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const routes = await Route.find().populate('stops');
    res.json(routes);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Create route
router.post('/routes', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { name, description, stops } = req.body;

    const route = await Route.create({ name, description, stops });
    res.status(201).json(route);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Update route
router.put('/routes/:id', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { name, description, stops, isActive } = req.body;

    const route = await Route.findByIdAndUpdate(
      req.params.id,
      { name, description, stops, isActive },
      { new: true }
    ).populate('stops');

    if (!route) {
      res.status(404).json({ error: 'Route not found' });
      return;
    }

    res.json(route);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Delete route
router.delete('/routes/:id', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    await Route.findByIdAndUpdate(req.params.id, { isActive: false });
    res.json({ message: 'Route deactivated successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ==================== STOP MANAGEMENT ====================

// Get all stops
router.get('/stops', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const stops = await Stop.find().sort({ order: 1 });
    res.json(stops);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Create stop
router.post('/stops', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { name, address, location, estimatedTime, order } = req.body;

    const stop = await Stop.create({ name, address, location, estimatedTime, order });
    res.status(201).json(stop);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Update stop
router.put('/stops/:id', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { name, address, location, estimatedTime, order, isActive } = req.body;

    const stop = await Stop.findByIdAndUpdate(
      req.params.id,
      { name, address, location, estimatedTime, order, isActive },
      { new: true }
    );

    if (!stop) {
      res.status(404).json({ error: 'Stop not found' });
      return;
    }

    res.json(stop);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Delete stop
router.delete('/stops/:id', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    await Stop.findByIdAndUpdate(req.params.id, { isActive: false });
    res.json({ message: 'Stop deactivated successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ==================== STUDENT MANAGEMENT ====================

// Get all students
router.get('/students', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { busId, page = 1, limit = 20 } = req.query;
    
    const filter: any = {};
    if (busId) filter.busId = busId;

    const students = await Student.find(filter)
      .populate('parentId', 'name email phone')
      .populate('busId', 'busNumber')
      .populate('stopId', 'name')
      .skip((Number(page) - 1) * Number(limit))
      .limit(Number(limit));

    const total = await Student.countDocuments(filter);

    res.json({
      students,
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

// Create student
router.post('/students', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { name, grade, section, rollNumber, parentId, busId, routeId, stopId } = req.body;

    const student = await Student.create({
      name,
      grade,
      section,
      rollNumber,
      parentId,
      busId,
      routeId,
      stopId
    });

    res.status(201).json(student);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Update student
router.put('/students/:id', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { name, grade, section, rollNumber, parentId, busId, routeId, stopId, isActive } = req.body;

    const student = await Student.findByIdAndUpdate(
      req.params.id,
      { name, grade, section, rollNumber, parentId, busId, routeId, stopId, isActive },
      { new: true }
    )
      .populate('parentId', 'name email phone')
      .populate('busId', 'busNumber')
      .populate('stopId', 'name');

    if (!student) {
      res.status(404).json({ error: 'Student not found' });
      return;
    }

    res.json(student);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Delete student
router.delete('/students/:id', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    await Student.findByIdAndUpdate(req.params.id, { isActive: false });
    res.json({ message: 'Student deactivated successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ==================== LIVE TRACKING ====================

// Get all active buses with locations
router.get('/live-tracking', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const activeTrips = await Trip.find({ status: 'in_progress' })
      .populate('busId')
      .populate('driverId', 'name phone')
      .populate('routeId', 'name');

    const trackingData = activeTrips.map(trip => {
      const bus = trip.busId as any;
      const driver = trip.driverId as any;
      const route = trip.routeId as any;

      return {
        tripId: trip._id,
        bus: {
          id: bus._id,
          busNumber: bus.busNumber,
          currentLocation: bus.currentLocation
        },
        driver: {
          id: driver._id,
          name: driver.name,
          phone: driver.phone
        },
        route: {
          id: route._id,
          name: route.name
        },
        tripType: trip.type,
        startTime: trip.startTime,
        isLiveStreamActive: trip.isLiveStreamActive,
        studentsCount: trip.studentPickups.length,
        pickedUp: trip.studentPickups.filter(s => s.status === 'picked_up').length,
        dropped: trip.studentPickups.filter(s => s.status === 'dropped').length
      };
    });

    res.json(trackingData);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ==================== EMERGENCY MANAGEMENT ====================

// Get all emergency alerts
router.get('/emergencies', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { status } = req.query;
    
    const filter: any = {};
    if (status) filter.status = status;

    const alerts = await EmergencyAlert.find(filter)
      .populate('busId', 'busNumber')
      .populate('driverId', 'name phone')
      .populate('tripId')
      .sort({ createdAt: -1 });

    res.json(alerts);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Acknowledge emergency
router.put('/emergencies/:id/acknowledge', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const alert = await EmergencyAlert.findByIdAndUpdate(
      req.params.id,
      { 
        status: 'acknowledged',
        acknowledgedBy: req.user?._id
      },
      { new: true }
    );

    if (!alert) {
      res.status(404).json({ error: 'Alert not found' });
      return;
    }

    res.json(alert);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Resolve emergency
router.put('/emergencies/:id/resolve', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const alert = await EmergencyAlert.findByIdAndUpdate(
      req.params.id,
      { 
        status: 'resolved',
        resolvedAt: new Date()
      },
      { new: true }
    );

    if (!alert) {
      res.status(404).json({ error: 'Alert not found' });
      return;
    }

    res.json(alert);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// ==================== DASHBOARD STATS ====================

router.get('/dashboard-stats', authenticateToken, authorizeRoles('admin'), async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const [
      totalBuses,
      activeBuses,
      totalStudents,
      totalDrivers,
      totalParents,
      activeTrips,
      activeEmergencies,
      todayTrips
    ] = await Promise.all([
      Bus.countDocuments({ isActive: true }),
      Trip.countDocuments({ status: 'in_progress' }),
      Student.countDocuments({ isActive: true }),
      User.countDocuments({ role: 'driver', isActive: true }),
      User.countDocuments({ role: 'parent', isActive: true }),
      Trip.countDocuments({ status: 'in_progress' }),
      EmergencyAlert.countDocuments({ status: 'active' }),
      Trip.countDocuments({
        createdAt: { $gte: new Date(new Date().setHours(0, 0, 0, 0)) }
      })
    ]);

    res.json({
      totalBuses,
      activeBuses,
      totalStudents,
      totalDrivers,
      totalParents,
      activeTrips,
      activeEmergencies,
      todayTrips
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
