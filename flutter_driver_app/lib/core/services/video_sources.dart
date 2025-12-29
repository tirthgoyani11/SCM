import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'device_interfaces.dart';
import 'socket_service.dart';

/// Phone Camera Source - Built-in smartphone camera
class PhoneCameraSource implements VideoSource {
  final bool useRearCamera;
  final int quality;
  
  PhoneCameraSource({
    this.useRearCamera = true,
    this.quality = 70,
  });

  @override
  VideoSourceType get type => VideoSourceType.phoneCamera;
  
  @override
  String get name => useRearCamera ? 'Rear Camera' : 'Front Camera';
  
  bool _isConnected = false;
  @override
  bool get isConnected => _isConnected;

  MediaStream? _localStream;
  final SocketService _socketService = SocketService();
  final Map<String, RTCPeerConnection> _peerConnections = {};

  final Map<String, dynamic> _mediaConstraints = {
    'audio': true,
    'video': {
      'facingMode': 'environment',
      'width': {'ideal': 1280},
      'height': {'ideal': 720},
      'frameRate': {'ideal': 24},
    },
  };

  @override
  Future<bool> connect() async {
    try {
      _mediaConstraints['video']['facingMode'] = useRearCamera ? 'environment' : 'user';
      _localStream = await navigator.mediaDevices.getUserMedia(_mediaConstraints);
      _isConnected = true;
      debugPrint('📹 Phone camera connected');
      return true;
    } catch (e) {
      debugPrint('❌ Phone camera connection failed: $e');
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream = null;
    
    for (final pc in _peerConnections.values) {
      await pc.close();
    }
    _peerConnections.clear();
    
    _isConnected = false;
    debugPrint('📹 Phone camera disconnected');
  }

  @override
  Future<Stream<List<int>>?> getVideoStream() async {
    // For WebRTC, we don't return raw bytes
    return null;
  }

  @override
  Future<void> startStreaming() async {
    // WebRTC streaming is handled via signaling
    _setupSignaling();
  }

  @override
  Future<void> stopStreaming() async {
    for (final pc in _peerConnections.values) {
      await pc.close();
    }
    _peerConnections.clear();
  }

  void _setupSignaling() {
    _socketService.on('stream:viewer-join', (data) async {
      final viewerId = data['viewerId'] as String;
      await _createPeerConnection(viewerId);
    });

    _socketService.on('stream:answer', (data) async {
      final viewerId = data['viewerId'] as String;
      final answer = data['answer'];
      final pc = _peerConnections[viewerId];
      if (pc != null) {
        await pc.setRemoteDescription(
          RTCSessionDescription(answer['sdp'], answer['type']),
        );
      }
    });

    _socketService.on('stream:ice-candidate', (data) async {
      final viewerId = data['viewerId'] as String;
      final candidate = data['candidate'];
      final pc = _peerConnections[viewerId];
      if (pc != null) {
        await pc.addCandidate(RTCIceCandidate(
          candidate['candidate'],
          candidate['sdpMid'],
          candidate['sdpMLineIndex'],
        ));
      }
    });
  }

  Future<void> _createPeerConnection(String viewerId) async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    final pc = await createPeerConnection(config);
    _peerConnections[viewerId] = pc;

    // Add tracks
    _localStream?.getTracks().forEach((track) {
      pc.addTrack(track, _localStream!);
    });

    // Create and send offer
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    _socketService.emit('stream:offer', {
      'viewerId': viewerId,
      'offer': {'type': offer.type, 'sdp': offer.sdp},
    });

    // Handle ICE candidates
    pc.onIceCandidate = (candidate) {
      _socketService.emit('stream:ice-candidate', {
        'viewerId': viewerId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };
  }

  MediaStream? get localStream => _localStream;
}

/// RTSP Camera Source - External Dashcam or CCTV via RTSP
class RtspCameraSource implements VideoSource {
  final String rtspUrl;
  final String? username;
  final String? password;
  final String displayName;

  RtspCameraSource({
    required this.rtspUrl,
    this.username,
    this.password,
    this.displayName = 'RTSP Camera',
  });

  @override
  VideoSourceType get type => rtspUrl.toLowerCase().contains('dashcam') 
      ? VideoSourceType.dashcam 
      : VideoSourceType.cctv;
  
  @override
  String get name => displayName;
  
  bool _isConnected = false;
  @override
  bool get isConnected => _isConnected;

  StreamController<List<int>>? _streamController;

  @override
  Future<bool> connect() async {
    try {
      // Build RTSP URL with credentials if provided
      String fullUrl = rtspUrl;
      if (username != null && password != null) {
        final uri = Uri.parse(rtspUrl);
        fullUrl = '${uri.scheme}://$username:$password@${uri.host}:${uri.port}${uri.path}';
      }

      // TODO: Implement RTSP connection
      // Options:
      // 1. Use flutter_vlc_player for playback
      // 2. Use ffmpeg to transcode to WebRTC
      // 3. Use a media server (e.g., MediaMTX) as proxy
      
      debugPrint('📹 Connecting to RTSP: $fullUrl');
      
      // For now, we'll relay through backend
      _isConnected = true;
      return true;
    } catch (e) {
      debugPrint('❌ RTSP connection failed: $e');
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    await _streamController?.close();
    _streamController = null;
    _isConnected = false;
    debugPrint('📹 RTSP camera disconnected');
  }

  @override
  Future<Stream<List<int>>?> getVideoStream() async {
    _streamController = StreamController<List<int>>.broadcast();
    return _streamController?.stream;
  }

  @override
  Future<void> startStreaming() async {
    // Send RTSP URL to backend for relay
    final socketService = SocketService();
    socketService.emit('stream:rtsp-source', {
      'rtspUrl': rtspUrl,
      'username': username,
      'password': password,
    });
  }

  @override
  Future<void> stopStreaming() async {
    final socketService = SocketService();
    socketService.emit('stream:rtsp-stop', {});
  }
}

/// IP Camera Source - CCTV via HTTP/MJPEG
class IpCameraSource implements VideoSource {
  final String cameraUrl;
  final String? username;
  final String? password;
  final String displayName;

  IpCameraSource({
    required this.cameraUrl,
    this.username,
    this.password,
    this.displayName = 'IP Camera',
  });

  @override
  VideoSourceType get type => VideoSourceType.cctv;
  
  @override
  String get name => displayName;
  
  bool _isConnected = false;
  @override
  bool get isConnected => _isConnected;

  StreamController<List<int>>? _streamController;
  StreamSubscription? _httpSubscription;

  @override
  Future<bool> connect() async {
    try {
      // Test connection to camera
      final request = http.Request('GET', Uri.parse(cameraUrl));
      if (username != null && password != null) {
        final credentials = base64Encode(utf8.encode('$username:$password'));
        request.headers['Authorization'] = 'Basic $credentials';
      }

      final response = await http.Client().send(request);
      if (response.statusCode == 200) {
        _isConnected = true;
        debugPrint('📹 IP Camera connected: $displayName');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ IP Camera connection failed: $e');
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    await _httpSubscription?.cancel();
    await _streamController?.close();
    _httpSubscription = null;
    _streamController = null;
    _isConnected = false;
    debugPrint('📹 IP Camera disconnected');
  }

  @override
  Future<Stream<List<int>>?> getVideoStream() async {
    if (!_isConnected) return null;

    _streamController = StreamController<List<int>>.broadcast();

    try {
      final request = http.Request('GET', Uri.parse(cameraUrl));
      if (username != null && password != null) {
        final credentials = base64Encode(utf8.encode('$username:$password'));
        request.headers['Authorization'] = 'Basic $credentials';
      }

      final response = await http.Client().send(request);
      _httpSubscription = response.stream.listen(
        (data) => _streamController?.add(data),
        onError: (e) => debugPrint('❌ Stream error: $e'),
        onDone: () => _streamController?.close(),
      );
    } catch (e) {
      debugPrint('❌ Failed to get video stream: $e');
    }

    return _streamController?.stream;
  }

  @override
  Future<void> startStreaming() async {
    // For MJPEG streams, relay through backend
    final socketService = SocketService();
    socketService.emit('stream:mjpeg-source', {
      'cameraUrl': cameraUrl,
      'username': username,
      'password': password,
    });
  }

  @override
  Future<void> stopStreaming() async {
    await disconnect();
  }
}

/// RTMP Stream Source - For professional streaming setups
class RtmpStreamSource implements VideoSource {
  final String rtmpUrl;
  final String streamKey;
  final String displayName;

  RtmpStreamSource({
    required this.rtmpUrl,
    required this.streamKey,
    this.displayName = 'RTMP Stream',
  });

  @override
  VideoSourceType get type => VideoSourceType.dashcam;
  
  @override
  String get name => displayName;
  
  bool _isConnected = false;
  @override
  bool get isConnected => _isConnected;

  @override
  Future<bool> connect() async {
    try {
      // RTMP streams are typically push-based
      // The dashcam/camera pushes to an RTMP server
      // We just need to verify the stream exists
      debugPrint('📹 RTMP stream configured: $rtmpUrl');
      _isConnected = true;
      return true;
    } catch (e) {
      debugPrint('❌ RTMP connection failed: $e');
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    _isConnected = false;
  }

  @override
  Future<Stream<List<int>>?> getVideoStream() async => null;

  @override
  Future<void> startStreaming() async {
    // Notify backend about RTMP source
    final socketService = SocketService();
    socketService.emit('stream:rtmp-source', {
      'rtmpUrl': '$rtmpUrl/$streamKey',
    });
  }

  @override
  Future<void> stopStreaming() async {}
}
