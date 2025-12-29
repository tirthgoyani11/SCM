import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import '../repository/trip_repository.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/location_service.dart';

// Events
abstract class TripEvent extends Equatable {
  const TripEvent();

  @override
  List<Object?> get props => [];
}

class TripLoadAssignedBus extends TripEvent {}

class TripLoadCurrentTrip extends TripEvent {}

class TripStart extends TripEvent {
  final String busId;
  final String routeId;

  const TripStart({required this.busId, required this.routeId});

  @override
  List<Object?> get props => [busId, routeId];
}

class TripEnd extends TripEvent {
  final String tripId;

  const TripEnd({required this.tripId});

  @override
  List<Object?> get props => [tripId];
}

class TripLocationUpdate extends TripEvent {
  final Position position;

  const TripLocationUpdate({required this.position});

  @override
  List<Object?> get props => [position];
}

class TripStudentPickup extends TripEvent {
  final String tripId;
  final String studentId;

  const TripStudentPickup({required this.tripId, required this.studentId});

  @override
  List<Object?> get props => [tripId, studentId];
}

class TripStudentDropoff extends TripEvent {
  final String tripId;
  final String studentId;

  const TripStudentDropoff({required this.tripId, required this.studentId});

  @override
  List<Object?> get props => [tripId, studentId];
}

class TripEmergencyAlert extends TripEvent {
  final String tripId;
  final String alertType;
  final String message;

  const TripEmergencyAlert({
    required this.tripId,
    required this.alertType,
    required this.message,
  });

  @override
  List<Object?> get props => [tripId, alertType, message];
}

class TripStartStreaming extends TripEvent {
  final String busId;

  const TripStartStreaming({required this.busId});

  @override
  List<Object?> get props => [busId];
}

class TripStopStreaming extends TripEvent {}

// States
abstract class TripState extends Equatable {
  const TripState();

  @override
  List<Object?> get props => [];
}

class TripInitial extends TripState {}

class TripLoading extends TripState {}

class TripNoAssignment extends TripState {}

class TripReady extends TripState {
  final Map<String, dynamic> bus;
  final List<dynamic> routes;

  const TripReady({required this.bus, required this.routes});

  @override
  List<Object?> get props => [bus, routes];
}

class TripActive extends TripState {
  final Map<String, dynamic> trip;
  final Map<String, dynamic> bus;
  final List<dynamic> students;
  final List<dynamic> stops;
  final Position? currentPosition;
  final bool isStreaming;

  const TripActive({
    required this.trip,
    required this.bus,
    required this.students,
    required this.stops,
    this.currentPosition,
    this.isStreaming = false,
  });

