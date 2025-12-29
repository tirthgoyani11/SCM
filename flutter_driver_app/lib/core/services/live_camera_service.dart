import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:camera/camera.dart';
import 'socket_service.dart';

/// Live Camera Streaming Service
/// Enables the driver's phone camera to stream live video to parents/admins
/// Supports:
/// - WebRTC peer-to-peer streaming
/// - Multiple viewer connections
/// - Front/rear camera switching
/// - Quality adaptation based on network
/// - Recording capabilities
class LiveCameraService {
  static final LiveCameraService _instance = LiveCameraService._internal();
  factory LiveCameraService() => _instance;
  LiveCameraService._internal();

  final SocketService _socketService = SocketService();
  
  // Camera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _currentCameraIndex = 0;
  
  // WebRTC
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final Map<String, RTCPeerConnection> _viewerConnections = {};
  
  // State
  bool _isStreaming = false;
  bool _isInitialized = false;
  String? _currentTripId;
  String? _busId;
  
  // Stream quality settings
  Map<String, dynamic> _mediaConstraints = {
    'audio': true,
    'video': {
      'facingMode': 'environment', // Rear camera by default
      'width': {'ideal': 1280},
      'height': {'ideal': 720},
      'frameRate': {'ideal': 24},
    },
  };
  
  // WebRTC configuration
  final Map<String, dynamic> _rtcConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  // Callbacks
  Function(RTCVideoRenderer)? onLocalVideoReady;
  Function(String, bool)? onViewerConnectionChanged;
  Function(String)? onError;

