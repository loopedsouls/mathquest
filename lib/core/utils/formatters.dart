import 'package:intl/intl.dart';

/// Formatters for displaying data
class Formatters {
  Formatters._();

  /// Format date to Brazilian format (dd/MM/yyyy)
  static String date(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format date and time to Brazilian format (dd/MM/yyyy HH:mm)
  static String dateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  /// Format time only (HH:mm)
  static String time(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Format relative time (e.g., "2 horas atrás")
  static String relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Agora mesmo';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minuto' : 'minutos'} atrás';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hora' : 'horas'} atrás';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'dia' : 'dias'} atrás';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'semana' : 'semanas'} atrás';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'mês' : 'meses'} atrás';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'ano' : 'anos'} atrás';
    }
  }

  /// Format number with thousand separators
  static String number(num value) {
    return NumberFormat('#,###', 'pt_BR').format(value);
  }

  /// Format percentage
  static String percentage(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Format currency (BRL)
  static String currency(double value) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
  }

  /// Format XP value
  static String xp(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M XP';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K XP';
    }
    return '$value XP';
  }

  /// Format streak days
  static String streak(int days) {
    if (days == 0) {
      return 'Sem sequência';
    } else if (days == 1) {
      return '1 dia';
    } else {
      return '$days dias';
    }
  }

  /// Format level
  static String level(int level) {
    return 'Nível $level';
  }

  /// Format duration (seconds to mm:ss or HH:mm:ss)
  static String duration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Format file size (bytes to human-readable)
  static String fileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Format school year
  static String schoolYear(String year) {
    // Ensure consistent format
    if (year.contains('ano')) return year;
    return '$yearº ano';
  }

  /// Format quiz score
  static String quizScore(int correct, int total) {
    final percentage = total > 0 ? (correct / total * 100).toStringAsFixed(0) : '0';
    return '$correct/$total ($percentage%)';
  }

  /// Format BNCC code
  static String bnccCode(String code) {
    // Format like EF06MA01 to EF06-MA-01
    if (code.length >= 6) {
      final prefix = code.substring(0, 4);
      final subject = code.substring(4, 6);
      final number = code.length > 6 ? code.substring(6) : '';
      return '$prefix-$subject${number.isNotEmpty ? '-$number' : ''}';
    }
    return code;
  }
}
