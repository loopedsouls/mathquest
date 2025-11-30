
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'data/datasources/remote/firebase_service.dart';
import 'app/theme/app_theme.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'presentation/screens/splash/splash_screen.dart';

// Verificar se Firebase está disponível na plataforma atual
bool get firebaseAvailable {
  // Firebase não funciona no Linux desktop
  if (!kIsWeb) {
    try {
      return !Platform.isLinux;
    } catch (e) {
      // Se Platform falhar, assumir que não está disponível
      return false;
    }
  }
  // Na web, Firebase funciona
  return true;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carregar variáveis de ambiente
  await dotenv.load(fileName: ".env");

  // Inicializar Firebase apenas se disponível na plataforma
  if (firebaseAvailable) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Inicializar Firebase App Check
    try {
      await FirebaseAppCheck.instance.activate();
      print('Firebase App Check ativado com sucesso');
    } catch (e) {
      // App Check pode falhar em algumas plataformas (como Windows) ou durante desenvolvimento
      // mas isso não deve impedir o funcionamento do app
      print('Erro ao inicializar App Check (normal em desenvolvimento): $e');
    }

    // Inicializar Remote Config
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await remoteConfig.fetchAndActivate();
    } catch (e) {
      // Remote Config pode falhar em algumas plataformas (como Windows)
      // mas isso não deve impedir o funcionamento do app
      print('Erro ao inicializar Remote Config: $e');
    }

    // Inicializar Crashlytics após Remote Config
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    } catch (e) {
      // Crashlytics pode falhar em algumas plataformas (como Windows)
      // mas isso não deve impedir o funcionamento do app
      print('Erro ao inicializar Crashlytics: $e');
    }

    // Inicializar OpenAI API
    try {
      await AIService.initialize();
    } catch (e) {
      // OpenAI pode falhar se a chave não estiver configurada
      // mas isso não deve impedir o funcionamento do app
      print('Erro ao inicializar OpenAI API: $e');
    }
  } else {
    print(
        'Firebase não disponível nesta plataforma - executando em modo offline');
  }

  // Configurar orientações permitidas e UI overlay
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Configurar a UI overlay com cores modernas
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MathTutorApp());
}

class MathTutorApp extends StatelessWidget {
  const MathTutorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MathQuest - Tutoria Inteligente',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Usar tema escuro como padrão
      navigatorObservers: firebaseAvailable
          ? [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)]
          : [],
      home: const ResponsiveWrapper(
        child: AuthWrapper(),
      ),
    );
  }
}

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkBackgroundColor,
                AppTheme.darkSurfaceColor.withValues(alpha: 0.5),
              ],
            ),
          ),
          child: isDesktop
              ? child // Desktop não precisa de SafeArea devido ao layout customizado
              : SafeArea(child: child), // Mobile mantém SafeArea
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Se Firebase não estiver disponível (ex: Linux), pular autenticação
    if (!firebaseAvailable) {
      return const SplashScreen();
    }

    return StreamBuilder<User?>(
      stream: AuthRepositoryImpl().authStateChanges.map((user) => user != null ? FirebaseAuth.instance.currentUser : null),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Mostrar o app principal - usuário pode estar logado ou como convidado
        return const SplashScreen();
      },
    );
  }
}
