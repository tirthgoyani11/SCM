import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_interfaces.dart';
import 'gps_sources.dart';
import 'video_sources.dart';
import 'socket_service.dart';

/// Unified Telemetry Service
/// Manages all input sources (GPS + Video) and provides a single interface
/// for the IoT edge device functionality
class UnifiedTelemetryService {
  static final UnifiedTelemetryService _instance = UnifiedTelemetryService._internal();
  factory UnifiedTelemetryService() => _instance;
  UnifiedTelemetryService._internal();

  final DeviceManager _deviceManager = DeviceManager();
  final SocketService _socketService = SocketService();
  
  // State
  bool _isTracking = false;
  String? _currentTripId;
  String? _busId;
  
  // Telemetry buffer for offline mode
  final List<Map<String, dynamic>> _telemetryBuffer = [];
  static const int _maxBufferSize = 500;
  
  // Stream subscriptions
  StreamSubscription<GpsData>? _gpsSubscription;

  // Callbacks
  Function(GpsData)? onLocationUpdate;
  Function(String, dynamic)? onError;

  /// Initialize with default sources
  Future<void> initialize() async {
    // Register default GPS sources
    _deviceManager.registerGpsSource(PhoneGpsSource());
    
    // Register default video source
    _deviceManager.registerVideoSource(PhoneCameraSource(useRearCamera: true));
    
    // Load saved configurations
    await _loadSavedConfig();
    
    debugPrint('📡 Unified Telemetry Service initialized');
  }

  /// Load saved device configurations
  Future<void> _loadSavedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load RTSP cameras
      final rtspCameras = prefs.getStringList('rtsp_cameras') ?? [];
      for (final config in rtspCameras) {
        final parts = config.split('|');
        if (parts.length >= 2) {
          _deviceManager.registerVideoSource(RtspCameraSource(
            rtspUrl: parts[0],
            displayName: parts[1],
            username: parts.length > 2 ? parts[2] : null,
            password: parts.length > 3 ? parts[3] : null,
          ));
        }
      }

      // Load IP cameras
      final ipCameras = prefs.getStringList('ip_cameras') ?? [];
      for (final config in ipCameras) {
        final parts = config.split('|');
        if (parts.length >= 2) {
          _deviceManager.registerVideoSource(IpCameraSource(
            cameraUrl: parts[0],
            displayName: parts[1],
            username: parts.length > 2 ? parts[2] : null,
            password: parts.length > 3 ? parts[3] : null,
          ));
        }
      }

