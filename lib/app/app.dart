import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'theme/app_theme.dart';
import 'routes.dart';
import '../main.dart';

/// Main Application Widget
class MathQuestApp extends StatelessWidget {
  const MathQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MathQuest - Tutoria Inteligente',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      navigatorObservers: firebaseAvailable
          ? [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)]
          : [],
      onGenerateRoute: AppRoutes.generateRoute,
      initialRoute: AppRoutes.splash,
    );
  }
}
