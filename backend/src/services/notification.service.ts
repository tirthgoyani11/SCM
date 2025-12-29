import admin from 'firebase-admin';
import { User, Notification } from '../models';
import { logger } from '../utils/logger';

// Initialize Firebase Admin
const initializeFirebase = (): void => {
  if (!admin.apps.length) {
    try {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          privateKeyId: process.env.FIREBASE_PRIVATE_KEY_ID,
          privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          clientId: process.env.FIREBASE_CLIENT_ID,
        } as admin.ServiceAccount),
      });
      logger.info('Firebase Admin initialized successfully');
    } catch (error) {
      logger.error('Firebase Admin initialization failed:', error);
    }
  }
};

initializeFirebase();

export interface NotificationPayload {
  userId: string;
  title: string;
  body: string;
  type: 'bus_approaching' | 'pickup_confirmation' | 'drop_confirmation' | 'emergency' | 'general';
  data?: Record<string, string>;
}

export const sendPushNotification = async (payload: NotificationPayload): Promise<boolean> => {
  try {
    const user = await User.findById(payload.userId);
    if (!user || !user.fcmToken) {
      logger.warn(`No FCM token found for user ${payload.userId}`);
      return false;
    }

    // Save notification to database
    await Notification.create({
      userId: payload.userId,
      title: payload.title,
      body: payload.body,
      type: payload.type,
      data: payload.data,
    });

    // Send push notification
    const message: admin.messaging.Message = {
      token: user.fcmToken,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: {
        type: payload.type,
        ...payload.data,
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'bus_tracking',
          priority: 'high',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: payload.title,
              body: payload.body,
            },
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    await admin.messaging().send(message);
    logger.info(`Push notification sent to user ${payload.userId}`);
    return true;
  } catch (error) {
    logger.error('Error sending push notification:', error);
    return false;
  }
};

export const sendBulkNotifications = async (
  userIds: string[],
  title: string,
  body: string,
  type: NotificationPayload['type'],
  data?: Record<string, string>
): Promise<void> => {
  const promises = userIds.map((userId) =>
    sendPushNotification({ userId, title, body, type, data })
  );
  await Promise.allSettled(promises);
};

export const sendEmergencyAlert = async (
  userIds: string[],
  busNumber: string,
  location: { latitude: number; longitude: number },
  alertType: string
): Promise<void> => {
  await sendBulkNotifications(
    userIds,
    '🚨 EMERGENCY ALERT',
    `Emergency on Bus ${busNumber}. Type: ${alertType}`,
    'emergency',
    {
      busNumber,
      latitude: location.latitude.toString(),
      longitude: location.longitude.toString(),
      alertType,
    }
  );
};
