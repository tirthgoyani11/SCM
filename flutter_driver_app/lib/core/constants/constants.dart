class ApiConstants {
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String profile = '/auth/profile';
  static const String updateFcmToken = '/auth/fcm-token';
  
  // Driver endpoints
  static const String myBus = '/driver/my-bus';
  static const String activeTrip = '/driver/active-trip';
  static const String startTrip = '/driver/start-trip';
  static const String endTrip = '/driver/end-trip';
  static const String updateLocation = '/driver/update-location';
  static const String confirmPickup = '/driver/confirm-pickup';
  static const String confirmDrop = '/driver/confirm-drop';
  static const String markAbsent = '/driver/mark-absent';
  static const String toggleStream = '/driver/toggle-stream';
  static const String emergency = '/driver/emergency';
  static const String routeStops = '/driver/route-stops';
}

class StorageKeys {
  static const String authToken = 'auth_token';
  static const String userId = 'user_id';
  static const String userRole = 'user_role';
  static const String userName = 'user_name';
  static const String userEmail = 'user_email';
  static const String fcmToken = 'fcm_token';
}

class AppConstants {
  static const int locationUpdateInterval = 5; // seconds
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;
}
