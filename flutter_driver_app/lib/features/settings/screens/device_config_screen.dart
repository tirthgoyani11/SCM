import 'package:flutter/material.dart';
import '../../core/services/device_interfaces.dart';
import '../../core/services/unified_telemetry_service.dart';
import '../../core/services/service_locator.dart';

/// Device Configuration Screen
/// Allows drivers to configure and manage input devices:
/// - GPS sources (phone, Bluetooth, OBD-II, fleet trackers)
/// - Video sources (phone camera, dashcam, CCTV)
class DeviceConfigScreen extends StatefulWidget {
  const DeviceConfigScreen({super.key});

  @override
  State<DeviceConfigScreen> createState() => _DeviceConfigScreenState();
}

class _DeviceConfigScreenState extends State<DeviceConfigScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UnifiedTelemetryService _telemetryService = UnifiedTelemetryService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Configuration'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.gps_fixed), text: 'GPS Sources'),
            Tab(icon: Icon(Icons.videocam), text: 'Video Sources'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGpsSourcesTab(),
          _buildVideoSourcesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDeviceDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGpsSourcesTab() {
    final gpsSources = _telemetryService.gpsSources;
    final activeSource = _telemetryService.activeGpsSource;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: gpsSources.length,
      itemBuilder: (context, index) {
        final source = gpsSources[index];
        final isActive = source == activeSource;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isActive ? Colors.green : Colors.grey,
              child: Icon(
                _getGpsIcon(source.type),
                color: Colors.white,
              ),
            ),
            title: Text(source.name),
            subtitle: Text(_getGpsTypeLabel(source.type)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (source.isConnected)
                  const Chip(
                    label: Text('Connected'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                const SizedBox(width: 8),
                Radio<GpsSource>(
                  value: source,
                  groupValue: activeSource,
                  onChanged: (value) async {
                    if (value != null) {
                      final success = await _telemetryService.selectGpsSource(value);
                      if (success) {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Switched to ${value.name}')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to connect to ${value.name}')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoSourcesTab() {
    final videoSources = _telemetryService.videoSources;
    final activeSource = _telemetryService.activeVideoSource;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: videoSources.length,
      itemBuilder: (context, index) {
        final source = videoSources[index];
        final isActive = source == activeSource;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isActive ? Colors.blue : Colors.grey,
              child: Icon(
                _getVideoIcon(source.type),
                color: Colors.white,
              ),
            ),
            title: Text(source.name),
            subtitle: Text(_getVideoTypeLabel(source.type)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (source.isConnected)
                  const Chip(
                    label: Text('Connected'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                const SizedBox(width: 8),
                Radio<VideoSource>(
                  value: source,
                  groupValue: activeSource,
                  onChanged: (value) async {
                    if (value != null) {
                      final success = await _telemetryService.selectVideoSource(value);
                      if (success) {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Switched to ${value.name}')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to connect to ${value.name}')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddDeviceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Device',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // GPS Device Options
            const Text('GPS Devices', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.bluetooth),
                  label: const Text('Bluetooth GPS'),
                  onPressed: () => _showBluetoothGpsDialog(context),
                ),
                ActionChip(
                  avatar: const Icon(Icons.directions_car),
                  label: const Text('OBD-II Tracker'),
                  onPressed: () => _showObdiiDialog(context),
                ),
                ActionChip(
                  avatar: const Icon(Icons.cloud),
                  label: const Text('Fleet Tracker'),
                  onPressed: () => _showFleetTrackerDialog(context),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Video Device Options
            const Text('Video Devices', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.camera),
                  label: const Text('RTSP Dashcam'),
                  onPressed: () => _showRtspCameraDialog(context, 'Dashcam'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.videocam),
                  label: const Text('CCTV Camera'),
                  onPressed: () => _showRtspCameraDialog(context, 'CCTV'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.photo_camera),
                  label: const Text('IP Camera'),
                  onPressed: () => _showIpCameraDialog(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBluetoothGpsDialog(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => _BluetoothGpsDialog(
        onAdd: (deviceId, name) async {
          await _telemetryService.addExternalGps(
            type: 'bluetooth',
            deviceId: deviceId,
            deviceName: name,
          );
          setState(() {});
        },
      ),
    );
  }

  void _showObdiiDialog(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => _ObdiiDialog(
        onAdd: (address) async {
          await _telemetryService.addExternalGps(
            type: 'obdii',
            deviceId: address,
          );
          setState(() {});
        },
      ),
    );
  }

  void _showFleetTrackerDialog(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => _FleetTrackerDialog(
        onAdd: (trackerId, apiEndpoint, apiKey) async {
          await _telemetryService.addExternalGps(
            type: 'fleet',
            deviceId: trackerId,
            apiEndpoint: apiEndpoint,
            apiKey: apiKey,
          );
          setState(() {});
        },
      ),
    );
  }

  void _showRtspCameraDialog(BuildContext context, String type) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => _RtspCameraDialog(
        type: type,
        onAdd: (url, name, username, password) async {
          await _telemetryService.addRtspCamera(
            rtspUrl: url,
            name: name,
            username: username,
            password: password,
          );
          setState(() {});
        },
      ),
    );
  }

  void _showIpCameraDialog(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => _IpCameraDialog(
        onAdd: (url, name, username, password) async {
          await _telemetryService.addIpCamera(
            cameraUrl: url,
            name: name,
            username: username,
            password: password,
          );
          setState(() {});
        },
      ),
    );
  }

  IconData _getGpsIcon(GpsSourceType type) {
    switch (type) {
      case GpsSourceType.phoneGps:
        return Icons.smartphone;
      case GpsSourceType.externalBluetooth:
        return Icons.bluetooth;
      case GpsSourceType.externalUsb:
        return Icons.usb;
      case GpsSourceType.obdii:
        return Icons.directions_car;
      case GpsSourceType.dedicatedTracker:
        return Icons.cloud;
    }
  }

  String _getGpsTypeLabel(GpsSourceType type) {
    switch (type) {
      case GpsSourceType.phoneGps:
        return 'Built-in Phone GPS';
      case GpsSourceType.externalBluetooth:
        return 'Bluetooth GPS Device';
      case GpsSourceType.externalUsb:
        return 'USB GPS Dongle';
      case GpsSourceType.obdii:
        return 'OBD-II Vehicle Tracker';
      case GpsSourceType.dedicatedTracker:
        return 'Fleet GPS Tracker';
    }
  }

  IconData _getVideoIcon(VideoSourceType type) {
    switch (type) {
      case VideoSourceType.phoneCamera:
        return Icons.phone_android;
      case VideoSourceType.dashcam:
        return Icons.camera;
      case VideoSourceType.cctv:
        return Icons.videocam;
      case VideoSourceType.webcam:
        return Icons.camera_alt;
    }
  }

  String _getVideoTypeLabel(VideoSourceType type) {
    switch (type) {
      case VideoSourceType.phoneCamera:
        return 'Built-in Phone Camera';
      case VideoSourceType.dashcam:
        return 'External Dashcam';
      case VideoSourceType.cctv:
        return 'CCTV Camera';
      case VideoSourceType.webcam:
        return 'USB Webcam';
    }
  }
}

// Dialog widgets for adding devices
class _BluetoothGpsDialog extends StatefulWidget {
  final Function(String deviceId, String name) onAdd;

  const _BluetoothGpsDialog({required this.onAdd});

  @override
  State<_BluetoothGpsDialog> createState() => _BluetoothGpsDialogState();
}

class _BluetoothGpsDialogState extends State<_BluetoothGpsDialog> {
  final _deviceIdController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Bluetooth GPS'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _deviceIdController,
            decoration: const InputDecoration(
              labelText: 'Device ID / MAC Address',
              hintText: 'XX:XX:XX:XX:XX:XX',
            ),
          ),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Device Name',
              hintText: 'My Bluetooth GPS',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onAdd(_deviceIdController.text, _nameController.text);
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _ObdiiDialog extends StatefulWidget {
  final Function(String address) onAdd;

  const _ObdiiDialog({required this.onAdd});

  @override
  State<_ObdiiDialog> createState() => _ObdiiDialogState();
}

class _ObdiiDialogState extends State<_ObdiiDialog> {
  final _addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add OBD-II Tracker'),
      content: TextField(
        controller: _addressController,
        decoration: const InputDecoration(
          labelText: 'OBD-II Device Address',
          hintText: 'XX:XX:XX:XX:XX:XX',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onAdd(_addressController.text);
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _FleetTrackerDialog extends StatefulWidget {
  final Function(String trackerId, String apiEndpoint, String apiKey) onAdd;

  const _FleetTrackerDialog({required this.onAdd});

  @override
  State<_FleetTrackerDialog> createState() => _FleetTrackerDialogState();
}

class _FleetTrackerDialogState extends State<_FleetTrackerDialog> {
  final _trackerIdController = TextEditingController();
  final _apiEndpointController = TextEditingController();
  final _apiKeyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Fleet Tracker'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _trackerIdController,
            decoration: const InputDecoration(labelText: 'Tracker ID'),
          ),
          TextField(
            controller: _apiEndpointController,
            decoration: const InputDecoration(
              labelText: 'API Endpoint',
              hintText: 'https://api.tracker.com',
            ),
          ),
          TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(labelText: 'API Key'),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onAdd(
              _trackerIdController.text,
              _apiEndpointController.text,
              _apiKeyController.text,
            );
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _RtspCameraDialog extends StatefulWidget {
  final String type;
  final Function(String url, String name, String? username, String? password) onAdd;

  const _RtspCameraDialog({required this.type, required this.onAdd});

  @override
  State<_RtspCameraDialog> createState() => _RtspCameraDialogState();
}

class _RtspCameraDialogState extends State<_RtspCameraDialog> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add ${widget.type}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'RTSP URL',
                hintText: 'rtsp://192.168.1.100:554/stream',
              ),
            ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'My ${widget.type}',
              ),
            ),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username (optional)'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password (optional)'),
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onAdd(
              _urlController.text,
              _nameController.text,
              _usernameController.text.isEmpty ? null : _usernameController.text,
              _passwordController.text.isEmpty ? null : _passwordController.text,
            );
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _IpCameraDialog extends StatefulWidget {
  final Function(String url, String name, String? username, String? password) onAdd;

  const _IpCameraDialog({required this.onAdd});

  @override
  State<_IpCameraDialog> createState() => _IpCameraDialogState();
}

class _IpCameraDialogState extends State<_IpCameraDialog> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add IP Camera'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Camera URL',
                hintText: 'http://192.168.1.100/video.mjpg',
              ),
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Bus CCTV',
              ),
            ),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username (optional)'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password (optional)'),
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onAdd(
              _urlController.text,
              _nameController.text,
              _usernameController.text.isEmpty ? null : _usernameController.text,
              _passwordController.text.isEmpty ? null : _passwordController.text,
            );
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
