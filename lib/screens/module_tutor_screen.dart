import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/modulo_bncc.dart';
import '../models/progresso_usuario.dart';
import '../models/conversa.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_components.dart';
import '../widgets/latex_markdown_widget.dart';
import '../services/ia_service.dart';
import '../services/conversa_service.dart';
import '../unused/quiz_multipla_escolha_screen.dart';
import '../unused/quiz_verdadeiro_falso_screen.dart';
import '../unused/quiz_complete_a_frase_screen.dart';

class ModuleTutorScreen extends StatefulWidget {
  final ModuloBNCC modulo;
  final ProgressoUsuario progresso;
  final bool isOfflineMode;

  const ModuleTutorScreen({
    super.key,
    required this.modulo,
    required this.progresso,
    required this.isOfflineMode,
  });

  @override
  State<ModuleTutorScreen> createState() => _ModuleTutorScreenState();
}

class _ModuleTutorScreenState extends State<ModuleTutorScreen>
    with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late MathTutorService _tutorService;
  bool _isLoading = false;
  bool _tutorInitialized = false;
  late AnimationController _typingAnimationController;
  final bool _useGemini = true;
  final String _modeloOllama = 'llama3.2:1b';

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
    _typingAnimationController.repeat();
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
      final apiKey = prefs.getString('gemini_api_key');

      if (_useGemini && (apiKey == null || apiKey.isEmpty)) {
        setState(() {
          _tutorInitialized = false;
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
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao inicializar tutor: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _sendWelcomeMessage() async {
    final welcomePrompt = '''
Você é um tutor de matemática especializado na BNCC (Base Nacional Comum Curricular). 
O aluno está estudando o módulo "${widget.modulo.titulo}" do ${widget.modulo.anoEscolar}, 
na unidade temática "${widget.modulo.unidadeTematica}".

Descrição do módulo: ${widget.modulo.descricao}

**IMPORTANTE**: Use formatação Markdown e LaTeX para deixar sua resposta organizada:
- Use **negrito** para destacar conceitos importantes
- Use *itálico* para ênfase
- Use # ou ## para títulos e subtítulos
- Use listas numeradas (1. 2. 3.) ou bullet points (- ou *)
- Use `código` para fórmulas matemáticas simples
- Use LaTeX inline para fórmulas: \$f(x) = ax^2 + bx + c\$
- Use LaTeX em bloco para equações complexas: \$\$\\sum_{n=1}^{\\infty} \\frac{1}{n^2} = \\frac{\\pi^2}{6}\$\$
- Use > para dicas importantes

Dê as boas-vindas ao aluno de forma amigável e apresente:
1. **Um resumo simples** e claro do que ele vai aprender neste módulo
2. **Pergunte o que especificamente** ele gostaria de aprender ou revisar
3. **Mencione que você pode gerar atividades** práticas para ele

Seja motivador, use emojis quando apropriado, mantenha uma linguagem adequada para a idade, e sempre formate em Markdown com LaTeX.
''';

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _tutorService.aiService.generate(welcomePrompt);
      _addMessage(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _addMessage(ChatMessage(
        text:
            'Olá! Sou seu tutor de matemática! 🧮✨\n\nVamos estudar sobre ${widget.modulo.titulo}. O que você gostaria de aprender hoje?',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      if (_conversaAtual == null) {
        _conversaAtual = Conversa(
          id: ConversaService.gerarIdConversa(),
          titulo: _tituloConversa,
          dataCreacao: DateTime.now(),
          ultimaAtualizacao: DateTime.now(),
          mensagens: [],
          contexto: widget.modulo.titulo,
        );
      }

      // Atualiza a conversa com as mensagens atuais
      _conversaAtual = _conversaAtual!.copyWith(
        mensagens: _messages,
        ultimaAtualizacao: DateTime.now(),
      );

      // Gera título automático se ainda não foi gerado
      if (_tituloConversa == 'Nova Conversa' && _messages.length >= 2) {
        _tituloConversa = await ConversaService.gerarTituloAutomatico(
          _messages,
          widget.modulo.titulo,
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

    try {
      final contextPrompt = '''
Você é um tutor de matemática especializado na BNCC, especificamente no módulo "${widget.modulo.titulo}" 
do ${widget.modulo.anoEscolar}, unidade temática "${widget.modulo.unidadeTematica}".

Descrição do módulo: ${widget.modulo.descricao}

**IMPORTANTE**: Use formatação Markdown e LaTeX para deixar suas respostas organizadas:
- Use **negrito** para destacar conceitos importantes
- Use *itálico* para ênfase
- Use # ou ## para títulos e subtítulos
- Use listas numeradas (1. 2. 3.) ou bullet points (- ou *)
- Use `código` para fórmulas matemáticas simples
- Use LaTeX inline para fórmulas: \$f(x) = ax^2 + bx + c\$
- Use LaTeX em bloco para equações complexas: \$\$\\int_a^b f(x) dx\$\$
- Use > para dicas importantes

Conversa anterior:
${_messages.where((m) => !m.isUser).take(3).map((m) => "Tutor: ${m.text}").join("\n")}
${_messages.where((m) => m.isUser).take(3).map((m) => "Usuário: ${m.text}").join("\n")}

Pergunta atual do aluno: "$text"

Responda de forma educativa, clara e apropriada para a idade. Se o aluno pedir atividades ou exercícios,
sugira que ele use o **"Gerador de Atividades"** que criará exercícios personalizados.

Use emojis quando apropriado, seja encorajador e sempre formate sua resposta em Markdown com LaTeX.
''';

      final response = await _tutorService.aiService.generate(contextPrompt);
      _addMessage(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _addMessage(ChatMessage(
        text:
            'Desculpe, tive um probleminha para responder. Pode perguntar novamente? 😅',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showActivityGenerator() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildActivityGenerator(),
    );
  }

  Widget _buildActivityGenerator() {
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.darkBorderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Gerador de Atividades',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: isTablet ? 18 : 16,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Text(
            'Escolha o tipo de atividade para praticar ${widget.modulo.titulo}',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.darkTextSecondaryColor,
            ),
          ),
          SizedBox(height: isTablet ? 24 : 20),
          _buildQuizOption(
            'Múltipla Escolha',
            'Questões com alternativas personalizadas',
            Icons.quiz_rounded,
            () => _navegarParaQuiz('multipla_escolha'),
            isTablet,
          ),
          SizedBox(height: isTablet ? 12 : 10),
          _buildQuizOption(
            'Verdadeiro ou Falso',
            'Afirmações para validar conhecimento',
            Icons.check_box_outline_blank_rounded,
            () => _navegarParaQuiz('verdadeiro_falso'),
            isTablet,
          ),
          SizedBox(height: isTablet ? 12 : 10),
          _buildQuizOption(
            'Complete a Frase',
            'Exercícios de preenchimento',
            Icons.edit_outlined,
            () => _navegarParaQuiz('complete_frase'),
            isTablet,
          ),
          SizedBox(height: isTablet ? 20 : 16),
        ],
      ),
    );
  }

  Widget _buildQuizOption(String titulo, String descricao, IconData icon,
      VoidCallback onTap, bool isTablet) {
    return Material(
      color: AppTheme.darkBackgroundColor,
      borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.darkBorderColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
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
                  icon,
                  color: Colors.white,
                  size: isTablet ? 20 : 16,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: AppTheme.headingSmall.copyWith(
                        fontSize: isTablet ? 16 : 14,
                      ),
                    ),
                    SizedBox(height: isTablet ? 4 : 2),
                    Text(
                      descricao,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.darkTextSecondaryColor,
                        fontSize: isTablet ? 12 : 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.darkTextSecondaryColor,
                size: isTablet ? 16 : 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navegarParaQuiz(String tipo) {
    Navigator.pop(context); // Fecha o bottom sheet

    Widget quizScreen;
    switch (tipo) {
      case 'multipla_escolha':
        quizScreen = QuizMultiplaEscolhaScreen(
          isOfflineMode: widget.isOfflineMode,
          topico: widget.modulo.unidadeTematica,
          dificuldade: widget.progresso.nivelUsuario.nome.toLowerCase(),
        );
        break;
      case 'verdadeiro_falso':
        quizScreen = QuizVerdadeiroFalsoScreen(
          isOfflineMode: widget.isOfflineMode,
          topico: widget.modulo.unidadeTematica,
          dificuldade: widget.progresso.nivelUsuario.nome.toLowerCase(),
        );
        break;
      case 'complete_frase':
        quizScreen = QuizCompleteAFraseScreen(
          topico: widget.modulo.unidadeTematica,
          dificuldade: widget.progresso.nivelUsuario.nome.toLowerCase(),
        );
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => quizScreen),
    );
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
              Icons.psychology_rounded,
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
                  'Tutor de Matemática',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: isTablet ? 18 : 16,
                  ),
                ),
                Text(
                  '${widget.modulo.unidadeTematica} - ${widget.modulo.anoEscolar}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.darkTextSecondaryColor,
                    fontSize: isTablet ? 12 : 11,
                  ),
                ),
              ],
            ),
          ),
          ModernButton(
            text: 'Atividades',
            onPressed: _showActivityGenerator,
            isPrimary: false,
            icon: Icons.auto_awesome_rounded,
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
                  : LatexMarkdownWidget(
                      data: message.text,
                      isTablet: isTablet,
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
              Icons.psychology_rounded,
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
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
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
                  hintText: 'Digite sua pergunta...',
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


