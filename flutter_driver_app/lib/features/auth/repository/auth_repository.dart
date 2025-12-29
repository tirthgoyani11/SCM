import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/services/api_service.dart';

class AuthRepository {
  final ApiService _apiService;
  final FlutterSecureStorage _storage;

  AuthRepository({
    required ApiService apiService,
    required FlutterSecureStorage storage,
  })  : _apiService = apiService,
        _storage = storage;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiService.login(email, password);
    
    // Store tokens
    await _storage.write(key: 'access_token', value: response['token']);
    await _storage.write(key: 'user_id', value: response['user']['id']);
    await _storage.write(key: 'user_role', value: response['user']['role']);
    
    return response;
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: 'user_role');
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    return await _apiService.getCurrentUser();
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    return await _apiService.updateProfile(data);
  }

  Future<void> updateFcmToken(String fcmToken) async {
    await _apiService.updateFcmToken(fcmToken);
  }
}
