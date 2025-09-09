import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/modulo_bncc.dart';
import '../models/progresso_usuario.dart';
import '../models/conversa.dart';
import '../services/progresso_service.dart';
import '../theme/app_theme.dart';
import '../widgets/latex_markdown_widget.dart';
import '../widgets/queue_status_indicator.dart';
import '../services/ia_service.dart';
import '../services/conversa_service.dart';
import '../services/ai_queue_service.dart';
import '../../widgets/modern_components.dart';
import 'package:file_picker/file_picker.dart';

class ConversasSalvasScreen extends StatefulWidget {
  const ConversasSalvasScreen({super.key});

  @override
  State<ConversasSalvasScreen> createState() => _ConversasSalvasScreenState();
}

class _ConversasSalvasScreenState extends State<ConversasSalvasScreen> {
  List<Conversa> _conversas = [];
  bool _isLoading = true;
  String _filtroContexto = 'todos';

  @override
  void initState() {
    super.initState();
    _carregarConversas();
  }

  Future<void> _carregarConversas() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final conversas = await ConversaService.listarConversas();
      if (mounted) {
        setState(() {
          _conversas = conversas;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Conversa> get _conversasFiltradas {
    if (_filtroContexto == 'todos') {
      return _conversas;
    } else if (_filtroContexto == 'geral') {
      return _conversas.where((c) => c.contexto == 'geral').toList();
    } else {
      return _conversas.where((c) => c.contexto != 'geral').toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: AppTheme.darkBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkBackgroundColor,
              AppTheme.darkSurfaceColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isTablet),
              _buildFiltros(isTablet),
              Expanded(
                child: _buildListaConversas(isTablet),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: isTablet ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceColor.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Voltar',
          ),
          const SizedBox(width: 8),
          Container(
            width: isTablet ? 48 : 40,
            height: isTablet ? 48 : 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryLightColor],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              color: Colors.white,
              size: isTablet ? 24 : 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conversas Salvas',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: isTablet ? 18 : 16,
                  ),
                ),
                Text(
                  '${_conversasFiltradas.length} conversas',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.darkTextSecondaryColor,
                    fontSize: isTablet ? 12 : 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros(bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: isTablet ? 16 : 12,
      ),
      child: Row(
        children: [
          Text(
            'Filtrar: ',
            style: AppTheme.bodyMedium.copyWith(
              fontSize: isTablet ? 14 : 12,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFiltroChip('todos', 'Todas', isTablet),
                  const SizedBox(width: 8),
                  _buildFiltroChip('geral', 'Chat Geral', isTablet),
                  const SizedBox(width: 8),
                  _buildFiltroChip('modulos', 'Módulos', isTablet),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String valor, String label, bool isTablet) {
    final isSelected = _filtroContexto == valor;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filtroContexto = valor;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 8 : 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.darkSurfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? AppTheme.primaryColor : AppTheme.darkBorderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.darkTextSecondaryColor,
            fontSize: isTablet ? 12 : 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildListaConversas(bool isTablet) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final conversas = _conversasFiltradas;

    if (conversas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: isTablet ? 80 : 60,
              color: AppTheme.darkTextSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma conversa encontrada',
              style: AppTheme.headingSmall.copyWith(
                color: AppTheme.darkTextSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Inicie uma conversa com a IA para que ela apareça aqui',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.darkTextSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: isTablet ? 16 : 12,
      ),
      itemCount: conversas.length,
      itemBuilder: (context, index) {
        final conversa = conversas[index];
        return _buildConversaCard(conversa, isTablet);
      },
    );
  }

  Widget _buildConversaCard(Conversa conversa, bool isTablet) {
    final ultimaMensagem = conversa.mensagens.isNotEmpty
        ? conversa.mensagens.last.text
        : 'Conversa vazia';

    return Container(
        margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
        child: ModernCard(
          child: InkWell(
            onTap: () => _abrirConversa(conversa),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: isTablet ? 40 : 32,
                        height: isTablet ? 40 : 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: conversa.contexto == 'geral'
                                ? [
                                    AppTheme.primaryColor,
                                    AppTheme.primaryLightColor
                                  ]
                                : [AppTheme.accentColor, AppTheme.successColor],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          conversa.contexto == 'geral'
                              ? Icons.smart_toy_rounded
                              : Icons.school_rounded,
                          color: Colors.white,
                          size: isTablet ? 20 : 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conversa.titulo,
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: isTablet ? 16 : 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              conversa.contexto == 'geral'
                                  ? 'Chat Geral'
                                  : conversa.contexto,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.darkTextSecondaryColor,
                                fontSize: isTablet ? 12 : 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _deletarConversa(conversa),
                        icon: const Icon(Icons.delete_outline_rounded),
                        iconSize: isTablet ? 20 : 18,
                        tooltip: 'Deletar conversa',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ultimaMensagem,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.darkTextSecondaryColor,
                      fontSize: isTablet ? 13 : 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${conversa.mensagens.length} mensagens',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                          fontSize: isTablet ? 11 : 10,
                        ),
                      ),
                      Text(
                        _formatarData(conversa.ultimaAtualizacao),
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                          fontSize: isTablet ? 11 : 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  String _formatarData(DateTime data) {
    final agora = DateTime.now();
    final diferenca = agora.difference(data);

    if (diferenca.inDays == 0) {
      return '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
    } else if (diferenca.inDays == 1) {
      return 'Ontem';
    } else if (diferenca.inDays < 7) {
      return '${diferenca.inDays} dias atrás';
    } else {
      return '${data.day}/${data.month}/${data.year}';
    }
  }

  void _abrirConversa(Conversa conversa) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          mode: ChatMode.general,
          conversaInicial: conversa,
        ),
      ),
    );
  }

  Future<void> _deletarConversa(Conversa conversa) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurfaceColor,
        title: Text(
          'Deletar Conversa',
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Tem certeza que deseja deletar a conversa "${conversa.titulo}"?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.darkTextSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await ConversaService.deletarConversa(conversa.id);
      _carregarConversas();
    }
  }
}

enum ChatMode {
  general, // Chat geral de IA
  module, // Chat específico do módulo
  sidebar, // Chat com sidebar
  saved, // Listagem de conversas salvas
}

class ChatScreen extends StatefulWidget {
  final ChatMode mode;
  final ModuloBNCC? modulo;
  final ProgressoUsuario? progresso;
  final bool isOfflineMode;
  final Conversa? conversaInicial;
  final String? promptPreconfigurado;
  final VoidCallback? onBackPressed;

  const ChatScreen({
    super.key,
    required this.mode,
    this.modulo,
    this.progresso,
    this.isOfflineMode = false,
    this.conversaInicial,
    this.promptPreconfigurado,
    this.onBackPressed,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  // Chat
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FocusNode _textFieldFocusNode = FocusNode();

  // Serviços
  late MathTutorService _tutorService;
  late AIQueueService _aiQueueService;

  // Estado
  bool _isLoading = false;
  bool _tutorInitialized = false;
  late AnimationController _typingAnimationController;
  bool _showConversationsList =
      false; // Novo estado para controlar se mostra lista de conversas ou chat - false para modo módulo

  // Novos campos para aulas
  int _totalAulas = 0;
  int _aulaAtual = 1;

  // Configurações de IA
  bool _useGemini = true;
  String _modeloOllama = 'gemma3:1b';
  String _selectedAI =
      'gemini'; // Novo campo para armazenar o tipo de IA selecionado

  // Conversas
  List<Conversa> _conversas = [];
  bool _loadingConversas = true;
  Conversa? _conversaAtual;
  String _contextoAtual = 'geral';
  String _filtroContexto = 'todos';

  @override
  void initState() {
    super.initState();
    _aiQueueService = AIQueueService();
    _initializeTypingAnimation();
    _initializeTutor();

    // Define se deve mostrar lista de conversas baseado no modo
    _showConversationsList = widget.mode != ChatMode.module;

    // Listener para atualizar o estado do botão de enviar
    _textController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // Configurar FocusNode para detectar Enter e Shift+Enter
    _textFieldFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          // Se Shift+Enter, inserir nova linha
          if (HardwareKeyboard.instance.isShiftPressed) {
            final currentText = _textController.text;
            final selection = _textController.selection;
            final newText =
                '${currentText.substring(0, selection.start)}\n${currentText.substring(selection.end)}';
            _textController.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(
                offset: selection.start + 1,
              ),
            );
            return KeyEventResult.handled;
          } else {
            // Se apenas Enter, enviar mensagem
            if (_textController.text.trim().isNotEmpty && _tutorInitialized) {
              _sendMessage(_textController.text);
            }
            return KeyEventResult.handled;
          }
        }
      }
      return KeyEventResult.ignored;
    };

    if (widget.mode == ChatMode.sidebar ||
        widget.mode == ChatMode.saved ||
        widget.mode == ChatMode.module ||
        widget.mode == ChatMode.general) {
      _carregarConversas();
    }

    if (widget.modulo != null) {
      _contextoAtual = widget.modulo!.titulo;
      // Inicializa dados das aulas se disponível no progresso
      if (widget.progresso != null) {
        final chaveModulo =
            '${widget.modulo!.unidadeTematica}_${widget.modulo!.anoEscolar}';
        _totalAulas = widget.progresso!.totalAulasPorModulo[chaveModulo] ?? 0;
        _aulaAtual = widget.progresso!.obterProximaAula(
            widget.modulo!.unidadeTematica, widget.modulo!.anoEscolar);
      }
    }

    if (widget.conversaInicial != null) {
      _carregarConversa(widget.conversaInicial!);
    } else if (widget.mode == ChatMode.general) {
      // Para o modo geral, iniciar automaticamente uma nova conversa
      _novaConversa();
    } else if (widget.mode == ChatMode.module) {
      // Para o modo módulo, tentar carregar conversa existente ou deixar vazio
      _carregarConversaModuloExistente();
    }
  }

  void _initializeTypingAnimation() {
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _typingAnimationController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeTutor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedAI = prefs.getString('selected_ai') ?? 'gemini';
      final apiKey = prefs.getString('gemini_api_key');
      final modeloOllama = prefs.getString('modelo_ollama') ?? 'gemma3:1b';

      _selectedAI = selectedAI; // Armazenar o tipo de IA selecionado
      _useGemini = selectedAI == 'gemini';
      _modeloOllama = modeloOllama;

      // Define o nome da IA baseado na configuração
      if (_useGemini) {
      } else if (selectedAI == 'flutter_gemma') {
      } else {}

      // Verifica se a configuração está completa
      if (_useGemini && (apiKey == null || apiKey.isEmpty)) {
        if (mounted) {
          setState(() {
            _tutorInitialized = false;
          });
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('API Key do Gemini não configurada'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Inicializa o serviço de IA
      AIService aiService;
      if (_useGemini) {
        aiService = GeminiService(apiKey: apiKey!);
      } else if (selectedAI == 'flutter_gemma') {
        aiService = FlutterGemmaService();
      } else {
        aiService = OllamaService(defaultModel: _modeloOllama);
      }

      _tutorService = MathTutorService(aiService: aiService);
      _aiQueueService.initialize(_tutorService);

      if (mounted) {
        setState(() {
          _tutorInitialized = true;
        });
      }

      // Envia mensagem de boas-vindas se necessário
      // Removido daqui - será chamado após carregamento da conversa
    } catch (e) {
      if (mounted) {
        setState(() {
          _tutorInitialized = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao inicializar IA: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _sendWelcomeMessage() async {
    String welcomePrompt;

    switch (widget.mode) {
      case ChatMode.module:
        // Para módulos, gerar mensagem completa com estrutura de aulas
        welcomePrompt = '''
Você é um tutor de matemática especializado na BNCC, especificamente no módulo "${widget.modulo!.titulo}" 
do ${widget.modulo!.anoEscolar}, unidade temática "${widget.modulo!.unidadeTematica}".

**IMPORTANTE**: 
1. Dê uma mensagem de boas-vindas calorosa e apresente-se como tutor do módulo
2. Explique TUDO que o aluno vai aprender neste módulo de forma empolgante e detalhada
3. Defina quantas aulas terá este módulo (entre 5 a 10 aulas, baseado na complexidade do conteúdo)
4. Liste os tópicos principais que serão abordados em cada aula
5. Use emojis e formatação Markdown

Responda EXATAMENTE no seguinte formato (mantendo a estrutura):

# 🎓 Bem-vindo ao Módulo: [TÍTULO DO MÓDULO]

Olá! Eu sou seu tutor de matemática e estou muito animado para estudar com você! 

## 📚 O que você vai aprender

[Explicação completa e empolgante sobre o que será aprendido]

## 🗓️ Estrutura do Curso

Este módulo terá **X aulas** organizadas da seguinte forma:

**Aula 1:** [Tópico]
**Aula 2:** [Tópico]
[... continue até a última aula]

## 🚀 Vamos começar?

Agora você pode escolher uma das opções abaixo para continuar seus estudos!

[BOTÃO:Quiz do Conteúdo]
[BOTÃO:Aula 1]
[BOTÃO:Curiosidades do Assunto]
''';
        break;
      default:
        welcomePrompt = '''
Você é um assistente de matemática amigável e educativo. 
Dê as boas-vindas ao usuário de forma calorosa e apresente-se.
Use emojis e formatação Markdown.
''';
    }

    try {
      final response = await _aiQueueService.addRequest(
        conversaId: _getConversationId(),
        prompt: welcomePrompt,
        userMessage: '',
        useGemini: _useGemini,
        modeloOllama: _modeloOllama,
      );

      // Se for módulo, extrair o número de aulas da resposta
      if (widget.mode == ChatMode.module) {
        _extrairTotalAulasResposta(response.text);
      }

      _addMessage(ChatMessage(
        text: response.text,
        isUser: false,
        timestamp: DateTime.now(),
        aiProvider: _useGemini
            ? 'gemini'
            : (_selectedAI == 'flutter_gemma' ? 'flutter_gemma' : 'ollama'),
      ));

      // Adicionar botões de ação se for módulo
      if (widget.mode == ChatMode.module) {
        _adicionarBotoesAcao();
      }
    } catch (e) {
      String fallbackMessage;
      if (widget.mode == ChatMode.module) {
        fallbackMessage = '''
# 🎓 Bem-vindo ao Módulo: ${widget.modulo!.titulo}

Olá! Estou aqui para ser seu tutor neste módulo de matemática! 😊

## 📚 O que você vai aprender
${widget.modulo!.descricao}

## 🚀 Vamos começar?
Escolha uma das opções abaixo para continuar seus estudos!

[BOTÃO:Quiz do Conteúdo]
[BOTÃO:Aula 1]
[BOTÃO:Curiosidades do Assunto]
''';
        _totalAulas = 5; // Valor padrão
        if (widget.progresso != null && widget.modulo != null) {
          widget.progresso!.definirTotalAulas(widget.modulo!.unidadeTematica,
              widget.modulo!.anoEscolar, _totalAulas);
        }
      } else {
        fallbackMessage =
            'Olá! Estou aqui para ajudar com matemática. Como posso ajudar você hoje? 😊';
      }

      _addMessage(ChatMessage(
        text: fallbackMessage,
        isUser: false,
        timestamp: DateTime.now(),
        aiProvider: _useGemini
            ? 'gemini'
            : (_selectedAI == 'flutter_gemma' ? 'flutter_gemma' : 'ollama'),
      ));

      if (widget.mode == ChatMode.module) {
        _adicionarBotoesAcao();
      }
    }
  }

  // Método para extrair o número total de aulas da resposta da IA
  void _extrairTotalAulasResposta(String resposta) {
    // Busca por padrões como "X aulas", "terá 5 aulas", etc.
    final regex = RegExp(r'(\d+)\s*aulas?', caseSensitive: false);
    final match = regex.firstMatch(resposta);

    if (match != null) {
      _totalAulas = int.tryParse(match.group(1)!) ?? 5;
    } else {
      _totalAulas = 5; // Valor padrão
    }

    // Salva no progresso do usuário
    if (widget.progresso != null && widget.modulo != null) {
      widget.progresso!.definirTotalAulas(widget.modulo!.unidadeTematica,
          widget.modulo!.anoEscolar, _totalAulas);
      _aulaAtual = widget.progresso!.obterProximaAula(
          widget.modulo!.unidadeTematica, widget.modulo!.anoEscolar);
      ProgressoService.salvarProgresso(widget.progresso!);
    }
  }

  // Método para adicionar botões de ação após a mensagem de boas-vindas
  void _adicionarBotoesAcao() {
    final botaoAula = widget.progresso != null && widget.modulo != null
        ? widget.progresso!.obterProximaAula(
            widget.modulo!.unidadeTematica, widget.modulo!.anoEscolar)
        : 1;

    final buttons = [
      ChatButton(
        text: 'Quiz do Conteúdo',
        action: 'quiz',
        icon: '🧩',
        description: 'Teste seus conhecimentos com perguntas sobre o módulo',
      ),
      ChatButton(
        text: 'Aula $botaoAula',
        action: 'aula_$botaoAula',
        icon: '📖',
        description: botaoAula == 1
            ? 'Comece sua primeira aula'
            : 'Continue com a próxima aula',
      ),
      ChatButton(
        text: 'Curiosidades do Assunto',
        action: 'curiosidades',
        icon: '🔍',
        description: 'Descubra fatos interessantes e aplicações práticas',
      ),
    ];

    const mensagemComBotoes = '''
## 🎯 **Escolha uma opção para continuar:**

Use os botões abaixo para navegar pelo módulo:
''';

    // Adiciona mensagem com botões clicáveis
    setState(() {
      _messages.add(ChatMessage(
        text: mensagemComBotoes,
        isUser: false,
        timestamp: DateTime.now(),
        aiProvider: 'system',
        buttons: buttons,
      ));
    });
  }

  // Método para detectar se o texto é um clique em botão
  bool _detectarCliqueBotao(String texto) {
    final textoLower = texto.toLowerCase();
    return textoLower.contains('quiz do conteúdo') ||
        textoLower.contains('aula') ||
        textoLower.contains('curiosidades do assunto') ||
        textoLower.contains('revisar módulo');
  }

  // Método para detectar e processar cliques nos botões
  Future<void> _processarCliqueBotao(String texto) async {
    String prompt = '';

    if (texto.toLowerCase().contains('quiz do conteúdo')) {
      prompt = _gerarPromptQuiz();
    } else if (texto.toLowerCase().contains('aula')) {
      // Extrai o número da aula
      final regexAula = RegExp(r'aula\s*(\d+)', caseSensitive: false);
      final match = regexAula.firstMatch(texto);
      final numeroAula = match != null ? int.tryParse(match.group(1)!) ?? 1 : 1;
      prompt = _gerarPromptAula(numeroAula);
    } else if (texto.toLowerCase().contains('curiosidades')) {
      prompt = _gerarPromptCuriosidades();
    }

    if (prompt.isNotEmpty) {
      await _enviarPromptPersonalizado(prompt, texto);
    }
  }

  String _gerarPromptQuiz() {
    return '''
Você é um tutor de matemática especializado na BNCC. Crie um quiz de 5 perguntas sobre o módulo "${widget.modulo!.titulo}" 
do ${widget.modulo!.anoEscolar}, unidade temática "${widget.modulo!.unidadeTematica}".

O quiz deve:
- Ter perguntas de múltipla escolha com 4 alternativas (A, B, C, D)
- Ser adequado ao nível escolar especificado
- Abordar conceitos importantes do módulo
- Incluir questões práticas e aplicadas
- Ter dificuldade progressiva

Formate como:

**🎯 Quiz: ${widget.modulo!.titulo}**

**Questão 1:** [pergunta]
A) [alternativa]
B) [alternativa] 
C) [alternativa]
D) [alternativa]

[Continue para as 5 questões]

**Gabarito:**
1-A, 2-B, 3-C, 4-D, 5-A (exemplo)

---

## 🎯 **Escolha uma opção para continuar:**

### 🧩 Quiz do Conteúdo
*Gere um novo quiz sobre o módulo*

### 📖 Aula $_aulaAtual
*${_aulaAtual <= _totalAulas ? 'Continue com a próxima aula' : 'Revisar conteúdo do módulo'}*

### 🔍 Curiosidades do Assunto  
*Descubra fatos interessantes e aplicações práticas*

---

Use emojis e formatação Markdown!
''';
  }

  String _gerarPromptAula(int numeroAula) {
    return '''
Você é um tutor de matemática especializado na BNCC. Crie uma aula completa e detalhada sobre o módulo "${widget.modulo!.titulo}" 
do ${widget.modulo!.anoEscolar}, unidade temática "${widget.modulo!.unidadeTematica}".

**AULA $numeroAula**

A aula deve incluir:
1. Título da aula
2. Objetivos de aprendizagem
3. Explicação teórica clara e detalhada com exemplos
4. Exercícios práticos (3-5 exercícios com resolução)
5. Dicas importantes
6. Resumo dos pontos principais

Use formatação Markdown e LaTeX para fórmulas matemáticas.
Seja didático e use linguagem apropriada para ${widget.modulo!.anoEscolar}.

Ao final da aula, se for a aula $_totalAulas (última), parabenize o aluno pela conclusão do módulo!

---

## 🎯 **Escolha uma opção para continuar:**

### 🧩 Quiz do Conteúdo
*Teste seus conhecimentos sobre o módulo*

### 📖 ${numeroAula < _totalAulas ? 'Aula ${numeroAula + 1}' : 'Revisar Módulo'}
*${numeroAula < _totalAulas ? 'Continue com a próxima aula' : 'Revisar todo o conteúdo do módulo'}*

### 🔍 Curiosidades do Assunto  
*Descubra fatos interessantes e aplicações práticas*

---
''';
  }

  String _gerarPromptCuriosidades() {
    return '''
Você é um tutor de matemática especializado na BNCC. Compartilhe curiosidades fascinantes sobre o módulo "${widget.modulo!.titulo}" 
do ${widget.modulo!.anoEscolar}, unidade temática "${widget.modulo!.unidadeTematica}".

Inclua:
1. 🌟 Fatos históricos interessantes sobre o tema
2. 🔬 Aplicações na vida real e profissões que usam esses conceitos
3. 🎯 Dicas e macetes para facilitar o aprendizado
4. 🧩 Problemas curiosos ou paradoxos matemáticos relacionados
5. 🚀 Como esse conhecimento se conecta com outros tópicos de matemática

Use emojis, seja envolvente e desperte a curiosidade do aluno!

---

## 🎯 **Escolha uma opção para continuar:**

### 🧩 Quiz do Conteúdo
*Teste seus conhecimentos sobre o módulo*

### 📖 Aula $_aulaAtual
*${_aulaAtual <= _totalAulas ? 'Continue com a próxima aula' : 'Revisar conteúdo do módulo'}*

### 🔍 Curiosidades do Assunto  
*Descubra mais fatos interessantes*

---
''';
  }

  Future<void> _enviarPromptPersonalizado(
      String prompt, String acaoUsuario) async {
    // Adiciona a ação do usuário como mensagem
    _addMessage(ChatMessage(
      text: acaoUsuario,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    _typingAnimationController.repeat();

    try {
      final response = await _aiQueueService.addRequest(
        conversaId: _getConversationId(),
        prompt: prompt,
        userMessage: acaoUsuario,
        useGemini: _useGemini,
        modeloOllama: _modeloOllama,
      );

      _addMessage(ChatMessage(
        text: response.text,
        isUser: false,
        timestamp: DateTime.now(),
        aiProvider: _useGemini
            ? 'gemini'
            : (_selectedAI == 'flutter_gemma' ? 'flutter_gemma' : 'ollama'),
      ));

      // Se foi uma aula completada, atualizar progresso
      if (acaoUsuario.toLowerCase().contains('aula') &&
          widget.progresso != null &&
          widget.modulo != null) {
        widget.progresso!.completarAula(
            widget.modulo!.unidadeTematica, widget.modulo!.anoEscolar);
        _aulaAtual = widget.progresso!.obterProximaAula(
            widget.modulo!.unidadeTematica, widget.modulo!.anoEscolar);
        await ProgressoService.salvarProgresso(widget.progresso!);
      }
    } catch (e) {
      _addMessage(ChatMessage(
        text:
            'Desculpe, tive um probleminha para responder. Pode tentar novamente? 😅',
        isUser: false,
        timestamp: DateTime.now(),
        aiProvider: _useGemini
            ? 'gemini'
            : (_selectedAI == 'flutter_gemma' ? 'flutter_gemma' : 'ollama'),
      ));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _typingAnimationController.stop();
    }
  }

  String _getConversationId() {
    if (_conversaAtual != null) {
      return _conversaAtual!.id;
    }

    switch (widget.mode) {
      case ChatMode.module:
        return 'module_${widget.modulo!.titulo}';
      case ChatMode.sidebar:
        return 'sidebar_chat_${DateTime.now().millisecondsSinceEpoch}';
      default:
        return 'ai_chat_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });

    // Auto-scroll para a última mensagem
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || !_tutorInitialized) return;

    // Verificar se é um clique em botão de ação no modo módulo
    if (widget.mode == ChatMode.module && _detectarCliqueBotao(text)) {
      await _processarCliqueBotao(text);
      return;
    }

    _addMessage(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    _textController.clear();
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    _typingAnimationController.repeat();

    try {
      final contextPrompt = _buildContextPrompt(text);

      final response = await _aiQueueService.addRequest(
        conversaId: _getConversationId(),
        prompt: contextPrompt,
        userMessage: text,
        useGemini: _useGemini,
        modeloOllama: _modeloOllama,
      );

      _addMessage(ChatMessage(
        text: response.text,
        isUser: false,
        timestamp: DateTime.now(),
        aiProvider: _useGemini
            ? 'gemini'
            : (_selectedAI == 'flutter_gemma' ? 'flutter_gemma' : 'ollama'),
      ));
    } catch (e) {
      _addMessage(ChatMessage(
        text:
            'Desculpe, tive um probleminha para responder. Pode perguntar novamente? 😅',
        isUser: false,
        timestamp: DateTime.now(),
        aiProvider: _useGemini
            ? 'gemini'
            : (_selectedAI == 'flutter_gemma' ? 'flutter_gemma' : 'ollama'),
      ));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _typingAnimationController.stop();
    }
  }

  String _buildContextPrompt(String userMessage) {
    // Se há um prompt preconfigurado, use-o
    if (widget.promptPreconfigurado != null) {
      return '''
${widget.promptPreconfigurado}

Conversa anterior:
${_messages.where((m) => !m.isUser).take(3).map((m) => "Tutor: ${m.text}").join("\n")}
${_messages.where((m) => m.isUser).take(3).map((m) => "Usuário: ${m.text}").join("\n")}

Pergunta atual do aluno: "$userMessage"

Responda de forma educativa, clara e apropriada.
Use emojis quando apropriado e sempre formate sua resposta em Markdown com LaTeX.
''';
    }

    switch (widget.mode) {
      case ChatMode.module:
        return '''
Você é um tutor de matemática especializado na BNCC, especificamente no módulo "${widget.modulo!.titulo}"
do ${widget.modulo!.anoEscolar}, unidade temática "${widget.modulo!.unidadeTematica}".

Descrição do módulo: ${widget.modulo!.descricao}

**IMPORTANTE**: Use formatação Markdown e LaTeX para deixar suas respostas organizadas.

Conversa anterior:
${_messages.where((m) => !m.isUser).take(3).map((m) => "Tutor: ${m.text}").join("\n")}
${_messages.where((m) => m.isUser).take(3).map((m) => "Usuário: ${m.text}").join("\n")}

Pergunta atual do aluno: "$userMessage"

Responda de forma educativa, clara e apropriada para a idade.
Use emojis quando apropriado e sempre formate sua resposta em Markdown com LaTeX.
''';

      default:
        return '''
Você é um assistente de matemática educativo e amigável.

**IMPORTANTE**: Use formatação Markdown e LaTeX para deixar suas respostas organizadas e legíveis.

Conversa anterior:
${_messages.where((m) => !m.isUser).take(3).map((m) => "Assistente: ${m.text}").join("\n")}
${_messages.where((m) => m.isUser).take(3).map((m) => "Usuário: ${m.text}").join("\n")}

Pergunta atual do usuário: "$userMessage"

Responda de forma educativa, clara e apropriada.
Use emojis quando apropriado e sempre formate sua resposta em Markdown com LaTeX.
''';
    }
  }

  // Métodos de conversas
  Future<void> _carregarConversas() async {
    if (mounted) {
      setState(() => _loadingConversas = true);
    }
    try {
      final conversas = await ConversaService.listarConversas();
      if (mounted) {
        setState(() {
          _conversas = conversas;
          _loadingConversas = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingConversas = false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar conversas: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _carregarConversa(Conversa conversa) async {
    if (mounted) {
      setState(() {
        _conversaAtual = conversa;
        _messages.clear();
        _messages.addAll(conversa.mensagens);
        _contextoAtual = conversa.contexto;
      });
    }

    // Auto-scroll para a última mensagem
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    // Não verificar boas-vindas aqui - será feito pelo método que chamou _carregarConversa
  }

  // Método para verificar se deve enviar mensagem de boas-vindas
  Future<void> _verificarEnviarBoasVindas() async {
    // Só envia boas-vindas se o tutor estiver inicializado
    if (!_tutorInitialized) return;

    // Para módulos: só envia se não há conversa atual E mensagens estão vazias
    if (widget.mode == ChatMode.module &&
        _conversaAtual == null &&
        _messages.isEmpty) {
      await _sendWelcomeMessage();
    }
    // Para outros modos: só envia se não há conversa atual
    else if (widget.mode != ChatMode.saved &&
        widget.mode != ChatMode.module &&
        _conversaAtual == null) {
      await _sendWelcomeMessage();
    }
  }

  Future<void> _carregarConversaModuloExistente() async {
    if (widget.modulo == null) return;

    try {
      final conversas = await ConversaService.listarConversas();
      final conversaId = 'module_${widget.modulo!.titulo}';

      // Debug: imprimir informações sobre as conversas encontradas
      print('Procurando conversa com ID: $conversaId');
      print('Total de conversas encontradas: ${conversas.length}');
      print('IDs das conversas: ${conversas.map((c) => c.id).toList()}');

      final conversaModulo = conversas
          .where(
            (conversa) => conversa.id == conversaId,
          )
          .toList();

      if (conversaModulo.isNotEmpty) {
        final conversa = conversaModulo.first;
        print(
            'Conversa encontrada: ${conversa.id} com ${conversa.mensagens.length} mensagens');
        // Se já existe uma conversa para o módulo, carregar ela
        _carregarConversa(conversa);
      } else {
        print('Nenhuma conversa encontrada para o módulo, criando nova');
        // Se não existe conversa, aguardar inicialização do tutor e enviar boas-vindas
        if (mounted) {
          setState(() {
            _contextoAtual = widget.modulo!.titulo;
          });
        }

        // Aguardar inicialização do tutor se necessário
        if (!_tutorInitialized) {
          print('Aguardando inicialização do tutor...');
          await _initializeTutor();
        }

        await _sendWelcomeMessage();
      }
    } catch (e) {
      print('Erro ao carregar conversa do módulo: $e');
      // Em caso de erro, tentar enviar boas-vindas mesmo assim
      if (mounted) {
        setState(() {
          _contextoAtual = widget.modulo!.titulo;
        });
      }

      // Aguardar inicialização do tutor se necessário
      if (!_tutorInitialized) {
        await _initializeTutor();
      }

      await _sendWelcomeMessage();
    }
  }

  void _novaConversa() {
    if (mounted) {
      setState(() {
        _conversaAtual = null;
        _messages.clear();
        _contextoAtual = widget.modulo?.titulo ?? 'geral';
        _showConversationsList = false; // Garante que estamos no chat
      });
    }

    // Verificar se deve enviar mensagem de boas-vindas
    _verificarEnviarBoasVindas();
  }

  void _abrirConversaNoChat(Conversa conversa) {
    _carregarConversa(conversa);
    if (mounted) {
      setState(() {
        _showConversationsList = false;
      });
    }
  }

  void _gerarQuizModulo() async {
    if (widget.modulo == null) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }
    _typingAnimationController.repeat();

    try {
      final quizPrompt = '''
Você é um tutor de matemática especializado na BNCC. Crie um quiz de 5 perguntas sobre o módulo "${widget.modulo!.titulo}" 
do ${widget.modulo!.anoEscolar}, unidade temática "${widget.modulo!.unidadeTematica}".

O quiz deve:
- Ter perguntas de múltipla escolha com 4 alternativas (A, B, C, D)
- Ser adequado ao nível escolar especificado
- Abordar conceitos importantes do módulo
- Incluir questões práticas e aplicadas
- Ter dificuldade progressiva

Formate como:

**🎯 Quiz: ${widget.modulo!.titulo}**

**Questão 1:** [pergunta]
A) [alternativa]
B) [alternativa] 
C) [alternativa]
D) [alternativa]

[Continue para as 5 questões]

**Gabarito:**
1-A, 2-B, 3-C, 4-D, 5-A (exemplo)

Use emojis e formatação Markdown para deixar mais atrativo!
''';

      final response = await _aiQueueService.addRequest(
        conversaId: _getConversationId(),
        prompt: quizPrompt,
        userMessage: 'Gerar quiz do módulo',
        useGemini: _useGemini,
        modeloOllama: _modeloOllama,
      );

      _addMessage(ChatMessage(
        text: response.text,
        isUser: false,
        timestamp: DateTime.now(),
        aiProvider: _useGemini
            ? 'gemini'
            : (_selectedAI == 'flutter_gemma' ? 'flutter_gemma' : 'ollama'),
      ));
    } catch (e) {
      _addMessage(ChatMessage(
        text: 'Desculpe, não foi possível gerar o quiz. Tente novamente. 😅',
        isUser: false,
        timestamp: DateTime.now(),
        aiProvider: _useGemini
            ? 'gemini'
            : (_selectedAI == 'flutter_gemma' ? 'flutter_gemma' : 'ollama'),
      ));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _typingAnimationController.stop();
    }
  }

  void _adicionarArquivo() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        ScaffoldMessenger.of(mounted as BuildContext).showSnackBar(
          SnackBar(
            content: Text('Arquivo selecionado: ${file.name}'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        try {
          final file = result.files.first;

          // Verificar se os bytes estão disponíveis
          if (file.bytes == null) {
            ScaffoldMessenger.of(mounted as BuildContext).showSnackBar(
              SnackBar(
                content:
                    Text('Erro: Não foi possível ler o arquivo ${file.name}'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
            return;
          }

          // Ler o conteúdo do arquivo localmente
          final fileBytes = file.bytes!;
          String fileContent = '';

          // Tentar decodificar como texto se for um arquivo de texto comum
          if (file.name.endsWith('.txt') ||
              file.name.endsWith('.md') ||
              file.name.endsWith('.json')) {
            fileContent = String.fromCharCodes(fileBytes);
          } else if (file.name.endsWith('.pdf')) {
            // Para PDFs, você pode usar uma biblioteca como pdf_text ou similar para extrair texto
            // Por enquanto, apenas indicar que é um PDF
            fileContent =
                '[Conteúdo do PDF: ${file.name}] - Extração de texto não implementada localmente';
          } else if (file.name.endsWith('.png') ||
              file.name.endsWith('.jpg') ||
              file.name.endsWith('.jpeg')) {
            // Para imagens, codificar em base64 para enviar à IA
            fileContent =
                'data:image/${file.name.split('.').last};base64,${base64Encode(fileBytes)}';
          } else {
            fileContent =
                '[Arquivo binário: ${file.name}] - Tipo não suportado para processamento local';
          }

          // Adicionar mensagem no chat sobre o arquivo
          _addMessage(ChatMessage(
            text: 'Arquivo anexado: ${file.name}\nConteúdo: $fileContent',
            isUser: true,
            timestamp: DateTime.now(),
          ));

          // Enviar para a IA processar o conteúdo do arquivo
          if (_tutorInitialized) {
            final promptComArquivo = '''
      Você recebeu um arquivo anexado pelo usuário. Aqui está o conteúdo:

      $fileContent

      Analise este conteúdo e forneça uma resposta útil relacionada ao contexto de matemática e educação.
      Se for uma imagem, descreva o que vê e como se relaciona com matemática.
      Se for texto, resuma ou explique o conteúdo.
      ''';

            await _sendMessage(promptComArquivo);
          }

          ScaffoldMessenger.of(mounted as BuildContext).showSnackBar(
            SnackBar(
              content: Text('Arquivo "${file.name}" processado localmente!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(mounted as BuildContext).showSnackBar(
            SnackBar(
              content: Text('Erro ao processar arquivo: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(mounted as BuildContext).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar arquivo: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  // UI
  @override
  Widget build(BuildContext context) {
    // Se está mostrando a lista de conversas, mostra a tela de conversas
    if (_showConversationsList) {
      return _buildConversationsListScreen();
    }
    // Caso contrário, mostra o chat
    return _buildChatScreen();
  }

  Widget _buildChatScreen() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.darkBackgroundColor,
      drawer: _buildConversationsDrawer(isTablet),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkBackgroundColor,
              AppTheme.darkSurfaceColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildChatHeader(isTablet),
              Expanded(child: _buildChatArea(isTablet)),
              _buildInputArea(isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationsDrawer(bool isTablet) {
    return Drawer(
      backgroundColor: AppTheme.darkSurfaceColor,
      child: SafeArea(
        child: StatefulBuilder(
          builder: (context, setState) {
            String searchQuery = '';

            List<Conversa> getConversasFiltradas() {
              if (searchQuery.isEmpty) {
                return _conversas;
              }
              return _conversas.where((conversa) {
                final titulo = conversa.titulo.toLowerCase();
                final ultimaMensagem = conversa.mensagens.isNotEmpty
                    ? conversa.mensagens.last.text.toLowerCase()
                    : '';
                final query = searchQuery.toLowerCase();

                return titulo.contains(query) || ultimaMensagem.contains(query);
              }).toList();
            }

            final conversasFiltradas = getConversasFiltradas();

            return Column(
              children: [
                // Header do drawer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.darkBorderColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryLightColor
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.history_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Conversas Salvas',
                              style: AppTheme.headingMedium.copyWith(
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${conversasFiltradas.length} conversa${conversasFiltradas.length != 1 ? 's' : ''}',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.darkTextSecondaryColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Campo de busca
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.darkBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.darkBorderColor,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.darkTextPrimaryColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar conversas...',
                        hintStyle: AppTheme.bodySmall.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppTheme.darkTextSecondaryColor,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ),

                // Filtros
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'Filtrar:',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('todos', 'Todas', isTablet),
                              const SizedBox(width: 8),
                              _buildFilterChip('geral', 'Chat Geral', isTablet),
                              const SizedBox(width: 8),
                              _buildFilterChip('modulos', 'Módulos', isTablet),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de conversas
                Expanded(
                  child: _loadingConversas
                      ? const Center(child: CircularProgressIndicator())
                      : conversasFiltradas.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    searchQuery.isEmpty
                                        ? Icons.chat_bubble_outline_rounded
                                        : Icons.search_off_rounded,
                                    size: 48,
                                    color: AppTheme.darkTextSecondaryColor,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    searchQuery.isEmpty
                                        ? 'Nenhuma conversa encontrada'
                                        : 'Nenhuma conversa encontrada para "$searchQuery"',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.darkTextSecondaryColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    searchQuery.isEmpty
                                        ? 'Inicie uma conversa com a IA para que ela apareça aqui'
                                        : 'Tente usar outros termos de busca',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.darkTextSecondaryColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: conversasFiltradas.length,
                              itemBuilder: (context, index) {
                                final conversa = conversasFiltradas[index];
                                return _buildConversaTile(conversa, isTablet);
                              },
                            ),
                ),

                // Footer com botão nova conversa
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppTheme.darkBorderColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(); // Fecha o drawer
                        _novaConversa();
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Nova Conversa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatHeader(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Botão de voltar apenas no modo módulo
          if (widget.mode == ChatMode.module) ...[
            IconButton(
              onPressed:
                  widget.onBackPressed ?? () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Voltar aos módulos',
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.mode == ChatMode.module && widget.modulo != null
                      ? widget.modulo!.titulo
                      : _conversaAtual?.titulo ?? 'Nova Conversa',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: isTablet ? 18 : 16,
                  ),
                ),
                Text(
                  widget.mode == ChatMode.module && widget.modulo != null
                      ? '${widget.modulo!.anoEscolar} - ${widget.modulo!.unidadeTematica}'
                      : _contextoAtual,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.darkTextSecondaryColor,
                  ),
                ),
                // Mostra progresso das aulas se estiver no modo módulo
                if (widget.mode == ChatMode.module &&
                    widget.modulo != null &&
                    widget.progresso != null &&
                    _totalAulas > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Aula $_aulaAtual/$_totalAulas',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(widget.progresso!.calcularProgressoAulas(widget.modulo!.unidadeTematica, widget.modulo!.anoEscolar) * 100).round()}% completo',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const QueueStatusIndicator(),
          if (widget.mode != ChatMode.module) ...[
            IconButton(
              onPressed: () => _mostrarConversasSalvasDialog(),
              icon: const Icon(Icons.history_rounded),
              tooltip: 'Ver conversas salvas',
            ),
            IconButton(
              onPressed: _novaConversa,
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Nova conversa',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatArea(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _messages.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _messages.length && _isLoading) {
            return _buildTypingIndicator();
          }

          final message = _messages[index];
          return _buildMessageBubble(message, isTablet);
        },
      ),
    );
  }

  Widget _buildInputArea(bool isTablet) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceColor.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorderColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Botões de ações (quiz e arquivo) - apenas no mobile para módulos
          if (isMobile && widget.mode == ChatMode.module) ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: _gerarQuizModulo,
                      icon: const Icon(Icons.quiz_rounded, size: 16),
                      label: const Text(
                        'Quiz do Módulo',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.2),
                        foregroundColor: AppTheme.primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 36,
                  width: 36,
                  child: IconButton(
                    onPressed: _adicionarArquivo,
                    icon: const Icon(Icons.attach_file_rounded, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          AppTheme.accentColor.withValues(alpha: 0.2),
                      foregroundColor: AppTheme.accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: AppTheme.accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Área de input de texto
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Botões laterais no desktop/tablet
              if (!isMobile && widget.mode == ChatMode.module) ...[
                IconButton(
                  onPressed: _gerarQuizModulo,
                  icon: const Icon(Icons.quiz_rounded),
                  tooltip: 'Quiz do Módulo',
                  style: IconButton.styleFrom(
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.2),
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _adicionarArquivo,
                  icon: const Icon(Icons.attach_file_rounded),
                  tooltip: 'Adicionar Arquivo',
                  style: IconButton.styleFrom(
                    backgroundColor:
                        AppTheme.accentColor.withValues(alpha: 0.2),
                    foregroundColor: AppTheme.accentColor,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _textFieldFocusNode,
                  style: AppTheme.bodyMedium,
                  maxLines: isMobile ? 3 : 5,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Digite sua pergunta...',
                    hintStyle: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.darkTextSecondaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(isMobile ? 20 : 25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.darkBackgroundColor,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 20 : 14,
                      vertical: isMobile ? 10 : (isTablet ? 16 : 12),
                    ),
                  ),
                  enabled: _tutorInitialized,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: isMobile ? 40 : 48,
                width: isMobile ? 40 : 48,
                child: IconButton(
                  onPressed: _textController.text.trim().isNotEmpty
                      ? () => _sendMessage(_textController.text)
                      : null,
                  icon: Icon(
                    Icons.send_rounded,
                    size: isMobile ? 18 : 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _tutorInitialized &&
                            _textController.text.trim().isNotEmpty
                        ? AppTheme.primaryColor
                        : AppTheme.darkBorderColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.darkBorderColor,
                    disabledForegroundColor: AppTheme.darkTextSecondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar da IA
          Container(
            width: isTablet ? 32 : 28,
            height: isTablet ? 32 : 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryLightColor],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: isTablet ? 16 : 14,
            ),
          ),
          const SizedBox(width: 8),
          // Bolha de mensagem com os pontos animados
          Flexible(
            child: Container(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              decoration: BoxDecoration(
                color: AppTheme.darkSurfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAnimatedDot(0),
                  const SizedBox(width: 6),
                  _buildAnimatedDot(1),
                  const SizedBox(width: 6),
                  _buildAnimatedDot(2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot(int index) {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        // Calcula a opacidade baseada na posição do índice e no tempo da animação
        final animationValue = _typingAnimationController.value;
        final phase = (animationValue * 2 * pi) + (index * pi * 2 / 3);
        final opacity = (sin(phase) + 1) / 2; // Vai de 0 a 1

        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color:
                AppTheme.primaryColor.withValues(alpha: 0.4 + (opacity * 0.6)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isTablet) {
    // Mensagens do sistema (botões de ação) têm visual diferenciado
    final isSystemMessage = message.aiProvider == 'system';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: isTablet ? 32 : 28,
              height: isTablet ? 32 : 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSystemMessage
                      ? [
                          AppTheme.accentColor,
                          AppTheme.accentColor.withValues(alpha: 0.7)
                        ]
                      : [AppTheme.primaryColor, AppTheme.primaryLightColor],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSystemMessage
                    ? Icons.touch_app_rounded
                    : Icons.psychology_rounded,
                color: Colors.white,
                size: isTablet ? 16 : 14,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppTheme.primaryColor
                    : isSystemMessage
                        ? AppTheme.accentColor.withValues(alpha: 0.1)
                        : AppTheme.darkSurfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: isSystemMessage
                    ? Border.all(
                        color: AppTheme.accentColor.withValues(alpha: 0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LatexMarkdownWidget(
                    data: message.text,
                  ),
                  // Renderiza botões se presentes
                  if (message.buttons != null &&
                      message.buttons!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...message.buttons!
                        .map((button) => _buildActionButton(button, isTablet))
                        .toList(),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: isTablet ? 32 : 28,
              height: isTablet ? 32 : 28,
              decoration: BoxDecoration(
                color: AppTheme.darkSurfaceColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_rounded,
                color: AppTheme.primaryColor,
                size: isTablet ? 16 : 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(ChatButton button, bool isTablet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _handleButtonAction(button.action),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          children: [
            Text(
              button.icon,
              style: TextStyle(fontSize: isTablet ? 20 : 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    button.text,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ) ??
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (button.description != null &&
                      button.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      button.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ) ??
                          TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.8),
              size: isTablet ? 16 : 14,
            ),
          ],
        ),
      ),
    );
  }

  void _handleButtonAction(String action) async {
    // Processa a ação do botão como se fosse uma mensagem do usuário
    setState(() {
      _messages.add(ChatMessage(
        text: action,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });

    await _processarCliqueBotao(action);
  }

  Widget _buildFilterChip(String valor, String label, bool isTablet) {
    final isSelected = _filtroContexto == valor;

    return GestureDetector(
      onTap: () {
        if (mounted) {
          setState(() {
            _filtroContexto = valor;
          });
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 12 : 10,
          vertical: isTablet ? 6 : 5,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.darkSurfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? AppTheme.primaryColor : AppTheme.darkBorderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.darkTextSecondaryColor,
            fontSize: isTablet ? 11 : 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildConversaTile(Conversa conversa, bool isTablet) {
    final ultimaMensagem = conversa.mensagens.isNotEmpty
        ? conversa.mensagens.last.text
        : 'Conversa vazia';
    final isSelected = _conversaAtual?.id == conversa.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _abrirConversaNoChat(conversa),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: conversa.contexto == 'geral'
                            ? [
                                AppTheme.primaryColor,
                                AppTheme.primaryLightColor
                              ]
                            : [AppTheme.accentColor, AppTheme.successColor],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      conversa.contexto == 'geral'
                          ? Icons.smart_toy_rounded
                          : Icons.school_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      conversa.titulo,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isTablet ? 14 : 13,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.darkTextPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deletarConversa(conversa),
                    icon: const Icon(Icons.delete_outline_rounded),
                    iconSize: 16,
                    tooltip: 'Deletar conversa',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                ultimaMensagem,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.darkTextSecondaryColor,
                  fontSize: isTablet ? 12 : 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${conversa.mensagens.length} msgs',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.darkTextSecondaryColor,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    _formatarData(conversa.ultimaAtualizacao),
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.darkTextSecondaryColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Conversa> get _conversasFiltradas {
    if (_filtroContexto == 'todos') {
      return _conversas;
    } else if (_filtroContexto == 'geral') {
      return _conversas.where((c) => c.contexto == 'geral').toList();
    } else {
      return _conversas.where((c) => c.contexto != 'geral').toList();
    }
  }

  String _formatarData(DateTime data) {
    final agora = DateTime.now();
    final diferenca = agora.difference(data);

    if (diferenca.inDays == 0) {
      return '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
    } else if (diferenca.inDays == 1) {
      return 'Ontem';
    } else if (diferenca.inDays < 7) {
      return '${diferenca.inDays} dias';
    } else {
      return '${data.day}/${data.month}';
    }
  }

  Future<void> _deletarConversa(Conversa conversa) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurfaceColor,
        title: Text(
          'Deletar Conversa',
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Tem certeza que deseja deletar a conversa "${conversa.titulo}"?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.darkTextSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        await ConversaService.deletarConversa(conversa.id);
        // Se a conversa deletada era a atual, limpar o chat
        if (_conversaAtual?.id == conversa.id) {
          _novaConversa();
        }
        // Recarregar a lista de conversas
        await _carregarConversas();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao deletar conversa: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Widget _buildConversationsListScreen() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;

    return Scaffold(
      backgroundColor: AppTheme.darkBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkBackgroundColor,
              AppTheme.darkSurfaceColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : 16,
                  vertical: isTablet ? 16 : 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurfaceColor.withValues(alpha: 0.8),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Voltar',
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: isTablet ? 48 : 40,
                      height: isTablet ? 48 : 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryLightColor
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Conversas Salvas',
                            style: AppTheme.headingMedium.copyWith(
                              fontSize: isTablet ? 18 : 16,
                            ),
                          ),
                          Text(
                            '${_conversas.length} conversas',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.darkTextSecondaryColor,
                              fontSize: isTablet ? 12 : 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Botão para nova conversa
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showConversationsList = false;
                          _novaConversa();
                        });
                      },
                      icon: const Icon(Icons.add_rounded),
                      tooltip: 'Nova conversa',
                      iconSize: 24,
                    ),
                  ],
                ),
              ),

              // Filtros
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : 16,
                  vertical: isTablet ? 16 : 12,
                ),
                child: Row(
                  children: [
                    Text(
                      'Filtrar: ',
                      style: AppTheme.bodyMedium.copyWith(
                        fontSize: isTablet ? 14 : 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('todos', 'Todas', isTablet),
                            const SizedBox(width: 8),
                            _buildFilterChip('geral', 'Chat Geral', isTablet),
                            const SizedBox(width: 8),
                            _buildFilterChip('modulos', 'Módulos', isTablet),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de conversas
              Expanded(
                child: _loadingConversas
                    ? const Center(child: CircularProgressIndicator())
                    : _conversasFiltradas.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: isTablet ? 80 : 60,
                                  color: AppTheme.darkTextSecondaryColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhuma conversa encontrada',
                                  style: AppTheme.headingSmall.copyWith(
                                    color: AppTheme.darkTextSecondaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Clique em + para iniciar uma nova conversa',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.darkTextSecondaryColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 24 : 16,
                              vertical: isTablet ? 16 : 12,
                            ),
                            itemCount: _conversasFiltradas.length,
                            itemBuilder: (context, index) {
                              final conversa = _conversasFiltradas[index];
                              return _buildConversaTile(conversa, isTablet);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarConversasSalvasDialog() async {
    final conversas = await ConversaService.listarConversas();
    final conversasIniciais =
        conversas.where((c) => c.contexto == 'geral').toList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          String searchQuery = '';

          List<Conversa> getConversasFiltradas() {
            if (searchQuery.isEmpty) {
              return conversasIniciais;
            }
            return conversasIniciais.where((conversa) {
              final titulo = conversa.titulo.toLowerCase();
              final ultimaMensagem = conversa.mensagens.isNotEmpty
                  ? conversa.mensagens.last.text.toLowerCase()
                  : '';
              final query = searchQuery.toLowerCase();

              return titulo.contains(query) || ultimaMensagem.contains(query);
            }).toList();
          }

          final conversasFiltradas = getConversasFiltradas();

          return Dialog(
            backgroundColor: AppTheme.darkSurfaceColor,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.95,
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                children: [
                  // Header com título e busca
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.darkBorderColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Conversas Salvas',
                                style: AppTheme.headingMedium.copyWith(
                                  color: AppTheme.darkTextPrimaryColor,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'Fechar',
                              style: IconButton.styleFrom(
                                foregroundColor:
                                    AppTheme.darkTextSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Campo de busca
                        Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.darkBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.darkBorderColor,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                              });
                            },
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.darkTextPrimaryColor,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Buscar conversas...',
                              hintStyle: AppTheme.bodySmall.copyWith(
                                color: AppTheme.darkTextSecondaryColor,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: AppTheme.darkTextSecondaryColor,
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Lista de conversas
                  Expanded(
                    child: conversasFiltradas.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  searchQuery.isEmpty
                                      ? Icons.chat_bubble_outline_rounded
                                      : Icons.search_off_rounded,
                                  size: 48,
                                  color: AppTheme.darkTextSecondaryColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  searchQuery.isEmpty
                                      ? 'Nenhuma conversa encontrada'
                                      : 'Nenhuma conversa encontrada para "$searchQuery"',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.darkTextSecondaryColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  searchQuery.isEmpty
                                      ? 'Inicie uma conversa com a IA para que ela apareça aqui'
                                      : 'Tente usar outros termos de busca',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.darkTextSecondaryColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: conversasFiltradas.length,
                            itemBuilder: (context, index) {
                              final conversa = conversasFiltradas[index];
                              final ultimaMensagem =
                                  conversa.mensagens.isNotEmpty
                                      ? conversa.mensagens.last.text
                                      : 'Conversa vazia';

                              return Container(
                                margin: const EdgeInsets.only(
                                    bottom: 4, left: 8, right: 8),
                                child: ModernCard(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      _carregarConversa(conversa);
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  AppTheme.primaryColor,
                                                  AppTheme.primaryLightColor
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.chat_bubble_outline_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  conversa.titulo,
                                                  style: AppTheme.bodySmall
                                                      .copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme
                                                        .darkTextPrimaryColor,
                                                    fontSize: 13,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  ultimaMensagem.length > 80
                                                      ? '${ultimaMensagem.substring(0, 80)}...'
                                                      : ultimaMensagem,
                                                  style: AppTheme.bodySmall
                                                      .copyWith(
                                                    color: AppTheme
                                                        .darkTextSecondaryColor,
                                                    fontSize: 11,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${conversa.dataCreacao.day}/${conversa.dataCreacao.month}',
                                            style: AppTheme.bodySmall.copyWith(
                                              color: AppTheme
                                                  .darkTextSecondaryColor,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Footer com contador
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppTheme.darkBorderColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${conversasFiltradas.length} conversa${conversasFiltradas.length != 1 ? 's' : ''}',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.darkTextSecondaryColor,
                            fontSize: 11,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Fechar',
                            style: TextStyle(color: AppTheme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
