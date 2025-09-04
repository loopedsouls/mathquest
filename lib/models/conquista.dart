enum TipoConquista {
  moduloCompleto,     // Completar um módulo específico
  unidadeCompleta,    // Completar toda uma unidade temática
  nivelAlcancado,     // Alcançar um nível (Intermediário, Avançado, etc.)
  streakExercicios,   // Sequência de exercícios corretos
  pontuacaoTotal,     // Atingir total de pontos
  tempoRecord,        // Resolver exercício rapidamente
  perfeccionista,     // 100% de acerto em um módulo
  persistente,        // Completar exercícios vários dias seguidos
}

class Conquista {
  final String id;
  final String titulo;
  final String descricao;
  final String emoji;
  final TipoConquista tipo;
  final Map<String, dynamic> criterios;
  final int pontosBonus;
  final DateTime? dataConquista;
  final bool desbloqueada;

  Conquista({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.emoji,
    required this.tipo,
    required this.criterios,
    this.pontosBonus = 0,
    this.dataConquista,
    this.desbloqueada = false,
  });

  Conquista copyWith({
    DateTime? dataConquista,
    bool? desbloqueada,
  }) {
    return Conquista(
      id: id,
      titulo: titulo,
      descricao: descricao,
      emoji: emoji,
      tipo: tipo,
      criterios: criterios,
      pontosBonus: pontosBonus,
      dataConquista: dataConquista ?? this.dataConquista,
      desbloqueada: desbloqueada ?? this.desbloqueada,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'emoji': emoji,
      'tipo': tipo.index,
      'criterios': criterios,
      'pontosBonus': pontosBonus,
      'dataConquista': dataConquista?.toIso8601String(),
      'desbloqueada': desbloqueada,
    };
  }

  factory Conquista.fromJson(Map<String, dynamic> json) {
    return Conquista(
      id: json['id'],
      titulo: json['titulo'],
      descricao: json['descricao'],
      emoji: json['emoji'],
      tipo: TipoConquista.values[json['tipo']],
      criterios: Map<String, dynamic>.from(json['criterios']),
      pontosBonus: json['pontosBonus'] ?? 0,
      dataConquista: json['dataConquista'] != null 
          ? DateTime.parse(json['dataConquista']) 
          : null,
      desbloqueada: json['desbloqueada'] ?? false,
    );
  }
}

