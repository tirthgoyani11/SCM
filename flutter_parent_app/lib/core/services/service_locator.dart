import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import 'socket_service.dart';
import 'notification_service.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/repository/auth_repository.dart';
import '../../features/tracking/bloc/tracking_bloc.dart';
import '../../features/tracking/repository/tracking_repository.dart';
import '../../features/notifications/bloc/notification_bloc.dart';
import '../../features/notifications/repository/notification_repository.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Core services
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  
  getIt.registerLazySingleton<ApiService>(() => ApiService());
  
  getIt.registerLazySingleton<SocketService>(() => SocketService());
  
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  
  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      apiService: getIt<ApiService>(),
      storage: getIt<FlutterSecureStorage>(),
    ),
  );
  
  getIt.registerLazySingleton<TrackingRepository>(
    () => TrackingRepository(
      apiService: getIt<ApiService>(),
      socketService: getIt<SocketService>(),
    ),
  );
  
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(apiService: getIt<ApiService>()),
  );
  
  // Blocs
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      authRepository: getIt<AuthRepository>(),
      socketService: getIt<SocketService>(),
      notificationService: getIt<NotificationService>(),
    ),
  );
  
  getIt.registerFactory<TrackingBloc>(
    () => TrackingBloc(
      trackingRepository: getIt<TrackingRepository>(),
      socketService: getIt<SocketService>(),
    ),
  );
  
  getIt.registerFactory<NotificationBloc>(
    () => NotificationBloc(
      notificationRepository: getIt<NotificationRepository>(),
    ),
  );
  
  // Initialize notification service
  await getIt<NotificationService>().initialize();
}
