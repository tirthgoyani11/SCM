import { getDistance } from 'geolib';
import { Student, User, Stop, Trip } from '../models';
import { sendPushNotification } from './notification.service';
import { logger } from '../utils/logger';

interface Location {
  latitude: number;
  longitude: number;
}

interface AlertState {
  [studentId: string]: {
    farAlertSent: boolean;
    nearAlertSent: boolean;
  };
}

// Track alert states to avoid duplicate notifications
const alertStates: AlertState = {};

const ALERT_DISTANCE_FAR = parseInt(process.env.ALERT_DISTANCE_FAR || '500');
const ALERT_DISTANCE_NEAR = parseInt(process.env.ALERT_DISTANCE_NEAR || '100');

export const calculateDistance = (from: Location, to: Location): number => {
  return getDistance(
    { latitude: from.latitude, longitude: from.longitude },
    { latitude: to.latitude, longitude: to.longitude }
  );
};

export const calculateETA = (distance: number, speedKmh: number = 30): number => {
  // Returns ETA in minutes
  if (speedKmh <= 0) speedKmh = 30; // Default speed
  const speedMs = (speedKmh * 1000) / 3600; // Convert km/h to m/s
  return Math.ceil(distance / speedMs / 60);
};

export const checkAndSendProximityAlerts = async (
  tripId: string,
  busLocation: Location,
  speed: number
): Promise<void> => {
  try {
    const trip = await Trip.findById(tripId)
      .populate('routeId')
      .populate({
        path: 'studentPickups.studentId',
        populate: { path: 'parentId stopId' }
      });

    if (!trip || trip.status !== 'in_progress') return;

    for (const pickup of trip.studentPickups) {
      if (pickup.status !== 'pending') continue;

      const student = pickup.studentId as any;
      if (!student || !student.parentId || !student.stopId) continue;

      const stop = student.stopId as any;
      const parent = student.parentId as any;
      const studentId = student._id.toString();

      // Initialize alert state if not exists
      if (!alertStates[studentId]) {
        alertStates[studentId] = { farAlertSent: false, nearAlertSent: false };
      }

      const distance = calculateDistance(busLocation, {
        latitude: stop.location.latitude,
        longitude: stop.location.longitude,
      });

      const eta = calculateETA(distance, speed);

      // Check for far alert (500m)
      if (distance <= ALERT_DISTANCE_FAR && !alertStates[studentId].farAlertSent) {
        await sendPushNotification({
          userId: parent._id.toString(),
          title: '🚌 Bus Arriving Soon!',
          body: `Bus is ${distance}m away from ${stop.name}. ETA: ${eta} minutes. Please be ready!`,
          type: 'bus_approaching',
          data: {
            distance: distance.toString(),
            eta: eta.toString(),
            stopName: stop.name,
            studentName: student.name,
          },
        });
        alertStates[studentId].farAlertSent = true;
        logger.info(`Far alert sent for student ${studentId}`);
      }

      // Check for near alert (100m)
      if (distance <= ALERT_DISTANCE_NEAR && !alertStates[studentId].nearAlertSent) {
        await sendPushNotification({
          userId: parent._id.toString(),
          title: '🚌 Bus Almost There!',
          body: `Bus is ${distance}m away! Please be at ${stop.name} now.`,
          type: 'bus_approaching',
          data: {
            distance: distance.toString(),
            eta: eta.toString(),
            stopName: stop.name,
            studentName: student.name,
            urgent: 'true',
          },
        });
        alertStates[studentId].nearAlertSent = true;
        logger.info(`Near alert sent for student ${studentId}`);
      }
    }
  } catch (error) {
    logger.error('Error checking proximity alerts:', error);
  }
};

export const resetAlertStates = (tripId: string): void => {
  // Reset all alert states when trip ends or is cancelled
  Object.keys(alertStates).forEach((key) => {
    delete alertStates[key];
  });
};

export const sendPickupConfirmation = async (
  studentId: string,
  busNumber: string
): Promise<void> => {
  try {
    const student = await Student.findById(studentId).populate('parentId');
    if (!student || !student.parentId) return;

    const parent = student.parentId as any;
    await sendPushNotification({
      userId: parent._id.toString(),
      title: '✅ Pickup Confirmed',
      body: `${student.name} has been picked up by Bus ${busNumber}.`,
      type: 'pickup_confirmation',
      data: {
        studentName: student.name,
        busNumber,
        timestamp: new Date().toISOString(),
      },
    });
  } catch (error) {
    logger.error('Error sending pickup confirmation:', error);
  }
};

export const sendDropConfirmation = async (
  studentId: string,
  busNumber: string
): Promise<void> => {
  try {
    const student = await Student.findById(studentId).populate('parentId');
    if (!student || !student.parentId) return;

    const parent = student.parentId as any;
    await sendPushNotification({
      userId: parent._id.toString(),
      title: '✅ Drop Confirmed',
      body: `${student.name} has been dropped off from Bus ${busNumber}.`,
      type: 'drop_confirmation',
      data: {
        studentName: student.name,
        busNumber,
        timestamp: new Date().toISOString(),
      },
    });
  } catch (error) {
    logger.error('Error sending drop confirmation:', error);
  }
};
