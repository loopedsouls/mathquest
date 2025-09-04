import 'package:flutter/material.dart';
import '../models/conversa.dart';
import '../models/modulo_bncc.dart';
import '../models/progresso_usuario.dart';
import '../services/conversa_service.dart';
import '../services/ia_service.dart';
import '../services/ai_queue_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_components.dart';
import '../widgets/latex_markdown_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatWithSidebarScreen extends StatefulWidget {
  final ModuloBNCC? modulo;
  final ProgressoUsuario? progresso;
  final bool isOfflineMode;

  const ChatWithSidebarScreen({
    super.key,
    this.modulo,
    this.progresso,
    required this.isOfflineMode,
  });

  @override
  State<ChatWithSidebarScreen> createState() => _ChatWithSidebarScreenState();
}

class _ChatWithSidebarScreenState extends State<ChatWithSidebarScreen>
    with TickerProviderStateMixin {
  // Chat
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late MathTutorService _tutorService;
  late AIQueueService _aiQueueService;
  bool _isLoading = false;
  bool _tutorInitialized = false;
  late AnimationController _typingAnimationController;
  bool _useGemini = true; // Será carregado das configurações
  String _modeloOllama = 'gemma3:1b'; // Será carregado das configurações

  // Conversas
  List<Conversa> _conversas = [];
  bool _loadingConversas = true;
  Conversa? _conversaAtual;
  String _contextoAtual = 'geral';
  String _resumoContexto = '';

  @override
  void initState() {
    super.initState();
    _aiQueueService = AIQueueService();
    _initializeTypingAnimation();
    _initializeTutor();
    _carregarConversas();
    if (widget.modulo != null) {
      _contextoAtual = widget.modulo!.titulo;
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
    _textController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeTutor() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Carrega configurações do usuário
      final selectedAI = prefs.getString('selected_ai') ?? 'gemini';
      _useGemini = selectedAI == 'gemini';
      _modeloOllama = prefs.getString('modelo_ollama') ?? 'gemma3:1b';

      final apiKey = prefs.getString('gemini_api_key');

      if (_useGemini && (apiKey == null || apiKey.isEmpty)) {
        setState(() => _tutorInitialized = false);
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

      AIService aiService;
      if (_useGemini) {
        aiService = GeminiService(apiKey: apiKey!);
      } else {
        aiService = OllamaService(defaultModel: _modeloOllama);
      }

      _tutorService = MathTutorService(aiService: aiService);
      
      // Inicializa o sistema de filas
      _aiQueueService.initialize(_tutorService);
      
      setState(() => _tutorInitialized = true);

      // Só envia mensagem de boas-vindas se não há conversa selecionada
      if (_conversaAtual == null) {
        await _sendWelcomeMessage();
      }
    } catch (e) {
      setState(() => _tutorInitialized = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao inicializar tutor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
    }
  }

  Future<void> _sendWelcomeMessage() async {
    if (widget.modulo != null) {
      final welcomePrompt = '''
Você é um tutor de matemática especializado na BNCC. 
O aluno está estudando o módulo "${widget.modulo!.titulo}" do ${widget.modulo!.anoEscolar}, 
na unidade temática "${widget.modulo!.unidadeTematica}".

Dê boas-vindas ao aluno de forma amigável e apresente o módulo usando formatação Markdown e LaTeX.
''';

      try {
        final response = await _tutorService.aiService.generate(welcomePrompt);
        _addMessage(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
          aiProvider: _useGemini ? 'gemini' : 'ollama',
        ));
      } catch (e) {
        _addMessage(ChatMessage(
          text:
              'Olá! Sou seu tutor de matemática! 🧮✨\n\nVamos estudar sobre ${widget.modulo!.titulo}. O que você gostaria de aprender hoje?',
          isUser: false,
          timestamp: DateTime.now(),
          aiProvider: _useGemini ? 'gemini' : 'ollama',
        ));
      }
    } else {
      _addMessage(ChatMessage(
        text:
            '# Olá! 👋\n\nSou seu tutor de matemática personalizado! 🧮✨\n\n**Como posso ajudar você hoje?**\n\n- Explicar conceitos matemáticos\n- Resolver exercícios passo a passo\n- Esclarecer dúvidas\n- Gerar atividades práticas\n\nDigite sua pergunta e vamos começar! 🚀',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
  }

  void _addMessage(ChatMessage message) {
    setState(() => _messages.add(message));
    _scrollToBottom();
    _salvarConversaAutomaticamente();
  }

  void _scrollToBottom() {
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

  Future<String> _gerarResumoContexto() async {
    if (_messages.length < 4) return '';

    try {
      final mensagensRecentes = _messages.length > 6
          ? _messages.sublist(_messages.length - 6)
          : _messages;

      final contexto = mensagensRecentes
          .map((m) => "${m.isUser ? 'Usuário' : 'Tutor'}: ${m.text}")
          .join('\n');

      final prompt = '''
Resuma em no máximo 2 frases o contexto desta conversa de matemática para manter continuidade:

$contexto

Contexto resumido:''';

      final resumo = await _tutorService.aiService.generate(prompt);
      return resumo.trim();
    } catch (e) {
      return 'Conversa sobre matemática em andamento.';
    }
  }

  Future<void> _salvarConversaAutomaticamente() async {
    if (_messages.isEmpty || !_tutorInitialized) return;

    try {
      _conversaAtual ??= Conversa(
        id: ConversaService.gerarIdConversa(),
        titulo: 'Nova Conversa',
        dataCreacao: DateTime.now(),
        ultimaAtualizacao: DateTime.now(),
        mensagens: [],
        contexto: _contextoAtual,
      );

      _conversaAtual = _conversaAtual!.copyWith(
        mensagens: _messages,
        ultimaAtualizacao: DateTime.now(),
      );

      if (_conversaAtual!.titulo == 'Nova Conversa' && _messages.length >= 2) {
        final titulo = await ConversaService.gerarTituloAutomatico(
          _messages,
          _contextoAtual,
          _tutorService,
        );
        _conversaAtual = _conversaAtual!.copyWith(titulo: titulo);
      }

      // Gera resumo do contexto para próximas mensagens
      _resumoContexto = await _gerarResumoContexto();

      await ConversaService.salvarConversa(_conversaAtual!);
      await _carregarConversas(); // Atualiza a lista
    } catch (e) {
      // Ignora erros
    }
  }

  Future<void> _carregarConversa(Conversa conversa) async {
    setState(() {
      _conversaAtual = conversa;
      _messages.clear();
      _messages.addAll(conversa.mensagens);
      _contextoAtual = conversa.contexto;
      _isLoading = false;
    });

    // Gera resumo da conversa carregada
    _resumoContexto = await _gerarResumoContexto();
    _scrollToBottom();
  }

  void _novaConversa() {
    setState(() {
      _conversaAtual = null;
      _messages.clear();
      _resumoContexto = '';
      _contextoAtual = widget.modulo?.titulo ?? 'geral';
    });

    if (_tutorInitialized) {
      _sendWelcomeMessage();
    }
  }

  Future<void> _deletarConversa(Conversa conversa) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurfaceColor,
        title: const Text('Excluir Conversa'),
        content: Text('Deseja excluir a conversa "${conversa.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmacao == true) {
      await ConversaService.deletarConversa(conversa.id);
      await _carregarConversas();

      if (_conversaAtual?.id == conversa.id) {
        _novaConversa();
      }
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || !_tutorInitialized) return;

    _addMessage(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    _textController.clear();
    setState(() => _isLoading = true);
    _typingAnimationController.repeat();

    try {
      String contextPrompt = '''
Você é um tutor de matemática especializado na BNCC.
Use formatação Markdown e LaTeX para suas respostas.

Contexto atual: $_contextoAtual
''';

      // Adiciona resumo do contexto se disponível
      if (_resumoContexto.isNotEmpty) {
        contextPrompt += '\nContexto da conversa: $_resumoContexto\n';
      }

      // Adiciona contexto do módulo se disponível
      if (widget.modulo != null) {
        contextPrompt += '''
Módulo específico: "${widget.modulo!.titulo}" do ${widget.modulo!.anoEscolar}
Unidade temática: "${widget.modulo!.unidadeTematica}"
Descrição: ${widget.modulo!.descricao}
''';
      }

      // Adiciona mensagens recentes para contexto
      final mensagensRecentes = _messages.length > 4
          ? _messages.sublist(_messages.length - 4)
          : _messages;

      final contextoMensagens = mensagensRecentes
          .map((m) =>
              "${m.isUser ? 'Usuário' : 'Tutor'}: ${m.text.length > 200 ? '${m.text.substring(0, 200)}...' : m.text}")
          .join('\n');

      contextPrompt += '''

Mensagens recentes:
$contextoMensagens

Pergunta atual: "$text"

Responda de forma educativa e clara, usando Markdown e LaTeX.
''';

      // Adiciona à fila e aguarda resultado
      final response = await _aiQueueService.addRequest(
        conversaId: _conversaAtual?.id ?? 'sidebar_chat_${DateTime.now().millisecondsSinceEpoch}',
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
        text: 'Desculpe, tive um problema para responder. Pode tentar novamente? 😅',
        isUser: false,
        timestamp: DateTime.now(),
        aiProvider: _useGemini ? 'gemini' : 'ollama',
      ));
    } finally {
      setState(() => _isLoading = false);
      _typingAnimationController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;
    final isMobile = screenWidth < 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.darkBackgroundColor,
      drawer: isMobile ? _buildMobileDrawer() : null,
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
          child: isMobile
              ? _buildMobileLayout(isTablet)
              : _buildDesktopLayout(isTablet, isDesktop),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(bool isTablet) {
    return Column(
      children: [
        _buildMobileChatHeader(isTablet),
        Expanded(child: _buildChatArea(isTablet)),
        _buildInputArea(isTablet),
      ],
    );
  }

  Widget _buildDesktopLayout(bool isTablet, bool isDesktop) {
    return Row(
      children: [
        // Sidebar com conversas
        Container(
          width: isDesktop ? 320 : (isTablet ? 280 : 250),
          decoration: BoxDecoration(
            color: AppTheme.darkSurfaceColor.withValues(alpha: 0.8),
            border: Border(
              right: BorderSide(
                color: AppTheme.darkBorderColor,
                width: 1,
              ),
            ),
          ),
          child: _buildSidebar(isTablet),
        ),

        // Área do chat
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

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: AppTheme.darkSurfaceColor,
      child: SafeArea(
        child: _buildSidebar(false),
      ),
    );
  }

  Widget _buildMobileChatHeader(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceColor.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Conversas',
          ),
          const SizedBox(width: 8),
          Container(
            width: isTablet ? 40 : 32,
            height: isTablet ? 40 : 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryLightColor],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology_rounded,
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
                  _conversaAtual?.titulo ?? 'Nova Conversa',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: isTablet ? 16 : 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _contextoAtual,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.darkTextSecondaryColor,
                    fontSize: isTablet ? 12 : 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _novaConversa,
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Nova conversa',
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool isTablet) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Column(
      children: [
        // Header da sidebar
        Container(
          padding: EdgeInsets.all(isTablet ? 20 : (isMobile ? 12 : 16)),
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
              if (isMobile) ...[
                // Header mobile com botão de fechar
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Conversas',
                        style: AppTheme.headingMedium.copyWith(
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Fechar',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ] else ...[
                // Header desktop/tablet
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Conversas',
                        style: AppTheme.headingMedium.copyWith(
                          fontSize: isTablet ? 18 : 16,
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
                const SizedBox(height: 12),
              ],
              ModernButton(
                text: 'Nova Conversa',
                onPressed: () {
                  _novaConversa();
                  if (isMobile) Navigator.pop(context);
                },
                isPrimary: true,
                icon: Icons.chat_rounded,
              ),
            ],
          ),
        ),

        // Lista de conversas
        Expanded(
          child: _loadingConversas
              ? const Center(child: CircularProgressIndicator())
              : _conversas.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: isMobile ? 40 : 48,
                              color: AppTheme.darkTextSecondaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhuma conversa ainda',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.darkTextSecondaryColor,
                                fontSize: isMobile ? 14 : 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding:
                          EdgeInsets.all(isMobile ? 8 : (isTablet ? 12 : 8)),
                      itemCount: _conversas.length,
                      itemBuilder: (context, index) => _buildConversaItem(
                          _conversas[index], isTablet, isMobile),
                    ),
        ),
      ],
    );
  }

  Widget _buildConversaItem(Conversa conversa, bool isTablet,
      [bool isMobile = false]) {
    final isSelected = _conversaAtual?.id == conversa.id;

    return Container(
        margin: EdgeInsets.only(bottom: isTablet ? 8 : (isMobile ? 4 : 6)),
        child: Material(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.2)
              : AppTheme.darkBackgroundColor,
          borderRadius:
              BorderRadius.circular(isTablet ? 12 : (isMobile ? 6 : 8)),
          child: InkWell(
            onTap: () {
              _carregarConversa(conversa);
              if (isMobile) Navigator.pop(context); // Fecha drawer em mobile
            },
            borderRadius:
                BorderRadius.circular(isTablet ? 12 : (isMobile ? 6 : 8)),
            child: Container(
              padding: EdgeInsets.all(isTablet ? 16 : (isMobile ? 8 : 12)),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.darkBorderColor,
                  width: 1,
                ),
                borderRadius:
                    BorderRadius.circular(isTablet ? 12 : (isMobile ? 6 : 8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversa.titulo,
                          style: AppTheme.headingSmall.copyWith(
                            fontSize: isTablet ? 14 : (isMobile ? 11 : 12),
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.darkTextPrimaryColor,
                          ),
                          maxLines: isMobile ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deletarConversa(conversa);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 16),
                                SizedBox(width: 8),
                                Text('Excluir'),
                              ],
                            ),
                          ),
                        ],
                        icon: Icon(
                          Icons.more_vert_rounded,
                          size: isMobile ? 14 : 16,
                          color: AppTheme.darkTextSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 6 : 8,
                          vertical: isMobile ? 2 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(isMobile ? 8 : 12),
                        ),
                        child: Text(
                          conversa.contexto,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.accentColor,
                            fontSize: isTablet ? 10 : (isMobile ? 8 : 9),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatarData(conversa.ultimaAtualizacao),
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                          fontSize: isTablet ? 10 : (isMobile ? 8 : 9),
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
      return '${diferenca.inDays}d atrás';
    } else {
      return '${data.day}/${data.month}';
    }
  }

  Widget _buildChatHeader(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceColor.withValues(alpha: 0.8),
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
            width: isTablet ? 40 : 32,
            height: isTablet ? 40 : 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryLightColor],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology_rounded,
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
                  _conversaAtual?.titulo ?? 'Nova Conversa',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
                Text(
                  _contextoAtual,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.darkTextSecondaryColor,
                    fontSize: isTablet ? 12 : 10,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Fechar',
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
        itemCount: _messages.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _messages.length) {
            return _buildTypingIndicator(isTablet);
          }
          return _buildMessageBubble(_messages[index], isTablet);
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isTablet) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : (isMobile ? 8 : 12)),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: isTablet ? 28 : (isMobile ? 20 : 24),
              height: isTablet ? 28 : (isMobile ? 20 : 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryLightColor],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology_rounded,
                color: Colors.white,
                size: isTablet ? 14 : (isMobile ? 10 : 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(isTablet ? 16 : (isMobile ? 8 : 12)),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppTheme.primaryColor
                    : AppTheme.darkSurfaceColor,
                borderRadius:
                    BorderRadius.circular(isTablet ? 16 : (isMobile ? 8 : 12)),
                border: !message.isUser
                    ? Border.all(
                        color: AppTheme.darkBorderColor,
                        width: 1,
                      )
                    : null,
              ),
              child: message.isUser
                  ? Text(
                      message.text,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 14 : (isMobile ? 11 : 12),
                        height: 1.5,
                      ),
                    )
                  : LatexMarkdownWidget(
                      data: message.text,
                      isTablet: isTablet,
                    ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: isTablet ? 28 : (isMobile ? 20 : 24),
              height: isTablet ? 28 : (isMobile ? 20 : 24),
              decoration: BoxDecoration(
                color: AppTheme.accentColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: isTablet ? 14 : (isMobile ? 10 : 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isTablet) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isTablet ? 28 : 24,
            height: isTablet ? 28 : 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryLightColor],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: isTablet ? 14 : 12,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: AppTheme.darkSurfaceColor,
              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
              border: Border.all(
                color: AppTheme.darkBorderColor,
                width: 1,
              ),
            ),
            child: AnimatedBuilder(
              animation: _typingAnimationController,
              builder: (context, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_useGemini ? 'Gemini' : 'Ollama'} está pensando',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.darkTextSecondaryColor,
                            fontSize: isTablet ? 12 : 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ...List.generate(3, (index) {
                          final delay = index * 0.2;
                          final animation = Tween<double>(begin: 0.4, end: 1.0)
                              .animate(CurvedAnimation(
                            parent: _typingAnimationController,
                            curve: Interval(
                              delay,
                              0.6 + delay,
                              curve: Curves.easeInOut,
                            ),
                          ));
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            child: Opacity(
                              opacity: animation.value,
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isTablet) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : (isMobile ? 12 : 16)),
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
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.darkBackgroundColor,
                borderRadius:
                    BorderRadius.circular(isTablet ? 24 : (isMobile ? 16 : 20)),
                border: Border.all(
                  color: AppTheme.darkBorderColor,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _textController,
                style: TextStyle(
                  color: AppTheme.darkTextPrimaryColor,
                  fontSize: isTablet ? 14 : (isMobile ? 11 : 12),
                ),
                decoration: InputDecoration(
                  hintText: 'Digite sua pergunta...',
                  hintStyle: TextStyle(
                    color: AppTheme.darkTextSecondaryColor,
                    fontSize: isTablet ? 14 : (isMobile ? 11 : 12),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 20 : (isMobile ? 12 : 16),
                    vertical: isTablet ? 16 : (isMobile ? 8 : 12),
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                enabled: _tutorInitialized && !_isLoading,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: isTablet ? 44 : (isMobile ? 32 : 36),
            height: isTablet ? 44 : (isMobile ? 32 : 36),
            decoration: BoxDecoration(
              gradient: _tutorInitialized && !_isLoading
                  ? LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryLightColor
                      ],
                    )
                  : null,
              color: !_tutorInitialized || _isLoading
                  ? AppTheme.darkBorderColor
                  : null,
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius:
                    BorderRadius.circular(isTablet ? 22 : (isMobile ? 16 : 18)),
                onTap: _tutorInitialized && !_isLoading
                    ? () => _sendMessage(_textController.text)
                    : null,
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: isTablet ? 20 : (isMobile ? 14 : 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
