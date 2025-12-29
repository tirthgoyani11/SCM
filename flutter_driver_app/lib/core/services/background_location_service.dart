import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import '../services/socket_service.dart';

/// Background Location Service
/// Enables continuous GPS tracking even when app is in background
/// Essential for IoT edge device functionality
class BackgroundLocationService {
  static final BackgroundLocationService _instance = BackgroundLocationService._internal();
  factory BackgroundLocationService() => _instance;
  BackgroundLocationService._internal();

  final FlutterBackgroundService _service = FlutterBackgroundService();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  bool _isRunning = false;

  /// Initialize the background service
  Future<void> initialize() async {
    // Initialize notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);

    // Configure background service
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'school_bus_driver_tracking',
        initialNotificationTitle: 'School Bus Tracking',
        initialNotificationContent: 'Location tracking is active',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );

    debugPrint('📍 Background location service initialized');
  }

  /// Start background tracking
  Future<void> startTracking({
    required String tripId,
    required String busId,
    required String socketUrl,
    required String token,
  }) async {
    if (_isRunning) {
      debugPrint('⚠️ Background tracking already running');
      return;
    }

    // Pass data to background service
    _service.invoke('setData', {
      'tripId': tripId,
      'busId': busId,
      'socketUrl': socketUrl,
      'token': token,
    });

    await _service.startService();
    _isRunning = true;
    debugPrint('🚀 Background location tracking started');
  }

  /// Stop background tracking
  Future<void> stopTracking() async {
    if (!_isRunning) return;
    
    _service.invoke('stop');
    _isRunning = false;
    debugPrint('🛑 Background location tracking stopped');
  }

  /// Check if service is running
  Future<bool> isRunning() async {
    return await _service.isRunning();
  }

  /// Update notification
  void updateNotification(String title, String content) {
    _service.invoke('updateNotification', {
      'title': title,
      'content': content,
    });
  }
}

/// Background service entry point
@pragma('vm:entry-point')
Future<void> _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  String? tripId;
  String? busId;
  String? socketUrl;
  String? token;
  StreamSubscription<Position>? positionSubscription;
  SocketService? socketService;

  // Handle data from main app
  service.on('setData').listen((event) {
    tripId = event?['tripId'];
    busId = event?['busId'];
    socketUrl = event?['socketUrl'];
    token = event?['token'];
    
    // Connect socket
    if (socketUrl != null && token != null) {
      socketService = SocketService();
      socketService!.connect(socketUrl!, token!);
    }
  });

  // Handle stop request
  service.on('stop').listen((event) async {
    await positionSubscription?.cancel();
    socketService?.disconnect();
    service.stopSelf();
  });

  // Handle notification update
  service.on('updateNotification').listen((event) {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: event?['title'] ?? 'School Bus Tracking',
        content: event?['content'] ?? 'Location tracking is active',
      );
    }
  });

  // Set as foreground service on Android
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  // Start location tracking
  const locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );

  positionSubscription = Geolocator.getPositionStream(
    locationSettings: locationSettings,
  ).listen((Position position) {
    // Send location to server
    if (tripId != null && busId != null && socketService != null) {
      socketService!.emit('location:update', {
        'tripId': tripId,
        'busId': busId,
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'speed': position.speed,
          'heading': position.heading,
          'accuracy': position.accuracy,
          'timestamp': DateTime.now().toIso8601String(),
        },
      });

      // Update notification with current speed
      final speedKmh = (position.speed * 3.6).toStringAsFixed(1);
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Trip Active',
          content: 'Speed: $speedKmh km/h',
        );
      }
    }

    debugPrint('📍 BG Location: ${position.latitude}, ${position.longitude}');
  });

  debugPrint('🔄 Background service running');
}

/// iOS background handler
@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  return true;
}