class ConquistasData {
  static final List<Conquista> _conquistasBase = [
    // Conquistas por módulo completo
    Conquista(
      id: 'primeiro_modulo',
      titulo: 'Primeiro Passo',
      descricao: 'Complete seu primeiro módulo',
      emoji: '🌱',
      tipo: TipoConquista.moduloCompleto,
      criterios: {'quantidade': 1},
      pontosBonus: 50,
    ),
    Conquista(
      id: 'dez_modulos',
      titulo: 'Dedicado',
      descricao: 'Complete 10 módulos',
      emoji: '📚',
      tipo: TipoConquista.moduloCompleto,
      criterios: {'quantidade': 10},
      pontosBonus: 200,
    ),
    Conquista(
      id: 'todos_modulos',
      titulo: 'Mestre BNCC',
      descricao: 'Complete todos os 20 módulos',
      emoji: '🏆',
      tipo: TipoConquista.moduloCompleto,
      criterios: {'quantidade': 20},
      pontosBonus: 1000,
    ),

    // Conquistas por unidade completa
    Conquista(
      id: 'numeros_completo',
      titulo: 'Mestre dos Números',
      descricao: 'Complete toda a unidade de Números',
      emoji: '🔢',
      tipo: TipoConquista.unidadeCompleta,
      criterios: {'unidade': 'Números'},
      pontosBonus: 300,
    ),
    Conquista(
      id: 'algebra_completo',
      titulo: 'Algebrista',
      descricao: 'Complete toda a unidade de Álgebra',
      emoji: '📐',
      tipo: TipoConquista.unidadeCompleta,
      criterios: {'unidade': 'Álgebra'},
      pontosBonus: 300,
    ),
    Conquista(
      id: 'geometria_completo',
      titulo: 'Geômetra',
      descricao: 'Complete toda a unidade de Geometria',
      emoji: '📏',
      tipo: TipoConquista.unidadeCompleta,
      criterios: {'unidade': 'Geometria'},
      pontosBonus: 300,
    ),
    Conquista(
      id: 'grandezas_completo',
      titulo: 'Medidor Expert',
      descricao: 'Complete toda a unidade de Grandezas e Medidas',
      emoji: '📊',
      tipo: TipoConquista.unidadeCompleta,
      criterios: {'unidade': 'Grandezas e Medidas'},
      pontosBonus: 300,
    ),
    Conquista(
      id: 'probabilidade_completo',
      titulo: 'Estatístico',
      descricao: 'Complete toda a unidade de Probabilidade e Estatística',
      emoji: '📈',
      tipo: TipoConquista.unidadeCompleta,
      criterios: {'unidade': 'Probabilidade e Estatística'},
      pontosBonus: 300,
    ),

    // Conquistas por nível
    Conquista(
      id: 'nivel_intermediario',
      titulo: 'Evoluindo',
      descricao: 'Alcance o nível Intermediário',
      emoji: '📖',
      tipo: TipoConquista.nivelAlcancado,
      criterios: {'nivel': 1}, // NivelUsuario.intermediario.index
      pontosBonus: 150,
    ),
    Conquista(
      id: 'nivel_avancado',
      titulo: 'Progredindo',
      descricao: 'Alcance o nível Avançado',
      emoji: '🎓',
      tipo: TipoConquista.nivelAlcancado,
      criterios: {'nivel': 2}, // NivelUsuario.avancado.index
      pontosBonus: 300,
    ),
    Conquista(
      id: 'nivel_especialista',
      titulo: 'Especialista BNCC',
      descricao: 'Alcance o nível Especialista',
      emoji: '👑',
      tipo: TipoConquista.nivelAlcancado,
      criterios: {'nivel': 3}, // NivelUsuario.especialista.index
      pontosBonus: 500,
    ),

    // Conquistas por streak
    Conquista(
      id: 'streak_5',
      titulo: 'Em Ritmo',
      descricao: 'Acerte 5 exercícios seguidos',
      emoji: '🔥',
      tipo: TipoConquista.streakExercicios,
      criterios: {'streak': 5},
      pontosBonus: 50,
    ),
    Conquista(
      id: 'streak_10',
      titulo: 'Imparável',
      descricao: 'Acerte 10 exercícios seguidos',
      emoji: '⚡',
      tipo: TipoConquista.streakExercicios,
      criterios: {'streak': 10},
      pontosBonus: 100,
    ),
    Conquista(
      id: 'streak_20',
      titulo: 'Fenômeno',
      descricao: 'Acerte 20 exercícios seguidos',
      emoji: '🌟',
      tipo: TipoConquista.streakExercicios,
      criterios: {'streak': 20},
      pontosBonus: 250,
    ),

    // Conquistas por pontuação
    Conquista(
      id: 'mil_pontos',
      titulo: 'Milionário',
      descricao: 'Acumule 1000 pontos totais',
      emoji: '💰',
      tipo: TipoConquista.pontuacaoTotal,
      criterios: {'pontos': 1000},
      pontosBonus: 100,
    ),
    Conquista(
      id: 'cinco_mil_pontos',
      titulo: 'Magnata',
      descricao: 'Acumule 5000 pontos totais',
      emoji: '💎',
      tipo: TipoConquista.pontuacaoTotal,
      criterios: {'pontos': 5000},
      pontosBonus: 500,
    ),

    // Conquistas especiais
    Conquista(
      id: 'velocista',
      titulo: 'Velocista',
      descricao: 'Resolva um exercício em menos de 10 segundos',
      emoji: '⚡',
      tipo: TipoConquista.tempoRecord,
      criterios: {'tempo_maximo': 10},
      pontosBonus: 75,
    ),
    Conquista(
      id: 'perfeccionista',
      titulo: 'Perfeccionista',
      descricao: 'Complete um módulo com 100% de acerto',
      emoji: '💯',
      tipo: TipoConquista.perfeccionista,
      criterios: {'taxa_acerto': 1.0},
      pontosBonus: 150,
    ),
  ];

  static List<Conquista> obterTodasConquistas() {
    return List.from(_conquistasBase);
  }

  static List<Conquista> obterConquistasPorTipo(TipoConquista tipo) {
    return _conquistasBase.where((c) => c.tipo == tipo).toList();
  }

  static Conquista? obterConquistaPorId(String id) {
    try {
      return _conquistasBase.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<Conquista> obterConquistasDesbloqueadas(List<String> idsDesbloqueadas) {
    return _conquistasBase
        .where((c) => idsDesbloqueadas.contains(c.id))
        .map((c) => c.copyWith(desbloqueada: true))
        .toList();
  }

  static List<Conquista> obterConquistasBloqueadas(List<String> idsDesbloqueadas) {
    return _conquistasBase
        .where((c) => !idsDesbloqueadas.contains(c.id))
        .toList();
  }
}
