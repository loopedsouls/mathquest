import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../widgets/common/animated_logo.dart';
import '../../widgets/flame/splash_game.dart';

/// Splash screen shown on app launch
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const String _onboardingCompleteKey = 'onboarding_complete';

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateToNextScreen();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
    ));

    _controller.forward();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Check onboarding and auth status
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool(_onboardingCompleteKey) ?? false;
    final isGuest = prefs.getBool('is_guest') ?? false;

    if (!mounted) return;

    if (!onboardingComplete) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      return;
    }

    // If guest mode, go directly to home
    if (isGuest) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      return;
    }

    // Check if user is logged in
    final authRepository = AuthRepositoryImpl();
    if (authRepository.isSignedIn) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Cores baseadas no tema
    final backgroundColor = isDark 
        ? AppColors.darkBackground 
        : AppColors.lightBackground;
    final overlayColor = isDark 
        ? const Color(0xFF1a1a2e) 
        : const Color(0xFFE8E8F0);
    final textPrimaryColor = isDark 
        ? AppColors.darkTextPrimary 
        : AppColors.lightTextPrimary;
    final textSecondaryColor = isDark 
        ? AppColors.darkTextSecondary 
        : AppColors.lightTextSecondary;
    final progressColor = isDark 
        ? Colors.white 
        : AppColors.primary;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Flame animated background
          Positioned.fill(
            child: GameWidget(
              game: SplashGame(
                primaryColor: Theme.of(context).primaryColor,
                secondaryColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    overlayColor.withValues(alpha: 0.3),
                    overlayColor.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AnimatedLogo(size: 150),
                        const SizedBox(height: 24),
                        Text(
                          'MathQuest',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                color: textPrimaryColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aprenda Matemática Jogando',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: textSecondaryColor,
                                  ),
                        ),
                        const SizedBox(height: 48),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(progressColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
