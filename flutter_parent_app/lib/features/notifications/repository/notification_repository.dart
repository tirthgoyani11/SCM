import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';

class NotificationRepository {
  final ApiService apiService;

  NotificationRepository({required this.apiService});

  Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    try {
      final response = await apiService.getNotifications(page: page);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['notifications'] ?? [];
        final notifications = data.map((json) => NotificationModel.fromJson(json)).toList();
        
        return {
          'notifications': notifications,
          'unreadCount': response.data['unreadCount'] ?? 0,
          'totalPages': response.data['pagination']?['pages'] ?? 1,
        };
      }
      return {'notifications': [], 'unreadCount': 0, 'totalPages': 1};
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await apiService.markNotificationRead(notificationId);
  }

  Future<void> markAllAsRead() async {
    await apiService.markAllNotificationsRead();
  }
}
