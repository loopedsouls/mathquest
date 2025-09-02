import 'package:flutter/material.dart';
import '../services/tutor_service.dart';
import '../widgets/option_button.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  GameScreenState createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // Estado do jogo
  bool carregando = false;
  bool autoMode = false;
  String historia = '';
  List<String> opcoes = [];
  String? respostaSelecionada;
  String feedback = '';
  String explicacao = '';

  late TutorService tutorService;

  // Configurações educacionais (adaptado para Matemática BNCC)
  String topicoAtual = 'Frações';
  String nivelDificuldade = 'médio';
  String serieEscolar = '6º ano';
  Map<String, dynamic> progressoAluno = {};

  // Animações
  late AnimationController _dialogueController;
  late Animation<Offset> _dialogueAnimation;

  @override
  void initState() {
    super.initState();
    tutorService = TutorService();
    _iniciarAnimacoes();
    carregarExercicio();
  }

  void _iniciarAnimacoes() {
    _dialogueController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _dialogueAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _dialogueController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> carregarExercicio() async {
    setState(() {
      carregando = true;
      respostaSelecionada = null;
      feedback = '';
      explicacao = '';
    });

    try {
      final prompt = _construirPromptEducacional();
      final resultado = await tutorService.gerarExercicioMatematico(
        prompt: prompt,
        contexto: progressoAluno,
        topico: topicoAtual,
        nivel: nivelDificuldade,
      );

      setState(() {
        historia = resultado['exercicio'] ?? 'Exercício não disponível';
        opcoes = List<String>.from(resultado['opcoes'] ?? []);
        carregando = false;
      });

      _salvarNoHistorico({
        'tipo': 'exercicio',
        'texto': historia,
        'timestamp': DateTime.now(),
      });

      if (autoMode) {
        _iniciarAutoAvaliacao();
      }
    } catch (e) {
      setState(() {
        historia = 'Erro ao gerar exercício. Tente novamente.';
        opcoes = [];
        carregando = false;
      });
    }
  }

  String _construirPromptEducacional() {
    return '''
      Tópico: $topicoAtual
      Nível: $nivelDificuldade
      Série: $serieEscolar
      Progresso do aluno: ${progressoAluno.toString()}
      BNCC: Gere um exercício matemático contextualizado, com explicação passo a passo e opções de resposta.
      Inclua feedback personalizado baseado no desempenho anterior.
    ''';
  }

  void _salvarNoHistorico(Map<String, dynamic> map) {
    // Implementar salvamento no histórico (ex.: SQLite)
  }

  void _iniciarAutoAvaliacao() {
    // Implementar lógica de auto-avaliação
  }

  Future<void> selecionarOpcao(int index) async {
    setState(() {
      carregando = true;
      respostaSelecionada = opcoes[index];
    });

    final escolha = opcoes[index];

    final analise = await _analisarResposta(escolha, index);
    _atualizarProgresso(escolha, analise);

    final resultado = await tutorService.avaliarResposta(escolha);

    setState(() {
      historia = resultado['explicacao'] ?? 'Explicação não disponível';
      feedback = resultado['feedback'] ?? '';
      explicacao = resultado['dica'] ?? '';
      respostaSelecionada = null;
      carregando = false;
    });
  }

  Future<Map<String, dynamic>> _analisarResposta(
      String resposta, int indice) async {
    // Lógica para analisar resposta matemática
    return {
      'correta': resposta == 'resposta_correta', // Placeholder
      'impacto': 'positivo',
      'dificuldade': nivelDificuldade,
    };
  }

  void _atualizarProgresso(String resposta, Map<String, dynamic> analise) {
    // Atualizar progresso baseado em resposta
    progressoAluno[topicoAtual] =
        (progressoAluno[topicoAtual] ?? 0) + (analise['correta'] ? 1 : 0);
  }

  void showHistory() {
    // Implementar exibição do histórico
  }

  void skipDialogue() {
    carregarExercicio();
  }

  void toggleAutoMode() {
    setState(() {
      autoMode = !autoMode;
    });
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurações Educacionais'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Tópico Matemático'),
                subtitle: Text(topicoAtual),
                trailing: const Icon(Icons.edit),
                onTap: () => _mostrarSeletorTopico(),
              ),
              ListTile(
                title: const Text('Dificuldade'),
                subtitle: Text(nivelDificuldade),
                trailing: const Icon(Icons.tune),
                onTap: () => _mostrarSeletorDificuldade(),
              ),
              ListTile(
                title: const Text('Série Escolar'),
                subtitle: Text(serieEscolar),
                trailing: const Icon(Icons.school),
                onTap: () => _mostrarSeletorSerie(),
              ),
              const Divider(),
              ListTile(
                title: const Text('Imprimir Exercício (Modo Desplugado)'),
                leading: const Icon(Icons.print),
                onTap: () {
                  Navigator.pop(context);
                  _imprimirExercicio();
                },
              ),
              ListTile(
                title: const Text('Relatório de Progresso'),
                leading: const Icon(Icons.bar_chart),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarRelatorio();
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

  void _mostrarSeletorTopico() {
    final topicos = ['Frações', 'Geometria', 'Porcentagem', 'Equações'];
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Escolher Tópico'),
        children: topicos
            .map((topico) => SimpleDialogOption(
                  onPressed: () {
                    setState(() {
                      topicoAtual = topico;
                    });
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Text(topico),
                ))
            .toList(),
      ),
    );
  }

  void _mostrarSeletorDificuldade() {
    final dificuldades = ['fácil', 'médio', 'difícil'];
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Nível de Dificuldade'),
        children: dificuldades
            .map((dificuldade) => SimpleDialogOption(
                  onPressed: () {
                    setState(() {
                      nivelDificuldade = dificuldade;
                    });
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Text(dificuldade),
                ))
            .toList(),
      ),
    );
  }

  void _mostrarSeletorSerie() {
    final series = ['5º ano', '6º ano', '7º ano', '8º ano', '9º ano'];
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Série Escolar'),
        children: series
            .map((serie) => SimpleDialogOption(
                  onPressed: () {
                    setState(() {
                      serieEscolar = serie;
                    });
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Text(serie),
                ))
            .toList(),
      ),
    );
  }

  void _imprimirExercicio() {
    // Lógica para imprimir exercício (modo desplugado)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exercício enviado para impressão!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _mostrarRelatorio() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Relatório de Progresso',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...progressoAluno.entries.map((entry) => ListTile(
                  title: Text(entry.key),
                  subtitle: Text('Pontos: ${entry.value}'),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          if (opcoes.isEmpty && !carregando) {
            carregarExercicio();
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1E1E2E),
                Color(0xFF2A2A3D),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              // Fundo animado
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(seconds: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Informações educacionais
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
                    'Tópico: $topicoAtual | Nível: $nivelDificuldade | Série: $serieEscolar',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              // Menu de opções (exercícios)
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
                          'Escolha a resposta:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...opcoes.asMap().entries.map((entry) {
                          final index = entry.key;
                          final opcao = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ElevatedButton(
                              onPressed: () => selecionarOpcao(index),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: respostaSelecionada == opcao
                                    ? (opcao == 'resposta_correta'
                                        ? Colors.green
                                        : Colors.red)
                                    : Colors.blueAccent,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                opcao,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

              // Caixa de diálogo (explicação/exercício)
              Align(
                alignment: Alignment.bottomCenter,
                child: SlideTransition(
                  position: _dialogueAnimation,
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          top: -20,
                          right: -20,
                          child: Opacity(
                            opacity: 0.1,
                            child: Image.asset(
                              'assets/images/brain.png',
                              width: 100,
                              height: 100,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 8),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Container(
                                  key: ValueKey<String>(historia),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (historia.isEmpty && !carregando)
                                            ? 'Nenhum exercício gerado.'
                                            : historia,
                                        style: const TextStyle(
                                          fontSize: 18,
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
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Gerado por IA | Tópico: $topicoAtual | Dificuldade: $nivelDificuldade',
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
                              if (feedback.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: feedback.startsWith('Parabéns')
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    feedback,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              if (explicacao.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    explicacao,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Barra de controles
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
                        label: 'Next',
                        onTap: skipDialogue,
                      ),
                      OptionButton(
                        label: 'Auto',
                        isActive: autoMode,
                        onTap: toggleAutoMode,
                      ),
                      OptionButton(
                        label: 'Print',
                        onTap: _imprimirExercicio,
                      ),
                      OptionButton(
                        label: 'Report',
                        onTap: _mostrarRelatorio,
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
}
