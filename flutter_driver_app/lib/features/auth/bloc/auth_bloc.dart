import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../repository/auth_repository.dart';
import '../../../core/services/socket_service.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthUpdateFcmToken extends AuthEvent {
  final String fcmToken;

  const AuthUpdateFcmToken({required this.fcmToken});

  @override
  List<Object?> get props => [fcmToken];
}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final Map<String, dynamic> user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final SocketService _socketService;

  AuthBloc({
    required AuthRepository authRepository,
    required SocketService socketService,
  })  : _authRepository = authRepository,
        _socketService = socketService,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthUpdateFcmToken>(_onAuthUpdateFcmToken);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      if (isLoggedIn) {
        final user = await _authRepository.getCurrentUser();
        
        // Verify user is a driver
        if (user['role'] != 'driver') {
          await _authRepository.logout();
          emit(const AuthError(message: 'Access denied. Driver account required.'));
          return;
        }
        
        final token = await _authRepository.getToken();
        _socketService.connect(token!);
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _authRepository.login(event.email, event.password);
      final user = response['user'];
      
      // Verify user is a driver
      if (user['role'] != 'driver') {
        await _authRepository.logout();
        emit(const AuthError(message: 'Access denied. This app is for drivers only.'));
        return;
      }
      
      final token = response['token'];
      _socketService.connect(token);
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    _socketService.disconnect();
    emit(AuthUnauthenticated());
  }

  Future<void> _onAuthUpdateFcmToken(
    AuthUpdateFcmToken event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.updateFcmToken(event.fcmToken);
    } catch (e) {
      // Silent fail for FCM token update
    }
  }
}
