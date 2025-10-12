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
