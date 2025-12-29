class ApiConstants {
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String profile = '/auth/profile';
  static const String updateFcmToken = '/auth/fcm-token';
  static const String changePassword = '/auth/change-password';
  
  // Parent endpoints
  static const String children = '/parent/children';
  static const String busLocation = '/parent/bus-location';
  static const String activeTrip = '/parent/active-trip';
  static const String streamAvailable = '/parent/stream-available';
  static const String tripHistory = '/parent/trip-history';
  static const String notifications = '/parent/notifications';
  static const String markNotificationRead = '/parent/notifications';
  static const String markAllNotificationsRead = '/parent/notifications/read-all';
  
  // Socket events
  static const String socketLocationUpdate = 'location:updated';
  static const String socketLocationSubscribe = 'location:subscribe';
  static const String socketLocationUnsubscribe = 'location:unsubscribe';
  static const String socketStreamJoin = 'stream:join';
  static const String socketStreamLeave = 'stream:leave';
  static const String socketWebrtcOffer = 'webrtc:offer';
  static const String socketWebrtcAnswer = 'webrtc:answer';
  static const String socketWebrtcIceCandidate = 'webrtc:ice-candidate';
  static const String socketStreamStarted = 'stream:started';
  static const String socketStreamStopped = 'stream:stopped';
  static const String socketEmergencyAlert = 'emergency:alert';
}

class StorageKeys {
  static const String authToken = 'auth_token';
  static const String userId = 'user_id';
  static const String userRole = 'user_role';
  static const String userName = 'user_name';
  static const String userEmail = 'user_email';
  static const String fcmToken = 'fcm_token';
  static const String selectedChildId = 'selected_child_id';
  static const String isDarkMode = 'is_dark_mode';
}

class AppConstants {
  static const int locationUpdateInterval = 5; // seconds
  static const int connectionTimeout = 30; // seconds
  static const int receiveTimeout = 30; // seconds
  static const double defaultMapZoom = 15.0;
  static const int alertDistanceFar = 500; // meters
  static const int alertDistanceNear = 100; // meters
}
