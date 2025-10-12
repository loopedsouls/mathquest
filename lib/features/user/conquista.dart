enum TipoConquista {
  moduloCompleto, // Completar um módulo específico
  unidadeCompleta, // Completar toda uma unidade temática
  nivelAlcancado, // Alcançar um nível (Intermediário, Avançado, etc.)
  streakExercicios, // Sequência de exercícios corretos
  pontuacaoTotal, // Atingir total de pontos
  tempoRecord, // Resolver exercício rapidamente
  perfeccionista, // 100% de acerto em um módulo
  persistente, // Completar exercícios vários dias seguidos
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
      emoji: 'assets/models/Primeiro-Passo.svg',
      tipo: TipoConquista.moduloCompleto,
      criterios: {'quantidade': 1},
      pontosBonus: 50,
    ),
    Conquista(
      id: 'dez_modulos',
      titulo: 'Dedicado',
      descricao: 'Complete 10 módulos',
      emoji: 'assets/models/Dedicado.svg',
      tipo: TipoConquista.moduloCompleto,
      criterios: {'quantidade': 10},
      pontosBonus: 200,
    ),

    // Conquistas por unidade completa
    Conquista(
      id: 'numeros_completo',
      titulo: 'Mestre dos Números',
      descricao: 'Complete toda a unidade de Números',
      emoji: 'assets/models/Mestre-dos-números.svg',
      tipo: TipoConquista.unidadeCompleta,
      criterios: {'unidade': 'Números'},
      pontosBonus: 300,
    ),
    Conquista(
      id: 'algebra_completo',
      titulo: 'Algebrista',
      descricao: 'Complete toda a unidade de Álgebra',
      emoji: 'assets/models/Algebrista.svg',
      tipo: TipoConquista.unidadeCompleta,
      criterios: {'unidade': 'Álgebra'},
      pontosBonus: 300,
    ),
    Conquista(
      id: 'geometria_completo',
      titulo: 'Geômetra',
      descricao: 'Complete toda a unidade de Geometria',
      emoji: 'assets/models/Geômetra.svg',
      tipo: TipoConquista.unidadeCompleta,
      criterios: {'unidade': 'Geometria'},
      pontosBonus: 300,
    ),
    Conquista(
      id: 'grandezas_completo',
      titulo: 'Medidor Expert',
      descricao: 'Complete toda a unidade de Grandezas e Medidas',
      emoji: 'assets/models/MEdidor-Expert.svg',
      tipo: TipoConquista.unidadeCompleta,
      criterios: {'unidade': 'Grandezas e Medidas'},
      pontosBonus: 300,
    ),
    Conquista(
      id: 'probabilidade_completo',
      titulo: 'Estatístico',
      descricao: 'Complete toda a unidade de Probabilidade e Estatística',
      emoji: 'assets/models/Estatistico.svg',
      tipo: TipoConquista.unidadeCompleta,
      criterios: {'unidade': 'Probabilidade e Estatística'},
      pontosBonus: 300,
    ),

    // Conquistas por nível
    Conquista(
      id: 'nivel_intermediario',
      titulo: 'Evoluindo',
      descricao: 'Alcance o nível Intermediário',
      emoji: 'assets/models/Evoluindo.svg',
      tipo: TipoConquista.nivelAlcancado,
      criterios: {'nivel': 1}, // NivelUsuario.intermediario.index
      pontosBonus: 150,
    ),
    Conquista(
      id: 'nivel_avancado',
      titulo: 'Progredindo',
      descricao: 'Alcance o nível Avançado',
      emoji: 'assets/models/Progredidndo.svg',
      tipo: TipoConquista.nivelAlcancado,
      criterios: {'nivel': 2}, // NivelUsuario.avancado.index
      pontosBonus: 300,
    ),

    // Conquistas especiais
    Conquista(
      id: 'primeiro_exercicio',
      titulo: 'Primeiro Exercício',
      descricao: 'Complete seu primeiro exercício',
      emoji: 'assets/models/Primeiro-Passo.svg',
      tipo: TipoConquista.moduloCompleto,
      criterios: {'exercicios_completos': 1},
      pontosBonus: 25,
    ),

    // Conquista especial BNCC
    Conquista(
      id: 'mestre_bncc',
      titulo: 'Mestre BNCC',
      descricao: 'Domine todos os objetivos da BNCC do seu ano letivo',
      emoji: 'assets/models/Mestre-BNCC.svg',
      tipo: TipoConquista.unidadeCompleta,
      criterios: {'objetivos_bncc_completos': true},
      pontosBonus: 1000,
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

  static List<Conquista> obterConquistasDesbloqueadas(
      List<String> idsDesbloqueadas) {
    return _conquistasBase
        .where((c) => idsDesbloqueadas.contains(c.id))
        .map((c) => c.copyWith(desbloqueada: true))
        .toList();
  }

  static List<Conquista> obterConquistasBloqueadas(
      List<String> idsDesbloqueadas) {
    return _conquistasBase
        .where((c) => !idsDesbloqueadas.contains(c.id))
        .toList();
  }
}
