class Conversa {
  final String id;
  final String titulo;
  final DateTime dataCreacao;
  final DateTime ultimaAtualizacao;
  final List<ChatMessage> mensagens;
  final String contexto; // 'geral' ou ID do módulo

  Conversa({
    required this.id,
    required this.titulo,
    required this.dataCreacao,
    required this.ultimaAtualizacao,
    required this.mensagens,
    required this.contexto,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'dataCreacao': dataCreacao.toIso8601String(),
      'ultimaAtualizacao': ultimaAtualizacao.toIso8601String(),
      'mensagens': mensagens.map((m) => m.toJson()).toList(),
      'contexto': contexto,
    };
  }

  factory Conversa.fromJson(Map<String, dynamic> json) {
    return Conversa(
      id: json['id'],
      titulo: json['titulo'],
      dataCreacao: DateTime.parse(json['dataCreacao']),
      ultimaAtualizacao: DateTime.parse(json['ultimaAtualizacao']),
      mensagens: (json['mensagens'] as List)
          .map((m) => ChatMessage.fromJson(m))
          .toList(),
      contexto: json['contexto'],
    );
  }

  Conversa copyWith({
    String? titulo,
    DateTime? ultimaAtualizacao,
    List<ChatMessage>? mensagens,
  }) {
    return Conversa(
      id: id,
      titulo: titulo ?? this.titulo,
      dataCreacao: dataCreacao,
      ultimaAtualizacao: ultimaAtualizacao ?? this.ultimaAtualizacao,
      mensagens: mensagens ?? this.mensagens,
      contexto: contexto,
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String?
      aiProvider; // 'gemini', 'ollama', ou null para mensagens do usuário
  final List<ChatButton>? buttons; // Botões opcionais para interação

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.aiProvider,
    this.buttons,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'aiProvider': aiProvider,
      'buttons': buttons?.map((b) => b.toJson()).toList(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      aiProvider: json['aiProvider'],
      buttons: json['buttons'] != null
          ? (json['buttons'] as List)
              .map((b) => ChatButton.fromJson(b))
              .toList()
          : null,
    );
  }
}

class ChatButton {
  final String text;
  final String action;
  final String icon;
  final String? description;

  ChatButton({
    required this.text,
    required this.action,
    required this.icon,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'action': action,
      'icon': icon,
      'description': description,
    };
  }

  factory ChatButton.fromJson(Map<String, dynamic> json) {
    return ChatButton(
      text: json['text'],
      action: json['action'],
      icon: json['icon'],
      description: json['description'],
    );
  }
}
