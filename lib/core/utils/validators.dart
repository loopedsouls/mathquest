/// Validators for form fields and data
class Validators {
  Validators._();

  /// Validate email format
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Digite seu email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }
    return null;
  }

  /// Validate password strength
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Digite sua senha';
    }
    if (value.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres';
    }
    return null;
  }

  /// Validate password confirmation
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Confirme sua senha';
    }
    if (value != password) {
      return 'As senhas não coincidem';
    }
    return null;
  }

  /// Validate required field
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? 'Campo $fieldName é obrigatório' : 'Campo obrigatório';
    }
    return null;
  }

  /// Validate name (2-50 characters, letters only)
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Digite seu nome';
    }
    if (value.length < 2) {
      return 'Nome muito curto';
    }
    if (value.length > 50) {
      return 'Nome muito longo';
    }
    return null;
  }

  /// Validate API key format
  static String? apiKey(String? value, String provider) {
    if (value == null || value.isEmpty) {
      return 'Digite a chave da API';
    }
    switch (provider.toLowerCase()) {
      case 'openai':
        if (!value.startsWith('sk-')) {
          return 'Chave OpenAI deve começar com "sk-"';
        }
        break;
      case 'gemini':
        if (value.length < 20) {
          return 'Chave Gemini parece inválida';
        }
        break;
    }
    return null;
  }

  /// Validate numeric input
  static String? numeric(String? value, {int? min, int? max}) {
    if (value == null || value.isEmpty) {
      return 'Digite um número';
    }
    final number = int.tryParse(value);
    if (number == null) {
      return 'Valor deve ser numérico';
    }
    if (min != null && number < min) {
      return 'Valor mínimo: $min';
    }
    if (max != null && number > max) {
      return 'Valor máximo: $max';
    }
    return null;
  }

  /// Validate school year selection
  static String? schoolYear(String? value) {
    if (value == null || value.isEmpty) {
      return 'Selecione o ano escolar';
    }
    final validYears = ['6º ano', '7º ano', '8º ano', '9º ano'];
    if (!validYears.contains(value)) {
      return 'Ano escolar inválido';
    }
    return null;
  }

  /// Validate difficulty level
  static String? difficulty(String? value) {
    if (value == null || value.isEmpty) {
      return 'Selecione a dificuldade';
    }
    final validLevels = ['fácil', 'médio', 'difícil'];
    if (!validLevels.contains(value.toLowerCase())) {
      return 'Nível de dificuldade inválido';
    }
    return null;
  }

  /// Validate URL format
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL is optional
    }
    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );
    if (!urlRegex.hasMatch(value)) {
      return 'URL inválida';
    }
    return null;
  }
}
