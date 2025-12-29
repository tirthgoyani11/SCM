import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/socket_service.dart';

class TrackingRepository {
  final ApiService apiService;
  final SocketService socketService;

  TrackingRepository({
    required this.apiService,
    required this.socketService,
  });

  Future<List<Child>> getChildren() async {
    try {
      final response = await apiService.getChildren();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Child.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<TrackingInfo?> getBusLocation(String childId) async {
    try {
      final response = await apiService.getBusLocation(childId);
      if (response.statusCode == 200) {
        return TrackingInfo.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<ActiveTripInfo?> getActiveTrip(String childId) async {
    try {
      final response = await apiService.getActiveTrip(childId);
      if (response.statusCode == 200) {
        return ActiveTripInfo.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> checkStreamAvailable(String childId) async {
    try {
      final response = await apiService.checkStreamAvailable(childId);
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Trip>> getTripHistory(String childId, {int page = 1}) async {
    try {
      final response = await apiService.getTripHistory(childId, page: page);
      if (response.statusCode == 200) {
        final List<dynamic> trips = response.data['trips'] ?? [];
        return trips.map((json) => Trip.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
