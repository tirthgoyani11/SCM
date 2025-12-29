import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'socket_service.dart';

/// IoT Edge Device Service
/// Transforms the driver's mobile phone into a smart IoT edge device
/// Capabilities:
/// - Continuous GPS tracking with background support
/// - Motion/acceleration detection for harsh braking/speeding alerts
/// - Battery monitoring for power management
/// - Offline data caching and sync
/// - Network quality monitoring
class IoTEdgeService {
  static final IoTEdgeService _instance = IoTEdgeService._internal();
  factory IoTEdgeService() => _instance;
  IoTEdgeService._internal();

  final SocketService _socketService = SocketService();
  
  // Stream subscriptions
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<BatteryState>? _batterySubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  // Sensor data
  final Battery _battery = Battery();
  
  // Edge device state
  bool _isTracking = false;
  String? _currentTripId;
  String? _busId;
  
  // Telemetry data buffer (for offline caching)
  final List<Map<String, dynamic>> _telemetryBuffer = [];
  static const int _maxBufferSize = 1000;
  
  // Motion detection thresholds
  static const double _harshBrakingThreshold = 15.0; // m/s²
  static const double _harshAccelerationThreshold = 12.0; // m/s²
  static const double _sharpTurnThreshold = 8.0; // m/s²
  
  // Previous accelerometer values for smoothing
  double _prevAccelX = 0;
  double _prevAccelY = 0;
  double _prevAccelZ = 0;
  
  // Network state
  bool _isOnline = true;
  int _batteryLevel = 100;
  
  // Callbacks
  Function(Position)? onLocationUpdate;
  Function(String, Map<String, dynamic>)? onDrivingEvent;
  Function(int)? onBatteryLevelChange;
  Function(bool)? onConnectivityChange;

  /// Initialize the IoT Edge Service
  Future<void> initialize() async {
    await _initializeConnectivity();
    await _initializeBattery();
    await _loadCachedTelemetry();
    debugPrint('📡 IoT Edge Service initialized');
  }

  /// Start edge device tracking for a trip
  Future<void> startTracking({
    required String tripId,
    required String busId,
    int locationIntervalMs = 3000,
  }) async {
    if (_isTracking) {
      debugPrint('⚠️ Already tracking');
      return;
    }

    _currentTripId = tripId;
    _busId = busId;
    _isTracking = true;

    // Start all sensors
    await _startGPSTracking(intervalMs: locationIntervalMs);
    _startMotionDetection();
    
    debugPrint('🚀 IoT Edge tracking started for trip: $tripId');
  }

  /// Stop edge device tracking
  Future<void> stopTracking() async {
    _isTracking = false;
    
    await _positionSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    
    _positionSubscription = null;
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    
    // Flush any remaining buffered data
    await _flushTelemetryBuffer();
    
    _currentTripId = null;
    _busId = null;
    
    debugPrint('🛑 IoT Edge tracking stopped');
  }

  /// Start GPS tracking with high accuracy
  Future<void> _startGPSTracking({int intervalMs = 3000}) async {
    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('❌ Location permissions permanently denied');
      return;
    }

