import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Application Theme Configuration
class AppTheme {
  // Re-export colors for backward compatibility
  static Color get primaryColor => AppColors.primary;
  static Color get primaryDarkColor => AppColors.primaryDark;
  static Color get primaryLightColor => AppColors.primaryLight;
  static Color get primaryAccent => AppColors.primaryAccent;

  static Color get secondaryColor => AppColors.secondary;
  static Color get secondaryDarkColor => AppColors.secondaryDark;
  static Color get secondaryLightColor => AppColors.secondaryLight;

  static Color get successColor => AppColors.success;
  static Color get errorColor => AppColors.error;
  static Color get warningColor => AppColors.warning;
  static Color get infoColor => AppColors.info;

  static Color get darkBackgroundColor => AppColors.darkBackground;
  static Color get darkSurfaceColor => AppColors.darkSurface;
  static Color get darkCardColor => AppColors.darkCard;
  static Color get darkTextPrimaryColor => AppColors.darkTextPrimary;
  static Color get darkTextSecondaryColor => AppColors.darkTextSecondary;
  static Color get darkTextHintColor => AppColors.darkTextHint;
  static Color get darkBorderColor => AppColors.darkBorder;
  static Color get darkDividerColor => AppColors.darkDivider;

  static Color get lightBackgroundColor => AppColors.lightBackground;
  static Color get lightSurfaceColor => AppColors.lightSurface;
  static Color get lightCardColor => AppColors.lightCard;
  static Color get lightTextPrimaryColor => AppColors.lightTextPrimary;
  static Color get lightTextSecondaryColor => AppColors.lightTextSecondary;
  static Color get lightTextHintColor => AppColors.lightTextHint;
  static Color get lightBorderColor => AppColors.lightBorder;
  static Color get lightDividerColor => AppColors.lightDivider;

  static Color get glassLight => AppColors.glassLight;
  static Color get glassDark => AppColors.glassDark;
  static Color get blurOverlay => AppColors.blurOverlay;

  static List<Color> get modernGradient1 => AppColors.gradientPrimary;
  static List<Color> get modernGradient2 => AppColors.gradientSecondary;
  static List<Color> get modernGradient3 => AppColors.gradientTertiary;
  static List<Color> get neutralGradient1 => AppColors.gradientNeutralLight;
  static List<Color> get neutralGradient2 => AppColors.gradientNeutralDark;

  static Color get accentColor => AppColors.accent;
  static Color get highlightColor => AppColors.highlight;
  static Color get overlayColor => AppColors.overlay;
  static Color get neutroColor => AppColors.neutral;

  static Color get excelentColor => AppColors.excellent;
  static Color get bomColor => AppColors.good;
  static Color get regularColor => AppColors.regular;
  static Color get baixoColor => AppColors.low;

  // Spacing and radius
  static double get spacing => 16.0;
  static double get spacingSmall => 8.0;
  static double get spacingLarge => 24.0;
  static double get radius => 8.0;
  static double get radiusSmall => 6.0;
  static double get radiusLarge => 12.0;
  static double get radiusXLarge => 16.0;
  static double get padding => 16.0;
  static double get paddingLarge => 20.0;

  // Shadows
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

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> cardShadowDark = [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.22),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  // Primary gradient
  // ignore: prefer_const_constructors
  static LinearGradient primaryGradient = LinearGradient(
    colors: const [AppColors.primary, AppColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text styles
  static TextStyle get displayLarge => AppTextStyles.displayLarge;
  static TextStyle get displayMedium => AppTextStyles.displayMedium;
  static TextStyle get displaySmall => AppTextStyles.displaySmall;
  static TextStyle get headingLarge => AppTextStyles.headingLarge;
  static TextStyle get headingMedium => AppTextStyles.headingMedium;
  static TextStyle get headingSmall => AppTextStyles.headingSmall;
  static TextStyle get bodyLarge => AppTextStyles.bodyLarge;
  static TextStyle get bodyMedium => AppTextStyles.bodyMedium;
  static TextStyle get bodySmall => AppTextStyles.bodySmall;
  static TextStyle get caption => AppTextStyles.caption;
  static TextStyle get button => AppTextStyles.button;

  // Getters for colors
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
  static Color get backgroundColor => darkBackgroundColor;

  // Card decorations
  static BoxDecoration get modernCard => BoxDecoration(
        borderRadius: BorderRadius.circular(radiusXLarge),
        color: lightCardColor,
        boxShadow: cardShadow,
        border: Border.all(
            color: lightBorderColor.withValues(alpha: 0.08), width: 1),
      );

  static BoxDecoration get modernCardDark => BoxDecoration(
        borderRadius: BorderRadius.circular(radiusXLarge),
        color: darkCardColor,
        boxShadow: cardShadowDark,
        border: Border.all(
            color: darkBorderColor.withValues(alpha: 0.16), width: 1),
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

  // Button styles
  static ButtonStyle get elevatedButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      );

  static ButtonStyle get buttonStyle => elevatedButtonStyle;

  // Helper methods
  static Color getSeverityColor(String severity) =>
      AppColors.getSeverityColor(severity);
  static Color getPerformanceColor(String status) =>
      AppColors.getPerformanceColor(status);
  static Color getUserTypeColor(String userType) =>
      AppColors.getUserTypeColor(userType);
  static Color getPermissionColorByCategory(String category) =>
      AppColors.getPermissionColor(category);
  static Color getPermissionColor(String s) => AppColors.neutral;

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
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
        headlineLarge: AppTextStyles.headingLarge
            .copyWith(color: lightTextPrimaryColor),
        headlineMedium: AppTextStyles.headingMedium
            .copyWith(color: lightTextPrimaryColor),
        headlineSmall:
            AppTextStyles.headingSmall.copyWith(color: lightTextPrimaryColor),
        titleLarge:
            AppTextStyles.titleLarge.copyWith(color: lightTextPrimaryColor),
        titleMedium:
            AppTextStyles.titleMedium.copyWith(color: lightTextPrimaryColor),
        bodyLarge:
            AppTextStyles.bodyLarge.copyWith(color: lightTextPrimaryColor),
        bodyMedium:
            AppTextStyles.bodyMedium.copyWith(color: lightTextSecondaryColor),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: lightTextHintColor),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
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
        headlineLarge:
            AppTextStyles.headingLarge.copyWith(color: darkTextPrimaryColor),
        headlineMedium:
            AppTextStyles.headingMedium.copyWith(color: darkTextPrimaryColor),
        headlineSmall:
            AppTextStyles.headingSmall.copyWith(color: darkTextPrimaryColor),
        titleLarge:
            AppTextStyles.titleLarge.copyWith(color: darkTextPrimaryColor),
        titleMedium:
            AppTextStyles.titleMedium.copyWith(color: darkTextPrimaryColor),
        bodyLarge:
            AppTextStyles.bodyLarge.copyWith(color: darkTextPrimaryColor),
        bodyMedium:
            AppTextStyles.bodyMedium.copyWith(color: darkTextSecondaryColor),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: darkTextHintColor),
      ),
      dividerColor: darkDividerColor,
      dialogTheme: DialogThemeData(backgroundColor: darkCardColor),
    );
  }

  // SnackBar methods
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