      // Load external GPS devices
      final externalGps = prefs.getStringList('external_gps') ?? [];
      for (final config in externalGps) {
        final parts = config.split('|');
        if (parts.length >= 2) {
          final type = parts[0];
          switch (type) {
            case 'bluetooth':
              _deviceManager.registerGpsSource(BluetoothGpsSource(
                deviceId: parts[1],
                deviceName: parts.length > 2 ? parts[2] : 'Bluetooth GPS',
              ));
              break;
            case 'fleet':
              _deviceManager.registerGpsSource(FleetTrackerGpsSource(
                trackerId: parts[1],
                apiEndpoint: parts[2],
                apiKey: parts.length > 3 ? parts[3] : '',
              ));
              break;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading device config: $e');
    }
  }

  /// Add a new RTSP camera (Dashcam/CCTV)
  Future<void> addRtspCamera({
    required String rtspUrl,
    required String name,
    String? username,
    String? password,
  }) async {
    final source = RtspCameraSource(
      rtspUrl: rtspUrl,
      displayName: name,
      username: username,
      password: password,
    );
    
    _deviceManager.registerVideoSource(source);
    
    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    final cameras = prefs.getStringList('rtsp_cameras') ?? [];
    cameras.add('$rtspUrl|$name|${username ?? ''}|${password ?? ''}');
    await prefs.setStringList('rtsp_cameras', cameras);
    
    debugPrint('📹 Added RTSP camera: $name');
  }

  /// Add a new IP camera (CCTV)
  Future<void> addIpCamera({
    required String cameraUrl,
    required String name,
    String? username,
    String? password,
  }) async {
    final source = IpCameraSource(
      cameraUrl: cameraUrl,
      displayName: name,
      username: username,
      password: password,
    );
    
    _deviceManager.registerVideoSource(source);
    
    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    final cameras = prefs.getStringList('ip_cameras') ?? [];
    cameras.add('$cameraUrl|$name|${username ?? ''}|${password ?? ''}');
    await prefs.setStringList('ip_cameras', cameras);
    
    debugPrint('📹 Added IP camera: $name');
  }

  /// Add external GPS device
  Future<void> addExternalGps({
    required String type, // 'bluetooth', 'fleet', 'obdii'
    required String deviceId,
    String? deviceName,
    String? apiEndpoint,
    String? apiKey,
  }) async {
    GpsSource source;
    
    switch (type) {
      case 'bluetooth':
        source = BluetoothGpsSource(
          deviceId: deviceId,
          deviceName: deviceName ?? 'Bluetooth GPS',
        );
        break;
      case 'fleet':
        source = FleetTrackerGpsSource(
          trackerId: deviceId,
          apiEndpoint: apiEndpoint ?? '',
          apiKey: apiKey ?? '',
        );
        break;
      case 'obdii':
        source = ObdiiGpsSource(deviceAddress: deviceId);
        break;
      default:
        throw ArgumentError('Unknown GPS type: $type');
    }
    
    _deviceManager.registerGpsSource(source);
    
    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    final gpsDevices = prefs.getStringList('external_gps') ?? [];
    gpsDevices.add('$type|$deviceId|${deviceName ?? ''}|${apiEndpoint ?? ''}|${apiKey ?? ''}');
    await prefs.setStringList('external_gps', gpsDevices);
    
    debugPrint('📍 Added external GPS: ${source.name}');
  }

  /// Get all available video sources
  List<VideoSource> get videoSources => _deviceManager.videoSources;

  /// Get all available GPS sources
  List<GpsSource> get gpsSources => _deviceManager.gpsSources;

  /// Get active video source
  VideoSource? get activeVideoSource => _deviceManager.activeVideoSource;

  /// Get active GPS source
  GpsSource? get activeGpsSource => _deviceManager.activeGpsSource;

  /// Select video source
  Future<bool> selectVideoSource(VideoSource source) async {
    return await _deviceManager.setActiveVideoSource(source);
  }

  /// Select GPS source
  Future<bool> selectGpsSource(GpsSource source) async {
    final success = await _deviceManager.setActiveGpsSource(source);
    if (success && _isTracking) {
      // Restart GPS subscription with new source
      await _startGpsTracking();
    }
    return success;
  }

  /// Start tracking with selected sources
  Future<void> startTracking({
    required String tripId,
    required String busId,
  }) async {
    if (_isTracking) {
      debugPrint('⚠️ Already tracking');
      return;
    }

    _currentTripId = tripId;
    _busId = busId;
    _isTracking = true;

    // Auto-detect sources if not selected
    if (_deviceManager.activeGpsSource == null) {
      await _deviceManager.autoDetectSources();
    }

    // Start GPS tracking
    await _startGpsTracking();

    // Notify server
    _socketService.emit('tracking:started', {
      'tripId': tripId,
      'busId': busId,
      'gpsSource': _deviceManager.activeGpsSource?.type.name ?? 'unknown',
      'videoSource': _deviceManager.activeVideoSource?.type.name ?? 'none',
    });

    debugPrint('🚀 Tracking started for trip: $tripId');
  }

  /// Start GPS tracking subscription
  Future<void> _startGpsTracking() async {
    await _gpsSubscription?.cancel();
    
    final gpsSource = _deviceManager.activeGpsSource;
    if (gpsSource == null) {
      debugPrint('⚠️ No GPS source available');
      return;
    }

    if (!gpsSource.isConnected) {
      await gpsSource.connect();
    }

    _gpsSubscription = gpsSource.locationStream.listen(
      _handleGpsData,
      onError: (e) {
        debugPrint('❌ GPS error: $e');
        onError?.call('gps', e);
      },
    );
  }

  /// Handle incoming GPS data
  void _handleGpsData(GpsData data) {
    if (!_isTracking) return;

    final telemetry = {
      'type': 'location',
      'tripId': _currentTripId,
      'busId': _busId,
      'timestamp': data.timestamp.toIso8601String(),
      'location': data.toJson(),
      'source': data.source.name,
    };

    // Send to server
    if (_socketService.isConnected) {
      _socketService.emit('iot:telemetry', telemetry);
      _flushBuffer();
    } else {
      _bufferTelemetry(telemetry);
    }

    // Callback for UI
    onLocationUpdate?.call(data);
  }

  /// Buffer telemetry for offline mode
  void _bufferTelemetry(Map<String, dynamic> data) {
    if (_telemetryBuffer.length >= _maxBufferSize) {
      _telemetryBuffer.removeAt(0);
    }
    _telemetryBuffer.add(data);
  }

  /// Flush buffered telemetry
  void _flushBuffer() {
    if (_telemetryBuffer.isEmpty) return;
    
    for (final data in _telemetryBuffer) {
      _socketService.emit('iot:telemetry', data);
    }
    _telemetryBuffer.clear();
    debugPrint('📤 Flushed ${_telemetryBuffer.length} buffered records');
  }

  /// Start video streaming
  Future<void> startVideoStreaming() async {
    final videoSource = _deviceManager.activeVideoSource;
    if (videoSource == null) {
      debugPrint('⚠️ No video source selected');
      return;
    }

    if (!videoSource.isConnected) {
      await videoSource.connect();
    }

    await videoSource.startStreaming();

    _socketService.emit('stream:available', {
      'tripId': _currentTripId,
      'busId': _busId,
      'streamType': videoSource.type.name,
      'sourceName': videoSource.name,
    });

    debugPrint('🎥 Video streaming started: ${videoSource.name}');
  }

  /// Stop video streaming
  Future<void> stopVideoStreaming() async {
    final videoSource = _deviceManager.activeVideoSource;
    if (videoSource != null) {
      await videoSource.stopStreaming();
    }

    _socketService.emit('stream:stopped', {
      'tripId': _currentTripId,
      'busId': _busId,
    });

    debugPrint('🛑 Video streaming stopped');
  }

  /// Stop tracking
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    _isTracking = false;
    
    await _gpsSubscription?.cancel();
    _gpsSubscription = null;

    await stopVideoStreaming();

    _socketService.emit('tracking:stopped', {
      'tripId': _currentTripId,
      'busId': _busId,
    });

    _currentTripId = null;
    _busId = null;

    debugPrint('🛑 Tracking stopped');
  }

  /// Get current status
  Map<String, dynamic> getStatus() {
    return {
      'isTracking': _isTracking,
      'tripId': _currentTripId,
      'busId': _busId,
      'gpsSource': {
        'type': _deviceManager.activeGpsSource?.type.name,
        'name': _deviceManager.activeGpsSource?.name,
        'connected': _deviceManager.activeGpsSource?.isConnected ?? false,
      },
      'videoSource': {
        'type': _deviceManager.activeVideoSource?.type.name,
        'name': _deviceManager.activeVideoSource?.name,
        'connected': _deviceManager.activeVideoSource?.isConnected ?? false,
      },
      'availableGpsSources': _deviceManager.gpsSources.map((s) => s.name).toList(),
      'availableVideoSources': _deviceManager.videoSources.map((s) => s.name).toList(),
      'bufferedRecords': _telemetryBuffer.length,
    };
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopTracking();
    await _deviceManager.dispose();
  }
}
