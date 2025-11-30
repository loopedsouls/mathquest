import 'dart:async';
import 'package:flutter/material.dart';

/// Timer widget for gameplay
class TimerWidget extends StatefulWidget {
  final int duration;
  final VoidCallback onTimeUp;

  const TimerWidget({
    super.key,
    required this.duration,
    required this.onTimeUp,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  late int _secondsRemaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.duration;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        widget.onTimeUp();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color get _color {
    if (_secondsRemaining > widget.duration * 0.5) {
      return const Color(0xFF4CAF50);
    }
    if (_secondsRemaining > widget.duration * 0.25) {
      return const Color(0xFFFF9800);
    }
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: _color,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            '${_secondsRemaining}s',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
