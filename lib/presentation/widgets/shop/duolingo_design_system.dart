import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Duolingo-style Design System for MathQuest Shop
/// Provides gamified components with rounded shapes, vibrant colors, and playful animations

// ============================================================================
// COLORS - Duolingo-inspired vibrant palette
// ============================================================================

class DuoColors {
  // Primary colors
  static const Color green = Color(0xFF58CC02);
  static const Color greenDark = Color(0xFF58A700);
  static const Color greenLight = Color(0xFF89E219);
  
  // Secondary colors
  static const Color blue = Color(0xFF1CB0F6);
  static const Color blueDark = Color(0xFF1899D6);
  static const Color blueLight = Color(0xFF49C0F8);
  
  // Accent colors
  static const Color orange = Color(0xFFFF9600);
  static const Color orangeDark = Color(0xFFE58600);
  static const Color orangeLight = Color(0xFFFFB020);
  
  static const Color red = Color(0xFFFF4B4B);
  static const Color redDark = Color(0xFFEA2B2B);
  static const Color redLight = Color(0xFFFF6B6B);
  
  static const Color purple = Color(0xFFCE82FF);
  static const Color purpleDark = Color(0xFFA855F7);
  static const Color purpleLight = Color(0xFFE0B0FF);
  
  static const Color pink = Color(0xFFFF86D0);
  static const Color pinkDark = Color(0xFFFF4EB8);
  static const Color pinkLight = Color(0xFFFFB8E6);
  
  static const Color yellow = Color(0xFFFFD900);
  static const Color yellowDark = Color(0xFFE5C000);
  static const Color yellowLight = Color(0xFFFFE54C);
  
  // Neutral colors
  static const Color gray = Color(0xFF777777);
  static const Color grayLight = Color(0xFFAFAFAF);
  static const Color grayDark = Color(0xFF4B4B4B);
  
  // Background colors
  static const Color bgDark = Color(0xFF131F24);
  static const Color bgCard = Color(0xFF1A2B33);
  static const Color bgElevated = Color(0xFF233640);
  
  // Rarity colors
  static const Color rarityCommon = gray;
  static const Color rarityRare = blue;
  static const Color rarityEpic = purple;
  static const Color rarityLegendary = orange;
}

// ============================================================================
// DYNAMIC THEME SYSTEM
// ============================================================================

/// Holds the current theme colors that can change based on preview or selection
class DuoThemeColors {
  final Color bgDark;
  final Color bgCard;
  final Color bgElevated;
  final Color accent;
  final List<Color> gradientColors;
  final Color textPrimary;
  final Color textSecondary;
  final Color iconColor;

  const DuoThemeColors({
    required this.bgDark,
    required this.bgCard,
    required this.bgElevated,
    required this.accent,
    required this.gradientColors,
    required this.textPrimary,
    required this.textSecondary,
    required this.iconColor,
  });

  /// Default dark theme
  static const DuoThemeColors defaultDarkTheme = DuoThemeColors(
    bgDark: DuoColors.bgDark,
    bgCard: DuoColors.bgCard,
    bgElevated: DuoColors.bgElevated,
    accent: DuoColors.green,
    gradientColors: [DuoColors.bgDark, DuoColors.bgCard, DuoColors.bgElevated],
    textPrimary: Colors.white,
    textSecondary: DuoColors.gray,
    iconColor: Colors.white,
  );

  /// Default light theme
  static const DuoThemeColors defaultLightTheme = DuoThemeColors(
    bgDark: Color(0xFFF5F5F5),
    bgCard: Color(0xFFFFFFFF),
    bgElevated: Color(0xFFE8E8E8),
    accent: DuoColors.green,
    gradientColors: [Color(0xFFF5F5F5), Color(0xFFFFFFFF), Color(0xFFE8E8E8)],
    textPrimary: Color(0xFF1A1A2E),
    textSecondary: Color(0xFF6B7280),
    iconColor: Color(0xFF1A1A2E),
  );

  /// Legacy: Default theme (dark for backwards compatibility)
  static const DuoThemeColors defaultTheme = defaultDarkTheme;

  /// Create theme from theme variant data (light or dark map)
  factory DuoThemeColors.fromVariant(Map<String, dynamic> variantData) {
    return DuoThemeColors(
      bgDark: Color(variantData['bgDark'] as int),
      bgCard: Color(variantData['bgCard'] as int),
      bgElevated: Color(variantData['bgElevated'] as int),
      accent: Color(variantData['accent'] as int),
      gradientColors: [
        Color(variantData['bgDark'] as int),
        Color(variantData['bgCard'] as int),
        Color(variantData['bgElevated'] as int),
      ],
      textPrimary: Color(variantData['textPrimary'] as int),
      textSecondary: Color(variantData['textSecondary'] as int),
      iconColor: Color(variantData['iconColor'] as int),
    );
  }

  /// Legacy: Create theme from old theme data format
  factory DuoThemeColors.fromThemeData(Map<String, dynamic> themeData) {
    // Check if it's the new format with light/dark variants
    if (themeData.containsKey('light') && themeData.containsKey('dark')) {
      // Default to dark variant for legacy calls
      return DuoThemeColors.fromVariant(themeData['dark'] as Map<String, dynamic>);
    }
    
    // Old format with 'colors' array
    final colors = (themeData['colors'] as List).cast<int>();
    final bgColor = Color(colors[0]);
    
    // Calculate text colors based on background brightness
    final brightness = ThemeData.estimateBrightnessForColor(bgColor);
    final isDark = brightness == Brightness.dark;
    
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary = isDark 
        ? Colors.white.withValues(alpha: 0.7) 
        : const Color(0xFF1A1A2E).withValues(alpha: 0.7);
    final iconColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    
    return DuoThemeColors(
      bgDark: bgColor,
      bgCard: Color(colors[1]),
      bgElevated: Color(colors[2]),
      accent: Color(colors[1]),
      gradientColors: colors.map((c) => Color(c)).toList(),
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      iconColor: iconColor,
    );
  }

