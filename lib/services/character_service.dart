import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character_model.dart';
import 'dart:math';

class PersonagemService {
  static const String _keyPerfil = 'perfil_personagem';

  // Singleton
  static final PersonagemService _instance = PersonagemService._internal();
  factory PersonagemService() => _instance;
  PersonagemService._internal();

  PerfilPersonagem? _perfilAtual;
  List<ItemPersonalizacao> _todosItens = [];

  // Novos campos para sistema de personagens gacha
  static const String _personagensKey = 'personagens_colecao';
  static const String _personagemSelecionadoKey = 'personagem_selecionado';
  static const String _gachaTentativasKey = 'gacha_tentativas';

  List<Personagem> _personagens = [];
  Personagem? _personagemSelecionado;
  int _gachaTentativas = 0;

  // Getter para o perfil atual
  PerfilPersonagem? get perfilAtual => _perfilAtual;

  /// Inicializa o serviço carregando dados salvos
  Future<void> inicializar() async {
    await _carregarPerfil();
    _inicializarItensBase();
    await _carregarPersonagensGacha();
  }

  /// Carrega dados dos personagens gacha
  Future<void> _carregarPersonagensGacha() async {
    final prefs = await SharedPreferences.getInstance();

    // Carrega tentativas gacha
    _gachaTentativas = prefs.getInt(_gachaTentativasKey) ?? 0;

    // Carrega personagens da coleção
    final personagensJson = prefs.getStringList(_personagensKey) ?? [];
    _personagens = personagensJson
        .map((json) => Personagem.fromJson(Map<String, dynamic>.from(
            Map<String, dynamic>.from(Uri.splitQueryString(json)))))
        .toList();

    // Carrega personagem selecionado
    final selecionadoJson = prefs.getString(_personagemSelecionadoKey);
    if (selecionadoJson != null) {
      _personagemSelecionado = Personagem.fromJson(
          Map<String, dynamic>.from(Uri.splitQueryString(selecionadoJson)));
    }
  }

