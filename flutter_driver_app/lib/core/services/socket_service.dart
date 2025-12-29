import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await _storage.read(key: StorageKeys.authToken);
    if (token == null) return;

    _socket = io.io(
      'http://localhost:3000',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      print('Socket connected');
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  // Location updates
  void sendLocationUpdate({
    required String busId,
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
  }) {
    _socket?.emit('location:update', {
      'busId': busId,
      'latitude': latitude,
      'longitude': longitude,
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
    });
  }

  // Trip events
  void emitTripStarted(String tripId, String busId) {
    _socket?.emit('trip:started', {
      'tripId': tripId,
      'busId': busId,
    });
  }

  void emitTripEnded(String tripId, String busId) {
    _socket?.emit('trip:ended', {
      'tripId': tripId,
      'busId': busId,
    });
  }

  // WebRTC streaming
  void emitStreamStarted(String tripId) {
    _socket?.emit('stream:started', tripId);
  }

  void emitStreamStopped(String tripId) {
    _socket?.emit('stream:stopped', tripId);
  }

  void joinStream(String tripId) {
    _socket?.emit('stream:join', tripId);
  }

  void sendWebRTCOffer(String tripId, dynamic signal) {
    _socket?.emit('webrtc:offer', {
      'tripId': tripId,
      'signal': signal,
    });
  }

  void sendIceCandidate(String tripId, dynamic signal) {
    _socket?.emit('webrtc:ice-candidate', {
      'tripId': tripId,
      'signal': signal,
    });
  }

  void onWebRTCAnswer(Function(dynamic) callback) {
    _socket?.on('webrtc:answer', callback);
  }

  void onIceCandidate(Function(dynamic) callback) {
    _socket?.on('webrtc:ice-candidate', callback);
  }

  void onViewerJoined(Function(dynamic) callback) {
    _socket?.on('stream:viewer-joined', callback);
  }

  void onViewerLeft(Function(dynamic) callback) {
    _socket?.on('stream:viewer-left', callback);
  }

  void offStreamEvents() {
    _socket?.off('webrtc:answer');
    _socket?.off('webrtc:ice-candidate');
    _socket?.off('stream:viewer-joined');
    _socket?.off('stream:viewer-left');
  }

  // Emergency
  void emitEmergency({
    required String tripId,
    required String type,
    required double latitude,
    required double longitude,
  }) {
    _socket?.emit('emergency:alert', {
      'tripId': tripId,
      'type': type,
      'location': {
        'latitude': latitude,
        'longitude': longitude,
      },
    });
  }
}
