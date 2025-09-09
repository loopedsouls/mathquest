import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/modulo_bncc.dart';
import '../models/progresso_usuario.dart';
import '../models/conversa.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_components.dart';
import '../widgets/latex_markdown_widget.dart';
import '../widgets/queue_status_indicator.dart';
import '../services/ia_service.dart';
import '../services/conversa_service.dart';
import '../services/ai_queue_service.dart';

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

  const ChatScreen({
    super.key,
    required this.mode,
    this.modulo,
    this.progresso,
    this.isOfflineMode = false,
    this.conversaInicial,
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

  // Serviços
  late MathTutorService _tutorService;
  late AIQueueService _aiQueueService;

  // Estado
  bool _isLoading = false;
  bool _tutorInitialized = false;
  late AnimationController _typingAnimationController;

  // Configurações de IA
  bool _useGemini = true;
  String _modeloOllama = 'gemma3:1b';
  String _aiName = 'IA';

  // Conversas
  List<Conversa> _conversas = [];
  bool _loadingConversas = true;
  Conversa? _conversaAtual;
  String _contextoAtual = 'geral';
  String _tituloConversa = 'Nova Conversa';

  @override
  void initState() {
    super.initState();
    _aiQueueService = AIQueueService();
    _initializeTypingAnimation();
    _initializeTutor();

    if (widget.mode == ChatMode.sidebar || widget.mode == ChatMode.saved) {
      _carregarConversas();
    }

    if (widget.modulo != null) {
      _contextoAtual = widget.modulo!.titulo;
    }

    if (widget.conversaInicial != null) {
      _carregarConversa(widget.conversaInicial!);
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
    super.dispose();
  }

  Future<void> _initializeTutor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedAI = prefs.getString('selected_ai') ?? 'gemini';
      final apiKey = prefs.getString('gemini_api_key');
      final modeloOllama = prefs.getString('modelo_ollama') ?? 'gemma3:1b';

      _useGemini = selectedAI == 'gemini';
      _modeloOllama = modeloOllama;

      // Define o nome da IA baseado na configuração
      if (_useGemini) {
        _aiName = 'Gemini';
      } else {
        _aiName = 'Ollama ($_modeloOllama)';
      }

      // Verifica se a configuração está completa
      if (_useGemini && (apiKey == null || apiKey.isEmpty)) {
        setState(() {
          _tutorInitialized = false;
          _aiName = 'Gemini (Não configurado)';
        });
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
      } else {
        aiService = OllamaService(defaultModel: _modeloOllama);
      }

      _tutorService = MathTutorService(aiService: aiService);
      _aiQueueService.initialize(_tutorService);

      setState(() {
        _tutorInitialized = true;
      });

      // Envia mensagem de boas-vindas se necessário
      if (widget.mode != ChatMode.saved && _conversaAtual == null) {
        await _sendWelcomeMessage();
      }
    } catch (e) {
      setState(() {
        _tutorInitialized = false;
        _aiName = 'IA (Erro)';
      });
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
        welcomePrompt = '''
Você é um tutor de matemática especializado na BNCC, especificamente no módulo "${widget.modulo!.titulo}" 
do ${widget.modulo!.anoEscolar}, unidade temática "${widget.modulo!.unidadeTematica}".

Dê as boas-vindas ao aluno de forma calorosa e apresente-se como tutor do módulo.
Use emojis e formatação Markdown.
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

      _addMessage(ChatMessage(
        text: response.text,
        isUser: false,
        timestamp: DateTime.now(),
        aiProvider: _useGemini ? 'gemini' : 'ollama',
      ));
    } catch (e) {
      _addMessage(ChatMessage(
        text:
            'Olá! Estou aqui para ajudar com matemática. Como posso ajudar você hoje? 😊',
        isUser: false,
        timestamp: DateTime.now(),
        aiProvider: _useGemini ? 'gemini' : 'ollama',
      ));
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

    _addMessage(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    _textController.clear();
    setState(() {
      _isLoading = true;
    });
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
        aiProvider: _useGemini ? 'gemini' : 'ollama',
      ));
    } catch (e) {
      _addMessage(ChatMessage(
        text:
            'Desculpe, tive um probleminha para responder. Pode perguntar novamente? 😅',
        isUser: false,
        timestamp: DateTime.now(),
        aiProvider: _useGemini ? 'gemini' : 'ollama',
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
      _typingAnimationController.stop();
    }
  }

  String _buildContextPrompt(String userMessage) {
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
    setState(() => _loadingConversas = true);
    try {
      final conversas = await ConversaService.listarConversas();
      setState(() {
        _conversas = conversas;
        _loadingConversas = false;
      });
    } catch (e) {
      setState(() => _loadingConversas = false);
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
    setState(() {
      _conversaAtual = conversa;
      _messages.clear();
      _messages.addAll(conversa.mensagens);
      _tituloConversa = conversa.titulo;
      _contextoAtual = conversa.contexto;
    });

    // Auto-scroll para a última mensagem
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _novaConversa() {
    setState(() {
      _conversaAtual = null;
      _messages.clear();
      _contextoAtual = widget.modulo?.titulo ?? 'geral';
      _tituloConversa = 'Nova Conversa';
    });

    if (_tutorInitialized) {
      _sendWelcomeMessage();
    }
  }

  // UI
  @override
  Widget build(BuildContext context) {
    switch (widget.mode) {
      case ChatMode.saved:
        return _buildSavedConversationsScreen();
      default:
        return _buildChatScreen();
    }
  }

  Widget _buildChatScreen() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isMobile = screenWidth < 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.darkBackgroundColor,
      drawer: (widget.mode == ChatMode.sidebar && isMobile)
          ? _buildMobileDrawer()
          : null,
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
          child: widget.mode == ChatMode.sidebar && !isMobile
              ? _buildDesktopLayout(isTablet)
              : _buildMobileLayout(isTablet),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(bool isTablet) {
    return Column(
      children: [
        _buildHeader(isTablet),
        Expanded(child: _buildChatArea(isTablet)),
        _buildInputArea(isTablet),
      ],
    );
  }

  Widget _buildDesktopLayout(bool isTablet) {
    return Row(
      children: [
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: AppTheme.darkSurfaceColor.withValues(alpha: 0.5),
            border: Border(
              right: BorderSide(
                color: AppTheme.darkBorderColor,
                width: 1,
              ),
            ),
          ),
          child: _buildSidebar(isTablet),
        ),
        Expanded(
          child: Column(
            children: [
              _buildChatHeader(isTablet),
              Expanded(child: _buildChatArea(isTablet)),
              _buildInputArea(isTablet),
            ],
          ),
        ),
      ],
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
              widget.mode == ChatMode.module
                  ? Icons.psychology_rounded
                  : Icons.smart_toy_rounded,
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
                  widget.mode == ChatMode.module
                      ? 'Tutor de Matemática'
                      : _tituloConversa,
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: isTablet ? 18 : 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.mode == ChatMode.module
                      ? '${widget.modulo!.unidadeTematica} - ${widget.modulo!.anoEscolar}'
                      : _aiName,
                  style: AppTheme.bodySmall.copyWith(
                    color: _tutorInitialized
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                    fontSize: isTablet ? 12 : 11,
                  ),
                ),
              ],
            ),
          ),
          const QueueStatusIndicator(),
        ],
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _conversaAtual?.titulo ?? 'Nova Conversa',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: isTablet ? 18 : 16,
                  ),
                ),
                Text(
                  _contextoAtual,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.darkTextSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          const QueueStatusIndicator(),
          IconButton(
            onPressed: _novaConversa,
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Nova conversa',
          ),
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
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceColor.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: AppTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Digite sua pergunta...',
                hintStyle: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.darkTextSecondaryColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.darkBackgroundColor,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 20 : 16,
                  vertical: isTablet ? 16 : 12,
                ),
              ),
              onSubmitted: _sendMessage,
              enabled: _tutorInitialized,
            ),
          ),
          const SizedBox(width: 12),
          ModernButton(
            text: '',
            onPressed: _textController.text.trim().isNotEmpty
                ? () => _sendMessage(_textController.text)
                : null,
            isPrimary: true,
            icon: Icons.send_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.darkSurfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedBuilder(
              animation: _typingAnimationController,
              builder: (context, child) {
                return Text(
                  '${_useGemini ? 'Gemini' : 'Ollama'} está pensando...',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.primaryColor.withValues(
                      alpha: 0.5 + (_typingAnimationController.value * 0.5),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isTablet) {
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
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppTheme.primaryColor
                    : AppTheme.darkSurfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: LatexMarkdownWidget(
                data: message.text,
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

  // Placeholder implementations - simplificadas
  Widget _buildSidebar(bool isTablet) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Conversas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _novaConversa,
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Nova conversa',
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingConversas
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _conversas.length,
                  itemBuilder: (context, index) {
                    final conversa = _conversas[index];
                    return ListTile(
                      title: Text(
                        conversa.titulo,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        conversa.contexto,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      onTap: () => _carregarConversa(conversa),
                      selected: _conversaAtual?.id == conversa.id,
                      selectedTileColor:
                          AppTheme.primaryColor.withValues(alpha: 0.1),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: AppTheme.darkSurfaceColor,
      child: _buildSidebar(false),
    );
  }

  Widget _buildSavedConversationsScreen() {
    return Scaffold(
      backgroundColor: AppTheme.darkBackgroundColor,
      appBar: AppBar(
        title: const Text('Conversas Salvas'),
        backgroundColor: AppTheme.darkSurfaceColor,
      ),
      body: _loadingConversas
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _conversas.length,
              itemBuilder: (context, index) {
                final conversa = _conversas[index];
                return Card(
                  color: AppTheme.darkSurfaceColor,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(
                      conversa.titulo,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${conversa.contexto} • ${conversa.mensagens.length} mensagens',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    trailing: Text(
                      '${conversa.ultimaAtualizacao.day}/${conversa.ultimaAtualizacao.month}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            mode: ChatMode.general,
                            conversaInicial: conversa,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
