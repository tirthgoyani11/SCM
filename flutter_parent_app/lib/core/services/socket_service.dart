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
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .build(),
    );

    _socket!.onConnect((_) {
      print('Socket connected');
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
    });

    _socket!.onConnectError((error) {
      print('Socket connection error: $error');
    });

    _socket!.onError((error) {
      print('Socket error: $error');
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  // Location tracking
  void subscribeToBus(String busId) {
    _socket?.emit(ApiConstants.socketLocationSubscribe, busId);
  }

  void unsubscribeFromBus(String busId) {
    _socket?.emit(ApiConstants.socketLocationUnsubscribe, busId);
  }

  void onLocationUpdate(Function(dynamic) callback) {
    _socket?.on(ApiConstants.socketLocationUpdate, callback);
  }

  void offLocationUpdate() {
    _socket?.off(ApiConstants.socketLocationUpdate);
  }

  // Live streaming
  void joinStream(String tripId) {
    _socket?.emit(ApiConstants.socketStreamJoin, tripId);
  }

  void leaveStream(String tripId) {
    _socket?.emit(ApiConstants.socketStreamLeave, tripId);
  }

  void sendWebRTCAnswer(String tripId, dynamic signal) {
    _socket?.emit(ApiConstants.socketWebrtcAnswer, {
      'tripId': tripId,
      'signal': signal,
    });
  }

  void sendIceCandidate(String tripId, dynamic signal) {
    _socket?.emit(ApiConstants.socketWebrtcIceCandidate, {
      'tripId': tripId,
      'signal': signal,
    });
  }

  void onWebRTCOffer(Function(dynamic) callback) {
    _socket?.on(ApiConstants.socketWebrtcOffer, callback);
  }

  void onIceCandidate(Function(dynamic) callback) {
    _socket?.on(ApiConstants.socketWebrtcIceCandidate, callback);
  }

  void onStreamStarted(Function(dynamic) callback) {
    _socket?.on(ApiConstants.socketStreamStarted, callback);
  }

  void onStreamStopped(Function(dynamic) callback) {
    _socket?.on(ApiConstants.socketStreamStopped, callback);
  }

  void offStreamEvents() {
    _socket?.off(ApiConstants.socketWebrtcOffer);
    _socket?.off(ApiConstants.socketWebrtcIceCandidate);
    _socket?.off(ApiConstants.socketStreamStarted);
    _socket?.off(ApiConstants.socketStreamStopped);
  }

  // Emergency alerts
  void onEmergencyAlert(Function(dynamic) callback) {
    _socket?.on(ApiConstants.socketEmergencyAlert, callback);
  }

  void offEmergencyAlert() {
    _socket?.off(ApiConstants.socketEmergencyAlert);
  }

  // Student events
  void onStudentPickup(Function(dynamic) callback) {
    _socket?.on('student:pickup', callback);
  }

  void onStudentDrop(Function(dynamic) callback) {
    _socket?.on('student:drop', callback);
  }

  void offStudentEvents() {
    _socket?.off('student:pickup');
    _socket?.off('student:drop');
  }
}
