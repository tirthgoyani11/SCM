import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import 'socket_service.dart';
import 'location_service.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/repository/auth_repository.dart';
import '../../features/trip/bloc/trip_bloc.dart';
import '../../features/trip/repository/trip_repository.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Services
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  
  getIt.registerLazySingleton<ApiService>(() => ApiService());
  getIt.registerLazySingleton<SocketService>(() => SocketService());
  getIt.registerLazySingleton<LocationService>(() => LocationService());
  
  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      apiService: getIt<ApiService>(),
      storage: getIt<FlutterSecureStorage>(),
    ),
  );
  
  getIt.registerLazySingleton<TripRepository>(
    () => TripRepository(apiService: getIt<ApiService>()),
  );
  
  // Blocs
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      authRepository: getIt<AuthRepository>(),
      socketService: getIt<SocketService>(),
    ),
  );
  
  getIt.registerFactory<TripBloc>(
    () => TripBloc(
      tripRepository: getIt<TripRepository>(),
      socketService: getIt<SocketService>(),
      locationService: getIt<LocationService>(),
    ),
  );
}
