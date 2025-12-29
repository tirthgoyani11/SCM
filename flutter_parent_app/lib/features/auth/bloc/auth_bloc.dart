import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/models/models.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/notification_service.dart';
import '../repository/auth_repository.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  LoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String phone;

  RegisterRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.phone,
  });

  @override
  List<Object?> get props => [email, password, name, phone];
}

class LogoutRequested extends AuthEvent {}

class UpdateProfileRequested extends AuthEvent {
  final String? name;
  final String? phone;

  UpdateProfileRequested({this.name, this.phone});

  @override
  List<Object?> get props => [name, phone];
}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final SocketService socketService;
  final NotificationService notificationService;

  AuthBloc({
    required this.authRepository,
    required this.socketService,
    required this.notificationService,
  }) : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final isLoggedIn = await authRepository.isLoggedIn();
      
      if (isLoggedIn) {
        final user = await authRepository.getProfile();
        if (user != null) {
          // Connect socket
          await socketService.connect();
          
          // Update FCM token
          final fcmToken = notificationService.fcmToken;
          if (fcmToken != null) {
            await authRepository.updateFcmToken(fcmToken);
          }
          
          emit(AuthAuthenticated(user: user));
        } else {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final user = await authRepository.login(event.email, event.password);
      
      if (user != null) {
        // Connect socket
        await socketService.connect();
        
        // Update FCM token
        final fcmToken = notificationService.fcmToken;
        if (fcmToken != null) {
          await authRepository.updateFcmToken(fcmToken);
        }
        
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthError(message: 'Login failed. Please check your credentials.'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final user = await authRepository.register(
        email: event.email,
        password: event.password,
        name: event.name,
        phone: event.phone,
      );
      
      if (user != null) {
        // Connect socket
        await socketService.connect();
        
        // Update FCM token
        final fcmToken = notificationService.fcmToken;
        if (fcmToken != null) {
          await authRepository.updateFcmToken(fcmToken);
        }
        
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthError(message: 'Registration failed. Please try again.'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      await authRepository.logout();
      socketService.disconnect();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onUpdateProfileRequested(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;
    
    try {
      final user = await authRepository.updateProfile(
        name: event.name,
        phone: event.phone,
      );
      
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
}
