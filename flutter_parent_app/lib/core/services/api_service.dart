import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/constants.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: AppConstants.connectionTimeout),
        receiveTimeout: const Duration(seconds: AppConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: StorageKeys.authToken);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // Token expired - handle logout
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Auth APIs
  Future<Response> login(String email, String password) async {
    return _dio.post(ApiConstants.login, data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    return _dio.post(ApiConstants.register, data: {
      'email': email,
      'password': password,
      'name': name,
      'phone': phone,
      'role': 'parent',
    });
  }

  Future<Response> getProfile() async {
    return _dio.get(ApiConstants.profile);
  }

  Future<Response> updateFcmToken(String fcmToken) async {
    return _dio.put(ApiConstants.updateFcmToken, data: {
      'fcmToken': fcmToken,
    });
  }

  Future<Response> updateProfile({String? name, String? phone}) async {
    return _dio.put(ApiConstants.profile, data: {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
    });
  }

  Future<Response> changePassword(String currentPassword, String newPassword) async {
    return _dio.put(ApiConstants.changePassword, data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  // Parent APIs
  Future<Response> getChildren() async {
    return _dio.get(ApiConstants.children);
  }

  Future<Response> getBusLocation(String childId) async {
    return _dio.get('${ApiConstants.busLocation}/$childId');
  }

  Future<Response> getActiveTrip(String childId) async {
    return _dio.get('${ApiConstants.activeTrip}/$childId');
  }

  Future<Response> checkStreamAvailable(String childId) async {
    return _dio.get('${ApiConstants.streamAvailable}/$childId');
  }

  Future<Response> getTripHistory(String childId, {int page = 1, int limit = 10}) async {
    return _dio.get('${ApiConstants.tripHistory}/$childId', queryParameters: {
      'page': page,
      'limit': limit,
    });
  }

  Future<Response> getNotifications({int page = 1, int limit = 20}) async {
    return _dio.get(ApiConstants.notifications, queryParameters: {
      'page': page,
      'limit': limit,
    });
  }

  Future<Response> markNotificationRead(String notificationId) async {
    return _dio.put('${ApiConstants.markNotificationRead}/$notificationId/read');
  }

  Future<Response> markAllNotificationsRead() async {
    return _dio.put(ApiConstants.markAllNotificationsRead);
  }
}
