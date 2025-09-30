import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/personagem.dart';

class PersonagemService {
  static const String _keyPerfil = 'perfil_personagem';

  // Singleton
  static final PersonagemService _instance = PersonagemService._internal();
  factory PersonagemService() => _instance;
  PersonagemService._internal();

  PerfilPersonagem? _perfilAtual;
  List<ItemPersonalizacao> _todosItens = [];

  // Getter para o perfil atual
  PerfilPersonagem? get perfilAtual => _perfilAtual;

  /// Inicializa o serviço carregando dados salvos
  Future<void> inicializar() async {
    await _carregarPerfil();
    _inicializarItensBase();
  }

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
}
