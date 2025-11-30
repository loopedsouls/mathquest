import 'package:flutter/material.dart';

/// Answer option button for gameplay
class AnswerOption extends StatelessWidget {
  final String text;
  final int index;
  final bool isSelected;
  final bool? isCorrect;
  final bool showResult;
  final VoidCallback onTap;

  const AnswerOption({
    super.key,
    required this.text,
    required this.index,
    required this.isSelected,
    this.isCorrect,
    required this.showResult,
    required this.onTap,
  });

  Color get _backgroundColor {
    if (!showResult) {
      return isSelected ? const Color(0xFF6C63FF) : Colors.white;
    }
    if (isCorrect == true) {
      return const Color(0xFF4CAF50);
    }
    if (isSelected && isCorrect == false) {
      return const Color(0xFFF44336);
    }
    return Colors.white;
  }

  Color get _textColor {
    if (!showResult) {
      return isSelected ? Colors.white : Colors.black87;
    }
    if (isCorrect == true || (isSelected && isCorrect == false)) {
      return Colors.white;
    }
    return Colors.black87;
  }

  IconData? get _trailingIcon {
    if (!showResult) return null;
    if (isCorrect == true) return Icons.check_circle;
    if (isSelected && isCorrect == false) return Icons.cancel;
    return null;
  }

  String get _optionLetter {
    return String.fromCharCode(65 + index); // A, B, C, D
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Material(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        elevation: isSelected ? 4 : 2,
        child: InkWell(
          onTap: showResult ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                // Option letter
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected || showResult
                        ? Colors.white.withValues(alpha: 0.2)
                        : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _optionLetter,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Answer text
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _textColor,
                    ),
                  ),
                ),
                // Result icon
                if (_trailingIcon != null)
                  Icon(
                    _trailingIcon,
                    color: Colors.white,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
