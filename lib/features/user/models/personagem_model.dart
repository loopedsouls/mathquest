enum RaridadePersonagem {
  comum,     // Branco
  raro,      // Verde
  epico,     // Roxo
  lendario,  // Laranja
  mitico     // Vermelho
}

enum TipoPersonagem {
  guerreiro,    // Foco em força
  mago,         // Foco em inteligência
  ladino,       // Foco em velocidade
  clerigo,      // Foco em sorte/luck
  comerciante,  // Tema porcentagens
  agiota,       // Tema juros
}

class AtributosPersonagem {
  final int forca;       // Strength - aumenta pontos por resposta certa
  final int inteligencia; // Intelligence - aumenta chance de dicas
  final int velocidade;   // Speed - reduz tempo de resposta
  final int sorte;        // Luck - aumenta chance de itens raros

  const AtributosPersonagem({
    required this.forca,
    required this.inteligencia,
    required this.velocidade,
    required this.sorte,
  });

  int get total => forca + inteligencia + velocidade + sorte;

  AtributosPersonagem copyWith({
    int? forca,
    int? inteligencia,
    int? velocidade,
    int? sorte,
  }) {
    return AtributosPersonagem(
      forca: forca ?? this.forca,
      inteligencia: inteligencia ?? this.inteligencia,
      velocidade: velocidade ?? this.velocidade,
      sorte: sorte ?? this.sorte,
    );
  }

  Map<String, dynamic> toJson() => {
    'forca': forca,
    'inteligencia': inteligencia,
    'velocidade': velocidade,
    'sorte': sorte,
  };

  factory AtributosPersonagem.fromJson(Map<String, dynamic> json) {
    return AtributosPersonagem(
      forca: json['forca'] ?? 0,
      inteligencia: json['inteligencia'] ?? 0,
      velocidade: json['velocidade'] ?? 0,
      sorte: json['sorte'] ?? 0,
    );
  }
}

class HabilidadePersonagem {
  final String id;
  final String nome;
  final String descricao;
  final String icone;
  final Map<String, dynamic> efeito; // Ex: {'tipo': 'bonus_pontos', 'valor': 0.15}

  const HabilidadePersonagem({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.icone,
    required this.efeito,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'descricao': descricao,
    'icone': icone,
    'efeito': efeito,
  };

  factory HabilidadePersonagem.fromJson(Map<String, dynamic> json) {
    return HabilidadePersonagem(
      id: json['id'],
      nome: json['nome'],
      descricao: json['descricao'],
      icone: json['icone'],
      efeito: Map<String, dynamic>.from(json['efeito']),
    );
  }
}

class Personagem {
  final String id;
  final String nome;
  final String descricao;
  final String historia;
  final String imagem;
  final TipoPersonagem tipo;
  final RaridadePersonagem raridade;
  final AtributosPersonagem atributosBase;
  final List<HabilidadePersonagem> habilidades;
  final int nivel;
  final int experiencia;
  final bool evoluido;

  const Personagem({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.historia,
    required this.imagem,
    required this.tipo,
    required this.raridade,
    required this.atributosBase,
    required this.habilidades,
    this.nivel = 1,
    this.experiencia = 0,
    this.evoluido = false,
  });

  // Atributos atuais (considerando nível)
  AtributosPersonagem get atributosAtuais {
    double multiplicador = 1.0 + (nivel - 1) * 0.1; // +10% por nível
    if (evoluido) multiplicador *= 1.5; // +50% se evoluído

    return AtributosPersonagem(
      forca: (atributosBase.forca * multiplicador).round(),
      inteligencia: (atributosBase.inteligencia * multiplicador).round(),
      velocidade: (atributosBase.velocidade * multiplicador).round(),
      sorte: (atributosBase.sorte * multiplicador).round(),
    );
  }

  // Experiência necessária para próximo nível
  int get experienciaParaProximoNivel => nivel * 100;

  // Pode evoluir (nível máximo)
  bool get podeEvoluir => nivel >= 10 && !evoluido;

