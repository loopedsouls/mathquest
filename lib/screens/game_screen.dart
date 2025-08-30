import '../services/tutor_service.dart';
import 'package:flutter/material.dart';

class OptionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const OptionButton({
    required this.label,
    required this.onTap,
    this.isActive = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color:
                isActive ? Colors.white.withOpacity(0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isActive ? Colors.white : Colors.white70,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final String? apiKey;
  const GameScreen({super.key, this.apiKey});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  String _construirPromptContextual() {
    return '''
      Capítulo: ${estadoJogo['capitulo']}
      Personagem: $personagemAtivo
      Tema: $temaHistoria
      Complexidade: $nivelComplexidade
      Escolhas anteriores: ${estadoJogo['escolhasAnteriores']}
      Pontos de relacionamento: ${estadoJogo['pontosRelacionamento']}
      Inventário: ${estadoJogo['itensInventario']}
      Flags da história: ${estadoJogo['flagsHistoria']}
      Continue a narrativa de forma envolvente e apresente opções para o jogador.
    ''';
  }

  String historia = '';
  String explicacao = '';
  String feedback = '';
  bool carregando = false;
  int? respostaSelecionada;
  List<String> opcoes = [];
  List<Map<String, dynamic>> historico = [];
  late TutorService tutorService;
  bool autoMode = false;

  // Configurações de personalidade e contexto
  String personagemAtivo = 'Natsuki';
  String temaHistoria = 'aventura';
  String nivelComplexidade = 'médio';
  Map<String, dynamic> estadoJogo = {};

  // Animações
  late AnimationController _dialogueController;
  late AnimationController _characterController;
  late AnimationController _thinkingController;
  late Animation<Offset> _dialogueAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _thinkingAnimation;

  @override
  void initState() {
    super.initState();
    tutorService = TutorService(apiKey: widget.apiKey);
    _initAnimations();
    _initGameState();
    _startSequence();
  }

  void _initAnimations() {
    _dialogueController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _characterController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _thinkingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _dialogueAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _dialogueController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _characterController,
      curve: Curves.easeOut,
    ));

    _thinkingAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _thinkingController,
      curve: Curves.easeInOut,
    ));
  }

  void _initGameState() {
    estadoJogo = {
      'capitulo': 1,
      'escolhasAnteriores': [],
      'personalidadeJogador': {},
      'pontosRelacionamento': 0,
      'itensInventario': [],
      'flagsHistoria': {},
    };
  }

  void _startSequence() async {
    await _characterController.forward();
    await _dialogueController.forward();
    carregarHistoria();
  }

  @override
  void dispose() {
    _dialogueController.dispose();
    _characterController.dispose();
    _thinkingController.dispose();
    super.dispose();
  }

  Future<void> carregarHistoria() async {
    setState(() {
      carregando = true;
      respostaSelecionada = null;
      feedback = '';
      explicacao = '';
    });

    try {
      // Prompt contextual para o LLM
      final prompt = _construirPromptContextual();
      final resultado = await tutorService.gerarHistoriaAvancada(
        prompt: prompt,
        contexto: estadoJogo,
        personagem: personagemAtivo,
        tema: temaHistoria,
      );

      // Detecta erro padrão da LLM
      final respostaBruta = resultado['historia'] ?? '';
      final falhaLLM = respostaBruta
              .contains('Desculpe, não consegui gerar uma resposta agora.') ||
          respostaBruta.isEmpty;

      if (falhaLLM) {
        setState(() {
          historia =
              'A IA não conseguiu gerar uma resposta agora. Tente novamente.';
          opcoes = [];
          carregando = false;
        });
        _salvarNoHistorico({
          'tipo': 'narrativa',
          'texto': historia,
          'emocao': 'neutro',
          'timestamp': DateTime.now(),
        });
        return;
      }

      setState(() {
        historia = respostaBruta;
        opcoes = List<String>.from(resultado['opcoes'] ?? []);
        carregando = false;
      });

      _salvarNoHistorico({
        'tipo': 'narrativa',
        'texto': historia,
        'emocao': 'neutro',
        'timestamp': DateTime.now(),
      });

      if (autoMode) {
        _iniciarAutoPlay();
      }
    } catch (e) {
      setState(() {
        historia = 'Erro ao processar resposta da IA. Tente novamente.';
        opcoes = [];
        carregando = false;
      });
    }
  }

  Future<void> selecionarOpcao(int index) async {
    if (carregando || index >= opcoes.length) return;

    setState(() {
      carregando = true;
      respostaSelecionada = index;
    });

    await _dialogueController.animateTo(0.3);

    try {
      final escolha = opcoes[index];

      // Analisar a escolha com LLM
      final analiseEscolha = await _analisarEscolha(escolha, index);

      // Atualizar estado do jogo baseado na análise
      _atualizarEstadoJogo(escolha, analiseEscolha);

      _salvarNoHistorico({
        'tipo': 'escolha',
        'texto': "Escolha: $escolha",
        'impacto': analiseEscolha['impacto'] ?? 'neutro',
        'timestamp': DateTime.now(),
      });

      // Gerar continuação baseada na escolha
      // final prompt = _construirPromptEscolha(escolha, analiseEscolha);
      // final resultado = await tutorService.gerarContinuacaoHistoria(
      //   prompt: prompt,
      //   escolha: escolha,
      //   contexto: estadoJogo,
      // );
      // Substituir por método existente:
      final resultado = await tutorService.enviarEscolhaGemini(escolha);

      setState(() {
        historia = resultado['historia'] ?? 'Continuação não disponível';
        opcoes = List<String>.from(resultado['opcoes'] ?? []);
        feedback = '';
        explicacao = '';
        respostaSelecionada = null;
        carregando = false;
      });

      _salvarNoHistorico({
        'tipo': 'narrativa',
        'texto': historia,
        'feedback': feedback,
        'timestamp': DateTime.now(),
      });

      // Verificar se deve avançar capítulo
      // if (resultado['avancar_capitulo'] == true) {
      //   estadoJogo['capitulo']++;
      //   _mostrarTransicaoCapitulo();
      // }
    } catch (e) {
      setState(() {
        historia = 'Erro ao processar escolha. Verificando conexão com LLM...';
        opcoes = [];
        respostaSelecionada = null;
        carregando = false;
      });
    }

    await _dialogueController.forward();
  }

  Future<Map<String, dynamic>> _analisarEscolha(
      String escolha, int indice) async {
    // final prompt = '''
    // Analise a escolha do jogador no contexto da história atual:

    // CONTEXTO: $historia
    // ESCOLHA: "$escolha" (opção ${indice + 1})
    // ESTADO ATUAL: ${estadoJogo.toString()}

    // Forneça análise em JSON:
    // {
    //   "impacto": "positivo|neutro|negativo",
    //   "consequencias": ["lista", "de", "consequencias"],
    //   "mudanca_relacionamento": -5 a +5,
    //   "personalidade_revelada": "corajoso|cauteloso|romântico|etc",
    //   "dificuldade_futura": "fácil|médio|difícil"
    // }
    // ''';

    try {
      // final resposta = await tutorService.analisarEscolhaJogador(prompt);
      // return resposta;
      // Substituir por placeholder neutro, pois TutorService não tem esse método:
      return {
        'impacto': 'neutro',
        'consequencias': [],
        'mudanca_relacionamento': 0,
        'personalidade_revelada': 'indefinido',
        'dificuldade_futura': 'médio'
      };
    } catch (e) {
      return {
        'impacto': 'neutro',
        'consequencias': [],
        'mudanca_relacionamento': 0,
        'personalidade_revelada': 'indefinido',
        'dificuldade_futura': 'médio'
      };
    }
  }

  void _atualizarEstadoJogo(String escolha, Map<String, dynamic> analise) {
    // Atualizar escolhas anteriores
    estadoJogo['escolhasAnteriores'].add(escolha);
    if (estadoJogo['escolhasAnteriores'].length > 10) {
      estadoJogo['escolhasAnteriores'].removeAt(0);
    }

    // Atualizar pontos de relacionamento
    int mudanca = analise['mudanca_relacionamento'] ?? 0;
    estadoJogo['pontosRelacionamento'] += mudanca;

    // Atualizar personalidade do jogador
    String personalidade = analise['personalidade_revelada'] ?? '';
    if (personalidade.isNotEmpty) {
      estadoJogo['personalidadeJogador'][personalidade] =
          (estadoJogo['personalidadeJogador'][personalidade] ?? 0) + 1;
    }

    // Atualizar flags da história
    if (analise['novos_flags'] != null) {
      estadoJogo['flagsHistoria'].addAll(analise['novos_flags']);
    }
  }

  void _salvarNoHistorico(Map<String, dynamic> item) {
    historico.add(item);
    if (historico.length > 100) {
      historico.removeAt(0);
    }
  }

  void toggleAutoMode() {
    setState(() {
      autoMode = !autoMode;
    });

    if (autoMode) {
      _iniciarAutoPlay();
    }
  }

  void _iniciarAutoPlay() {
    if (autoMode && opcoes.isNotEmpty && !carregando) {
      Future.delayed(const Duration(seconds: 4), () {
        if (autoMode && opcoes.isNotEmpty) {
          // Auto mode inteligente: escolhe baseado na personalidade do jogador
          int melhorOpcao = _escolherOpcaoInteligente();
          selecionarOpcao(melhorOpcao);
        }
      });
    }
  }

  int _escolherOpcaoInteligente() {
    // Lógica simples para escolher baseada na personalidade predominante
    Map<String, int> personalidades =
        Map<String, int>.from(estadoJogo['personalidadeJogador'] ?? {});

    if (personalidades.isEmpty) return 0;

    String personalidadePredominante =
        personalidades.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    // Escolher opção baseada na personalidade (lógica simplificada)
    switch (personalidadePredominante) {
      case 'corajoso':
        return 0; // Primeira opção (geralmente mais ousada)
      case 'cauteloso':
        return opcoes.length - 1; // Última opção (geralmente mais segura)
      default:
        return 1; // Opção do meio
    }
  }

  void showHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Histórico & Estatísticas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Cap. ${estadoJogo['capitulo']} | ♥ ${estadoJogo['pontosRelacionamento']}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Estatísticas de personalidade
            if (estadoJogo['personalidadeJogador'].isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sua Personalidade:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...estadoJogo['personalidadeJogador'].entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key),
                                Text('${entry.value}x'),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: historico.length,
                reverse: true,
                itemBuilder: (context, index) {
                  final item = historico[historico.length - 1 - index];
                  final isEscolha = item['tipo'] == 'escolha';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isEscolha ? Colors.blue[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: isEscolha
                          ? Border.all(color: Colors.blue[200]!)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isEscolha ? Icons.touch_app : Icons.auto_stories,
                              size: 16,
                              color: isEscolha ? Colors.blue : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isEscolha ? 'Sua Escolha' : 'História',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isEscolha ? Colors.blue : Colors.grey,
                              ),
                            ),
                            const Spacer(),
                            if (item['timestamp'] != null)
                              Text(
                                '${item['timestamp'].hour.toString().padLeft(2, '0')}:${item['timestamp'].minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['texto'] ?? '',
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (item['feedback'] != null &&
                            item['feedback'].isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item['feedback'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.amber[800],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void skipDialogue() {
    if (opcoes.isNotEmpty && !carregando) {
      selecionarOpcao(0);
    } else if (!carregando) {
      carregarHistoria();
    }
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurações LLM'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Modo Automático'),
                subtitle: const Text('LLM escolhe automaticamente'),
                value: autoMode,
                onChanged: (value) {
                  toggleAutoMode();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Tema da História'),
                subtitle: Text(temaHistoria),
                trailing: const Icon(Icons.edit),
                onTap: () => _mostrarSeletorTema(),
              ),
              ListTile(
                title: const Text('Complexidade'),
                subtitle: Text(nivelComplexidade),
                trailing: const Icon(Icons.tune),
                onTap: () => _mostrarSeletorComplexidade(),
              ),
              ListTile(
                title: const Text('Personagem'),
                subtitle: Text(personagemAtivo),
                trailing: const Icon(Icons.person),
                onTap: () => _mostrarSeletorPersonagem(),
              ),
              const Divider(),
              ListTile(
                title: const Text('Reiniciar História'),
                leading: const Icon(Icons.refresh),
                onTap: () {
                  Navigator.pop(context);
                  _reiniciarJogo();
                },
              ),
              ListTile(
                title: const Text('Exportar Histórico'),
                leading: const Icon(Icons.download),
                onTap: () {
                  Navigator.pop(context);
                  _exportarHistorico();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _mostrarSeletorTema() {
    final temas = [
      'aventura',
      'romance',
      'mistério',
      'ficção científica',
      'fantasia'
    ];
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Escolher Tema'),
        children: temas
            .map((tema) => SimpleDialogOption(
                  onPressed: () {
                    setState(() {
                      temaHistoria = tema;
                    });
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Text(tema),
                ))
            .toList(),
      ),
    );
  }

  void _mostrarSeletorComplexidade() {
    final niveis = ['simples', 'médio', 'complexo', 'expert'];
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Nível de Complexidade'),
        children: niveis
            .map((nivel) => SimpleDialogOption(
                  onPressed: () {
                    setState(() {
                      nivelComplexidade = nivel;
                    });
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Text(nivel),
                ))
            .toList(),
      ),
    );
  }

  void _mostrarSeletorPersonagem() {
    final personagens = ['Natsuki', 'Monika', 'Sayori', 'Yuri'];
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Escolher Personagem'),
        children: personagens
            .map((personagem) => SimpleDialogOption(
                  onPressed: () {
                    setState(() {
                      personagemAtivo = personagem;
                    });
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Text(personagem),
                ))
            .toList(),
      ),
    );
  }

  void _reiniciarJogo() {
    setState(() {
      historico.clear();
      _initGameState();
      historia = '';
      opcoes = [];
      autoMode = false;
    });
    carregarHistoria();
  }

  void _exportarHistorico() {
    // Implementar exportação do histórico
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Histórico exportado com sucesso!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          if (opcoes.isEmpty && !carregando) {
            carregarHistoria();
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2C1810),
                Color(0xFF22223B),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Status do LLM
              Positioned(
                top: 50,
                right: 20,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: carregando ? Colors.orange : Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (carregando)
                        FadeTransition(
                          opacity: _thinkingAnimation,
                          child: const Icon(Icons.psychology,
                              color: Colors.white, size: 16),
                        ),
                      if (!carregando)
                        const Icon(Icons.check_circle,
                            color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        carregando ? 'LLM Pensando...' : 'LLM Conectado',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Informações do jogo
              Positioned(
                top: 50,
                left: 20,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Cap. ${estadoJogo['capitulo']} | ${personagemAtivo} | ♥ ${estadoJogo['pontosRelacionamento']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              // Personagem com animação (centralizado, mas sem caixa de diálogo junto)
              Align(
                alignment: Alignment.center,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        bottom: 120), // menos espaço para diálogo separado
                    child: Hero(
                      tag: 'character',
                      child: Container(
                        width: 340,
                        height: 480,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/character.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.grey[700]!,
                                    Colors.grey[900]!
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.person,
                                  size: 120,
                                  color: Colors.white24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Menu de opções centralizado na tela, com fundo apenas nas perguntas
              if (!carregando && opcoes.isNotEmpty)
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Escolha uma opção:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(opcoes.length, (index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => selecionarOpcao(index),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: respostaSelecionada == index
                                        ? Colors.blue.withOpacity(0.3)
                                        : Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: respostaSelecionada == index
                                          ? Colors.blue.withOpacity(0.5)
                                          : Colors.white.withOpacity(0.2),
                                      width:
                                          respostaSelecionada == index ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: _getOptionColor(index),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              opcoes[index],
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _getOptionHint(index),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white
                                                    .withOpacity(0.6),
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (autoMode &&
                                          index == _escolherOpcaoInteligente())
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'LLM',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

              // Caixa de diálogo separada, fixa no rodapé
              Align(
                alignment: Alignment.bottomCenter,
                child: SlideTransition(
                  position: _dialogueAnimation,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    constraints: const BoxConstraints(
                      maxWidth: 2000, // aumente a largura máxima
                      maxHeight: 700, // diminua a altura mínima
                      minWidth: 900, // opcional: garanta largura mínima
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Nome do personagem com indicador de emoção
                        Positioned(
                          top: -15,
                          left: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  personagemAtivo,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getEmotionColor(),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Indicador de LLM ativo
                        if (carregando)
                          Positioned(
                            top: -15,
                            right: 20,
                            child: FadeTransition(
                              opacity: _thinkingAnimation,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.psychology,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),

                        // Conteúdo principal do diálogo
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.1),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  key: ValueKey<String>(historia),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (historia.isEmpty && !carregando)
                                            ? 'Nenhuma resposta da IA.'
                                            : historia,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.white,
                                          height: 1.5,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      if (historia.isNotEmpty && !carregando)
                                        Container(
                                          margin:
                                              const EdgeInsets.only(top: 12),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 0,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Gerado por LLM | Tema: $temaHistoria | Complexidade: $nivelComplexidade',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              // Feedback e explicação
                              if (feedback.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.psychology,
                                            color: Colors.blue,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Análise LLM:',
                                            style: TextStyle(
                                              color: Colors.blue[300],
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        feedback,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (explicacao.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.amber.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.lightbulb,
                                            color: Colors.amber,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Dica do Sistema:',
                                            style: TextStyle(
                                              color: Colors.amber[300],
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        explicacao,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Barra de controles melhorada (mantida no rodapé)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.9),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OptionButton(
                        label: 'History',
                        onTap: showHistory,
                      ),
                      OptionButton(
                        label: 'Skip',
                        onTap: skipDialogue,
                      ),
                      OptionButton(
                        label: 'Auto',
                        isActive: autoMode,
                        onTap: toggleAutoMode,
                      ),
                      OptionButton(
                        label: 'Save',
                        onTap: () {
                          _salvarJogo();
                        },
                      ),
                      OptionButton(
                        label: 'Load',
                        onTap: () {
                          _carregarJogo();
                        },
                      ),
                      OptionButton(
                        label: 'Settings',
                        onTap: _showSettings,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEmotionColor() {
    // Retorna cor baseada na emoção atual (implementação simplificada)
    return Colors.green; // Padrão: neutro/feliz
  }

  Color _getOptionColor(int index) {
    // Cores diferentes para cada opção
    final colors = [Colors.blue, Colors.green, Colors.purple];
    return colors[index % colors.length].withOpacity(0.7);
  }

  String _getOptionHint(int index) {
    // Dicas baseadas no tipo de opção (análise simples)
    final hints = ['Ousado', 'Equilibrado', 'Cauteloso'];
    return hints[index % hints.length];
  }

  void _salvarJogo() {
    // Implementar salvamento do estado do jogo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Jogo salvo com sucesso!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _carregarJogo() {
    // Implementar carregamento do estado do jogo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Jogo carregado!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
