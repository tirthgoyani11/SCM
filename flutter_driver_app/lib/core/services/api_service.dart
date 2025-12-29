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
        headers: {'Content-Type': 'application/json'},
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
            // Handle token expiry
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Auth
  Future<Response> login(String email, String password) async {
    return _dio.post(ApiConstants.login, data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> getProfile() async {
    return _dio.get(ApiConstants.profile);
  }

  Future<Response> updateFcmToken(String fcmToken) async {
    return _dio.put(ApiConstants.updateFcmToken, data: {'fcmToken': fcmToken});
  }

  // Driver
  Future<Response> getMyBus() async {
    return _dio.get(ApiConstants.myBus);
  }

  Future<Response> getActiveTrip() async {
    return _dio.get(ApiConstants.activeTrip);
  }

  Future<Response> startTrip(String type) async {
    return _dio.post(ApiConstants.startTrip, data: {'type': type});
  }

  Future<Response> endTrip(String tripId) async {
    return _dio.post('${ApiConstants.endTrip}/$tripId');
  }

  Future<Response> updateLocation({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
  }) async {
    return _dio.post(ApiConstants.updateLocation, data: {
      'latitude': latitude,
      'longitude': longitude,
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
    });
  }

  Future<Response> confirmPickup(String tripId, String studentId) async {
    return _dio.post('${ApiConstants.confirmPickup}/$tripId/$studentId');
  }

  Future<Response> confirmDrop(String tripId, String studentId) async {
    return _dio.post('${ApiConstants.confirmDrop}/$tripId/$studentId');
  }

  Future<Response> markAbsent(String tripId, String studentId) async {
    return _dio.post('${ApiConstants.markAbsent}/$tripId/$studentId');
  }

  Future<Response> toggleStream(String tripId, bool isActive) async {
    return _dio.post('${ApiConstants.toggleStream}/$tripId', data: {
      'isActive': isActive,
    });
  }

  Future<Response> sendEmergency({
    required String type,
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    return _dio.post(ApiConstants.emergency, data: {
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      if (description != null) 'description': description,
    });
  }

  Future<Response> getRouteStops() async {
    return _dio.get(ApiConstants.routeStops);
  }
}
