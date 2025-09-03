import 'package:flutter/material.dart';

/// App Theme Configuration - Apenas tema escuro padrão
class AppTheme {
  // === CORES PRIMÁRIAS - Design System Moderno ===
  static Color primaryColor = const Color(0xFF03BC62); // color3
  static Color primaryDarkColor = const Color(0xFF009640); // color5
  static Color primaryLightColor = const Color(0xFF04CF73); // color2
  static Color primaryAccent = const Color(0xFF01A951); // color4

  // === CORES SECUNDÁRIAS ===
  static Color secondaryColor = const Color(0xFF05E284); // color1
  static Color secondaryDarkColor = const Color(0xFF009640); // color5
  static Color secondaryLightColor = const Color(0xFF04CF73); // color2

  // === CORES DE STATUS ===
  static Color successColor = const Color(0xFF03BC62); // color3
  static Color errorColor =
      const Color(0xFFE53E3E); // Vermelho moderno para erro
  static Color warningColor =
      const Color(0xFFFF8C00); // Laranja moderno para aviso
  static Color infoColor = const Color(0xFF3182CE); // Azul moderno para info

  // === CORES PARA MODO ESCURO ===
  static Color darkBackgroundColor =
      const Color(0xFF121212); // Preto suave moderno
  static Color darkSurfaceColor =
      const Color(0xFF1E1E1E); // Cinza escuro moderno
  static Color darkCardColor = const Color(0xFF2D2D2D); // Cinza médio moderno

  static Color darkTextPrimaryColor = const Color(0xFFFFFFFF); // Branco puro
  static Color darkTextSecondaryColor = const Color(0xFFB3B3B3); // Cinza claro
  static Color darkTextHintColor = const Color(0xFF757575); // Cinza médio

  static Color darkBorderColor = const Color(0xFF404040); // Cinza para bordas
  static Color darkDividerColor =
      const Color(0xFF404040); // Cinza para divisores

  // === CORES PARA MODO CLARO ===
  static Color lightBackgroundColor =
      const Color(0xFFFAFAFA); // Branco suave moderno
  static Color lightSurfaceColor = const Color(0xFFFFFFFF); // Branco puro
  static Color lightCardColor = const Color(0xFFFFFFFF); // Branco puro

  static Color lightTextPrimaryColor =
      const Color(0xFF2D3748); // Cinza escuro moderno
  static Color lightTextSecondaryColor = const Color(0xFF4A5568); // Cinza médio
  static Color lightTextHintColor = const Color(0xFF718096); // Cinza claro

  static Color lightBorderColor = const Color(0xFFE2E8F0); // Cinza muito claro
  static Color lightDividerColor = const Color(0xFFE2E8F0); // Cinza muito claro

  // === CORES MODERNAS - Glassmorphism & Elevações ===
  static Color glassLight =
      const Color(0xFFFFFFFF).withValues(alpha: 0.8); // Branco translúcido
  static Color glassDark =
      const Color(0xFF000000).withValues(alpha: 0.2); // Preto translúcido
  static Color blurOverlay =
      const Color(0xFF000000).withValues(alpha: 0.4); // Overlay escuro

  // Gradientes Modernos
  static List<Color> modernGradient1 = [
    const Color(0xFF05E284),
    const Color(0xFF009640)
  ]; // Gradiente primário verde
  static List<Color> modernGradient2 = [
    const Color(0xFF04CF73),
    const Color(0xFF01A951)
  ]; // Gradiente secundário verde
  static List<Color> modernGradient3 = [
    const Color(0xFF03BC62),
    const Color(0xFF009640)
  ]; // Gradiente terciário verde

  // Gradientes Neutros para Backgrounds
  static List<Color> neutralGradient1 = [
    const Color(0xFFF7FAFC),
    const Color(0xFFEDF2F7)
  ]; // Gradiente claro neutro
  static List<Color> neutralGradient2 = [
    const Color(0xFF2D3748),
    const Color(0xFF1A202C)
  ]; // Gradiente escuro neutro

