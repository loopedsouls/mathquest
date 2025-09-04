import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/ia_service.dart';
import '../services/conversa_service.dart';
import '../models/conversa.dart';
import '../widgets/latex_markdown_widget.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late MathTutorService _tutorService;
  bool _isLoading = false;
  bool _tutorInitialized = false;
  late AnimationController _typingAnimationController;

  // Configurações de IA
  bool _useGemini = true;
  String _modeloOllama = 'gemma3:1b';
  String _aiName = 'IA';

  // Sistema de conversas
  Conversa? _conversaAtual;
  String _tituloConversa = 'Nova Conversa';
  bool _conversaSalva = false;

  @override
  void initState() {
    super.initState();
    _initializeTypingAnimation();
    _initializeTutor();
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
      final selectedAI = prefs.getString('selected_ai') ?? 'gemini';
      final apiKey = prefs.getString('gemini_api_key');
      final modeloOllama = prefs.getString('modelo_ollama') ?? 'gemma3:1b';

      // Define o nome da IA baseado na configuração selecionada pelo usuário
      if (selectedAI == 'gemini') {
        _useGemini = true;
        _aiName = 'Gemini';
      } else {
        _useGemini = false;
        _modeloOllama = modeloOllama;
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
              content: Text(
                  'API Key do Gemini não configurada. Vá em Configurações para definir.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Inicializa o serviço de IA baseado na configuração
      AIService aiService;
      if (_useGemini) {
        aiService = GeminiService(apiKey: apiKey!);
      } else {
        aiService = OllamaService(defaultModel: _modeloOllama);
      }

      _tutorService = MathTutorService(aiService: aiService);
      setState(() {
        _tutorInitialized = true;
      });
      await _sendWelcomeMessage();
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
    const welcomePrompt = '''
Você é um assistente de matemática amigável e educativo. 
Dê as boas-vindas ao usuário de forma calorosa e apresente-se.

Use formatação Markdown e LaTeX para deixar sua resposta mais organizada:
- Use **negrito** para destacar palavras importantes
- Use *itálico* para ênfase
- Use # para títulos principais
- Use ## para subtítulos
- Use listas numeradas ou com bullet points
- Use `código` para fórmulas matemáticas simples
- Use LaTeX para fórmulas complexas: \$x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}\$ (inline)
- Use LaTeX em bloco para equações grandes: \$\$\\int_0^\\infty e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}\$\$

Explique que você pode ajudar com:
1. **Dúvidas sobre matemática**
2. **Explicações de conceitos**
3. **Resolução de problemas passo a passo**
4. **Sugestões de estudo**

Seja motivador, use emojis quando apropriado, e mantenha uma linguagem adequada.
Sempre use formatação Markdown e LaTeX nas suas respostas para ficar mais legível.
''';

    setState(() {
      _isLoading = true;
    });
    _typingAnimationController.repeat();

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
            'Olá! Sou seu assistente de matemática! 🤖📚\n\nEstou aqui para ajudar com suas dúvidas sobre matemática. O que você gostaria de aprender hoje?',
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

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
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

  Future<void> _salvarConversaAutomaticamente() async {
    if (_messages.isEmpty || !_tutorInitialized) return;

    try {
      // Se não tem conversa atual, cria uma nova
      _conversaAtual ??= Conversa(
        id: ConversaService.gerarIdConversa(),
        titulo: _tituloConversa,
        dataCreacao: DateTime.now(),
        ultimaAtualizacao: DateTime.now(),
        mensagens: [],
        contexto: 'geral',
      );

      // Atualiza a conversa com as mensagens atuais
      _conversaAtual = _conversaAtual!.copyWith(
        mensagens: _messages,
        ultimaAtualizacao: DateTime.now(),
      );

      // Gera título automático se ainda não foi gerado
      if (_tituloConversa == 'Nova Conversa' && _messages.length >= 2) {
        _tituloConversa = await ConversaService.gerarTituloAutomatico(
          _messages,
          'geral',
          _tutorService,
        );

        _conversaAtual = _conversaAtual!.copyWith(titulo: _tituloConversa);

        setState(() {
          _conversaSalva = true;
        });
      }

      // Salva a conversa
      await ConversaService.salvarConversa(_conversaAtual!);
    } catch (e) {
      // Ignora erros de salvamento para não interromper o chat
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
    setState(() {
      _isLoading = true;
    });
    _typingAnimationController.repeat();

    try {
      final contextPrompt = '''
Você é um assistente de matemática educativo e amigável. 

**IMPORTANTE**: Use formatação Markdown e LaTeX para deixar suas respostas organizadas e legíveis:
- Use **negrito** para destacar conceitos importantes
- Use *itálico* para ênfase
- Use # ou ## para títulos e subtítulos
- Use listas numeradas (1. 2. 3.) ou bullet points (- ou *)
- Use `código` para fórmulas matemáticas simples
- Use LaTeX inline para fórmulas: \$f(x) = ax^2 + bx + c\$
- Use LaTeX em bloco para equações complexas: \$\$\\sum_{n=1}^{\\infty} \\frac{1}{n^2} = \\frac{\\pi^2}{6}\$\$
- Use > para citações ou dicas importantes

Conversa anterior:
${_messages.where((m) => !m.isUser).take(3).map((m) => "Assistente: ${m.text}").join("\n")}
${_messages.where((m) => m.isUser).take(3).map((m) => "Usuário: ${m.text}").join("\n")}

Pergunta atual do usuário: "$text"

Responda de forma educativa, clara e apropriada. Se for uma questão matemática:
1. **Explique o conceito** por trás
2. **Mostre a resolução** passo a passo usando formatação LaTeX
3. **Dê dicas** para problemas similares

Use emojis quando apropriado, seja encorajador e sempre formate sua resposta em Markdown com LaTeX.
''';

      final response = await _tutorService.aiService.generate(contextPrompt);
      _addMessage(ChatMessage(
        text: response,
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
              Expanded(
                child: _buildChatArea(isTablet),
              ),
              _buildInputArea(isTablet),
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
              Icons.smart_toy_rounded,
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
                  _tituloConversa,
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: isTablet ? 18 : 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      _aiName,
                      style: AppTheme.bodySmall.copyWith(
                        color: _tutorInitialized
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                        fontSize: isTablet ? 12 : 11,
                      ),
                    ),
                    if (_conversaSalva) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.save_rounded,
                        size: 12,
                        color: AppTheme.successColor,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _tutorInitialized
                  ? AppTheme.successColor.withValues(alpha: 0.2)
                  : AppTheme.errorColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _tutorInitialized
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _tutorInitialized ? Icons.check_circle : Icons.error,
                  color: _tutorInitialized
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  _tutorInitialized ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: _tutorInitialized
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
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
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
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
                Icons.smart_toy_rounded,
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
                borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
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
                        fontSize: isTablet ? 16 : 14,
                        height: 1.5,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.aiProvider != null) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: message.aiProvider == 'gemini'
                                      ? Colors.blue.withValues(alpha: 0.2)
                                      : Colors.orange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: message.aiProvider == 'gemini'
                                        ? Colors.blue.withValues(alpha: 0.5)
                                        : Colors.orange.withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  message.aiProvider == 'gemini'
                                      ? 'Gemini'
                                      : 'Ollama',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: message.aiProvider == 'gemini'
                                        ? Colors.blue
                                        : Colors.orange,
                                    fontSize: isTablet ? 10 : 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.darkTextSecondaryColor,
                                  fontSize: isTablet ? 10 : 9,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        LatexMarkdownWidget(
                          data: message.text,
                          isTablet: isTablet,
                        ),
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
                color: AppTheme.accentColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: isTablet ? 16 : 14,
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
            width: isTablet ? 32 : 28,
            height: isTablet ? 32 : 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryLightColor],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: isTablet ? 16 : 14,
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
                                width: 6,
                                height: 6,
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
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceColor.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.darkBackgroundColor,
                borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                border: Border.all(
                  color: AppTheme.darkBorderColor,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _textController,
                style: TextStyle(
                  color: AppTheme.darkTextPrimaryColor,
                  fontSize: isTablet ? 16 : 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Digite sua pergunta sobre matemática...',
                  hintStyle: TextStyle(
                    color: AppTheme.darkTextSecondaryColor,
                    fontSize: isTablet ? 16 : 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 20 : 16,
                    vertical: isTablet ? 16 : 12,
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
            width: isTablet ? 48 : 40,
            height: isTablet ? 48 : 40,
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
                borderRadius: BorderRadius.circular(24),
                onTap: _tutorInitialized && !_isLoading
                    ? () => _sendMessage(_textController.text)
                    : null,
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: isTablet ? 24 : 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
