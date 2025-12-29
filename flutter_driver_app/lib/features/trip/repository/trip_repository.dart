import '../../../core/services/api_service.dart';

class TripRepository {
  final ApiService _apiService;

  TripRepository({required ApiService apiService}) : _apiService = apiService;

  Future<Map<String, dynamic>?> getAssignedBus() async {
    return await _apiService.getAssignedBus();
  }

  Future<Map<String, dynamic>?> getCurrentTrip() async {
    return await _apiService.getCurrentTrip();
  }

  Future<Map<String, dynamic>> startTrip(String busId, String routeId) async {
    return await _apiService.startTrip(busId, routeId);
  }

  Future<Map<String, dynamic>> endTrip(String tripId) async {
    return await _apiService.endTrip(tripId);
  }

  Future<Map<String, dynamic>> updateLocation(
    String tripId,
    double latitude,
    double longitude,
    double? speed,
    double? heading,
  ) async {
    return await _apiService.updateLocation(
      tripId,
      latitude,
      longitude,
      speed,
      heading,
    );
  }

  Future<Map<String, dynamic>> confirmStudentPickup(
    String tripId,
    String studentId,
  ) async {
    return await _apiService.confirmStudentPickup(tripId, studentId);
  }

  Future<Map<String, dynamic>> confirmStudentDropoff(
    String tripId,
    String studentId,
  ) async {
    return await _apiService.confirmStudentDropoff(tripId, studentId);
  }

  Future<List<dynamic>> getTripStudents(String tripId) async {
    return await _apiService.getTripStudents(tripId);
  }

  Future<List<dynamic>> getRouteStops(String routeId) async {
    return await _apiService.getRouteStops(routeId);
  }

  Future<Map<String, dynamic>> sendEmergencyAlert(
    String tripId,
    String alertType,
    String message,
    double latitude,
    double longitude,
  ) async {
    return await _apiService.sendEmergencyAlert(
      tripId,
      alertType,
      message,
      latitude,
      longitude,
    );
  }

  Future<List<dynamic>> getTripHistory({int page = 1, int limit = 20}) async {
    return await _apiService.getTripHistory(page: page, limit: limit);
  }
}
