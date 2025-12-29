import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/models/models.dart';
import '../../../core/services/socket_service.dart';
import '../repository/tracking_repository.dart';

// Events
abstract class TrackingEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadChildren extends TrackingEvent {}

class SelectChild extends TrackingEvent {
  final String childId;
  SelectChild(this.childId);
  @override
  List<Object?> get props => [childId];
}

class StartTracking extends TrackingEvent {
  final String childId;
  StartTracking(this.childId);
  @override
  List<Object?> get props => [childId];
}

class StopTracking extends TrackingEvent {}

class LocationUpdated extends TrackingEvent {
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed;

  LocationUpdated({
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
  });

  @override
  List<Object?> get props => [latitude, longitude, heading, speed];
}

class RefreshTrackingInfo extends TrackingEvent {
  final String childId;
  RefreshTrackingInfo(this.childId);
  @override
  List<Object?> get props => [childId];
}

// States
abstract class TrackingState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TrackingInitial extends TrackingState {}

class TrackingLoading extends TrackingState {}

class ChildrenLoaded extends TrackingState {
  final List<Child> children;
  final Child? selectedChild;

  ChildrenLoaded({required this.children, this.selectedChild});

  @override
  List<Object?> get props => [children, selectedChild];
}

class TrackingActive extends TrackingState {
  final Child child;
  final TrackingInfo? trackingInfo;
  final ActiveTripInfo? activeTripInfo;
  final BusLocation? currentLocation;

  TrackingActive({
    required this.child,
    this.trackingInfo,
    this.activeTripInfo,
    this.currentLocation,
  });

  TrackingActive copyWith({
    Child? child,
    TrackingInfo? trackingInfo,
    ActiveTripInfo? activeTripInfo,
    BusLocation? currentLocation,
  }) {
    return TrackingActive(
      child: child ?? this.child,
      trackingInfo: trackingInfo ?? this.trackingInfo,
      activeTripInfo: activeTripInfo ?? this.activeTripInfo,
      currentLocation: currentLocation ?? this.currentLocation,
    );
  }

  @override
  List<Object?> get props => [child, trackingInfo, activeTripInfo, currentLocation];
}

class TrackingError extends TrackingState {
  final String message;
  TrackingError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  final TrackingRepository trackingRepository;
  final SocketService socketService;
  String? _currentBusId;

  TrackingBloc({
    required this.trackingRepository,
    required this.socketService,
  }) : super(TrackingInitial()) {
    on<LoadChildren>(_onLoadChildren);
    on<SelectChild>(_onSelectChild);
    on<StartTracking>(_onStartTracking);
    on<StopTracking>(_onStopTracking);
    on<LocationUpdated>(_onLocationUpdated);
    on<RefreshTrackingInfo>(_onRefreshTrackingInfo);
  }

  Future<void> _onLoadChildren(
    LoadChildren event,
    Emitter<TrackingState> emit,
  ) async {
    emit(TrackingLoading());
    try {
      final children = await trackingRepository.getChildren();
      emit(ChildrenLoaded(
        children: children,
        selectedChild: children.isNotEmpty ? children.first : null,
      ));
    } catch (e) {
      emit(TrackingError(e.toString()));
    }
  }

  Future<void> _onSelectChild(
    SelectChild event,
    Emitter<TrackingState> emit,
  ) async {
    if (state is ChildrenLoaded) {
      final currentState = state as ChildrenLoaded;
      final selectedChild = currentState.children.firstWhere(
        (c) => c.id == event.childId,
        orElse: () => currentState.children.first,
      );
      emit(ChildrenLoaded(
        children: currentState.children,
        selectedChild: selectedChild,
      ));
    }
  }

  Future<void> _onStartTracking(
    StartTracking event,
    Emitter<TrackingState> emit,
  ) async {
    emit(TrackingLoading());
    try {
      final children = await trackingRepository.getChildren();
      final child = children.firstWhere(
        (c) => c.id == event.childId,
        orElse: () => children.first,
      );

      // Get tracking info
      final trackingInfo = await trackingRepository.getBusLocation(event.childId);
      final activeTripInfo = await trackingRepository.getActiveTrip(event.childId);

      // Subscribe to bus location updates
      if (child.bus != null) {
        _currentBusId = child.bus!.id;
        socketService.subscribeToBus(_currentBusId!);
        _setupLocationListener();
      }

      emit(TrackingActive(
        child: child,
        trackingInfo: trackingInfo,
        activeTripInfo: activeTripInfo,
        currentLocation: trackingInfo?.bus.currentLocation,
      ));
    } catch (e) {
      emit(TrackingError(e.toString()));
    }
  }

  void _setupLocationListener() {
    socketService.onLocationUpdate((data) {
      if (data != null && data['busId'] == _currentBusId) {
        add(LocationUpdated(
          latitude: (data['latitude'] as num).toDouble(),
          longitude: (data['longitude'] as num).toDouble(),
          heading: data['heading']?.toDouble(),
          speed: data['speed']?.toDouble(),
        ));
      }
    });
  }

  Future<void> _onStopTracking(
    StopTracking event,
    Emitter<TrackingState> emit,
  ) async {
    if (_currentBusId != null) {
      socketService.unsubscribeFromBus(_currentBusId!);
      socketService.offLocationUpdate();
      _currentBusId = null;
    }
    add(LoadChildren());
  }

  void _onLocationUpdated(
    LocationUpdated event,
    Emitter<TrackingState> emit,
  ) {
    if (state is TrackingActive) {
      final currentState = state as TrackingActive;
      emit(currentState.copyWith(
        currentLocation: BusLocation(
          latitude: event.latitude,
          longitude: event.longitude,
          heading: event.heading,
          speed: event.speed,
          timestamp: DateTime.now(),
        ),
      ));
    }
  }

  Future<void> _onRefreshTrackingInfo(
    RefreshTrackingInfo event,
    Emitter<TrackingState> emit,
  ) async {
    if (state is TrackingActive) {
      try {
        final trackingInfo = await trackingRepository.getBusLocation(event.childId);
        final activeTripInfo = await trackingRepository.getActiveTrip(event.childId);
        
        final currentState = state as TrackingActive;
        emit(currentState.copyWith(
          trackingInfo: trackingInfo,
          activeTripInfo: activeTripInfo,
        ));
      } catch (e) {
        // Silently fail refresh
      }
    }
  }

  @override
  Future<void> close() {
    if (_currentBusId != null) {
      socketService.unsubscribeFromBus(_currentBusId!);
      socketService.offLocationUpdate();
    }
    return super.close();
  }
}
