class Child {
  final String id;
  final String name;
  final String grade;
  final String section;
  final String rollNumber;
  final String? profileImage;
  final Bus? bus;
  final Stop? stop;

  Child({
    required this.id,
    required this.name,
    required this.grade,
    required this.section,
    required this.rollNumber,
    this.profileImage,
    this.bus,
    this.stop,
  });

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      grade: json['grade'] ?? '',
      section: json['section'] ?? '',
      rollNumber: json['rollNumber'] ?? '',
      profileImage: json['profileImage'],
      bus: json['busId'] != null ? Bus.fromJson(json['busId']) : null,
      stop: json['stopId'] != null ? Stop.fromJson(json['stopId']) : null,
    );
  }
}

class Bus {
  final String id;
  final String busNumber;
  final String licensePlate;
  final int capacity;
  final BusLocation? currentLocation;

  Bus({
    required this.id,
    required this.busNumber,
    required this.licensePlate,
    required this.capacity,
    this.currentLocation,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['_id'] ?? '',
      busNumber: json['busNumber'] ?? '',
      licensePlate: json['licensePlate'] ?? '',
      capacity: json['capacity'] ?? 0,
      currentLocation: json['currentLocation'] != null
          ? BusLocation.fromJson(json['currentLocation'])
          : null,
    );
  }
}

class BusLocation {
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed;
  final DateTime? timestamp;

  BusLocation({
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    this.timestamp,
  });

  factory BusLocation.fromJson(Map<String, dynamic> json) {
    return BusLocation(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      heading: json['heading']?.toDouble(),
      speed: json['speed']?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
    );
  }
}

class Stop {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? estimatedTime;
  final int order;

  Stop({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.estimatedTime,
    required this.order,
  });

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['location']?['latitude'] ?? 0).toDouble(),
      longitude: (json['location']?['longitude'] ?? 0).toDouble(),
      estimatedTime: json['estimatedTime'],
      order: json['order'] ?? 0,
    );
  }
}

class TrackingInfo {
  final Bus bus;
  final Stop? stop;
  final int? distance;
  final int? eta;

  TrackingInfo({
    required this.bus,
    this.stop,
    this.distance,
    this.eta,
  });

  factory TrackingInfo.fromJson(Map<String, dynamic> json) {
    return TrackingInfo(
      bus: Bus.fromJson(json['bus']),
      stop: json['stop'] != null ? Stop.fromJson(json['stop']) : null,
      distance: json['tracking']?['distance'],
      eta: json['tracking']?['eta'],
    );
  }
}

class Trip {
  final String id;
  final String type;
  final String status;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isLiveStreamActive;
  final Bus? bus;

  Trip({
    required this.id,
    required this.type,
    required this.status,
    this.startTime,
    this.endTime,
    required this.isLiveStreamActive,
    this.bus,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'])
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'])
          : null,
      isLiveStreamActive: json['isLiveStreamActive'] ?? false,
      bus: json['bus'] != null ? Bus.fromJson(json['bus']) : null,
    );
  }
}

class ActiveTripInfo {
  final bool active;
  final Trip? trip;
  final String childStatus;

  ActiveTripInfo({
    required this.active,
    this.trip,
    required this.childStatus,
  });

  factory ActiveTripInfo.fromJson(Map<String, dynamic> json) {
    return ActiveTripInfo(
      active: json['active'] ?? false,
      trip: json['trip'] != null ? Trip.fromJson(json['trip']) : null,
      childStatus: json['childStatus'] ?? 'pending',
    );
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? '',
      data: json['data'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class User {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String role;
  final String? profileImage;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
      profileImage: json['profileImage'],
    );
  }
}
