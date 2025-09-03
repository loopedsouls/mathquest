import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Botão moderno e responsivo
class ModernButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;
  final bool isFullWidth;
  final double? width;
  final double? height;

  const ModernButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.isFullWidth = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isFullWidth ? double.infinity : (width ?? (isTablet ? 280 : 250)),
      height: height ?? (isTablet ? 56 : 48),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isPrimary ? AppTheme.primaryColor : AppTheme.secondaryColor,
          foregroundColor: Colors.white,
          elevation: isPrimary ? 8 : 4,
          shadowColor: isPrimary
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 32 : 24,
            vertical: isTablet ? 16 : 12,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: isTablet ? 24 : 20),
                    SizedBox(width: isTablet ? 12 : 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Card moderno com glassmorphism
class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final bool hasGlow;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.hasGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
        color: AppTheme.darkCardColor,
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                ...AppTheme.mediumShadow,
              ]
            : AppTheme.softShadow,
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(isTablet ? 24 : 20),
        child: child,
      ),
    );
  }
}

/// Header responsivo
class ResponsiveHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showBackButton;

  const ResponsiveHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : (isTablet ? 24 : 16),
        vertical: isTablet ? 24 : 16,
      ),
      child: Row(
        children: [
          if (showBackButton) ...[
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: AppTheme.primaryColor,
                size: isTablet ? 28 : 24,
              ),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isDesktop ? 32 : (isTablet ? 28 : 24),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkTextPrimaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: isTablet ? 8 : 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : (isTablet ? 16 : 14),
                      color: AppTheme.darkTextSecondaryColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Status indicator moderno
class StatusIndicator extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final bool isActive;

  const StatusIndicator({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isActive ? 0.15 : 0.05),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        border: Border.all(
          color: color.withValues(alpha: isActive ? 0.3 : 0.1),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isTablet ? 12 : 10,
            height: isTablet ? 12 : 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
          SizedBox(width: isTablet ? 12 : 8),
          Icon(
            icon,
            color: color,
            size: isTablet ? 20 : 18,
          ),
          SizedBox(width: isTablet ? 8 : 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress indicator moderno
class ModernProgressIndicator extends StatelessWidget {
  final double value;
  final String label;
  final Color? color;

  const ModernProgressIndicator({
    super.key,
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final progressColor = color ?? AppTheme.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkTextPrimaryColor,
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.bold,
                color: progressColor,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Container(
          height: isTablet ? 8 : 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isTablet ? 4 : 3),
            color: AppTheme.darkBorderColor,
          ),
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isTablet ? 4 : 3),
                gradient: LinearGradient(
                  colors: [
                    progressColor,
                    progressColor.withValues(alpha: 0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: progressColor.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Input field moderno
class ModernTextField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixPressed;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;

  const ModernTextField({
    super.key,
    required this.hint,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixPressed,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        color: AppTheme.darkSurfaceColor,
        border: Border.all(
          color: AppTheme.darkBorderColor,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(
          fontSize: isTablet ? 18 : 16,
          color: AppTheme.darkTextPrimaryColor,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppTheme.darkTextHintColor,
            fontSize: isTablet ? 18 : 16,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  color: AppTheme.primaryColor,
                  size: isTablet ? 24 : 20,
                )
              : null,
          suffixIcon: suffixIcon != null
              ? IconButton(
                  onPressed: onSuffixPressed,
                  icon: Icon(
                    suffixIcon,
                    color: AppTheme.primaryColor,
                    size: isTablet ? 24 : 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: isTablet ? 20 : 16,
          ),
        ),
      ),
    );
  }
}
