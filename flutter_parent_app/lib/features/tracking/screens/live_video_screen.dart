import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';

class LiveVideoScreen extends StatefulWidget {
  final String tripId;
  final String busNumber;

  const LiveVideoScreen({
    super.key,
    required this.tripId,
    required this.busNumber,
  });

  @override
  State<LiveVideoScreen> createState() => _LiveVideoScreenState();
}

class _LiveVideoScreenState extends State<LiveVideoScreen> {
  final SocketService _socketService = getIt<SocketService>();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  bool _isConnecting = true;
  bool _isConnected = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      await _remoteRenderer.initialize();
      
      // Join the stream room
      _socketService.joinStream(widget.tripId);
      
      // Setup WebRTC listeners
      _setupWebRTCListeners();
      
      // Wait for stream to be available
      setState(() {
        _isConnecting = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize video: $e';
        _isConnecting = false;
      });
    }
  }

  void _setupWebRTCListeners() {
    // Handle incoming offer from driver
    _socketService.onWebRTCOffer((data) async {
      try {
        await _createPeerConnection();
        
        final offer = RTCSessionDescription(
          data['signal']['sdp'],
          data['signal']['type'],
        );
        
        await _peerConnection!.setRemoteDescription(offer);
        
        final answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);
        
        _socketService.sendWebRTCAnswer(widget.tripId, {
          'type': answer.type,
          'sdp': answer.sdp,
        });
      } catch (e) {
        setState(() {
          _error = 'Failed to process offer: $e';
        });
      }
    });

    // Handle ICE candidates
    _socketService.onIceCandidate((data) async {
      try {
        if (_peerConnection != null && data['signal'] != null) {
          final candidate = RTCIceCandidate(
            data['signal']['candidate'],
            data['signal']['sdpMid'],
            data['signal']['sdpMLineIndex'],
          );
          await _peerConnection!.addCandidate(candidate);
        }
      } catch (e) {
        print('Error adding ICE candidate: $e');
      }
    });

    // Handle stream stopped
    _socketService.onStreamStopped((_) {
      setState(() {
        _isConnected = false;
        _error = 'Stream ended by driver';
      });
    });
  }

  Future<void> _createPeerConnection() async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onIceCandidate = (candidate) {
      _socketService.sendIceCandidate(widget.tripId, {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    _peerConnection!.onTrack = (event) {
      if (event.track.kind == 'video') {
        setState(() {
          _remoteRenderer.srcObject = event.streams[0];
          _isConnecting = false;
          _isConnected = true;
        });
      }
    };

    _peerConnection!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        setState(() {
          _isConnected = false;
          _error = 'Connection lost';
        });
      }
    };
  }

  @override
  void dispose() {
    _socketService.leaveStream(widget.tripId);
    _socketService.offStreamEvents();
    _remoteRenderer.dispose();
    _peerConnection?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Live - Bus ${widget.busNumber}'),
        actions: [
          if (_isConnected)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video
          if (_isConnected)
            RTCVideoView(
              _remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          else
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam_off,
                    size: 64,
                    color: Colors.white54,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No video stream',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          
          // Loading overlay
          if (_isConnecting)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Connecting to live stream...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          
          // Error overlay
          if (_error != null)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _error = null;
                          _isConnecting = true;
                        });
                        _initializeVideo();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          
          // Controls
          if (_isConnected)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButton(
                    Icons.fullscreen,
                    'Fullscreen',
                    () {
                      // TODO: Implement fullscreen
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
