import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../features/trip/bloc/trip_bloc.dart';
import '../../../core/routes/app_router.dart';

class ActiveTripScreen extends StatefulWidget {
  const ActiveTripScreen({super.key});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  GoogleMapController? _mapController;
  bool _showStudentList = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripBloc, TripState>(
      listener: (context, state) {
        if (state is TripReady || state is TripNoAssignment) {
          Navigator.of(context).pushReplacementNamed(AppRouter.home);
        }
      },
      builder: (context, state) {
        if (state is! TripActive) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              // Map
              _buildMap(state),
              
              // Top info bar
              _buildTopBar(context, state),
              
              // Bottom controls
              _buildBottomControls(context, state),
              
              // Student list overlay
              if (_showStudentList) _buildStudentListOverlay(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMap(TripActive state) {
    final position = state.currentPosition;
    final initialPosition = position != null
        ? LatLng(position.latitude, position.longitude)
        : const LatLng(0, 0);

    Set<Marker> markers = {};
    
    // Current position marker
    if (position != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: LatLng(position.latitude, position.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    // Stop markers
    for (var i = 0; i < state.stops.length; i++) {
      final stop = state.stops[i];
      if (stop['location'] != null) {
        markers.add(
          Marker(
            markerId: MarkerId('stop_${stop['_id']}'),
            position: LatLng(
              stop['location']['coordinates'][1],
              stop['location']['coordinates'][0],
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
              title: 'Stop ${i + 1}',
              snippet: stop['name'],
            ),
          ),
        );
      }
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: 15,
      ),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
      },
    );
  }

  Widget _buildTopBar(BuildContext context, TripActive state) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.directions_bus,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.bus['busNumber'] ?? 'Bus',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          state.trip['route']?['name'] ?? 'Route',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
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
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    Icons.people,
                    '${_getStudentCount(state, 'picked_up')}/${state.students.length}',
                    'Picked Up',
                  ),
                  _buildStatItem(
                    Icons.location_on,
                    '${state.stops.length}',
                    'Stops',
                  ),
                  _buildStatItem(
                    Icons.speed,
                    '${state.currentPosition?.speed.toStringAsFixed(0) ?? '0'} km/h',
                    'Speed',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls(BuildContext context, TripActive state) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quick actions
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.people,
                      label: 'Students',
                      color: Colors.blue,
                      onTap: () {
                        setState(() {
                          _showStudentList = true;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: state.isStreaming 
                          ? Icons.videocam_off 
                          : Icons.videocam,
                      label: state.isStreaming ? 'Stop Stream' : 'Start Stream',
                      color: state.isStreaming ? Colors.red : Colors.purple,
                      onTap: () {
                        if (state.isStreaming) {
                          context.read<TripBloc>().add(TripStopStreaming());
                        } else {
                          context.read<TripBloc>().add(
                            TripStartStreaming(busId: state.bus['_id']),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.warning,
                      label: 'Emergency',
                      color: Colors.orange,
                      onTap: () => _showEmergencyDialog(context, state),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // End trip button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _showEndTripDialog(context, state),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.stop_circle),
                  label: const Text(
                    'End Trip',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentListOverlay(BuildContext context, TripActive state) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showStudentList = false;
          });
        },
        child: Container(
          color: Colors.black54,
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxHeight: 500),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          'Students (${state.students.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _showStudentList = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Student list
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: state.students.length,
                      itemBuilder: (context, index) {
                        final student = state.students[index];
                        return _buildStudentItem(context, state, student);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentItem(
    BuildContext context,
    TripActive state,
    dynamic student,
  ) {
    final status = student['status'] ?? 'pending';
    final isPickedUp = status == 'picked_up';
    final isDroppedOff = status == 'dropped_off';

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isDroppedOff) {
      statusColor = Colors.green;
      statusText = 'Dropped Off';
      statusIcon = Icons.check_circle;
    } else if (isPickedUp) {
      statusColor = Colors.blue;
      statusText = 'On Bus';
      statusIcon = Icons.directions_bus;
    } else {
      statusColor = Colors.grey;
      statusText = 'Waiting';
      statusIcon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.1),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'] ?? 'Student',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!isDroppedOff)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'pickup') {
                  context.read<TripBloc>().add(
                    TripStudentPickup(
                      tripId: state.trip['_id'],
                      studentId: student['_id'],
                    ),
                  );
                } else if (value == 'dropoff') {
                  context.read<TripBloc>().add(
                    TripStudentDropoff(
                      tripId: state.trip['_id'],
                      studentId: student['_id'],
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                if (!isPickedUp)
                  const PopupMenuItem(
                    value: 'pickup',
                    child: Row(
                      children: [
                        Icon(Icons.add_circle, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Pick Up'),
                      ],
                    ),
                  ),
                if (isPickedUp)
                  const PopupMenuItem(
                    value: 'dropoff',
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Drop Off'),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  int _getStudentCount(TripActive state, String status) {
    return state.students.where((s) => s['status'] == status).length;
  }

  void _showEmergencyDialog(BuildContext context, TripActive state) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Emergency Alert'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select the type of emergency:'),
            const SizedBox(height: 16),
            _buildEmergencyOption(
              context,
              state,
              'accident',
              'Accident',
              Icons.car_crash,
              Colors.red,
            ),
            _buildEmergencyOption(
              context,
              state,
              'breakdown',
              'Vehicle Breakdown',
              Icons.build,
              Colors.orange,
            ),
            _buildEmergencyOption(
              context,
              state,
              'medical',
              'Medical Emergency',
              Icons.medical_services,
              Colors.blue,
            ),
            _buildEmergencyOption(
              context,
              state,
              'other',
              'Other Emergency',
              Icons.error,
              Colors.purple,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyOption(
    BuildContext context,
    TripActive state,
    String type,
    String label,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        context.read<TripBloc>().add(
          TripEmergencyAlert(
            tripId: state.trip['_id'],
            alertType: type,
            message: '$label reported by driver',
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Emergency alert sent: $label'),
            backgroundColor: color,
          ),
        );
      },
    );
  }

  void _showEndTripDialog(BuildContext context, TripActive state) {
    final pendingStudents = state.students.where(
      (s) => s['status'] != 'dropped_off',
    ).length;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('End Trip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pendingStudents > 0)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$pendingStudents students have not been dropped off yet.',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    ),
                  ],
                ),
              ),
            const Text('Are you sure you want to end this trip?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<TripBloc>().add(
                TripEnd(tripId: state.trip['_id']),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('End Trip'),
          ),
        ],
      ),
    );
  }
}