  /// Get theme by ID with brightness (light/dark)
  static DuoThemeColors getThemeById(String? themeId, {required bool isDarkMode}) {
    if (themeId == null || themeId == 'theme_system') {
      return isDarkMode ? defaultDarkTheme : defaultLightTheme;
    }
    
    for (final theme in DuoThemes.all) {
      if (theme['id'] == themeId) {
        final variant = isDarkMode ? 'dark' : 'light';
        if (theme.containsKey(variant)) {
          return DuoThemeColors.fromVariant(theme[variant] as Map<String, dynamic>);
        }
      }
    }
    return isDarkMode ? defaultDarkTheme : defaultLightTheme;
  }
}

/// InheritedWidget to provide theme throughout the app
class DuoThemeProvider extends StatefulWidget {
  final Widget child;

  const DuoThemeProvider({
    super.key,
    required this.child,
  });

  static DuoThemeProviderState? of(BuildContext context) {
    return context.findAncestorStateOfType<DuoThemeProviderState>();
  }

  @override
  State<DuoThemeProvider> createState() => DuoThemeProviderState();
}

class DuoThemeProviderState extends State<DuoThemeProvider> with WidgetsBindingObserver {
  static const String _selectedThemeKey = 'selected_theme';
  static const String _previewThemeKey = 'preview_theme';
  static const String _themeBrightnessKey = 'theme_brightness'; // 0=light, 1=dark, 2=system

  String? _selectedThemeId;
  String? _previewThemeId;
  ThemeBrightness _themeBrightness = ThemeBrightness.system;
  DuoThemeColors _currentTheme = DuoThemeColors.defaultDarkTheme;

  DuoThemeColors get theme => _currentTheme;
  String? get selectedThemeId => _selectedThemeId;
  String? get previewThemeId => _previewThemeId;
  bool get isPreviewActive => _previewThemeId != null;
  ThemeBrightness get themeBrightness => _themeBrightness;
  
  /// Returns true if currently showing dark mode
  bool get isDarkMode {
    if (_themeBrightness == ThemeBrightness.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeBrightness == ThemeBrightness.dark;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTheme();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // System brightness changed, update theme if using system mode
    if (_themeBrightness == ThemeBrightness.system) {
      _updateCurrentTheme();
    }
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    var selectedTheme = prefs.getString(_selectedThemeKey) ?? 'theme_system';
    final previewTheme = prefs.getString(_previewThemeKey);
    final brightnessIndex = prefs.getInt(_themeBrightnessKey) ?? 2; // Default to system
    
    // Migrate old 'theme_dark' to 'theme_system'
    if (selectedTheme == 'theme_dark') {
      selectedTheme = 'theme_system';
      await prefs.setString(_selectedThemeKey, selectedTheme);
    }
    
    setState(() {
      _selectedThemeId = selectedTheme;
      _previewThemeId = previewTheme;
      _themeBrightness = ThemeBrightness.values[brightnessIndex];
      _updateCurrentTheme();
    });
  }

  void _updateCurrentTheme() {
    final themeId = _previewThemeId ?? _selectedThemeId;
    _currentTheme = DuoThemeColors.getThemeById(themeId, isDarkMode: isDarkMode);
  }

  /// Set brightness mode (light, dark, or system)
  Future<void> setBrightness(ThemeBrightness brightness) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeBrightnessKey, brightness.index);
    
    _themeBrightness = brightness;
    _updateCurrentTheme();
    setState(() {});
  }

  /// Set preview theme (temporary, for previewing in shop)
  void setPreviewTheme(String? themeId) {
    _previewThemeId = themeId;
    _updateCurrentTheme();
    setState(() {});
    // Save preview state
    SharedPreferences.getInstance().then((prefs) {
      if (themeId != null) {
        prefs.setString(_previewThemeKey, themeId);
      } else {
        prefs.remove(_previewThemeKey);
      }
    });
  }

  /// Select theme permanently
  Future<void> selectTheme(String themeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedThemeKey, themeId);
    await prefs.remove(_previewThemeKey);
    
    _selectedThemeId = themeId;
    _previewThemeId = null;
    _updateCurrentTheme();
    setState(() {});
  }

  /// Clear preview and return to selected theme
  void clearPreview() {
    setPreviewTheme(null);
  }

  @override
  Widget build(BuildContext context) {
    return _DuoThemeInherited(
      theme: _currentTheme,
      selectedThemeId: _selectedThemeId,
      previewThemeId: _previewThemeId,
      themeBrightness: _themeBrightness,
      isDarkMode: isDarkMode,
      child: widget.child,
    );
  }
}

class _DuoThemeInherited extends InheritedWidget {
  final DuoThemeColors theme;
  final String? selectedThemeId;
  final String? previewThemeId;
  final ThemeBrightness themeBrightness;
  final bool isDarkMode;

  const _DuoThemeInherited({
    required this.theme,
    required this.selectedThemeId,
    required this.previewThemeId,
    required this.themeBrightness,
    required this.isDarkMode,
    required super.child,
  });