  // Sombras Modernas
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.06),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.12),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> strongShadow = [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.25),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];

  // === CORES COMPLEMENTARES ===
  static Color accentColor = const Color(0xFF04CF73); // color2
  static Color highlightColor = const Color(0xFF05E284); // color1
  static Color overlayColor = const Color(0x80000000); // Overlay escuro neutro

  // === GRADIENTES ===
  static LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryDarkColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // === CORES DE PERMISSÃO ===
  static Color assignmentPermissionColor =
      const Color(0xFF3182CE); // Azul moderno
  static Color gradePermissionColor = const Color(0xFF03BC62); // Verde (mantém)
  static Color submissionPermissionColor =
      const Color(0xFF805AD5); // Roxo moderno
  static Color profilePermissionColor =
      const Color(0xFFFF8C00); // Laranja moderno
  static Color announcementPermissionColor =
      const Color(0xFFE53E3E); // Vermelho moderno
  static Color neutroColor = const Color(0xFF718096); // Cinza neutro moderno

  // === MÉTODOS UTILITÁRIOS ===
  /// Retorna a cor baseada na severidade do log
  static Color getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'ERROR':
        return errorColor;
      case 'WARNING':
        return warningColor;
      case 'INFO':
        return infoColor;
      case 'SUCCESS':
        return successColor;
      default:
        return neutroColor;
    }
  }

  static Color excelentColor = const Color(0xFF03BC62); // Verde - excelente
  static Color bomColor = const Color(0xFF3182CE); // Azul - bom
  static Color regularColor = const Color(0xFFFF8C00); // Laranja - regular
  static Color baixoColor = const Color(0xFFE53E3E); // Vermelho - baixo

  // === HELPER METHODS (opcional, pode remover se não usar) ===
  static Color getUserTypeColor(String userType) {
    switch (userType.toLowerCase()) {
      case 'admin':
        return errorColor; // Vermelho para admin
      case 'professor':
        return primaryColor; // Verde para professor
      case 'gestor':
        return const Color(0xFF805AD5); // Roxo para gestor
      case 'aluno':
        return const Color(0xFF3182CE); // Azul para aluno
      default:
        return neutroColor; // Cinza neutro
    }
  }

  /// Retorna a cor de permissão baseada na categoria
  static Color getPermissionColorByCategory(String category) {
    final categoryLower = category.toLowerCase();
    if (categoryLower.contains('assignment')) return assignmentPermissionColor;
    if (categoryLower.contains('grade')) return gradePermissionColor;
    if (categoryLower.contains('submission')) return submissionPermissionColor;
    if (categoryLower.contains('profile')) return profilePermissionColor;
    if (categoryLower.contains('announcement')) {
      return announcementPermissionColor;
    }
    return neutroColor;
  }

  static Color getPerformanceColor(String status) {
    switch (status.toLowerCase()) {
      case 'excelente':
        return excelentColor;
      case 'bom':
        return bomColor;
      case 'regular':
        return regularColor;
      case 'baixo':
        return baixoColor;
      default:
        return neutroColor;
    }
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: lightBackgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: lightCardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: lightTextPrimaryColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: lightTextPrimaryColor,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: lightTextPrimaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: lightTextPrimaryColor,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: lightTextPrimaryColor,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: lightTextPrimaryColor),
        bodyMedium: TextStyle(fontSize: 14, color: lightTextSecondaryColor),
        bodySmall: TextStyle(fontSize: 12, color: lightTextHintColor),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurfaceColor,
        foregroundColor: darkTextPrimaryColor,
        elevation: 2,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: darkCardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkTextPrimaryColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: darkTextPrimaryColor,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkTextPrimaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: darkTextPrimaryColor,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: darkTextPrimaryColor,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: darkTextPrimaryColor),
        bodyMedium: TextStyle(fontSize: 14, color: darkTextSecondaryColor),
        bodySmall: TextStyle(fontSize: 12, color: darkTextHintColor),
      ),
      dividerColor: darkDividerColor,
      dialogTheme: DialogThemeData(backgroundColor: darkCardColor),
    );
  }

  static getPermissionColor(String s) {}

  // === MISSING GETTERS FOR COLORS ===
  static Color get cardColor => lightCardColor;
  static Color get borderColor => lightBorderColor;
  static Color get darkBackground => darkBackgroundColor;
  static Color get darkCard => darkCardColor;
  static Color get darkBorder => darkBorderColor;
  static Color get surfaceColor => lightSurfaceColor;
  static Color get darkSurface => darkSurfaceColor;
  static Color get textMuted => lightTextHintColor;
  static Color get darkTextMuted => darkTextHintColor;
  static Color get textSecondary => lightTextSecondaryColor;
  static Color get darkTextSecondary => darkTextSecondaryColor;
  static Color get textPrimary => lightTextPrimaryColor;
  static Color get darkTextPrimary => darkTextPrimaryColor;
  static Color get primaryLight => primaryLightColor;
  static Color get primaryDark => primaryDarkColor;

  // === MISSING GETTERS FOR TEXT STYLES - Modernos ===
  static TextStyle get displayLarge => const TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.12,
      );

  static TextStyle get displayMedium => const TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.16,
      );

  static TextStyle get displaySmall => const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.22,
      );

  static TextStyle get headingSmall => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.33,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
      );

  static TextStyle get caption => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
      );

  static TextStyle get headingLarge => const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.25,
      );

  static TextStyle get headingMedium => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        height: 1.29,
      );

  // === COMPONENTES MODERNOS ===
  static BoxDecoration get modernCard => BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: lightCardColor,
        boxShadow: softShadow,
        border: Border.all(
            color: lightBorderColor.withValues(alpha: 0.1), width: 1),
      );

  static BoxDecoration get modernCardDark => BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: darkCardColor,
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF000000).withValues(alpha: 0.3), // Sombra neutra
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border:
            Border.all(color: darkBorderColor.withValues(alpha: 0.2), width: 1),
      );

  static BoxDecoration modernGlassCard(bool isDark) => BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? glassDark.withValues(alpha: 0.3)
            : glassLight.withValues(alpha: 0.7),
        border: Border.all(
          color: isDark
              ? darkBorderColor.withValues(alpha: 0.3)
              : lightBorderColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: isDark ? mediumShadow : softShadow,
      );

  // === MISSING GETTERS FOR SPACING AND RADIUS ===
  static double get spacing => 16.0;
  static double get spacingSmall => 8.0;
  static double get spacingLarge => 24.0;
  static double get radius => 8.0;
  static double get radiusLarge => 12.0;
  static double get radiusXLarge => 16.0;

  // === MISSING GETTERS FOR PADDING ===
  static double get paddingLarge => 20.0;
  static double get padding => 16.0;
  static double get radiusSmall => 6.0;

  // === MISSING GETTERS FOR COLORS ===
  static Color get backgroundColor => darkBackgroundColor;

  // === MISSING GETTERS FOR BUTTON STYLES ===
  static TextStyle get button => const TextStyle(
      fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white);

  static ButtonStyle get buttonStyle => ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      );

  // === MISSING SNACKBAR METHODS ===
  static void showSuccessSnackBar(BuildContext context, String message) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: successColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: errorColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void showWarningSnackBar(BuildContext context, String message) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: warningColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void showInfoSnackBar(BuildContext context, String message) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: infoColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