  Personagem copyWith({
    int? nivel,
    int? experiencia,
    bool? evoluido,
  }) {
    return Personagem(
      id: id,
      nome: nome,
      descricao: descricao,
      historia: historia,
      imagem: imagem,
      tipo: tipo,
      raridade: raridade,
      atributosBase: atributosBase,
      habilidades: habilidades,
      nivel: nivel ?? this.nivel,
      experiencia: experiencia ?? this.experiencia,
      evoluido: evoluido ?? this.evoluido,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'descricao': descricao,
    'historia': historia,
    'imagem': imagem,
    'tipo': tipo.index,
    'raridade': raridade.index,
    'atributosBase': atributosBase.toJson(),
    'habilidades': habilidades.map((h) => h.toJson()).toList(),
    'nivel': nivel,
    'experiencia': experiencia,
    'evoluido': evoluido,
  };

  factory Personagem.fromJson(Map<String, dynamic> json) {
    return Personagem(
      id: json['id'],
      nome: json['nome'],
      descricao: json['descricao'],
      historia: json['historia'],
      imagem: json['imagem'],
      tipo: TipoPersonagem.values[json['tipo'] ?? 0],
      raridade: RaridadePersonagem.values[json['raridade'] ?? 0],
      atributosBase: AtributosPersonagem.fromJson(json['atributosBase']),
      habilidades: (json['habilidades'] as List<dynamic>?)
          ?.map((h) => HabilidadePersonagem.fromJson(h))
          .toList() ?? [],
      nivel: json['nivel'] ?? 1,
      experiencia: json['experiencia'] ?? 0,
      evoluido: json['evoluido'] ?? false,
    );
  }
}

// Extensões para facilitar uso
extension RaridadePersonagemExtension on RaridadePersonagem {
  String get nome {
    switch (this) {
      case RaridadePersonagem.comum: return 'Comum';
      case RaridadePersonagem.raro: return 'Raro';
      case RaridadePersonagem.epico: return 'Épico';
      case RaridadePersonagem.lendario: return 'Lendário';
      case RaridadePersonagem.mitico: return 'Mítico';
    }
  }

  String get cor {
    switch (this) {
      case RaridadePersonagem.comum: return '#FFFFFF';
      case RaridadePersonagem.raro: return '#00FF00';
      case RaridadePersonagem.epico: return '#800080';
      case RaridadePersonagem.lendario: return '#FFA500';
      case RaridadePersonagem.mitico: return '#FF0000';
    }
  }

  double get chanceGacha {
    switch (this) {
      case RaridadePersonagem.comum: return 0.60; // 60%
      case RaridadePersonagem.raro: return 0.25;   // 25%
      case RaridadePersonagem.epico: return 0.10;   // 10%
      case RaridadePersonagem.lendario: return 0.04; // 4%
      case RaridadePersonagem.mitico: return 0.01;   // 1%
    }
  }
}

extension TipoPersonagemExtension on TipoPersonagem {
  String get nome {
    switch (this) {
      case TipoPersonagem.guerreiro: return 'Guerreiro';
      case TipoPersonagem.mago: return 'Mago';
      case TipoPersonagem.ladino: return 'Ladino';
      case TipoPersonagem.clerigo: return 'Clérigo';
      case TipoPersonagem.comerciante: return 'Comerciante';
      case TipoPersonagem.agiota: return 'Agiota';
    }
  }

  String get emoji {
    switch (this) {
      case TipoPersonagem.guerreiro: return '⚔️';
      case TipoPersonagem.mago: return '🧙';
      case TipoPersonagem.ladino: return '🗡️';
      case TipoPersonagem.clerigo: return '✨';
      case TipoPersonagem.comerciante: return '💰';
      case TipoPersonagem.agiota: return '🏦';
    }
  }

  String get descricao {
    switch (this) {
      case TipoPersonagem.guerreiro:
        return 'Focado em força bruta e resistência';
      case TipoPersonagem.mago:
        return 'Especialista em magia e conhecimento';
      case TipoPersonagem.ladino:
        return 'Ágil e preciso, mestre das sombras';
      case TipoPersonagem.clerigo:
        return 'Bençoeiro com sorte divina';
      case TipoPersonagem.comerciante:
        return 'Negociante astuto com olho para porcentagens';
      case TipoPersonagem.agiota:
        return 'Financista implacável especialista em juros';
    }
  }
}

class ItemPersonalizacao {
  final String id;
  final String nome;
  final String descricao;
  final String categoria; // 'cabeca', 'corpo', 'pernas', 'acessorio'
  final String imagemPath;
  final int preco; // em moedas do jogo
  final String raridade; // 'comum', 'raro', 'epico', 'lendario'
  final List<String> tagsEstilo; // ['casual', 'formal', 'esportivo']
  final bool desbloqueado;
  final DateTime? dataDesbloqueio;
  final String? condicaoDesbloqueio; // descrição de como desbloquear

  ItemPersonalizacao({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.categoria,
    required this.imagemPath,
    required this.preco,
    required this.raridade,
    this.tagsEstilo = const [],
    this.desbloqueado = false,
    this.dataDesbloqueio,
    this.condicaoDesbloqueio,
  });

