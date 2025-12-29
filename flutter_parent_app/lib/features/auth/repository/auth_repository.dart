import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/constants.dart';

class AuthRepository {
  final ApiService apiService;
  final FlutterSecureStorage storage;

  AuthRepository({
    required this.apiService,
    required this.storage,
  });

  Future<bool> isLoggedIn() async {
    final token = await storage.read(key: StorageKeys.authToken);
    return token != null;
  }

  Future<User?> login(String email, String password) async {
    try {
      final response = await apiService.login(email, password);
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        // Save token
        await storage.write(key: StorageKeys.authToken, value: data['token']);
        
        // Save user info
        final user = User.fromJson(data['user']);
        await storage.write(key: StorageKeys.userId, value: user.id);
        await storage.write(key: StorageKeys.userRole, value: user.role);
        await storage.write(key: StorageKeys.userName, value: user.name);
        await storage.write(key: StorageKeys.userEmail, value: user.email);
        
        return user;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final response = await apiService.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      
      if (response.statusCode == 201) {
        final data = response.data;
        
        // Save token
        await storage.write(key: StorageKeys.authToken, value: data['token']);
        
        // Save user info
        final user = User.fromJson(data['user']);
        await storage.write(key: StorageKeys.userId, value: user.id);
        await storage.write(key: StorageKeys.userRole, value: user.role);
        await storage.write(key: StorageKeys.userName, value: user.name);
        await storage.write(key: StorageKeys.userEmail, value: user.email);
        
        return user;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> getProfile() async {
    try {
      final response = await apiService.getProfile();
      
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateFcmToken(String fcmToken) async {
    try {
      await apiService.updateFcmToken(fcmToken);
      await storage.write(key: StorageKeys.fcmToken, value: fcmToken);
    } catch (e) {
      // Silently fail
    }
  }

  Future<User?> updateProfile({String? name, String? phone}) async {
    try {
      final response = await apiService.updateProfile(name: name, phone: phone);
      
      if (response.statusCode == 200) {
        final user = User.fromJson(response.data);
        if (name != null) {
          await storage.write(key: StorageKeys.userName, value: name);
        }
        return user;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await apiService.changePassword(currentPassword, newPassword);
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await storage.deleteAll();
  }

  Future<String?> getStoredUserName() async {
    return storage.read(key: StorageKeys.userName);
  }

  Future<String?> getStoredUserEmail() async {
    return storage.read(key: StorageKeys.userEmail);
  }
}
