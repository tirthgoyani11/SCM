import 'package:flutter/material.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/tracking/screens/tracking_screen.dart';
import '../../features/tracking/screens/live_video_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/history/screens/trip_history_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String tracking = '/tracking';
  static const String liveVideo = '/live-video';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String tripHistory = '/trip-history';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);
      
      case login:
        return _buildRoute(const LoginScreen(), settings);
      
      case register:
        return _buildRoute(const RegisterScreen(), settings);
      
      case home:
        return _buildRoute(const HomeScreen(), settings);
      
      case tracking:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          TrackingScreen(childId: args?['childId'] ?? ''),
          settings,
        );
      
      case liveVideo:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          LiveVideoScreen(
            tripId: args?['tripId'] ?? '',
            busNumber: args?['busNumber'] ?? '',
          ),
          settings,
        );
      
      case notifications:
        return _buildRoute(const NotificationsScreen(), settings);
      
      case profile:
        return _buildRoute(const ProfileScreen(), settings);
      
      case tripHistory:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          TripHistoryScreen(childId: args?['childId'] ?? ''),
          settings,
        );
      
      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
