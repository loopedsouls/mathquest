import 'package:flutter/material.dart';
import 'dart:async';

/// Widget que exibe texto com animação typewriter.
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration speed;
  final VoidCallback? onFinished;

  const TypewriterText({
    required this.text,
    this.style,
    this.speed = const Duration(milliseconds: 40),
    this.onFinished,
    super.key,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayed = '';
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _resetTyping();
    }
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.speed, (timer) {
      if (_index < widget.text.length) {
        setState(() {
          _displayed += widget.text[_index];
          _index++;
        });
      } else {
        _timer?.cancel();
        widget.onFinished?.call();
      }
    });
  }

  void _resetTyping() {
    _timer?.cancel();
    setState(() {
      _displayed = '';
      _index = 0;
    });
    _startTyping();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayed, style: widget.style);
  }
}