  TripActive copyWith({
    Map<String, dynamic>? trip,
    Map<String, dynamic>? bus,
    List<dynamic>? students,
    List<dynamic>? stops,
    Position? currentPosition,
    bool? isStreaming,
  }) {
    return TripActive(
      trip: trip ?? this.trip,
      bus: bus ?? this.bus,
      students: students ?? this.students,
      stops: stops ?? this.stops,
      currentPosition: currentPosition ?? this.currentPosition,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  @override
  List<Object?> get props => [trip, bus, students, stops, currentPosition, isStreaming];
}

class TripError extends TripState {
  final String message;

  const TripError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Bloc
class TripBloc extends Bloc<TripEvent, TripState> {
  final TripRepository _tripRepository;
  final SocketService _socketService;
  final LocationService _locationService;
  
  StreamSubscription<Position>? _locationSubscription;

  TripBloc({
    required TripRepository tripRepository,
    required SocketService socketService,
    required LocationService locationService,
  })  : _tripRepository = tripRepository,
        _socketService = socketService,
        _locationService = locationService,
        super(TripInitial()) {
    on<TripLoadAssignedBus>(_onLoadAssignedBus);
    on<TripLoadCurrentTrip>(_onLoadCurrentTrip);
    on<TripStart>(_onStartTrip);
    on<TripEnd>(_onEndTrip);
    on<TripLocationUpdate>(_onLocationUpdate);
    on<TripStudentPickup>(_onStudentPickup);
    on<TripStudentDropoff>(_onStudentDropoff);
    on<TripEmergencyAlert>(_onEmergencyAlert);
    on<TripStartStreaming>(_onStartStreaming);
    on<TripStopStreaming>(_onStopStreaming);
  }

  Future<void> _onLoadAssignedBus(
    TripLoadAssignedBus event,
    Emitter<TripState> emit,
  ) async {
    emit(TripLoading());
    try {
      final bus = await _tripRepository.getAssignedBus();
      
      if (bus == null) {
        emit(TripNoAssignment());
        return;
      }
      
      // Check for current active trip
      final currentTrip = await _tripRepository.getCurrentTrip();
      
      if (currentTrip != null) {
        final students = await _tripRepository.getTripStudents(currentTrip['_id']);
        final stops = await _tripRepository.getRouteStops(currentTrip['route']['_id']);
        
        _startLocationTracking(currentTrip['_id'], bus['_id']);
        
        emit(TripActive(
          trip: currentTrip,
          bus: bus,
          students: students,
          stops: stops,
        ));
      } else {
        emit(TripReady(
          bus: bus,
          routes: bus['routes'] ?? [],
        ));
      }
    } catch (e) {
      emit(TripError(message: e.toString()));
    }
  }

  Future<void> _onLoadCurrentTrip(
    TripLoadCurrentTrip event,
    Emitter<TripState> emit,
  ) async {
    add(TripLoadAssignedBus());
  }

  Future<void> _onStartTrip(
    TripStart event,
    Emitter<TripState> emit,
  ) async {
    emit(TripLoading());
    try {
      final trip = await _tripRepository.startTrip(event.busId, event.routeId);
      final bus = await _tripRepository.getAssignedBus();
      final students = await _tripRepository.getTripStudents(trip['_id']);
      final stops = await _tripRepository.getRouteStops(event.routeId);
      
      _startLocationTracking(trip['_id'], event.busId);
      
      emit(TripActive(
        trip: trip,
        bus: bus!,
        students: students,
        stops: stops,
      ));
    } catch (e) {
      emit(TripError(message: e.toString()));
    }
  }

  Future<void> _onEndTrip(
    TripEnd event,
    Emitter<TripState> emit,
  ) async {
    try {
      _stopLocationTracking();
      await _tripRepository.endTrip(event.tripId);
      
      final bus = await _tripRepository.getAssignedBus();
      if (bus != null) {
        emit(TripReady(
          bus: bus,
          routes: bus['routes'] ?? [],
        ));
      } else {
        emit(TripNoAssignment());
      }
    } catch (e) {
      emit(TripError(message: e.toString()));
    }
  }

  Future<void> _onLocationUpdate(
    TripLocationUpdate event,
    Emitter<TripState> emit,
  ) async {
    if (state is TripActive) {
      final currentState = state as TripActive;
      
      // Send location via socket
      _socketService.sendLocationUpdate(
        currentState.bus['_id'],
        event.position.latitude,
        event.position.longitude,
        event.position.speed,
        event.position.heading,
      );
      
      // Update location via API (less frequently)
      await _tripRepository.updateLocation(
        currentState.trip['_id'],
        event.position.latitude,
        event.position.longitude,
        event.position.speed,
        event.position.heading,
      );
      
      emit(currentState.copyWith(currentPosition: event.position));
    }
  }

  Future<void> _onStudentPickup(
    TripStudentPickup event,
    Emitter<TripState> emit,
  ) async {
    if (state is TripActive) {
      final currentState = state as TripActive;
      
      try {
        await _tripRepository.confirmStudentPickup(event.tripId, event.studentId);
        
        // Update students list
        final updatedStudents = currentState.students.map((s) {
          if (s['_id'] == event.studentId) {
            return {...s, 'status': 'picked_up', 'pickedUpAt': DateTime.now().toIso8601String()};
          }
          return s;
        }).toList();
        
        emit(currentState.copyWith(students: updatedStudents));
      } catch (e) {
        // Handle error silently or show snackbar
      }
    }
  }

  Future<void> _onStudentDropoff(
    TripStudentDropoff event,
    Emitter<TripState> emit,
  ) async {
    if (state is TripActive) {
      final currentState = state as TripActive;
      
      try {
        await _tripRepository.confirmStudentDropoff(event.tripId, event.studentId);
        
        // Update students list
        final updatedStudents = currentState.students.map((s) {
          if (s['_id'] == event.studentId) {
            return {...s, 'status': 'dropped_off', 'droppedOffAt': DateTime.now().toIso8601String()};
          }
          return s;
        }).toList();
        
        emit(currentState.copyWith(students: updatedStudents));
      } catch (e) {
        // Handle error silently or show snackbar
      }
    }
  }

  Future<void> _onEmergencyAlert(
    TripEmergencyAlert event,
    Emitter<TripState> emit,
  ) async {
    if (state is TripActive) {
      final currentState = state as TripActive;
      
      try {
        final position = currentState.currentPosition;
        if (position != null) {
          await _tripRepository.sendEmergencyAlert(
            event.tripId,
            event.alertType,
            event.message,
            position.latitude,
            position.longitude,
          );
        }
      } catch (e) {
        // Handle error
      }
    }
  }

  Future<void> _onStartStreaming(
    TripStartStreaming event,
    Emitter<TripState> emit,
  ) async {
    if (state is TripActive) {
      final currentState = state as TripActive;
      _socketService.startStreaming(event.busId);
      emit(currentState.copyWith(isStreaming: true));
    }
  }

  Future<void> _onStopStreaming(
    TripStopStreaming event,
    Emitter<TripState> emit,
  ) async {
    if (state is TripActive) {
      final currentState = state as TripActive;
      _socketService.stopStreaming(currentState.bus['_id']);
      emit(currentState.copyWith(isStreaming: false));
    }
  }

  void _startLocationTracking(String tripId, String busId) {
    _locationSubscription?.cancel();
    _locationSubscription = _locationService.getLocationStream().listen(
      (position) {
        add(TripLocationUpdate(position: position));
      },
    );
    
    _socketService.joinBusRoom(busId);
  }

  void _stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  @override
  Future<void> close() {
    _stopLocationTracking();
    return super.close();
  }
}