  static _DuoThemeInherited? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_DuoThemeInherited>();
  }

  @override
  bool updateShouldNotify(_DuoThemeInherited oldWidget) {
    return theme != oldWidget.theme || 
           selectedThemeId != oldWidget.selectedThemeId ||
           previewThemeId != oldWidget.previewThemeId ||
           themeBrightness != oldWidget.themeBrightness ||
           isDarkMode != oldWidget.isDarkMode;
  }
}

/// Extension to easily access theme colors
extension DuoThemeExtension on BuildContext {
  DuoThemeColors get duoTheme {
    final inherited = _DuoThemeInherited.of(this);
    return inherited?.theme ?? DuoThemeColors.defaultTheme;
  }
  
  bool get isThemePreviewActive {
    final inherited = _DuoThemeInherited.of(this);
    return inherited?.previewThemeId != null;
  }

  bool get isDuoThemeDark {
    final inherited = _DuoThemeInherited.of(this);
    return inherited?.isDarkMode ?? true;
  }

  ThemeBrightness get duoThemeBrightness {
    final inherited = _DuoThemeInherited.of(this);
    return inherited?.themeBrightness ?? ThemeBrightness.system;
  }
}

// ============================================================================
// DUOLINGO-STYLE BUTTON
// ============================================================================

class DuoButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color color;
  final Color? textColor;
  final IconData? icon;
  final double height;
  final bool isLoading;
  final bool disabled;
  final bool small;

  const DuoButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color = DuoColors.green,
    this.textColor,
    this.icon,
    this.height = 56,
    this.isLoading = false,
    this.disabled = false,
    this.small = false,
  });

  @override
  State<DuoButton> createState() => _DuoButtonState();
}

class _DuoButtonState extends State<DuoButton> {
  bool _isPressed = false;

  Color get _darkerColor {
    final hsl = HSLColor.fromColor(widget.color);
    return hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
  }

  double get _buttonHeight => widget.small ? 40 : widget.height;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.disabled || widget.isLoading;
    
    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: _buttonHeight,
        transform: Matrix4.translationValues(0, _isPressed ? 4 : 0, 0),
        child: Stack(
          children: [
            // Shadow/3D effect
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: _buttonHeight - 4,
                decoration: BoxDecoration(
                  color: isDisabled ? DuoColors.grayDark : _darkerColor,
                  borderRadius: BorderRadius.circular(widget.small ? 12 : 16),
                ),
              ),
            ),
            // Main button
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                height: _buttonHeight - (_isPressed ? 0 : 4),
                decoration: BoxDecoration(
                  color: isDisabled ? DuoColors.gray : widget.color,
                  borderRadius: BorderRadius.circular(widget.small ? 12 : 16),
                ),
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: widget.small ? 18 : 24,
                          height: widget.small ? 18 : 24,
                          child: CircularProgressIndicator(
                            strokeWidth: widget.small ? 2 : 3,
                            color: widget.textColor ?? Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                color: widget.textColor ?? Colors.white,
                                size: widget.small ? 18 : 24,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              widget.text,
                              style: TextStyle(
                                color: widget.textColor ?? Colors.white,
                                fontSize: widget.small ? 14 : 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DUOLINGO-STYLE ICON BUTTON (Circular)
// ============================================================================

class DuoIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final double size;
  final String? badge;

  const DuoIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color = DuoColors.blue,
    this.size = 56,
    this.badge,
  });

  @override
  State<DuoIconButton> createState() => _DuoIconButtonState();
}

class _DuoIconButtonState extends State<DuoIconButton> {
  bool _isPressed = false;

