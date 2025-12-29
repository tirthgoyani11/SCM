import 'dart:async';
import 'package:flutter/foundation.dart';

/// Video Source Types
enum VideoSourceType {
  phoneCamera,    // Built-in phone camera (IoT Edge)
  dashcam,        // External dashcam via RTSP/RTMP
  cctv,           // CCTV camera via RTSP/RTMP
  webcam,         // USB webcam (for tablets)
}

/// GPS Source Types
enum GpsSourceType {
  phoneGps,       // Built-in phone GPS
  externalBluetooth,  // Bluetooth GPS device
  externalUsb,    // USB GPS dongle
  obdii,          // OBD-II GPS tracker
  dedicatedTracker,   // Dedicated fleet GPS tracker
}

/// Abstract Video Source Interface
abstract class VideoSource {
  VideoSourceType get type;
  String get name;
  bool get isConnected;
  
  Future<bool> connect();
  Future<void> disconnect();
  Future<Stream<List<int>>?> getVideoStream();
  Future<void> startStreaming();
  Future<void> stopStreaming();
}

/// Abstract GPS Source Interface
abstract class GpsSource {
  GpsSourceType get type;
  String get name;
  bool get isConnected;
  
  Future<bool> connect();
  Future<void> disconnect();
  Stream<GpsData> get locationStream;
}

/// GPS Data Model
class GpsData {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? speed;
  final double? heading;
  final double? accuracy;
  final DateTime timestamp;
  final GpsSourceType source;

  GpsData({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.speed,
    this.heading,
    this.accuracy,
    required this.timestamp,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'speed': speed,
    'heading': heading,
    'accuracy': accuracy,
    'timestamp': timestamp.toIso8601String(),
    'source': source.name,
  };
}

/// Video Stream Configuration
class VideoStreamConfig {
  final VideoSourceType type;
  final String? rtspUrl;      // For dashcam/CCTV
  final String? rtmpUrl;      // Alternative stream URL
  final String? username;     // Authentication
  final String? password;
  final int quality;          // 1-100
  final bool useRearCamera;   // For phone camera

  VideoStreamConfig({
    required this.type,
    this.rtspUrl,
    this.rtmpUrl,
    this.username,
    this.password,
    this.quality = 70,
    this.useRearCamera = true,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'rtspUrl': rtspUrl,
    'rtmpUrl': rtmpUrl,
    'quality': quality,
  };
}

/// GPS Device Configuration
class GpsDeviceConfig {
  final GpsSourceType type;
  final String? deviceId;       // Bluetooth device ID
  final String? serialPort;     // USB serial port
  final int? baudRate;          // Serial baud rate
  final String? apiEndpoint;    // For cloud-connected trackers

  GpsDeviceConfig({
    required this.type,
    this.deviceId,
    this.serialPort,
    this.baudRate,
    this.apiEndpoint,
  });
}

/// Device Manager - Manages all connected devices
class DeviceManager {
  static final DeviceManager _instance = DeviceManager._internal();
  factory DeviceManager() => _instance;
  DeviceManager._internal();

  // Active sources
  VideoSource? _activeVideoSource;
  GpsSource? _activeGpsSource;
  
  // All registered sources
  final List<VideoSource> _videoSources = [];
  final List<GpsSource> _gpsSources = [];

  // Callbacks
  Function(VideoSource)? onVideoSourceChanged;
  Function(GpsSource)? onGpsSourceChanged;

  /// Register a video source
  void registerVideoSource(VideoSource source) {
    _videoSources.add(source);
    debugPrint('📹 Registered video source: ${source.name}');
  }

  /// Register a GPS source
  void registerGpsSource(GpsSource source) {
    _gpsSources.add(source);
    debugPrint('📍 Registered GPS source: ${source.name}');
  }

  /// Get all available video sources
  List<VideoSource> get videoSources => List.unmodifiable(_videoSources);

  /// Get all available GPS sources
  List<GpsSource> get gpsSources => List.unmodifiable(_gpsSources);

  /// Get active video source
  VideoSource? get activeVideoSource => _activeVideoSource;

  /// Get active GPS source
  GpsSource? get activeGpsSource => _activeGpsSource;

  /// Set active video source
  Future<bool> setActiveVideoSource(VideoSource source) async {
    // Disconnect current source
    if (_activeVideoSource != null) {
      await _activeVideoSource!.disconnect();
    }
    
    // Connect new source
    final connected = await source.connect();
    if (connected) {
      _activeVideoSource = source;
      onVideoSourceChanged?.call(source);
      debugPrint('📹 Active video source: ${source.name}');
    }
    return connected;
  }

  /// Set active GPS source
  Future<bool> setActiveGpsSource(GpsSource source) async {
    // Disconnect current source
    if (_activeGpsSource != null) {
      await _activeGpsSource!.disconnect();
    }
    
    // Connect new source
    final connected = await source.connect();
    if (connected) {
      _activeGpsSource = source;
      onGpsSourceChanged?.call(source);
      debugPrint('📍 Active GPS source: ${source.name}');
    }
    return connected;
  }

  /// Auto-detect and connect best available sources
  Future<void> autoDetectSources() async {
    // Try to find and connect video sources
    for (final source in _videoSources) {
      if (await source.connect()) {
        _activeVideoSource = source;
        break;
      }
    }

    // Try to find and connect GPS sources
    for (final source in _gpsSources) {
      if (await source.connect()) {
        _activeGpsSource = source;
        break;
      }
    }
  }

  /// Dispose all sources
  Future<void> dispose() async {
    for (final source in _videoSources) {
      await source.disconnect();
    }
    for (final source in _gpsSources) {
      await source.disconnect();
    }
    _videoSources.clear();
    _gpsSources.clear();
  }
}
