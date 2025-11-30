import 'package:flutter/material.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/gameplay/gameplay_screen.dart';
import '../presentation/screens/results/results_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/leaderboard/leaderboard_screen.dart';
import '../presentation/screens/shop/shop_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';

/// Application Routes Configuration
class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String gameplay = '/gameplay';
  static const String results = '/results';
  static const String profile = '/profile';
  static const String leaderboard = '/leaderboard';
  static const String shop = '/shop';
  static const String settings = '/settings';

  /// Generate route based on settings
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);
      case onboarding:
        return _buildRoute(const OnboardingScreen(), settings);
      case login:
        return _buildRoute(const LoginScreen(), settings);
      case register:
        return _buildRoute(const RegisterScreen(), settings);
      case home:
        return _buildRoute(const HomeScreen(), settings);
      case gameplay:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          GameplayScreen(
            lessonId: args?['lessonId'] ?? '',
          ),
          settings,
        );
      case results:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          ResultsScreen(
            lessonId: args?['lessonId'] ?? '',
            score: args?['score'] ?? 0,
            totalQuestions: args?['totalQuestions'] ?? 0,
            xpGained: args?['xpGained'] ?? 0,
          ),
          settings,
        );
      case profile:
        return _buildRoute(const ProfileScreen(), settings);
      case leaderboard:
        return _buildRoute(const LeaderboardScreen(), settings);
      case shop:
        return _buildRoute(const ShopScreen(), settings);
      case AppRoutes.settings:
        return _buildRoute(const SettingsScreen(), settings);
      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('Rota não encontrada: ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }

  /// Build route with animation
  static Route<dynamic> _buildRoute(Widget widget, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => widget,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