  /// Salva dados dos personagens gacha
  Future<void> _salvarPersonagensGacha() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_gachaTentativasKey, _gachaTentativas);

    // Salva personagens
    final personagensJson = _personagens
        .map((p) => Uri(queryParameters: p.toJson()).query)
        .toList();
    await prefs.setStringList(_personagensKey, personagensJson);

    // Salva personagem selecionado
    if (_personagemSelecionado != null) {
      final selecionadoJson = Uri(queryParameters: _personagemSelecionado!.toJson()).query;
      await prefs.setString(_personagemSelecionadoKey, selecionadoJson);
    } else {
      await prefs.remove(_personagemSelecionadoKey);
    }
  }

  // === MÉTODOS PARA PERSONAGENS GACHA ===

  /// Obtém todos os personagens disponíveis no jogo
  List<Personagem> obterPersonagensDisponiveis() {
    return _personagensBase;
  }

  /// Obtém personagens da coleção do jogador
  List<Personagem> obterColecaoPersonagens() {
    return List.from(_personagens);
  }

  /// Obtém personagem selecionado
  Personagem? obterPersonagemSelecionado() {
    return _personagemSelecionado;
  }

  /// Seleciona um personagem
  Future<bool> selecionarPersonagem(String personagemId) async {
    final personagem = _personagens.firstWhere(
      (p) => p.id == personagemId,
      orElse: () => throw Exception('Personagem não encontrado na coleção'),
    );

    _personagemSelecionado = personagem;
    await _salvarPersonagensGacha();
    return true;
  }

  /// Adiciona personagem à coleção
  Future<void> adicionarPersonagem(Personagem personagem) async {
    // Verifica se já possui
    final existente = _personagens.indexWhere((p) => p.id == personagem.id);
    if (existente >= 0) {
      // Já possui, aumenta nível ou evolui
      final atual = _personagens[existente];
      if (atual.nivel < 10) {
        // Aumenta nível
        final novoNivel = atual.nivel + 1;
        const novaExperiencia = 0; // Reset experiência ao subir nível
        _personagens[existente] = atual.copyWith(
          nivel: novoNivel,
          experiencia: novaExperiencia,
        );
      } else if (atual.podeEvoluir) {
        // Evolui
        _personagens[existente] = atual.copyWith(evoluido: true);
      }
      // Se não pode fazer nada, apenas mantém
    } else {
      // Novo personagem
      _personagens.add(personagem);
    }

    await _salvarPersonagensGacha();
  }

  /// Gacha - obtém personagem aleatório
  Future<Personagem?> fazerGacha() async {
    if (_perfilAtual == null || _perfilAtual!.moedas < 50) return null; // Custo do gacha

    _perfilAtual = _perfilAtual!.copyWith(moedas: _perfilAtual!.moedas - 50);
    await salvarPerfil();

    _gachaTentativas++;

    // Sistema de raridade ponderada
    final random = Random();
    final chance = random.nextDouble();

    RaridadePersonagem raridadeSelecionada;
    if (chance < RaridadePersonagem.mitico.chanceGacha) {
      raridadeSelecionada = RaridadePersonagem.mitico;
    } else if (chance < RaridadePersonagem.mitico.chanceGacha + RaridadePersonagem.lendario.chanceGacha) {
      raridadeSelecionada = RaridadePersonagem.lendario;
    } else if (chance < RaridadePersonagem.mitico.chanceGacha + RaridadePersonagem.lendario.chanceGacha + RaridadePersonagem.epico.chanceGacha) {
      raridadeSelecionada = RaridadePersonagem.epico;
    } else if (chance < RaridadePersonagem.mitico.chanceGacha + RaridadePersonagem.lendario.chanceGacha + RaridadePersonagem.epico.chanceGacha + RaridadePersonagem.raro.chanceGacha) {
      raridadeSelecionada = RaridadePersonagem.raro;
    } else {
      raridadeSelecionada = RaridadePersonagem.comum;
    }

    // Filtra personagens por raridade
    final candidatos = _personagensBase
        .where((p) => p.raridade == raridadeSelecionada)
        .toList();

    if (candidatos.isEmpty) return null;

    final personagemSorteado = candidatos[random.nextInt(candidatos.length)];

    // Adiciona à coleção
    await adicionarPersonagem(personagemSorteado);

    return personagemSorteado;
  }

  /// Ganha experiência para personagem selecionado
  Future<void> ganharExperiencia(int experiencia) async {
    if (_personagemSelecionado == null) return;

    final personagem = _personagemSelecionado!;
    final novaExperiencia = personagem.experiencia + experiencia;

    if (novaExperiencia >= personagem.experienciaParaProximoNivel) {
      // Sobe de nível
      final experienciaRestante = novaExperiencia - personagem.experienciaParaProximoNivel;
      final novoNivel = personagem.nivel + 1;

      _personagemSelecionado = personagem.copyWith(
        nivel: novoNivel,
        experiencia: experienciaRestante,
      );
    } else {
      _personagemSelecionado = personagem.copyWith(
        experiencia: novaExperiencia,
      );
    }

    // Atualiza na coleção também
    final index = _personagens.indexWhere((p) => p.id == personagem.id);
    if (index >= 0) {
      _personagens[index] = _personagemSelecionado!;
    }

    await _salvarPersonagensGacha();
  }

  /// Evolui personagem
  Future<bool> evoluirPersonagem(String personagemId) async {
    final index = _personagens.indexWhere((p) => p.id == personagemId);
    if (index < 0) return false;

    final personagem = _personagens[index];
    if (!personagem.podeEvoluir) return false;

    // Custo de evolução: 1000 moedas
    if (_perfilAtual == null || _perfilAtual!.moedas < 1000) return false;

    _perfilAtual = _perfilAtual!.copyWith(moedas: _perfilAtual!.moedas - 1000);
    await salvarPerfil();

    _personagens[index] = personagem.copyWith(evoluido: true);

    // Se era o selecionado, atualiza
    if (_personagemSelecionado?.id == personagemId) {
      _personagemSelecionado = _personagens[index];
    }

    await _salvarPersonagensGacha();
    return true;
  }

  /// Obtém estatísticas dos personagens
  Map<String, dynamic> obterEstatisticasPersonagens() {
    final totalPersonagens = _personagens.length;
    final porRaridade = <RaridadePersonagem, int>{};
    final porTipo = <TipoPersonagem, int>{};

    for (final personagem in _personagens) {
      porRaridade[personagem.raridade] = (porRaridade[personagem.raridade] ?? 0) + 1;
      porTipo[personagem.tipo] = (porTipo[personagem.tipo] ?? 0) + 1;
    }

    return {
      'total_personagens': totalPersonagens,
      'gacha_tentativas': _gachaTentativas,
      'personagem_selecionado': _personagemSelecionado?.nome ?? 'Nenhum',
      'por_raridade': porRaridade.map((k, v) => MapEntry(k.nome, v)),
      'por_tipo': porTipo.map((k, v) => MapEntry(k.nome, v)),
    };
  }

  /// Reseta dados dos personagens gacha (para testes)
  Future<void> resetarPersonagensGacha() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_personagensKey);
    await prefs.remove(_personagemSelecionadoKey);
    await prefs.remove(_gachaTentativasKey);

    _personagens.clear();
    _personagemSelecionado = null;
    _gachaTentativas = 0;
  }

  // Base de dados dos personagens disponíveis
  static final List<Personagem> _personagensBase = [
    // Guerreiros
    const Personagem(
      id: 'rex_guerreiro',
      nome: 'Rex',
      descricao: 'Guerreiro Lógico',
      historia: 'Um cavaleiro que encontrou a lógica nas batalhas matemáticas.',
      imagem: 'assets/personagens/rex.png',
      tipo: TipoPersonagem.guerreiro,
      raridade: RaridadePersonagem.raro,
      atributosBase: AtributosPersonagem(
        forca: 15, inteligencia: 8, velocidade: 10, sorte: 7,
      ),
      habilidades: [
        HabilidadePersonagem(
          id: 'bonus_pontos_rex',
          nome: 'Força Lógica',
          descricao: '+15% pontos por resposta certa',
          icone: '⚔️',
          efeito: {'tipo': 'bonus_pontos', 'valor': 0.15},
        ),
      ],
    ),

    // Magos
    const Personagem(
      id: 'luna_maga',
      nome: 'Luna',
      descricao: 'Maga do Tempo',
      historia: 'Uma feiticeira que manipula o tempo para resolver equações complexas.',
      imagem: 'assets/personagens/luna.png',
      tipo: TipoPersonagem.mago,
      raridade: RaridadePersonagem.epico,
      atributosBase: AtributosPersonagem(
        forca: 6, inteligencia: 18, velocidade: 12, sorte: 9,
      ),
      habilidades: [
        HabilidadePersonagem(
          id: 'tempo_extra_luna',
          nome: 'Manipulação Temporal',
          descricao: '+10% tempo extra para responder',
          icone: '⏰',
          efeito: {'tipo': 'tempo_extra', 'valor': 0.10},
        ),
      ],
    ),

    // Comerciantes
    const Personagem(
      id: 'viciado_porcentagens',
      nome: 'Mercador',
      descricao: 'Comerciante viciado em porcentagens',
      historia: 'Um negociante que vê oportunidades matemáticas em toda transação.',
      imagem: 'assets/personagens/mercador.png',
      tipo: TipoPersonagem.comerciante,
      raridade: RaridadePersonagem.comum,
      atributosBase: AtributosPersonagem(
        forca: 8, inteligencia: 12, velocidade: 8, sorte: 15,
      ),
      habilidades: [
        HabilidadePersonagem(
          id: 'bonus_porcentagem',
          nome: 'Olho para Negócios',
          descricao: '+20% chance de itens raros',
          icone: '💰',
          efeito: {'tipo': 'chance_item_raro', 'valor': 0.20},
        ),
      ],
    ),

    // Agiotas
    const Personagem(
      id: 'agiota_juros',
      nome: 'Financista',
      descricao: 'Agiota especialista em juros',
      historia: 'Um banqueiro implacável que calcula juros compostos na mente.',
      imagem: 'assets/personagens/financista.png',
      tipo: TipoPersonagem.agiota,
      raridade: RaridadePersonagem.lendario,
      atributosBase: AtributosPersonagem(
        forca: 10, inteligencia: 16, velocidade: 6, sorte: 13,
      ),
      habilidades: [
        HabilidadePersonagem(
          id: 'juros_compostos',
          nome: 'Cálculo Financeiro',
          descricao: '+25% pontos em questões de matemática financeira',
          icone: '💹',
          efeito: {'tipo': 'bonus_financeiro', 'valor': 0.25},
        ),
      ],
    ),

    // Adicione mais personagens conforme necessário...
  ];

  /// Carrega o perfil do usuário do SharedPreferences
  Future<PerfilPersonagem> _carregarPerfil() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final perfilJson = prefs.getString(_keyPerfil);

      if (perfilJson != null) {
        final Map<String, dynamic> dados = json.decode(perfilJson);
        _perfilAtual = PerfilPersonagem.fromJson(dados);
      } else {
        // Criar perfil padrão
        _perfilAtual = PerfilPersonagem(
          userId: 'user_default',
          nome: 'Matemático',
          nivel: 1,
          experiencia: 0,
          moedas: 500, // Moedas iniciais
          itensEquipados: {
            'cabeca': 'cabeca_basico',
            'corpo': 'corpo_basico',
            'pernas': 'pernas_basico',
          },
          itensInventario: [
            'cabeca_basico',
            'corpo_basico',
            'pernas_basico',
          ],
        );
        await salvarPerfil();
      }

      return _perfilAtual!;
    } catch (e) {
      // Em caso de erro, criar perfil padrão
      _perfilAtual = PerfilPersonagem(
        userId: 'user_default',
        nome: 'Matemático',
      );
      return _perfilAtual!;
    }
  }

  /// Salva o perfil atual no SharedPreferences
  Future<bool> salvarPerfil() async {
    try {
      if (_perfilAtual == null) return false;

      final prefs = await SharedPreferences.getInstance();
      final perfilJson = json.encode(_perfilAtual!.toJson());
      return await prefs.setString(_keyPerfil, perfilJson);
    } catch (e) {
      return false;
    }
  }

  /// Inicializa os itens base do jogo
  void _inicializarItensBase() {
    _todosItens = [
      // === CABEÇA ===
      ItemPersonalizacao(
        id: 'cabeca_basico',
        nome: 'Cabelo Básico',
        descricao: 'Um visual clássico para começar',
        categoria: 'cabeca',
        imagemPath: 'assets/personagem/cabeca_basico.png',
        preco: 0,
        raridade: 'comum',
        desbloqueado: true,
        tagsEstilo: ['casual'],
      ),
      ItemPersonalizacao(
        id: 'cabeca_estudioso',
        nome: 'Óculos de Estudioso',
        descricao: 'Para quem leva os estudos a sério',
        categoria: 'cabeca',
        imagemPath: 'assets/personagem/cabeca_oculos.png',
        preco: 150,
        raridade: 'comum',
        tagsEstilo: ['formal', 'intelectual'],
        condicaoDesbloqueio: 'Complete 10 módulos',
      ),
      ItemPersonalizacao(
        id: 'cabeca_genio',
        nome: 'Cabelo de Gênio',
        descricao: 'A inteligência se reflete no visual!',
        categoria: 'cabeca',
        imagemPath: 'assets/personagem/cabeca_genio.png',
        preco: 300,
        raridade: 'raro',
        tagsEstilo: ['especial', 'intelectual'],
        condicaoDesbloqueio: 'Atinja nível 10',
      ),

      // === CORPO ===
      ItemPersonalizacao(
        id: 'corpo_basico',
        nome: 'Camiseta Casual',
        descricao: 'Conforto para estudar',
        categoria: 'corpo',
        imagemPath: 'assets/personagem/corpo_basico.png',
        preco: 0,
        raridade: 'comum',
        desbloqueado: true,
        tagsEstilo: ['casual'],
      ),
      ItemPersonalizacao(
        id: 'corpo_matematico',
        nome: 'Camiseta Matemática',
        descricao: 'Para mostrar amor pelos números',
        categoria: 'corpo',
        imagemPath: 'assets/personagem/corpo_math.png',
        preco: 200,
        raridade: 'comum',
        tagsEstilo: ['temático', 'matemática'],
        condicaoDesbloqueio: 'Acerte 100 problemas',
      ),
      ItemPersonalizacao(
        id: 'corpo_lab',
        nome: 'Jaleco de Laboratório',
        descricao: 'Para os experimentos matemáticos',
        categoria: 'corpo',
        imagemPath: 'assets/personagem/corpo_lab.png',
        preco: 400,
        raridade: 'raro',
        tagsEstilo: ['formal', 'científico'],
        condicaoDesbloqueio: 'Complete módulo de Geometria',
      ),

      // === PERNAS ===
      ItemPersonalizacao(
        id: 'pernas_basico',
        nome: 'Calça Jeans',
        descricao: 'Clássico e confortável',
        categoria: 'pernas',
        imagemPath: 'assets/personagem/pernas_basico.png',
        preco: 0,
        raridade: 'comum',
        desbloqueado: true,
        tagsEstilo: ['casual'],
      ),
      ItemPersonalizacao(
        id: 'pernas_esportivo',
        nome: 'Calça Esportiva',
        descricao: 'Para quem gosta de dinamismo',
        categoria: 'pernas',
        imagemPath: 'assets/personagem/pernas_sport.png',
        preco: 180,
        raridade: 'comum',
        tagsEstilo: ['esportivo', 'dinâmico'],
        condicaoDesbloqueio: 'Complete 5 quizzes rápidos',
      ),

      // === ACESSÓRIOS ===
      ItemPersonalizacao(
        id: 'acessorio_medalha_bronze',
        nome: 'Medalha de Bronze',
        descricao: 'Primeira conquista importante',
        categoria: 'acessorio',
        imagemPath: 'assets/personagem/medalha_bronze.png',
        preco: 100,
        raridade: 'comum',
        tagsEstilo: ['conquista'],
        condicaoDesbloqueio: 'Ganhe sua primeira medalha',
      ),
      ItemPersonalizacao(
        id: 'acessorio_medalha_prata',
        nome: 'Medalha de Prata',
        descricao: 'Para os dedicados estudantes',
        categoria: 'acessorio',
        imagemPath: 'assets/personagem/medalha_prata.png',
        preco: 250,
        raridade: 'raro',
        tagsEstilo: ['conquista', 'prestígio'],
        condicaoDesbloqueio: 'Ganhe 10 medalhas',
      ),
      ItemPersonalizacao(
        id: 'acessorio_medalha_ouro',
        nome: 'Medalha de Ouro',
        descricao: 'Para os verdadeiros mestres',
        categoria: 'acessorio',
        imagemPath: 'assets/personagem/medalha_ouro.png',
        preco: 500,
        raridade: 'epico',
        tagsEstilo: ['conquista', 'élite'],
        condicaoDesbloqueio: 'Ganhe 50 medalhas',
      ),
      ItemPersonalizacao(
        id: 'acessorio_calculadora',
        nome: 'Calculadora Vintage',
        descricao: 'Um acessório nostálgico',
        categoria: 'acessorio',
        imagemPath: 'assets/personagem/calc_vintage.png',
        preco: 350,
        raridade: 'raro',
        tagsEstilo: ['vintage', 'matemática'],
        condicaoDesbloqueio: 'Complete 25 módulos',
      ),
    ];

    // Marcar itens como desbloqueados baseado no inventário do perfil
    if (_perfilAtual != null) {
      for (var item in _todosItens) {
        if (_perfilAtual!.possuiItem(item.id)) {
          final index = _todosItens.indexWhere((i) => i.id == item.id);
          if (index != -1) {
            _todosItens[index] = item.copyWith(desbloqueado: true);
          }
        }
      }
    }
  }

  /// Retorna todos os itens disponíveis
  List<ItemPersonalizacao> getTodosItens() => List.from(_todosItens);

  /// Retorna itens de uma categoria específica
  List<ItemPersonalizacao> getItensPorCategoria(String categoria) {
    return _todosItens.where((item) => item.categoria == categoria).toList();
  }

  /// Retorna apenas itens desbloqueados
  List<ItemPersonalizacao> getItensDesbloqueados() {
    return _todosItens.where((item) => item.desbloqueado).toList();
  }

  /// Retorna itens do inventário do usuário
  List<ItemPersonalizacao> getInventario() {
    if (_perfilAtual == null) return [];

    return _todosItens
        .where((item) => _perfilAtual!.possuiItem(item.id))
        .toList();
  }

  /// Equipa um item
  Future<bool> equiparItem(String itemId) async {
    try {
      if (_perfilAtual == null) return false;

      final item = _todosItens.firstWhere((i) => i.id == itemId);

      if (!_perfilAtual!.possuiItem(itemId)) return false;

      final itensEquipados =
          Map<String, String>.from(_perfilAtual!.itensEquipados);
      itensEquipados[item.categoria] = itemId;

      _perfilAtual = _perfilAtual!.copyWith(
        itensEquipados: itensEquipados,
        ultimaAtualizacao: DateTime.now(),
      );

      return await salvarPerfil();
    } catch (e) {
      return false;
    }
  }

  /// Compra um item
  Future<bool> comprarItem(String itemId) async {
    try {
      if (_perfilAtual == null) return false;

      final item = _todosItens.firstWhere((i) => i.id == itemId);

      if (_perfilAtual!.possuiItem(itemId)) return false; // Já possui
      if (!_perfilAtual!.podeComprarItem(item.preco)) {
        return false; // Sem dinheiro
      }

      final novoInventario = List<String>.from(_perfilAtual!.itensInventario);
      novoInventario.add(itemId);

      _perfilAtual = _perfilAtual!.copyWith(
        moedas: _perfilAtual!.moedas - item.preco,
        itensInventario: novoInventario,
        ultimaAtualizacao: DateTime.now(),
      );

      // Atualizar o item na lista como desbloqueado
      final index = _todosItens.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        _todosItens[index] = _todosItens[index].copyWith(
          desbloqueado: true,
          dataDesbloqueio: DateTime.now(),
        );
      }

      return await salvarPerfil();
    } catch (e) {
      return false;
    }
  }

  /// Adiciona experiência e moedas
  Future<bool> adicionarRecompensa({
    required int experiencia,
    required int moedas,
  }) async {
    try {
      if (_perfilAtual == null) return false;

      final novaExperiencia = _perfilAtual!.experiencia + experiencia;
      final novoNivel = (novaExperiencia / 1000).floor() + 1;
      final novasMoedas = _perfilAtual!.moedas + moedas;

      _perfilAtual = _perfilAtual!.copyWith(
        experiencia: novaExperiencia,
        nivel: novoNivel,
        moedas: novasMoedas,
        ultimaAtualizacao: DateTime.now(),
      );

      return await salvarPerfil();
    } catch (e) {
      return false;
    }
  }

  /// Atualiza o nome do personagem
  Future<bool> atualizarNome(String novoNome) async {
    try {
      if (_perfilAtual == null) return false;
      if (novoNome.trim().isEmpty) return false;

      _perfilAtual = _perfilAtual!.copyWith(
        nome: novoNome.trim(),
        ultimaAtualizacao: DateTime.now(),
      );

      return await salvarPerfil();
    } catch (e) {
      return false;
    }
  }

  /// Verifica e desbloqueia itens baseado em condições
  Future<List<ItemPersonalizacao>> verificarNovosDesbloqueios({
    int? nivel,
    int? modulosCompletos,
    int? problemasCorretos,
    int? medalhas,
  }) async {
    List<ItemPersonalizacao> novosItens = [];

    for (var item in _todosItens) {
      if (item.desbloqueado || _perfilAtual?.possuiItem(item.id) == true) {
        continue; // Já desbloqueado
      }

      bool deveDesbloquear = false;

      // Verificar condições de desbloqueio
      if (item.condicaoDesbloqueio != null) {
        final condicao = item.condicaoDesbloqueio!.toLowerCase();

        if (condicao.contains('nível') && nivel != null) {
          final nivelRequerido =
              int.tryParse(condicao.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
          deveDesbloquear = nivel >= nivelRequerido;
        }

        if (condicao.contains('módulo') && modulosCompletos != null) {
          final modulosRequeridos =
              int.tryParse(condicao.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
          deveDesbloquear = modulosCompletos >= modulosRequeridos;
        }

        if (condicao.contains('problema') && problemasCorretos != null) {
          final problemasRequeridos =
              int.tryParse(condicao.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
          deveDesbloquear = problemasCorretos >= problemasRequeridos;
        }

        if (condicao.contains('medalha') && medalhas != null) {
          final medalhasRequeridas =
              int.tryParse(condicao.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
          deveDesbloquear = medalhas >= medalhasRequeridas;
        }
      }

      if (deveDesbloquear) {
        // Adicionar automaticamente ao inventário
        final novoInventario = List<String>.from(_perfilAtual!.itensInventario);
        novoInventario.add(item.id);

        _perfilAtual = _perfilAtual!.copyWith(
          itensInventario: novoInventario,
          ultimaAtualizacao: DateTime.now(),
        );

        // Atualizar item como desbloqueado
        final index = _todosItens.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _todosItens[index] = item.copyWith(
            desbloqueado: true,
            dataDesbloqueio: DateTime.now(),
          );
          novosItens.add(_todosItens[index]);
        }
      }
    }

    if (novosItens.isNotEmpty) {
      await salvarPerfil();
    }

    return novosItens;
  }

  /// Calcula o bônus de pontos baseado no personagem selecionado
  double calcularBonusPontos(Personagem? personagem) {
    if (personagem == null) return 0.0;

    double bonusTotal = 0.0;

    // Bônus baseado em atributos (força aumenta pontos)
    final atributos = personagem.atributosAtuais;
    bonusTotal += atributos.forca * 0.01; // 1% por ponto de força

    // Bônus baseado em habilidades
    for (final habilidade in personagem.habilidades) {
      final efeito = habilidade.efeito;
      if (efeito['tipo'] == 'bonus_pontos') {
        bonusTotal += efeito['valor'] ?? 0.0;
      }
    }

    return bonusTotal;
  }
}
