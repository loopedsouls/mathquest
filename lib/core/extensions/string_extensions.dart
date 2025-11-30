/// Extension methods for String
extension StringExtensions on String {
  /// Check if string is a valid email
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Check if string is a valid URL
  bool get isValidUrl {
    return RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    ).hasMatch(this);
  }

  /// Check if string is numeric
  bool get isNumeric {
    return double.tryParse(this) != null;
  }

  /// Check if string is integer
  bool get isInteger {
    return int.tryParse(this) != null;
  }

  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize each word
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Remove extra whitespace
  String get removeExtraWhitespace {
    return replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Truncate with ellipsis
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Convert to slug
  String get toSlug {
    return toLowerCase()
        .replaceAll(RegExp(r'[áàãâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòõôö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
  }

  /// Convert to camelCase
  String get toCamelCase {
    if (isEmpty) return this;
    final words = split(RegExp(r'[\s_-]+'));
    final first = words.first.toLowerCase();
    final rest = words.skip(1).map((w) => w.capitalize);
    return first + rest.join();
  }

  /// Convert to snake_case
  String get toSnakeCase {
    return replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceAll(RegExp(r'^_'), '');
  }

  /// Get initials (up to 2 characters)
  String get initials {
    if (isEmpty) return '';
    final words = trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';
    if (words.length == 1) {
      return words[0].substring(0, words[0].length.clamp(0, 2)).toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  /// Check if contains only letters
  bool get isAlphabetic {
    return RegExp(r'^[a-zA-ZáàãâäéèêëíìîïóòõôöúùûüçÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇ]+$').hasMatch(this);
  }

  /// Check if contains only alphanumeric
  bool get isAlphanumeric {
    return RegExp(r'^[a-zA-Z0-9áàãâäéèêëíìîïóòõôöúùûüçÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇ]+$').hasMatch(this);
  }

  /// Remove HTML tags
  String get stripHtml {
    return replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// Parse to nullable int
  int? get toIntOrNull => int.tryParse(this);

  /// Parse to nullable double
  double? get toDoubleOrNull => double.tryParse(this);

  /// Reverse string
  String get reversed => split('').reversed.join();

  /// Check if is blank (empty or only whitespace)
  bool get isBlank => trim().isEmpty;

  /// Check if is not blank
  bool get isNotBlank => !isBlank;

  /// Extract numbers only
  String get numbersOnly => replaceAll(RegExp(r'[^0-9]'), '');

  /// Extract letters only
  String get lettersOnly => replaceAll(RegExp(r'[^a-zA-ZáàãâäéèêëíìîïóòõôöúùûüçÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇ]'), '');
}

/// Extension for nullable strings
extension NullableStringExtensions on String? {
  /// Check if string is null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Check if string is not null and not empty
  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;

  /// Return string or default value
  String orDefault([String defaultValue = '']) => this ?? defaultValue;
}
