import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_router.dart';
import '../bloc/tracking_bloc.dart';

class TrackingScreen extends StatefulWidget {
  final String childId;

  const TrackingScreen({super.key, required this.childId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    context.read<TrackingBloc>().add(StartTracking(widget.childId));
  }

  @override
  void dispose() {
    _mapController?.dispose();
    context.read<TrackingBloc>().add(StopTracking());
    super.dispose();
  }

  void _updateMarkers(double lat, double lng, double? heading) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('bus'),
          position: LatLng(lat, lng),
          rotation: heading ?? 0,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'School Bus'),
        ),
      };
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(lat, lng)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        actions: [
          BlocBuilder<TrackingBloc, TrackingState>(
            builder: (context, state) {
              if (state is TrackingActive &&
                  state.activeTripInfo?.active == true &&
                  state.activeTripInfo?.trip?.isLiveStreamActive == true) {
                return IconButton(
                  icon: const Icon(Icons.videocam, color: AppTheme.errorColor),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRouter.liveVideo,
                      arguments: {
                        'tripId': state.activeTripInfo!.trip!.id,
                        'busNumber': state.child.bus?.busNumber ?? '',
                      },
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TrackingBloc>().add(RefreshTrackingInfo(widget.childId));
            },
          ),
        ],
      ),
      body: BlocConsumer<TrackingBloc, TrackingState>(
        listener: (context, state) {
          if (state is TrackingActive && state.currentLocation != null) {
            _updateMarkers(
              state.currentLocation!.latitude,
              state.currentLocation!.longitude,
              state.currentLocation!.heading,
            );
          }
        },
        builder: (context, state) {
          if (state is TrackingLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TrackingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<TrackingBloc>().add(StartTracking(widget.childId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is TrackingActive) {
            final location = state.currentLocation;
            final initialPosition = location != null
                ? LatLng(location.latitude, location.longitude)
                : const LatLng(23.0225, 72.5714); // Default to Ahmedabad

            // Add stop marker if available
            if (state.child.stop != null) {
              _markers.add(
                Marker(
                  markerId: const MarkerId('stop'),
                  position: LatLng(
                    state.child.stop!.latitude,
                    state.child.stop!.longitude,
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                  infoWindow: InfoWindow(title: state.child.stop!.name),
                ),
              );
            }

            return Column(
              children: [
                // Map
                Expanded(
                  flex: 3,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: initialPosition,
                      zoom: 15,
                    ),
                    markers: _markers,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      if (location != null) {
                        _updateMarkers(
                          location.latitude,
                          location.longitude,
                          location.heading,
                        );
                      }
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                ),
                // Info Panel
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Child info
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                child: Text(
                                  state.child.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.child.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Grade ${state.child.grade} - ${state.child.section}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildStatusChip(state),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Trip status
                          if (state.activeTripInfo?.active == true) ...[
                            _buildInfoRow(
                              Icons.directions_bus,
                              'Bus ${state.child.bus?.busNumber ?? 'N/A'}',
                              state.activeTripInfo!.trip!.type == 'pickup'
                                  ? 'Picking up students'
                                  : 'Dropping students',
                            ),
                            const SizedBox(height: 12),
                          ],
                          // Distance and ETA
                          if (state.trackingInfo != null) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricCard(
                                    Icons.straighten,
                                    'Distance',
                                    state.trackingInfo!.distance != null
                                        ? '${state.trackingInfo!.distance} m'
                                        : 'N/A',
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildMetricCard(
                                    Icons.access_time,
                                    'ETA',
                                    state.trackingInfo!.eta != null
                                        ? '${state.trackingInfo!.eta} min'
                                        : 'N/A',
                                    Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          // Stop info
                          if (state.child.stop != null)
                            _buildInfoRow(
                              Icons.location_on,
                              'Stop',
                              state.child.stop!.name,
                            ),
                          const SizedBox(height: 20),
                          // Live video button
                          if (state.activeTripInfo?.active == true &&
                              state.activeTripInfo?.trip?.isLiveStreamActive == true)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRouter.liveVideo,
                                    arguments: {
                                      'tripId': state.activeTripInfo!.trip!.id,
                                      'busNumber': state.child.bus?.busNumber ?? '',
                                    },
                                  );
                                },
                                icon: const Icon(Icons.videocam),
                                label: const Text('Watch Live Video'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.errorColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return const Center(child: Text('No data available'));
        },
      ),
    );
  }

  Widget _buildStatusChip(TrackingActive state) {
    Color color;
    String text;

    if (state.activeTripInfo?.active != true) {
      color = Colors.grey;
      text = 'No Active Trip';
    } else {
      switch (state.activeTripInfo!.childStatus) {
        case 'picked_up':
          color = AppTheme.successColor;
          text = 'On Bus';
          break;
        case 'dropped':
          color = Colors.blue;
          text = 'Dropped';
          break;
        default:
          color = AppTheme.warningColor;
          text = 'Waiting';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey[600]),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