  ItemPersonalizacao copyWith({
    String? id,
    String? nome,
    String? descricao,
    String? categoria,
    String? imagemPath,
    int? preco,
    String? raridade,
    List<String>? tagsEstilo,
    bool? desbloqueado,
    DateTime? dataDesbloqueio,
    String? condicaoDesbloqueio,
  }) {
    return ItemPersonalizacao(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      categoria: categoria ?? this.categoria,
      imagemPath: imagemPath ?? this.imagemPath,
      preco: preco ?? this.preco,
      raridade: raridade ?? this.raridade,
      tagsEstilo: tagsEstilo ?? this.tagsEstilo,
      desbloqueado: desbloqueado ?? this.desbloqueado,
      dataDesbloqueio: dataDesbloqueio ?? this.dataDesbloqueio,
      condicaoDesbloqueio: condicaoDesbloqueio ?? this.condicaoDesbloqueio,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'categoria': categoria,
      'imagemPath': imagemPath,
      'preco': preco,
      'raridade': raridade,
      'tagsEstilo': tagsEstilo,
      'desbloqueado': desbloqueado,
      'dataDesbloqueio': dataDesbloqueio?.toIso8601String(),
      'condicaoDesbloqueio': condicaoDesbloqueio,
    };
  }

  factory ItemPersonalizacao.fromJson(Map<String, dynamic> json) {
    return ItemPersonalizacao(
      id: json['id'],
      nome: json['nome'],
      descricao: json['descricao'],
      categoria: json['categoria'],
      imagemPath: json['imagemPath'],
      preco: json['preco'],
      raridade: json['raridade'],
      tagsEstilo: List<String>.from(json['tagsEstilo'] ?? []),
      desbloqueado: json['desbloqueado'] ?? false,
      dataDesbloqueio: json['dataDesbloqueio'] != null
          ? DateTime.parse(json['dataDesbloqueio'])
          : null,
      condicaoDesbloqueio: json['condicaoDesbloqueio'],
    );
  }
}

class PerfilPersonagem {
  final String userId;
  final String nome;
  final int nivel;
  final int experiencia;
  final int moedas;
  final Map<String, String> itensEquipados; // categoria -> itemId
  final List<String> itensInventario; // ids dos itens possuídos
  final Map<String, dynamic> estatisticas;
  final DateTime ultimaAtualizacao;

  PerfilPersonagem({
    required this.userId,
    required this.nome,
    this.nivel = 1,
    this.experiencia = 0,
    this.moedas = 100,
    this.itensEquipados = const {},
    this.itensInventario = const [],
    this.estatisticas = const {},
    DateTime? ultimaAtualizacao,
  }) : ultimaAtualizacao = ultimaAtualizacao ?? DateTime.now();

  PerfilPersonagem copyWith({
    String? userId,
    String? nome,
    int? nivel,
    int? experiencia,
    int? moedas,
    Map<String, String>? itensEquipados,
    List<String>? itensInventario,
    Map<String, dynamic>? estatisticas,
    DateTime? ultimaAtualizacao,
  }) {
    return PerfilPersonagem(
      userId: userId ?? this.userId,
      nome: nome ?? this.nome,
      nivel: nivel ?? this.nivel,
      experiencia: experiencia ?? this.experiencia,
      moedas: moedas ?? this.moedas,
      itensEquipados: itensEquipados ?? Map.from(this.itensEquipados),
      itensInventario: itensInventario ?? List.from(this.itensInventario),
      estatisticas: estatisticas ?? Map.from(this.estatisticas),
      ultimaAtualizacao: ultimaAtualizacao ?? this.ultimaAtualizacao,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nome': nome,
      'nivel': nivel,
      'experiencia': experiencia,
      'moedas': moedas,
      'itensEquipados': itensEquipados,
      'itensInventario': itensInventario,
      'estatisticas': estatisticas,
      'ultimaAtualizacao': ultimaAtualizacao.toIso8601String(),
    };
  }

  factory PerfilPersonagem.fromJson(Map<String, dynamic> json) {
    return PerfilPersonagem(
      userId: json['userId'],
      nome: json['nome'],
      nivel: json['nivel'] ?? 1,
      experiencia: json['experiencia'] ?? 0,
      moedas: json['moedas'] ?? 100,
      itensEquipados: Map<String, String>.from(json['itensEquipados'] ?? {}),
      itensInventario: List<String>.from(json['itensInventario'] ?? []),
      estatisticas: Map<String, dynamic>.from(json['estatisticas'] ?? {}),
      ultimaAtualizacao: DateTime.parse(json['ultimaAtualizacao']),
    );
  }

  // Métodos utilitários
  int get experienciaParaProximoNivel => nivel * 1000;
  double get progressoNivel => experiencia / experienciaParaProximoNivel;

  bool possuiItem(String itemId) => itensInventario.contains(itemId);

  String? getItemEquipado(String categoria) => itensEquipados[categoria];

  bool podeComprarItem(int preco) => moedas >= preco;
}
