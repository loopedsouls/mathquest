import 'package:flutter/material.dart';

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
        height: widget.height,
        transform: Matrix4.translationValues(0, _isPressed ? 4 : 0, 0),
        child: Stack(
          children: [
            // Shadow/3D effect
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: widget.height - 4,
                decoration: BoxDecoration(
                  color: isDisabled ? DuoColors.grayDark : _darkerColor,
                  borderRadius: BorderRadius.circular(16),
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
                height: widget.height - (_isPressed ? 0 : 4),
                decoration: BoxDecoration(
                  color: isDisabled ? DuoColors.gray : widget.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
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
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              widget.text,
                              style: TextStyle(
                                color: widget.textColor ?? Colors.white,
                                fontSize: 18,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DuoColors.bgCard,
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
                color: DuoColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isSelected ? DuoColors.green : _rarityBorderColor,
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
                    style: const TextStyle(
                      color: Colors.white,
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
                        color: DuoColors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DuoColors.green),
                      ),
                      child: const Text(
                        'GRÁTIS',
                        style: TextStyle(
                          color: DuoColors.green,
                          fontSize: 11,
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
// PREDEFINED THEMES
// ============================================================================

class DuoThemes {
  static const List<Map<String, dynamic>> all = [
    {
      'id': 'theme_dark',
      'name': 'Escuro',
      'price': 0,
      'colors': [0xFF131F24, 0xFF1A2B33, 0xFF233640],
    },
    {
      'id': 'theme_ocean',
      'name': 'Oceano',
      'price': 100,
      'colors': [0xFF0077B6, 0xFF00B4D8, 0xFF90E0EF],
    },
    {
      'id': 'theme_forest',
      'name': 'Floresta',
      'price': 100,
      'colors': [0xFF2D6A4F, 0xFF40916C, 0xFF74C69D],
    },
    {
      'id': 'theme_sunset',
      'name': 'Pôr do Sol',
      'price': 150,
      'colors': [0xFFFF6B6B, 0xFFFFE66D, 0xFF4ECDC4],
    },
    {
      'id': 'theme_galaxy',
      'name': 'Galáxia',
      'price': 200,
      'colors': [0xFF2D00F7, 0xFF6A00F4, 0xFFDB00B6],
    },
    {
      'id': 'theme_candy',
      'name': 'Doce',
      'price': 150,
      'colors': [0xFFFF86D0, 0xFFFF4EB8, 0xFFCE82FF],
    },
    {
      'id': 'theme_fire',
      'name': 'Fogo',
      'price': 200,
      'colors': [0xFFFF4500, 0xFFFF6600, 0xFFFFD700],
    },
    {
      'id': 'theme_aurora',
      'name': 'Aurora',
      'price': 250,
      'colors': [0xFF00F5D4, 0xFF00BBF9, 0xFF9B5DE5],
    },
  ];
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
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: DuoColors.bgCard,
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
                  color: isSelected ? DuoColors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[index],
                      color: isSelected ? Colors.white : DuoColors.grayLight,
                      size: 22,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tabs[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : DuoColors.grayLight,
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
    return Stack(
      children: [
        // Background
        Container(
          height: height,
          decoration: BoxDecoration(
            color: DuoColors.bgCard,
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
                  color: Colors.white,
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
