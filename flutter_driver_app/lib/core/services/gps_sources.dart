import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'device_interfaces.dart';

/// Phone GPS Source - Built-in smartphone GPS
class PhoneGpsSource implements GpsSource {
  @override
  GpsSourceType get type => GpsSourceType.phoneGps;
  
  @override
  String get name => 'Phone GPS';
  
  bool _isConnected = false;
  @override
  bool get isConnected => _isConnected;

  StreamSubscription<Position>? _subscription;
  final StreamController<GpsData> _controller = StreamController<GpsData>.broadcast();

  @override
  Stream<GpsData> get locationStream => _controller.stream;

  @override
  Future<bool> connect() async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return false;
      }

      // Start listening to position updates
      const settings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      );

      _subscription = Geolocator.getPositionStream(locationSettings: settings)
          .listen((position) {
        _controller.add(GpsData(
          latitude: position.latitude,
          longitude: position.longitude,
          altitude: position.altitude,
          speed: position.speed,
          heading: position.heading,
          accuracy: position.accuracy,
          timestamp: DateTime.now(),
          source: GpsSourceType.phoneGps,
        ));
      });

      _isConnected = true;
      debugPrint('📍 Phone GPS connected');
      return true;
    } catch (e) {
      debugPrint('❌ Phone GPS connection failed: $e');
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    _isConnected = false;
    debugPrint('📍 Phone GPS disconnected');
  }
}

/// Bluetooth GPS Source - External Bluetooth GPS device
class BluetoothGpsSource implements GpsSource {
  final String deviceId;
  final String deviceName;

  BluetoothGpsSource({
    required this.deviceId,
    required this.deviceName,
  });

  @override
  GpsSourceType get type => GpsSourceType.externalBluetooth;
  
  @override
  String get name => 'Bluetooth GPS: $deviceName';
  
  bool _isConnected = false;
  @override
  bool get isConnected => _isConnected;

  final StreamController<GpsData> _controller = StreamController<GpsData>.broadcast();

  @override
  Stream<GpsData> get locationStream => _controller.stream;

  @override
  Future<bool> connect() async {
    try {
      // TODO: Implement Bluetooth connection using flutter_blue_plus
      // 1. Scan for device with deviceId
      // 2. Connect to device
      // 3. Subscribe to NMEA data characteristic
      // 4. Parse NMEA sentences to extract GPS data
      
      debugPrint('📍 Connecting to Bluetooth GPS: $deviceName');
      
      // Placeholder - implement actual Bluetooth connection
      // _isConnected = true;
      return false; // Not implemented yet
    } catch (e) {
      debugPrint('❌ Bluetooth GPS connection failed: $e');
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    _isConnected = false;
    debugPrint('📍 Bluetooth GPS disconnected');
  }

  /// Parse NMEA sentence to GpsData
  GpsData? _parseNmea(String nmea) {
    // Parse NMEA GPRMC or GPGGA sentences
    // Example: $GPRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W*6A
    try {
      final parts = nmea.split(',');
      if (parts[0] == '\$GPRMC' && parts[2] == 'A') {
        // Parse latitude
        final latRaw = double.parse(parts[3]);
        final latDeg = (latRaw / 100).floor();
        final latMin = latRaw - (latDeg * 100);
        var latitude = latDeg + (latMin / 60);
        if (parts[4] == 'S') latitude = -latitude;

        // Parse longitude
        final lonRaw = double.parse(parts[5]);
        final lonDeg = (lonRaw / 100).floor();
        final lonMin = lonRaw - (lonDeg * 100);
        var longitude = lonDeg + (lonMin / 60);
        if (parts[6] == 'W') longitude = -longitude;

        // Parse speed (knots to m/s)
        final speed = double.tryParse(parts[7])?.let((s) => s * 0.514444);
        
        // Parse heading
        final heading = double.tryParse(parts[8]);

        return GpsData(
          latitude: latitude,
          longitude: longitude,
          speed: speed,
          heading: heading,
          timestamp: DateTime.now(),
          source: GpsSourceType.externalBluetooth,
        );
      }
    } catch (e) {
      debugPrint('❌ NMEA parse error: $e');
    }
    return null;
  }
}

/// OBD-II GPS Source - Vehicle OBD-II tracker with GPS
class ObdiiGpsSource implements GpsSource {
  final String deviceAddress;

  ObdiiGpsSource({required this.deviceAddress});

  @override
  GpsSourceType get type => GpsSourceType.obdii;
  
  @override
  String get name => 'OBD-II GPS Tracker';
  
  bool _isConnected = false;
  @override
  bool get isConnected => _isConnected;

  final StreamController<GpsData> _controller = StreamController<GpsData>.broadcast();

  @override
  Stream<GpsData> get locationStream => _controller.stream;

  @override
  Future<bool> connect() async {
    try {
      // TODO: Implement OBD-II connection
      // Can use obd2_plugin or similar
      // OBD-II GPS trackers typically provide:
      // - GPS location via PID queries
      // - Vehicle speed from ECU
      // - Additional vehicle data
      
      debugPrint('📍 Connecting to OBD-II: $deviceAddress');
      return false; // Not implemented yet
    } catch (e) {
      debugPrint('❌ OBD-II connection failed: $e');
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    _isConnected = false;
    debugPrint('📍 OBD-II disconnected');
  }
}

/// External Fleet Tracker Source - Dedicated GPS tracker via API
class FleetTrackerGpsSource implements GpsSource {
  final String trackerId;
  final String apiEndpoint;
  final String apiKey;

  FleetTrackerGpsSource({
    required this.trackerId,
    required this.apiEndpoint,
    required this.apiKey,
  });

  @override
  GpsSourceType get type => GpsSourceType.dedicatedTracker;
  
  @override
  String get name => 'Fleet Tracker: $trackerId';
  
  bool _isConnected = false;
  @override
  bool get isConnected => _isConnected;

  Timer? _pollTimer;
  final StreamController<GpsData> _controller = StreamController<GpsData>.broadcast();

  @override
  Stream<GpsData> get locationStream => _controller.stream;

  @override
  Future<bool> connect() async {
    try {
      // Poll tracker API for location updates
      _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        await _fetchLocation();
      });
      
      _isConnected = true;
      debugPrint('📍 Fleet Tracker connected: $trackerId');
      return true;
    } catch (e) {
      debugPrint('❌ Fleet Tracker connection failed: $e');
      return false;
    }
  }

  Future<void> _fetchLocation() async {
    try {
      // TODO: Implement API call to tracker service
      // Example endpoints:
      // - GPS trackers like Teltonika, Queclink
      // - Fleet management APIs
      // - Custom tracker backends
      
      // final response = await http.get(
      //   Uri.parse('$apiEndpoint/trackers/$trackerId/location'),
      //   headers: {'Authorization': 'Bearer $apiKey'},
      // );
      // final data = jsonDecode(response.body);
      // _controller.add(GpsData(...));
    } catch (e) {
      debugPrint('❌ Fleet Tracker fetch error: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isConnected = false;
    debugPrint('📍 Fleet Tracker disconnected');
  }
}

// Extension for null-safe operations
extension NullableExtension<T> on T? {
  R? let<R>(R Function(T) block) => this == null ? null : block(this as T);
}
