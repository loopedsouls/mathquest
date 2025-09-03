import 'package:flutter/material.dart';

/// App Theme Configuration - Apenas tema escuro padrão
class AppTheme {
  // === CORES PRIMÁRIAS - Design System Moderno ===
  static Color primaryColor = Color(0xFF6366F1); // Indigo 500
  static Color primaryDarkColor = Color(0xFF4338CA); // Indigo 700
  static Color primaryLightColor = Color(0xFF818CF8); // Indigo 400
  static Color primaryAccent = Color(0xFFA855F7); // Purple 500

  // === CORES SECUNDÁRIAS ===
  static Color secondaryColor = Color(0xFF10B981); // Emerald 500
  static Color secondaryDarkColor = Color(0xFF047857); // Emerald 700
  static Color secondaryLightColor = Color(0xFF34D399); // Emerald 400

  // === CORES DE STATUS ===
  static Color successColor = Color(0xFF10B981); // Verde
  static Color errorColor = Color(0xFFEF4444); // Vermelho
  static Color warningColor = Color(0xFFF59E0B); // Amarelo/Laranja
  static Color infoColor = Color(0xFF06B6D4); // Cyan

  // === CORES PARA MODO ESCURO ===
  static Color darkBackgroundColor = Color(0xFF0F172A);
  static Color darkSurfaceColor = Color(0xFF1E293B);
  static Color darkCardColor = Color(0xFF1E293B);

  static Color darkTextPrimaryColor = Color(0xFFFFFFFF);
  static Color darkTextSecondaryColor = Color(0xFF94A3B8);
  static Color darkTextHintColor = Color(0xFF64748B);

  static Color darkBorderColor = Color(0xFF334155);
  static Color darkDividerColor = Color(0xFF334155);

  // === CORES PARA MODO CLARO ===
  static Color lightBackgroundColor = Color(0xFFF8FAFC);
  static Color lightSurfaceColor = Color(0xFFFFFFFF);
  static Color lightCardColor = Color(0xFFFFFFFF);

  static Color lightTextPrimaryColor = Color(0xFF0F172A);
  static Color lightTextSecondaryColor = Color(0xFF475569);
  static Color lightTextHintColor = Color(0xFF64748B);

  static Color lightBorderColor = Color(0xFFE2E8F0);
  static Color lightDividerColor = Color(0xFFE2E8F0);

  // === CORES MODERNAS - Glassmorphism & Elevações ===
  static Color glassLight = Color(0xFFFFFFFF).withOpacity(0.1);
  static Color glassDark = Color(0xFF000000).withOpacity(0.1);
  static Color blurOverlay = Color(0xFF000000).withOpacity(0.4);

  // Gradientes Modernos
  static List<Color> modernGradient1 = [Color(0xFF667EEA), Color(0xFF764BA2)];
  static List<Color> modernGradient2 = [Color(0xFFF093FB), Color(0xFFF5576C)];
  static List<Color> modernGradient3 = [Color(0xFF4FACFE), Color(0xFF00F2FE)];

  // Sombras Modernas
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0xFF000000).withOpacity(0.06),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Color(0xFF000000).withOpacity(0.12),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  static List<BoxShadow> strongShadow = [
    BoxShadow(
      color: Color(0xFF000000).withOpacity(0.25),
      blurRadius: 40,
      offset: Offset(0, 16),
    ),
  ];

  // === CORES COMPLEMENTARES ===
  static Color accentColor = Color(0xFF8B5CF6); // Purple
  static Color highlightColor = Color(0xFFFBBF24); // Yellow highlight
  static Color overlayColor = Color(0x80000000); // Semi-transparent black

  // === GRADIENTES ===
  static LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryDarkColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // === CORES DE PERMISSÃO ===
  static Color assignmentPermissionColor = Color(0xFF6366F1); // Indigo
  static Color gradePermissionColor = Color(0xFF10B981); // Emerald
  static Color submissionPermissionColor = Color(0xFFF59E0B); // Amber
  static Color profilePermissionColor = Color(0xFF06B6D4); // Cyan
  static Color announcementPermissionColor = Color(0xFF8B5CF6); // Purple
  static Color neutroColor = Color(0xFF64748B); // Neutral

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

  static Color excelentColor = Color(0xFF10B981); // Verde
  static Color bomColor = Color(0xFF6366F1); // Azul
  static Color regularColor = Color(0xFFF59E0B); // Amarelo
  static Color baixoColor = Color(0xFFEF4444); // Vermelho

  // === HELPER METHODS (opcional, pode remover se não usar) ===
  static Color getUserTypeColor(String userType) {
    switch (userType.toLowerCase()) {
      case 'admin':
        return errorColor;
      case 'professor':
        return primaryColor;
      case 'gestor':
        return secondaryDarkColor;
      case 'aluno':
        return secondaryColor;
      default:
        return darkTextHintColor;
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
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
  static TextStyle get displayLarge => TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static TextStyle get displayMedium => TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
  );

  static TextStyle get displaySmall => TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
  );

  static TextStyle get headingSmall => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
  );

  static TextStyle get bodyLarge => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static TextStyle get bodySmall => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  static TextStyle get caption => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  static TextStyle get headingLarge => TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.25,
  );

  static TextStyle get headingMedium => TextStyle(
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
    border: Border.all(color: lightBorderColor.withOpacity(0.1), width: 1),
  );

  static BoxDecoration get modernCardDark => BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    color: darkCardColor,
    boxShadow: [
      BoxShadow(
        color: Color(0xFF000000).withOpacity(0.3),
        blurRadius: 15,
        offset: Offset(0, 8),
      ),
    ],
    border: Border.all(color: darkBorderColor.withOpacity(0.2), width: 1),
  );

  static BoxDecoration modernGlassCard(bool isDark) => BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    color: isDark ? glassDark.withOpacity(0.3) : glassLight.withOpacity(0.7),
    border: Border.all(
      color: isDark
          ? darkBorderColor.withOpacity(0.3)
          : lightBorderColor.withOpacity(0.2),
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
  static TextStyle get button =>
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white);

  static ButtonStyle get buttonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  );

  // === MISSING SNACKBAR METHODS ===
  static void showSuccessSnackBar(BuildContext context, String message) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: successColor,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.all(16),
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
            Icon(Icons.error, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: errorColor,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.all(16),
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
            Icon(Icons.warning, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: warningColor,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.all(16),
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
            Icon(Icons.info, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: infoColor,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.all(16),
      ),
    );
  }
}