    // Configure location settings for IoT edge use
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _handleLocationUpdate,
      onError: (error) {
        debugPrint('❌ GPS Error: $error');
      },
    );
  }

  /// Handle incoming GPS location updates
  void _handleLocationUpdate(Position position) {
    if (!_isTracking) return;

    final telemetryData = {
      'type': 'location',
      'tripId': _currentTripId,
      'busId': _busId,
      'timestamp': DateTime.now().toIso8601String(),
      'location': {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'altitude': position.altitude,
        'accuracy': position.accuracy,
        'speed': position.speed, // m/s
        'speedAccuracy': position.speedAccuracy,
        'heading': position.heading,
        'headingAccuracy': position.headingAccuracy,
      },
      'deviceInfo': {
        'batteryLevel': _batteryLevel,
        'isOnline': _isOnline,
      },
    };

    // Send or buffer telemetry
    _sendTelemetry(telemetryData);
    
    // Callback for UI updates
    onLocationUpdate?.call(position);

    // Check for speed-based events
    _checkSpeedEvents(position.speed);
  }

  /// Check for speed-related driving events
  void _checkSpeedEvents(double speedMs) {
    final speedKmh = speedMs * 3.6;
    
    // Speeding detection (adjust threshold as needed)
    if (speedKmh > 60) { // Example: 60 km/h school zone limit
      _reportDrivingEvent('speeding', {
        'speed': speedKmh,
        'limit': 60,
      });
    }
  }

  /// Start motion detection using accelerometer
  void _startMotionDetection() {
    _accelerometerSubscription = accelerometerEventStream().listen(
      _handleAccelerometerEvent,
      onError: (error) {
        debugPrint('❌ Accelerometer Error: $error');
      },
    );

    _gyroscopeSubscription = gyroscopeEventStream().listen(
      _handleGyroscopeEvent,
      onError: (error) {
        debugPrint('❌ Gyroscope Error: $error');
      },
    );
  }

  /// Handle accelerometer events for harsh driving detection
  void _handleAccelerometerEvent(AccelerometerEvent event) {
    if (!_isTracking) return;

    // Apply low-pass filter for smoothing
    const alpha = 0.8;
    final accelX = alpha * event.x + (1 - alpha) * _prevAccelX;
    final accelY = alpha * event.y + (1 - alpha) * _prevAccelY;
    final accelZ = alpha * event.z + (1 - alpha) * _prevAccelZ;

    // Calculate acceleration changes (jerk)
    final deltaX = (accelX - _prevAccelX).abs();
    final deltaY = (accelY - _prevAccelY).abs();
    final deltaZ = (accelZ - _prevAccelZ).abs();

    // Detect harsh braking (sudden deceleration in Y axis - forward/backward)
    if (deltaY > _harshBrakingThreshold) {
      _reportDrivingEvent('harsh_braking', {
        'intensity': deltaY,
        'threshold': _harshBrakingThreshold,
      });
    }

    // Detect harsh acceleration
    if (deltaY > _harshAccelerationThreshold && accelY > 0) {
      _reportDrivingEvent('harsh_acceleration', {
        'intensity': deltaY,
        'threshold': _harshAccelerationThreshold,
      });
    }

    // Detect sharp turns (X axis - left/right)
    if (deltaX > _sharpTurnThreshold) {
      _reportDrivingEvent('sharp_turn', {
        'intensity': deltaX,
        'direction': accelX > 0 ? 'right' : 'left',
        'threshold': _sharpTurnThreshold,
      });
    }

    _prevAccelX = accelX;
    _prevAccelY = accelY;
    _prevAccelZ = accelZ;
  }

  /// Handle gyroscope events for rotation detection
  void _handleGyroscopeEvent(GyroscopeEvent event) {
    // Can be used for additional motion analysis
    // e.g., detecting phone orientation, rotation patterns
  }

  /// Report a driving event
  void _reportDrivingEvent(String eventType, Map<String, dynamic> data) {
    final eventData = {
      'type': 'driving_event',
      'eventType': eventType,
      'tripId': _currentTripId,
      'busId': _busId,
      'timestamp': DateTime.now().toIso8601String(),
      'data': data,
    };

    _sendTelemetry(eventData);
    onDrivingEvent?.call(eventType, data);
    
    debugPrint('🚨 Driving Event: $eventType - $data');
  }

  /// Send telemetry data (with offline buffering)
  void _sendTelemetry(Map<String, dynamic> data) {
    if (_isOnline && _socketService.isConnected) {
      // Send immediately if online
      _socketService.emit('iot:telemetry', data);
      
      // Also try to flush buffer
      _flushTelemetryBuffer();
    } else {
      // Buffer for later sync
      _bufferTelemetry(data);
    }
  }

  /// Buffer telemetry data for offline sync
  void _bufferTelemetry(Map<String, dynamic> data) {
    if (_telemetryBuffer.length >= _maxBufferSize) {
      // Remove oldest entries if buffer is full
      _telemetryBuffer.removeAt(0);
    }
    _telemetryBuffer.add(data);
    _saveCachedTelemetry();
  }

  /// Flush buffered telemetry when back online
  Future<void> _flushTelemetryBuffer() async {
    if (_telemetryBuffer.isEmpty || !_isOnline) return;

    final dataToSend = List<Map<String, dynamic>>.from(_telemetryBuffer);
    _telemetryBuffer.clear();

    for (final data in dataToSend) {
      _socketService.emit('iot:telemetry', data);
      await Future.delayed(const Duration(milliseconds: 50)); // Rate limiting
    }

    await _clearCachedTelemetry();
    debugPrint('📤 Flushed ${dataToSend.length} buffered telemetry records');
  }

  /// Initialize connectivity monitoring
  Future<void> _initializeConnectivity() async {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final wasOnline = _isOnline;
        _isOnline = results.isNotEmpty && 
                    !results.contains(ConnectivityResult.none);
        
        if (_isOnline && !wasOnline) {
          // Back online - flush buffer
          _flushTelemetryBuffer();
        }
        
        onConnectivityChange?.call(_isOnline);
        debugPrint('📶 Connectivity: ${_isOnline ? "Online" : "Offline"}');
      },
    );

    // Check initial state
    final result = await Connectivity().checkConnectivity();
    _isOnline = result.isNotEmpty && !result.contains(ConnectivityResult.none);
  }

  /// Initialize battery monitoring
  Future<void> _initializeBattery() async {
    _batteryLevel = await _battery.batteryLevel;
    
    _batterySubscription = _battery.onBatteryStateChanged.listen(
      (BatteryState state) async {
        _batteryLevel = await _battery.batteryLevel;
        onBatteryLevelChange?.call(_batteryLevel);
        
        // Warn if battery is low
        if (_batteryLevel < 20) {
          debugPrint('⚠️ Low battery: $_batteryLevel%');
        }
      },
    );
  }

  /// Save telemetry buffer to local storage
  Future<void> _saveCachedTelemetry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(_telemetryBuffer);
      await prefs.setString('iot_telemetry_buffer', jsonData);
    } catch (e) {
      debugPrint('❌ Error saving telemetry cache: $e');
    }
  }

  /// Load cached telemetry from local storage
  Future<void> _loadCachedTelemetry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString('iot_telemetry_buffer');
      if (jsonData != null) {
        final List<dynamic> data = jsonDecode(jsonData);
        _telemetryBuffer.addAll(data.cast<Map<String, dynamic>>());
        debugPrint('📥 Loaded ${_telemetryBuffer.length} cached telemetry records');
      }
    } catch (e) {
      debugPrint('❌ Error loading telemetry cache: $e');
    }
  }

  /// Clear cached telemetry
  Future<void> _clearCachedTelemetry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('iot_telemetry_buffer');
    } catch (e) {
      debugPrint('❌ Error clearing telemetry cache: $e');
    }
  }

  /// Get current device status
  Map<String, dynamic> getDeviceStatus() {
    return {
      'isTracking': _isTracking,
      'tripId': _currentTripId,
      'busId': _busId,
      'batteryLevel': _batteryLevel,
      'isOnline': _isOnline,
      'bufferedRecords': _telemetryBuffer.length,
    };
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
    _batterySubscription?.cancel();
    _connectivitySubscription?.cancel();
  }
}