  /// Initialize camera service
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('❌ No cameras available');
        return false;
      }
      
      // Find rear camera (for dashcam-style streaming)
      _currentCameraIndex = _cameras!.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      if (_currentCameraIndex < 0) _currentCameraIndex = 0;
      
      _isInitialized = true;
      debugPrint('📹 Camera service initialized with ${_cameras!.length} cameras');
      return true;
    } catch (e) {
      debugPrint('❌ Camera initialization error: $e');
      onError?.call('Camera initialization failed: $e');
      return false;
    }
  }

  /// Start live streaming for a trip
  Future<bool> startStreaming({
    required String tripId,
    required String busId,
  }) async {
    if (_isStreaming) {
      debugPrint('⚠️ Already streaming');
      return true;
    }

    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      _currentTripId = tripId;
      _busId = busId;

      // Get local media stream
      _localStream = await navigator.mediaDevices.getUserMedia(_mediaConstraints);
      
      // Setup socket listeners for WebRTC signaling
      _setupSignaling();
      
      // Notify server that streaming is available
      _socketService.emit('stream:available', {
        'tripId': tripId,
        'busId': busId,
        'streamType': 'dashcam',
      });

      _isStreaming = true;
      debugPrint('🎥 Live streaming started for trip: $tripId');
      return true;
    } catch (e) {
      debugPrint('❌ Start streaming error: $e');
      onError?.call('Failed to start streaming: $e');
      return false;
    }
  }

  /// Stop live streaming
  Future<void> stopStreaming() async {
    if (!_isStreaming) return;

    // Close all viewer connections
    for (final connection in _viewerConnections.values) {
      await connection.close();
    }
    _viewerConnections.clear();

    // Stop local stream
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream = null;

    // Notify server
    _socketService.emit('stream:stopped', {
      'tripId': _currentTripId,
      'busId': _busId,
    });

    _isStreaming = false;
    _currentTripId = null;
    _busId = null;
    
    debugPrint('🛑 Live streaming stopped');
  }

  /// Setup WebRTC signaling via Socket.IO
  void _setupSignaling() {
    // Handle viewer join request
    _socketService.on('stream:viewer-join', (data) async {
      final viewerId = data['viewerId'] as String;
      debugPrint('👀 Viewer joining: $viewerId');
      await _handleViewerJoin(viewerId);
    });

    // Handle viewer answer
    _socketService.on('stream:answer', (data) async {
      final viewerId = data['viewerId'] as String;
      final answer = data['answer'];
      await _handleViewerAnswer(viewerId, answer);
    });

    // Handle ICE candidate from viewer
    _socketService.on('stream:ice-candidate', (data) async {
      final viewerId = data['viewerId'] as String;
      final candidate = data['candidate'];
      await _handleIceCandidate(viewerId, candidate);
    });

    // Handle viewer disconnect
    _socketService.on('stream:viewer-left', (data) {
      final viewerId = data['viewerId'] as String;
      _handleViewerLeft(viewerId);
    });
  }

  /// Handle new viewer joining the stream
  Future<void> _handleViewerJoin(String viewerId) async {
    try {
      // Create peer connection for this viewer
      final peerConnection = await createPeerConnection(_rtcConfig);
      _viewerConnections[viewerId] = peerConnection;

      // Add local stream tracks
      _localStream?.getTracks().forEach((track) {
        peerConnection.addTrack(track, _localStream!);
      });

      // Handle ICE candidates
      peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
        _socketService.emit('stream:ice-candidate', {
          'tripId': _currentTripId,
          'viewerId': viewerId,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        });
      };

      // Handle connection state
      peerConnection.onConnectionState = (RTCPeerConnectionState state) {
        debugPrint('👀 Viewer $viewerId connection state: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          onViewerConnectionChanged?.call(viewerId, true);
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
                   state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          onViewerConnectionChanged?.call(viewerId, false);
        }
      };

      // Create offer
      final offer = await peerConnection.createOffer();
      await peerConnection.setLocalDescription(offer);

      // Send offer to viewer
      _socketService.emit('stream:offer', {
        'tripId': _currentTripId,
        'viewerId': viewerId,
        'offer': {
          'type': offer.type,
          'sdp': offer.sdp,
        },
      });

      debugPrint('📤 Sent offer to viewer: $viewerId');
    } catch (e) {
      debugPrint('❌ Error handling viewer join: $e');
    }
  }

  /// Handle answer from viewer
  Future<void> _handleViewerAnswer(String viewerId, Map<String, dynamic> answer) async {
    try {
      final peerConnection = _viewerConnections[viewerId];
      if (peerConnection == null) return;

      final description = RTCSessionDescription(
        answer['sdp'],
        answer['type'],
      );
      await peerConnection.setRemoteDescription(description);
      debugPrint('📥 Set remote description for viewer: $viewerId');
    } catch (e) {
      debugPrint('❌ Error handling viewer answer: $e');
    }
  }

  /// Handle ICE candidate from viewer
  Future<void> _handleIceCandidate(String viewerId, Map<String, dynamic> candidateData) async {
    try {
      final peerConnection = _viewerConnections[viewerId];
      if (peerConnection == null) return;

      final candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );
      await peerConnection.addCandidate(candidate);
    } catch (e) {
      debugPrint('❌ Error handling ICE candidate: $e');
    }
  }

  /// Handle viewer leaving
  void _handleViewerLeft(String viewerId) {
    final peerConnection = _viewerConnections.remove(viewerId);
    peerConnection?.close();
    onViewerConnectionChanged?.call(viewerId, false);
    debugPrint('👋 Viewer left: $viewerId');
  }

  /// Switch between front and rear camera
  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
    
    // Update constraints
    final isFront = _cameras![_currentCameraIndex].lensDirection == CameraLensDirection.front;
    _mediaConstraints['video']['facingMode'] = isFront ? 'user' : 'environment';
    
    // If streaming, restart with new camera
    if (_isStreaming) {
      final tripId = _currentTripId!;
      final busId = _busId!;
      await stopStreaming();
      await startStreaming(tripId: tripId, busId: busId);
    }
    
    debugPrint('📷 Switched to ${isFront ? "front" : "rear"} camera');
  }

  /// Set video quality
  void setVideoQuality(String quality) {
    switch (quality) {
      case 'low':
        _mediaConstraints['video']['width'] = {'ideal': 640};
        _mediaConstraints['video']['height'] = {'ideal': 480};
        _mediaConstraints['video']['frameRate'] = {'ideal': 15};
        break;
      case 'medium':
        _mediaConstraints['video']['width'] = {'ideal': 1280};
        _mediaConstraints['video']['height'] = {'ideal': 720};
        _mediaConstraints['video']['frameRate'] = {'ideal': 24};
        break;
      case 'high':
        _mediaConstraints['video']['width'] = {'ideal': 1920};
        _mediaConstraints['video']['height'] = {'ideal': 1080};
        _mediaConstraints['video']['frameRate'] = {'ideal': 30};
        break;
    }
    debugPrint('📹 Video quality set to: $quality');
  }

  /// Toggle audio
  void toggleAudio(bool enabled) {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = enabled;
    });
  }

  /// Get local video renderer for preview
  RTCVideoRenderer? getLocalRenderer() {
    // Implementation for local preview
    return null;
  }

  /// Get streaming status
  Map<String, dynamic> getStatus() {
    return {
      'isStreaming': _isStreaming,
      'tripId': _currentTripId,
      'busId': _busId,
      'viewerCount': _viewerConnections.length,
      'viewers': _viewerConnections.keys.toList(),
    };
  }

  /// Dispose resources
  void dispose() {
    stopStreaming();
    _cameraController?.dispose();
    _isInitialized = false;
  }
}
