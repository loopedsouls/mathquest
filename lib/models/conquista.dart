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
      id: 'vinte_modulos',
      titulo: 'Estudioso',
      descricao: 'Complete 20 módulos',
      emoji: '🎓',
      tipo: TipoConquista.moduloCompleto,
      criterios: {'quantidade': 20},
      pontosBonus: 400,
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

    // Conquistas especiais de tempo
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
      id: 'flash',
      titulo: 'Flash',
      descricao: 'Resolva um exercício em menos de 5 segundos',
      emoji: '🏃‍♂️',
      tipo: TipoConquista.tempoRecord,
      criterios: {'tempo_maximo': 5},
      pontosBonus: 150,
    ),

    // Conquistas de perfeição
    Conquista(
      id: 'perfeccionista',
      titulo: 'Perfeccionista',
      descricao: 'Complete um módulo com 100% de acerto',
      emoji: '💯',
      tipo: TipoConquista.perfeccionista,
      criterios: {'taxa_acerto': 1.0},
      pontosBonus: 150,
    ),
    Conquista(
      id: 'ace_matematico',
      titulo: 'Ás Matemático',
      descricao: 'Complete 5 módulos com 100% de acerto',
      emoji: '🎯',
      tipo: TipoConquista.perfeccionista,
      criterios: {'modulos_perfeitos': 5},
      pontosBonus: 500,
    ),

    // Conquistas de persistência
    Conquista(
      id: 'persistente_3_dias',
      titulo: 'Constante',
      descricao: 'Estude por 3 dias consecutivos',
      emoji: '🌟',
      tipo: TipoConquista.persistente,
      criterios: {'dias_consecutivos': 3},
      pontosBonus: 100,
    ),
    Conquista(
      id: 'persistente_7_dias',
      titulo: 'Dedicado',
      descricao: 'Estude por 7 dias consecutivos',
      emoji: '🔥',
      tipo: TipoConquista.persistente,
      criterios: {'dias_consecutivos': 7},
      pontosBonus: 250,
    ),
    Conquista(
      id: 'persistente_30_dias',
      titulo: 'Inabalável',
      descricao: 'Estude por 30 dias consecutivos',
      emoji: '👑',
      tipo: TipoConquista.persistente,
      criterios: {'dias_consecutivos': 30},
      pontosBonus: 1000,
    ),

    // Conquistas especiais temáticas
    Conquista(
      id: 'primeiro_exercicio',
      titulo: 'Primeiro Passo',
      descricao: 'Complete seu primeiro exercício',
      emoji: '🚀',
      tipo: TipoConquista.moduloCompleto,
      criterios: {'exercicios_completos': 1},
      pontosBonus: 25,
    ),
    Conquista(
      id: 'madrugador',
      titulo: 'Madrugador',
      descricao: 'Complete exercícios antes das 8h da manhã',
      emoji: '🌅',
      tipo: TipoConquista.tempoRecord,
      criterios: {'hora_maxima': 8},
      pontosBonus: 50,
    ),
    Conquista(
      id: 'coruja',
      titulo: 'Coruja Noturna',
      descricao: 'Complete exercícios após as 22h',
      emoji: '🦉',
      tipo: TipoConquista.tempoRecord,
      criterios: {'hora_minima': 22},
      pontosBonus: 50,
    ),
    Conquista(
      id: 'maratonista',
      titulo: 'Maratonista',
      descricao: 'Complete 50 exercícios em um único dia',
      emoji: '🏃‍♀️',
      tipo: TipoConquista.streakExercicios,
      criterios: {'exercicios_dia': 50},
      pontosBonus: 300,
    ),
    Conquista(
      id: 'exploradora',
      titulo: 'Exploradora',
      descricao: 'Complete pelo menos 1 exercício de cada unidade',
      emoji: '🗺️',
      tipo: TipoConquista.unidadeCompleta,
      criterios: {'unidades_exploradas': 5},
      pontosBonus: 200,
    ),
    Conquista(
      id: 'centenario',
      titulo: 'Centenário',
      descricao: 'Complete 100 exercícios no total',
      emoji: '💯',
      tipo: TipoConquista.streakExercicios,
      criterios: {'exercicios_total': 100},
      pontosBonus: 400,
    ),

    // Conquistas especiais e divertidas
    Conquista(
      id: 'calculadora_humana',
      titulo: 'Calculadora Humana',
      descricao: 'Acerte 10 exercícios de cálculo mental seguidos',
      emoji: '🧠',
      tipo: TipoConquista.streakExercicios,
      criterios: {'streak_calculo_mental': 10},
      pontosBonus: 200,
    ),
    Conquista(
      id: 'geometra_espacial',
      titulo: 'Geômetra Espacial',
      descricao: 'Domine todos os conceitos de geometria espacial',
      emoji: '🔷',
      tipo: TipoConquista.unidadeCompleta,
      criterios: {'geometria_espacial': true},
      pontosBonus: 300,
    ),
    Conquista(
      id: 'mestre_fracoes',
      titulo: 'Mestre das Frações',
      descricao: 'Complete 20 exercícios de frações com 100% de acerto',
      emoji: '🍰',
      tipo: TipoConquista.perfeccionista,
      criterios: {'fracoes_perfeitas': 20},
      pontosBonus: 250,
    ),
    Conquista(
      id: 'estatistico_genial',
      titulo: 'Estatístico Genial',
      descricao: 'Resolva corretamente todos os tipos de gráficos',
      emoji: '📊',
      tipo: TipoConquista.unidadeCompleta,
      criterios: {'tipos_graficos': 5},
      pontosBonus: 180,
    ),
    Conquista(
      id: 'probabilista',
      titulo: 'Probabilista',
      descricao: 'Acerte 15 exercícios de probabilidade consecutivos',
      emoji: '🎲',
      tipo: TipoConquista.streakExercicios,
      criterios: {'streak_probabilidade': 15},
      pontosBonus: 220,
    ),
    Conquista(
      id: 'rapido_e_furioso',
      titulo: 'Rápido e Furioso',
      descricao: 'Complete 10 exercícios em menos de 5 minutos',
      emoji: '🏎️',
      tipo: TipoConquista.tempoRecord,
      criterios: {'exercicios_rapidos': 10, 'tempo_total': 300},
      pontosBonus: 300,
    ),
    Conquista(
      id: 'sem_calculadora',
      titulo: 'Sem Calculadora',
      descricao: 'Resolva 25 exercícios de cálculo sem usar dicas',
      emoji: '🚫📱',
      tipo: TipoConquista.perfeccionista,
      criterios: {'sem_ajuda': 25},
      pontosBonus: 275,
    ),
    Conquista(
      id: 'resolver_problemas',
      titulo: 'Resolvedor de Problemas',
      descricao: 'Complete 15 problemas de aplicação prática',
      emoji: '🔧',
      tipo: TipoConquista.moduloCompleto,
      criterios: {'problemas_praticos': 15},
      pontosBonus: 350,
    ),
    Conquista(
      id: 'investigador',
      titulo: 'Investigador Matemático',
      descricao: 'Use a IA para fazer 10 perguntas sobre conceitos',
      emoji: '🔍',
      tipo: TipoConquista.streakExercicios,
      criterios: {'perguntas_ia': 10},
      pontosBonus: 150,
    ),
    Conquista(
      id: 'melhorou_nota',
      titulo: 'Evoluindo Sempre',
      descricao: 'Melhore sua pontuação em um tópico 3 vezes',
      emoji: '📈',
      tipo: TipoConquista.nivelAlcancado,
      criterios: {'melhorias': 3},
      pontosBonus: 125,
    ),

    // Conquistas comemorativas e sazonais
    Conquista(
      id: 'aniversario_app',
      titulo: 'Primeira Semana',
      descricao: 'Use o app por 7 dias (não consecutivos)',
      emoji: '🎂',
      tipo: TipoConquista.persistente,
      criterios: {'dias_uso_total': 7},
      pontosBonus: 100,
    ),
    Conquista(
      id: 'mes_completo',
      titulo: 'Mês Matemático',
      descricao: 'Use o app por 30 dias (não consecutivos)',
      emoji: '📅',
      tipo: TipoConquista.persistente,
      criterios: {'dias_uso_total': 30},
      pontosBonus: 500,
    ),
    Conquista(
      id: 'fim_de_semana',
      titulo: 'Fim de Semana Produtivo',
      descricao: 'Complete exercícios no sábado E domingo',
      emoji: '🌟',
      tipo: TipoConquista.persistente,
      criterios: {'fim_semana_ativo': true},
      pontosBonus: 80,
    ),
    Conquista(
      id: 'segunda_feira',
      titulo: 'Segunda-feira Motivada',
      descricao: 'Complete exercícios toda segunda por 4 semanas',
      emoji: '💪',
      tipo: TipoConquista.persistente,
      criterios: {'segundas_ativas': 4},
      pontosBonus: 150,
    ),
    Conquista(
      id: 'volta_aulas',
      titulo: 'Volta às Aulas',
      descricao: 'Complete 20 exercícios em fevereiro/março',
      emoji: '🎒',
      tipo: TipoConquista.moduloCompleto,
      criterios: {'exercicios_volta_aulas': 20},
      pontosBonus: 200,
    ),

    // Conquistas de colaboração e social
    Conquista(
      id: 'ajudou_colega',
      titulo: 'Colega Solidário',
      descricao: 'Compartilhe uma explicação útil',
      emoji: '🤝',
      tipo: TipoConquista.streakExercicios,
      criterios: {'compartilhamentos': 1},
      pontosBonus: 75,
    ),
    Conquista(
      id: 'guru_matematico',
      titulo: 'Guru Matemático',
      descricao: 'Alcance 10.000 pontos totais',
      emoji: '🧙‍♂️',
      tipo: TipoConquista.pontuacaoTotal,
      criterios: {'pontos': 10000},
      pontosBonus: 1000,
    ),
    Conquista(
      id: 'colecionador',
      titulo: 'Colecionador de Medalhas',
      descricao: 'Desbloqueie 50% de todas as conquistas',
      emoji: '🏅',
      tipo: TipoConquista.streakExercicios,
      criterios: {'porcentagem_conquistas': 0.5},
      pontosBonus: 500,
    ),
    Conquista(
      id: 'completista',
      titulo: 'Completista',
      descricao: 'Desbloqueie 90% de todas as conquistas',
      emoji: '🏆',
      tipo: TipoConquista.streakExercicios,
      criterios: {'porcentagem_conquistas': 0.9},
      pontosBonus: 1500,
    ),
    Conquista(
      id: 'lenda_matemática',
      titulo: 'Lenda Matemática',
      descricao: 'Desbloqueie TODAS as conquistas',
      emoji: '👑',
      tipo: TipoConquista.streakExercicios,
      criterios: {'porcentagem_conquistas': 1.0},
      pontosBonus: 2500,
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