  Color get _darkerColor {
    final hsl = HSLColor.fromColor(widget.color);
    return hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.size,
        height: widget.size + 6,
        transform: Matrix4.translationValues(0, _isPressed ? 4 : 0, 0),
        child: Stack(
          children: [
            // Shadow
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: widget.size,
                decoration: BoxDecoration(
                  color: _darkerColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Main button
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                height: widget.size - (_isPressed ? 0 : 4),
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: widget.size * 0.5,
                ),
              ),
            ),
            // Badge
            if (widget.badge != null)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: DuoColors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    widget.badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DUOLINGO-STYLE COIN DISPLAY
// ============================================================================

class DuoCoinDisplay extends StatelessWidget {
  final int coins;
  final bool showAnimation;

  const DuoCoinDisplay({
    super.key,
    required this.coins,
    this.showAnimation = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.duoTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DuoColors.yellow.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DuoCoinIcon(size: 24),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: const TextStyle(
              color: DuoColors.yellow,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DUOLINGO-STYLE COIN ICON
// ============================================================================

class DuoCoinIcon extends StatelessWidget {
  final double size;

  const DuoCoinIcon({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [DuoColors.yellowLight, DuoColors.yellow, DuoColors.orangeLight],
        ),
        boxShadow: [
          BoxShadow(
            color: DuoColors.yellow.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '◆',
          style: TextStyle(
            color: DuoColors.orangeDark,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DUOLINGO-STYLE AVATAR
// ============================================================================

class DuoAvatar extends StatelessWidget {
  final String? emoji;
  final Color backgroundColor;
  final Color borderColor;
  final double size;
  final int? level;
  final bool isLocked;
  final String? rarity; // common, rare, epic, legendary

  const DuoAvatar({
    super.key,
    this.emoji,
    this.backgroundColor = DuoColors.blue,
    this.borderColor = DuoColors.blueDark,
    this.size = 80,
    this.level,
    this.isLocked = false,
    this.rarity,
  });

  Color get _rarityColor {
    switch (rarity) {
      case 'rare':
        return DuoColors.blue;
      case 'epic':
        return DuoColors.purple;
      case 'legendary':
        return DuoColors.orange;
      default:
        return DuoColors.gray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Shadow
        Container(
          width: size,
          height: size + 6,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: isLocked ? DuoColors.grayDark : borderColor,
            shape: BoxShape.circle,
          ),
        ),
        // Main avatar
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isLocked ? DuoColors.gray : backgroundColor,
            shape: BoxShape.circle,
            border: rarity != null
                ? Border.all(color: _rarityColor, width: 3)
                : null,
          ),
          child: Center(
            child: isLocked
                ? Icon(
                    Icons.lock_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: size * 0.4,
                  )
                : Text(
                    emoji ?? '😊',
                    style: TextStyle(fontSize: size * 0.5),
                  ),
          ),
        ),
        // Level badge
        if (level != null && !isLocked)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: DuoColors.green,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: DuoColors.greenDark.withValues(alpha: 0.5),
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Lv.$level',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        // Rarity glow
        if (rarity == 'legendary' && !isLocked)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: DuoColors.orange.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// PREDEFINED AVATARS
// ============================================================================

class DuoAvatars {
  static const List<Map<String, dynamic>> all = [
    // Free avatars
    {'id': 'avatar_default', 'emoji': '😊', 'name': 'Feliz', 'price': 0, 'rarity': 'common', 'color': 0xFF58CC02},
    {'id': 'avatar_cool', 'emoji': '😎', 'name': 'Estiloso', 'price': 0, 'rarity': 'common', 'color': 0xFF1CB0F6},
    {'id': 'avatar_nerd', 'emoji': '🤓', 'name': 'Estudioso', 'price': 0, 'rarity': 'common', 'color': 0xFF9B59B6},
    
    // Common avatars
    {'id': 'avatar_think', 'emoji': '🤔', 'name': 'Pensador', 'price': 50, 'rarity': 'common', 'color': 0xFFFF9600},
    {'id': 'avatar_star', 'emoji': '🌟', 'name': 'Estrela', 'price': 75, 'rarity': 'common', 'color': 0xFFFFD900},
    {'id': 'avatar_rocket', 'emoji': '🚀', 'name': 'Foguete', 'price': 100, 'rarity': 'common', 'color': 0xFFE74C3C},
    
    // Rare avatars
    {'id': 'avatar_robot', 'emoji': '🤖', 'name': 'Robô', 'price': 200, 'rarity': 'rare', 'color': 0xFF3498DB},
    {'id': 'avatar_alien', 'emoji': '👽', 'name': 'Alien', 'price': 250, 'rarity': 'rare', 'color': 0xFF2ECC71},
    {'id': 'avatar_wizard', 'emoji': '🧙', 'name': 'Mago', 'price': 300, 'rarity': 'rare', 'color': 0xFF8E44AD},
    {'id': 'avatar_ninja', 'emoji': '🥷', 'name': 'Ninja', 'price': 350, 'rarity': 'rare', 'color': 0xFF2C3E50},
    
    // Epic avatars
    {'id': 'avatar_dragon', 'emoji': '🐉', 'name': 'Dragão', 'price': 500, 'rarity': 'epic', 'color': 0xFFE74C3C},
    {'id': 'avatar_unicorn', 'emoji': '🦄', 'name': 'Unicórnio', 'price': 600, 'rarity': 'epic', 'color': 0xFFCE82FF},
    {'id': 'avatar_phoenix', 'emoji': '🔥', 'name': 'Fênix', 'price': 700, 'rarity': 'epic', 'color': 0xFFFF4500},
    
    // Legendary avatars
    {'id': 'avatar_crown', 'emoji': '👑', 'name': 'Rei', 'price': 1000, 'rarity': 'legendary', 'color': 0xFFFFD700},
    {'id': 'avatar_diamond', 'emoji': '💎', 'name': 'Diamante', 'price': 1500, 'rarity': 'legendary', 'color': 0xFF00BFFF},
    {'id': 'avatar_infinity', 'emoji': '♾️', 'name': 'Infinito', 'price': 2000, 'rarity': 'legendary', 'color': 0xFFFF00FF},
  ];
}

// ============================================================================
// DUOLINGO-STYLE SHOP ITEM CARD
// ============================================================================

class DuoShopCard extends StatefulWidget {
  final String id;
  final String name;
  final String? description;
  final int price;
  final String emoji;
  final int color;
  final String rarity;
  final bool isPurchased;
  final bool isSelected;
  final VoidCallback? onTap;

  const DuoShopCard({
    super.key,
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.emoji,
    required this.color,
    this.rarity = 'common',
    this.isPurchased = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<DuoShopCard> createState() => _DuoShopCardState();
}

class _DuoShopCardState extends State<DuoShopCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.rarity == 'legendary') {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Color get _rarityBorderColor {
    switch (widget.rarity) {
      case 'rare':
        return DuoColors.blue;
      case 'epic':
        return DuoColors.purple;
      case 'legendary':
        return DuoColors.orange;
      default:
        return DuoColors.grayDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.duoTheme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(0, _isPressed ? 4 : 0, 0),
        child: Stack(
          children: [
            // Shadow
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: _rarityBorderColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            // Main card
            Container(
              height: _isPressed ? 144 : 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isSelected ? theme.accent : _rarityBorderColor,
                  width: widget.isSelected ? 3 : 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar/Emoji
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Color(widget.color).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color(widget.color),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Name
                  Text(
                    widget.name,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Price or status
                  if (widget.isPurchased)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: DuoColors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                    )
                  else if (widget.price == 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: DuoColors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: DuoColors.green),
                      ),
                      child: const Text(
                        'GRÁTIS',
                        style: TextStyle(
                          color: DuoColors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const DuoCoinIcon(size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.price}',
                          style: const TextStyle(
                            color: DuoColors.yellow,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // Rarity badge
            if (widget.rarity != 'common')
              Positioned(
                top: 8,
                right: 8,
                child: _RarityBadge(rarity: widget.rarity),
              ),
            // Selected checkmark
            if (widget.isSelected)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: DuoColors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RarityBadge extends StatelessWidget {
  final String rarity;

  const _RarityBadge({required this.rarity});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    IconData icon;

    switch (rarity) {
      case 'rare':
        color = DuoColors.blue;
        text = 'Raro';
        icon = Icons.star;
        break;
      case 'epic':
        color = DuoColors.purple;
        text = 'Épico';
        icon = Icons.auto_awesome;
        break;
      case 'legendary':
        color = DuoColors.orange;
        text = 'Lendário';
        icon = Icons.whatshot;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 2),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DUOLINGO-STYLE POWER-UP CARD
// ============================================================================

class DuoPowerUpCard extends StatefulWidget {
  final String id;
  final String name;
  final String description;
  final int price;
  final IconData icon;
  final int colorValue;
  final int quantity;
  final VoidCallback? onTap;

  const DuoPowerUpCard({
    super.key,
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    this.colorValue = 0xFFFF9600, // DuoColors.orange
    this.quantity = 0,
    this.onTap,
  });

  @override
  State<DuoPowerUpCard> createState() => _DuoPowerUpCardState();
}

class _DuoPowerUpCardState extends State<DuoPowerUpCard> {
  bool _isPressed = false;

  Color get _color => Color(widget.colorValue);

  Color get _darkerColor {
    final hsl = HSLColor.fromColor(_color);
    return hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(0, _isPressed ? 4 : 0, 0),
        child: Stack(
          children: [
            // Shadow
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: _darkerColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            // Main card
            Container(
              height: _isPressed ? 104 : 100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _color,
                    _darkerColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Price / Quantity
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const DuoCoinIcon(size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.price}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (widget.quantity > 0) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'x${widget.quantity}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PREDEFINED POWER-UPS
// ============================================================================

class DuoPowerUps {
  static const List<Map<String, dynamic>> all = [
    {
      'id': 'powerup_hint',
      'name': 'Dica Mágica',
      'description': 'Revela uma opção incorreta',
      'price': 50,
      'icon': Icons.lightbulb_rounded,
      'color': 0xFFFFD900,
    },
    {
      'id': 'powerup_time',
      'name': 'Tempo Extra',
      'description': '+15 segundos no cronômetro',
      'price': 75,
      'icon': Icons.timer_rounded,
      'color': 0xFF1CB0F6,
    },
    {
      'id': 'powerup_skip',
      'name': 'Pular Questão',
      'description': 'Pula sem perder pontos',
      'price': 100,
      'icon': Icons.skip_next_rounded,
      'color': 0xFFCE82FF,
    },
    {
      'id': 'powerup_double',
      'name': 'XP Dobrado',
      'description': '2x XP na próxima lição',
      'price': 150,
      'icon': Icons.auto_awesome_rounded,
      'color': 0xFF58CC02,
    },
    {
      'id': 'powerup_shield',
      'name': 'Escudo',
      'description': 'Protege de 1 erro',
      'price': 125,
      'icon': Icons.shield_rounded,
      'color': 0xFFFF4B4B,
    },
    {
      'id': 'powerup_freeze',
      'name': 'Congelar Streak',
      'description': 'Mantém streak por 1 dia',
      'price': 200,
      'icon': Icons.ac_unit_rounded,
      'color': 0xFF00BFFF,
    },
  ];
}

// ============================================================================
// DUOLINGO-STYLE THEME CARD
// ============================================================================

class DuoThemeCard extends StatefulWidget {
  final String id;
  final String name;
  final int price;
  final List<Color> colors;
  final bool isPurchased;
  final bool isSelected;
  final bool isPreview;
  final VoidCallback? onTap;
  final VoidCallback? onPreview;

  const DuoThemeCard({
    super.key,
    required this.id,
    required this.name,
    required this.price,
    required this.colors,
    this.isPurchased = false,
    this.isSelected = false,
    this.isPreview = false,
    this.onTap,
    this.onPreview,
  });

  @override
  State<DuoThemeCard> createState() => _DuoThemeCardState();
}

class _DuoThemeCardState extends State<DuoThemeCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(0, _isPressed ? 4 : 0, 0),
        child: Stack(
          children: [
            // Shadow
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: widget.colors.first.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            // Main card
            Container(
              height: _isPressed ? 144 : 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.colors,
                ),
                borderRadius: BorderRadius.circular(20),
                border: widget.isSelected
                    ? Border.all(color: DuoColors.green, width: 3)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Color preview circles
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: widget.colors
                        .take(3)
                        .map((c) => Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: c.withValues(alpha: 0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  // Name
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Price or status
                  if (widget.isPurchased)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: DuoColors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Adquirido',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (widget.price == 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white),
                      ),
                      child: const Text(
                        'GRÁTIS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const DuoCoinIcon(size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.price}',
                            style: const TextStyle(
                              color: DuoColors.yellow,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Selected checkmark
            if (widget.isSelected && !widget.isPreview)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: DuoColors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            // Preview badge
            if (widget.isPreview)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DuoColors.purple,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: DuoColors.purple.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'PREVIEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Preview button for unpurchased themes
            if (!widget.isPurchased && widget.price > 0 && widget.onPreview != null)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: widget.onPreview,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isPreview ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PREDEFINED THEMES - Each theme has light and dark variants
// ============================================================================

/// Theme brightness mode
enum ThemeBrightness { light, dark, system }

class DuoThemes {
  /// System default theme (adapts to light/dark mode)
  static const Map<String, dynamic> systemTheme = {
    'id': 'theme_system',
    'name': 'Padrão',
    'price': 0,
    'isSystem': true,
    'light': {
      'bgDark': 0xFFF5F5F5,
      'bgCard': 0xFFFFFFFF,
      'bgElevated': 0xFFE8E8E8,
      'accent': 0xFF58CC02,
      'textPrimary': 0xFF1A1A2E,
      'textSecondary': 0xFF6B7280,
      'iconColor': 0xFF1A1A2E,
    },
    'dark': {
      'bgDark': 0xFF131F24,
      'bgCard': 0xFF1A2B33,
      'bgElevated': 0xFF233640,
      'accent': 0xFF58CC02,
      'textPrimary': 0xFFFFFFFF,
      'textSecondary': 0xFF9CA3AF,
      'iconColor': 0xFFFFFFFF,
    },
  };

  /// Premium themes with light/dark variants
  static const List<Map<String, dynamic>> premiumThemes = [
    {
      'id': 'theme_ocean',
      'name': 'Oceano',
      'price': 100,
      'light': {
        'bgDark': 0xFFE6F4F9,
        'bgCard': 0xFFFFFFFF,
        'bgElevated': 0xFFD0ECFC,
        'accent': 0xFF0077B6,
        'textPrimary': 0xFF023E5C,
        'textSecondary': 0xFF4A7A94,
        'iconColor': 0xFF0077B6,
      },
      'dark': {
        'bgDark': 0xFF001D2E,
        'bgCard': 0xFF003049,
        'bgElevated': 0xFF004666,
        'accent': 0xFF00B4D8,
        'textPrimary': 0xFFFFFFFF,
        'textSecondary': 0xFF90E0EF,
        'iconColor': 0xFF00B4D8,
      },
    },
    {
      'id': 'theme_forest',
      'name': 'Floresta',
      'price': 100,
      'light': {
        'bgDark': 0xFFE8F5EF,
        'bgCard': 0xFFFFFFFF,
        'bgElevated': 0xFFD4EDDA,
        'accent': 0xFF2D6A4F,
        'textPrimary': 0xFF1B4332,
        'textSecondary': 0xFF4A7C59,
        'iconColor': 0xFF2D6A4F,
      },
      'dark': {
        'bgDark': 0xFF0D1F17,
        'bgCard': 0xFF1B4332,
        'bgElevated': 0xFF2D6A4F,
        'accent': 0xFF74C69D,
        'textPrimary': 0xFFFFFFFF,
        'textSecondary': 0xFFB7E4C7,
        'iconColor': 0xFF74C69D,
      },
    },
    {
      'id': 'theme_sunset',
      'name': 'Pôr do Sol',
      'price': 150,
      'light': {
        'bgDark': 0xFFFFF0E6,
        'bgCard': 0xFFFFFFFF,
        'bgElevated': 0xFFFFE0CC,
        'accent': 0xFFFF6B6B,
        'textPrimary': 0xFF8B2500,
        'textSecondary': 0xFFB35A3A,
        'iconColor': 0xFFFF6B6B,
      },
      'dark': {
        'bgDark': 0xFF2D1A1A,
        'bgCard': 0xFF4A2C2A,
        'bgElevated': 0xFF6B3A38,
        'accent': 0xFFFF6B6B,
        'textPrimary': 0xFFFFFFFF,
        'textSecondary': 0xFFFFB8A8,
        'iconColor': 0xFFFF6B6B,
      },
    },
    {
      'id': 'theme_galaxy',
      'name': 'Galáxia',
      'price': 200,
      'light': {
        'bgDark': 0xFFF0E6FF,
        'bgCard': 0xFFFFFFFF,
        'bgElevated': 0xFFE0CCFF,
        'accent': 0xFF6A00F4,
        'textPrimary': 0xFF2D0070,
        'textSecondary': 0xFF6B4D9E,
        'iconColor': 0xFF6A00F4,
      },
      'dark': {
        'bgDark': 0xFF0D0024,
        'bgCard': 0xFF1A0040,
        'bgElevated': 0xFF2D0070,
        'accent': 0xFFDB00B6,
        'textPrimary': 0xFFFFFFFF,
        'textSecondary': 0xFFE0A0FF,
        'iconColor': 0xFFDB00B6,
      },
    },
    {
      'id': 'theme_candy',
      'name': 'Doce',
      'price': 150,
      'light': {
        'bgDark': 0xFFFFF0F8,
        'bgCard': 0xFFFFFFFF,
        'bgElevated': 0xFFFFE0F0,
        'accent': 0xFFFF4EB8,
        'textPrimary': 0xFF8B0050,
        'textSecondary': 0xFFB35A8A,
        'iconColor': 0xFFFF4EB8,
      },
      'dark': {
        'bgDark': 0xFF2D0A20,
        'bgCard': 0xFF4A1535,
        'bgElevated': 0xFF6B2050,
        'accent': 0xFFFF86D0,
        'textPrimary': 0xFFFFFFFF,
        'textSecondary': 0xFFFFB8E0,
        'iconColor': 0xFFFF86D0,
      },
    },
    {
      'id': 'theme_fire',
      'name': 'Fogo',
      'price': 200,
      'light': {
        'bgDark': 0xFFFFF4E6,
        'bgCard': 0xFFFFFFFF,
        'bgElevated': 0xFFFFE6CC,
        'accent': 0xFFFF4500,
        'textPrimary': 0xFF8B2500,
        'textSecondary': 0xFFB35A3A,
        'iconColor': 0xFFFF4500,
      },
      'dark': {
        'bgDark': 0xFF1F0A00,
        'bgCard': 0xFF3D1500,
        'bgElevated': 0xFF5C2000,
        'accent': 0xFFFF6600,
        'textPrimary': 0xFFFFFFFF,
        'textSecondary': 0xFFFFD0A0,
        'iconColor': 0xFFFF6600,
      },
    },
    {
      'id': 'theme_aurora',
      'name': 'Aurora',
      'price': 250,
      'light': {
        'bgDark': 0xFFE6FFFC,
        'bgCard': 0xFFFFFFFF,
        'bgElevated': 0xFFCCFFF8,
        'accent': 0xFF00BBF9,
        'textPrimary': 0xFF004D66,
        'textSecondary': 0xFF4A8A99,
        'iconColor': 0xFF00BBF9,
      },
      'dark': {
        'bgDark': 0xFF001A1F,
        'bgCard': 0xFF003340,
        'bgElevated': 0xFF004D5C,
        'accent': 0xFF00F5D4,
        'textPrimary': 0xFFFFFFFF,
        'textSecondary': 0xFFA0FFF0,
        'iconColor': 0xFF00F5D4,
      },
    },
  ];

  /// Get all themes (system + premium)
  static List<Map<String, dynamic>> get all => [systemTheme, ...premiumThemes];

  /// Legacy getter for backwards compatibility (returns dark variants)
  static List<Map<String, dynamic>> get allLegacy {
    return all.map((theme) {
      final dark = theme['dark'] as Map<String, dynamic>;
      return {
        'id': theme['id'],
        'name': theme['name'],
        'price': theme['price'],
        'colors': [dark['bgDark'], dark['bgCard'], dark['bgElevated']],
      };
    }).toList();
  }
}

// ============================================================================
// DUOLINGO-STYLE STREAK ICON
// ============================================================================

class DuoStreakIcon extends StatelessWidget {
  final int streak;
  final double size;

  const DuoStreakIcon({
    super.key,
    required this.streak,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = streak > 0;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect for active streak
        if (isActive)
          Container(
            width: size * 1.2,
            height: size * 1.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: DuoColors.orange.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
        // Fire icon
        Icon(
          Icons.local_fire_department_rounded,
          color: isActive ? DuoColors.orange : DuoColors.gray,
          size: size,
        ),
        // Streak number
        Positioned(
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isActive ? DuoColors.orange : DuoColors.gray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$streak',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// DUOLINGO-STYLE XP ICON
// ============================================================================

class DuoXpIcon extends StatelessWidget {
  final int xp;
  final double size;

  const DuoXpIcon({
    super.key,
    required this.xp,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DuoColors.green.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DuoColors.green.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: DuoColors.green,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                'XP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$xp',
            style: const TextStyle(
              color: DuoColors.green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DUOLINGO-STYLE HEART ICON
// ============================================================================

class DuoHeartIcon extends StatelessWidget {
  final int hearts;
  final int maxHearts;
  final double size;

  const DuoHeartIcon({
    super.key,
    required this.hearts,
    this.maxHearts = 5,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DuoColors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DuoColors.red.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hearts > 0 ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: DuoColors.red,
            size: size,
          ),
          const SizedBox(width: 6),
          Text(
            '$hearts',
            style: const TextStyle(
              color: DuoColors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DUOLINGO-STYLE TAB BAR
// ============================================================================

class DuoTabBar extends StatelessWidget {
  final List<String> tabs;
  final List<IconData> icons;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const DuoTabBar({
    super.key,
    required this.tabs,
    required this.icons,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.duoTheme;
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? theme.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[index],
                      color: isSelected ? Colors.white : theme.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tabs[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : theme.textSecondary,
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ============================================================================
// DUOLINGO-STYLE PROGRESS BAR
// ============================================================================

class DuoProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color color;
  final double height;
  final bool showPercentage;

  const DuoProgressBar({
    super.key,
    required this.progress,
    this.color = DuoColors.green,
    this.height = 16,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.duoTheme;
    return Stack(
      children: [
        // Background
        Container(
          height: height,
          decoration: BoxDecoration(
            color: theme.bgCard,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
        // Progress
        FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(height / 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
        // Percentage text
        if (showPercentage)
          Positioned.fill(
            child: Center(
              child: Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: height * 0.6,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// DUOLINGO-STYLE BADGE
// ============================================================================

class DuoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isLocked;
  final double size;

  const DuoBadge({
    super.key,
    required this.icon,
    required this.label,
    this.color = DuoColors.yellow,
    this.isLocked = false,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            // Shadow
            Container(
              width: size,
              height: size,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: isLocked ? DuoColors.grayDark : color.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
            // Main badge
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: isLocked ? DuoColors.gray : color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
              child: Icon(
                isLocked ? Icons.lock_rounded : icon,
                color: Colors.white,
                size: size * 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isLocked ? DuoColors.gray : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ============================================================================
// GAMIFIED NAVIGATION BAR
// ============================================================================

class DuoNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const DuoNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.duoTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.bgCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Início',
              isSelected: selectedIndex == 0,
              color: DuoColors.blue,
              onTap: () => onDestinationSelected(0),
            ),
            _NavItem(
              icon: Icons.map_rounded,
              label: 'Mapa',
              isSelected: selectedIndex == 1,
              color: DuoColors.green,
              onTap: () => onDestinationSelected(1),
            ),
            _NavItem(
              icon: Icons.storefront_rounded,
              label: 'Loja',
              isSelected: selectedIndex == 2,
              color: DuoColors.orange,
              onTap: () => onDestinationSelected(2),
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'Perfil',
              isSelected: selectedIndex == 3,
              color: DuoColors.purple,
              onTap: () => onDestinationSelected(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.duoTheme;
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSelected ? 16 : 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? widget.color.withValues(alpha: 0.2) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.isSelected ? widget.color : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.isSelected ? Colors.white : theme.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isSelected ? widget.color : theme.textSecondary,
                  fontSize: 11,
                  fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// GAMIFIED PROFILE COMPONENTS
// ============================================================================

/// Gamified Avatar Display with emoji selection
class DuoProfileAvatar extends StatelessWidget {
  final String emoji;
  final int level;
  final String username;
  final int colorValue;
  final String rarity;
  final VoidCallback? onTap;

  const DuoProfileAvatar({
    super.key,
    required this.emoji,
    required this.level,
    required this.username,
    this.colorValue = 0xFF58CC02,
    this.rarity = 'common',
    this.onTap,
  });

  Color get _rarityGlow {
    switch (rarity) {
      case 'rare':
        return DuoColors.blue;
      case 'epic':
        return DuoColors.purple;
      case 'legendary':
        return DuoColors.yellow;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.duoTheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Avatar with level badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Glow effect for rare+ avatars
              if (rarity != 'common')
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _rarityGlow.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              // Main avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Color(colorValue).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: rarity != 'common' ? _rarityGlow : Color(colorValue),
                    width: 4,
                  ),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
              // Level badge
              Positioned(
                bottom: -5,
                right: -5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.accent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.bgDark, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: theme.accent.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    'Nv. $level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              // Edit icon
              if (onTap != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: DuoColors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.bgDark, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Username
          Text(
            username,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gamified Stat Card
class DuoStatCard extends StatelessWidget {
  final String title;
  final Map<String, String> stats;

  const DuoStatCard({
    super.key,
    required this.title,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.duoTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.bgCard.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...stats.entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  entry.value,
                  style: TextStyle(
                    color: theme.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

/// Gamified Quick Stat
class DuoQuickStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const DuoQuickStat({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.duoTheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Avatar Selection Dialog
class DuoAvatarSelectionDialog extends StatelessWidget {
  final String? currentAvatarId;
  final Set<String> purchasedAvatars;
  final ValueChanged<Map<String, dynamic>> onSelect;

  const DuoAvatarSelectionDialog({
    super.key,
    this.currentAvatarId,
    required this.purchasedAvatars,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.duoTheme;
    final availableAvatars = DuoAvatars.all.where((a) {
      final id = a['id'] as String;
      final price = a['price'] as int;
      return purchasedAvatars.contains(id) || price == 0;
    }).toList();

    return Dialog(
      backgroundColor: theme.bgDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Escolher Avatar',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: availableAvatars.length,
                itemBuilder: (context, index) {
                  final avatar = availableAvatars[index];
                  final id = avatar['id'] as String;
                  final isSelected = currentAvatarId == id;
                  return GestureDetector(
                    onTap: () {
                      onSelect(avatar);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? theme.accent : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            avatar['emoji'] as String,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            avatar['name'] as String,
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            DuoButton(
              text: 'Fechar',
              color: DuoColors.gray,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// HOME SCREEN COMPONENTS
// ============================================================================

/// Gamified User Header
class DuoUserHeader extends StatelessWidget {
  final String username;
  final String emoji;
  final int level;
  final int xp;
  final int xpToNext;
  final int coins;
  final VoidCallback? onCoinsTap;

  const DuoUserHeader({
    super.key,
    required this.username,
    required this.emoji,
    required this.level,
    required this.xp,
    required this.xpToNext,
    required this.coins,
    this.onCoinsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.duoTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.bgCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Mini avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: theme.accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: theme.accent, width: 2),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          // Name and level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                // XP Progress bar
                Row(
                  children: [
                    Text(
                      'Nv. $level',
                      style: TextStyle(
                        color: theme.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DuoProgressBar(
                        progress: xp / xpToNext,
                        color: theme.accent,
                        height: 8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$xp/$xpToNext',
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Coins
          GestureDetector(
            onTap: onCoinsTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: DuoColors.yellow.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DuoColors.yellow),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DuoCoinIcon(size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '$coins',
                    style: const TextStyle(
                      color: DuoColors.yellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gamified Daily Streak Card
class DuoDailyStreakCard extends StatelessWidget {
  final int streak;
  final bool isClaimed;
  final VoidCallback? onClaim;

  const DuoDailyStreakCard({
    super.key,
    required this.streak,
    required this.isClaimed,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DuoColors.orange,
            DuoColors.orange.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: DuoColors.orange.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Fire icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          // Streak info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak dias',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                Text(
                  'Sequência de estudos',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Claim button
          if (!isClaimed)
            DuoButton(
              text: 'Resgatar',
              color: Colors.white,
              textColor: DuoColors.orange,
              small: true,
              onPressed: onClaim,
            )
          else
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }
}

/// Journey Map Header
class DuoJourneyHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onFilterTap;

  const DuoJourneyHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.duoTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.map_rounded,
              color: theme.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onFilterTap != null)
            DuoIconButton(
              icon: Icons.filter_list_rounded,
              color: theme.bgCard,
              onPressed: onFilterTap,
            ),
        ],
      ),
    );
  }
}
