// MainMenu stub
import 'package:flutter/material.dart';

class MainMenu extends StatelessWidget {
  final VoidCallback? onNewGame;
  final VoidCallback? onContinue;
  final VoidCallback? onSettings;

  const MainMenu({this.onNewGame, this.onContinue, this.onSettings, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF22223B),
        ),
        child: Row(
          children: [
            // Menu à esquerda
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _RenpyButton(
                    text: 'New Game',
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/game');
                    },
                  ),
                  const SizedBox(height: 24),
                  _RenpyButton(
                    text: 'Continue',
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/continue');
                    },
                  ),
                  const SizedBox(height: 24),
                  _RenpyButton(
                    text: 'Settings',
                    onPressed: () {
                      Navigator.of(context).pushNamed('/settings');
                    },
                  ),
                ],
              ),
            ),
            // Título à direita
            Expanded(
              flex: 3,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Adaptive Check',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 54,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black87,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: 320,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.white24,
                            Colors.white54,
                            Colors.white24,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Narrativa interativa adaptativa para todos os públicos.',
                      style: TextStyle(
                        fontFamily: 'Segoe UI',
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '© 2025 Adaptive Check Studio • Versão 1.0',
                      style: TextStyle(
                        fontFamily: 'Segoe UI',
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.65),
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RenpyButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  const _RenpyButton({required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 56,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFF4A4E69),
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 24,
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: Colors.black,
          elevation: 4,
        ),
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}
