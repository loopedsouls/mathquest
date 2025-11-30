/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'MathQuest';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Sistema de Tutoria Matemática Adaptativa';

  // BNCC Years
  static const List<String> anosEscolares = [
    '6º ano',
    '7º ano',
    '8º ano',
    '9º ano',
  ];

  // BNCC Thematic Units
  static const List<String> unidadesTematicas = [
    'Números',
    'Álgebra',
    'Geometria',
    'Grandezas e Medidas',
    'Probabilidade e Estatística',
  ];

  // Difficulty levels
  static const List<String> difficultyLevels = [
    'fácil',
    'médio',
    'difícil',
  ];

  // Quiz types
  static const List<String> tiposQuiz = [
    'multipla_escolha',
    'verdadeiro_falso',
    'completar',
  ];

  // Gamification
  static const int xpPerCorrectAnswer = 10;
  static const int xpPerQuizCompletion = 50;
  static const int xpPerModuleCompletion = 200;
  static const int coinsPerCorrectAnswer = 5;
  static const int coinsPerDailyStreak = 20;

  // Cache
  static const int cacheExpirationHours = 24;
  static const int maxCachedQuestions = 500;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 800);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration aiGenerationTimeout = Duration(seconds: 60);
}
