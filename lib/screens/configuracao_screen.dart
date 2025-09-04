import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ia_service.dart';
import '../services/preload_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_components.dart';
import 'preload_screen.dart';

class ConfiguracaoScreen extends StatefulWidget {
  const ConfiguracaoScreen({super.key});

  @override
  State<ConfiguracaoScreen> createState() => _ConfiguracaoScreenState();
}

class _ConfiguracaoScreenState extends State<ConfiguracaoScreen>
    with TickerProviderStateMixin {
  final TextEditingController apiKeyController = TextEditingController();
  bool carregando = false;
  String status = '';
  String _selectedAI = 'gemini';
  String _modeloOllama = 'llama2';
  bool _preloadEnabled = false;
  int _currentCredits = 0;
  int _preloadQuantity = 100;

  List<String> _ollamaModels = [];
  bool _loadingModels = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _carregarConfiguracoes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recarrega créditos quando a tela volta a ser visível
    _recarregarCreditos();
  }

  Future<void> _recarregarCreditos() async {
    final credits = await PreloadService.getCredits();
    if (mounted) {
      setState(() {
        _currentCredits = credits;
      });
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _carregarConfiguracoes() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_api_key');
    final selectedAI = prefs.getString('selected_ai') ?? 'gemini';
    final modeloOllama = prefs.getString('modelo_ollama') ?? 'llama2';
    final preloadEnabled = await PreloadService.isPreloadEnabled();
    final credits = await PreloadService.getCredits();
    final quantity = await PreloadService.getPreloadQuantity();

    if (apiKey != null) {
      apiKeyController.text = apiKey;
    } else {
      apiKeyController.text = 'AIzaSyAiNcBfK0i7P6qPuqfhbT3ijZgHJKyW0xo';
    }

    setState(() {
      _selectedAI = selectedAI;
      _modeloOllama = modeloOllama;
      _preloadEnabled = preloadEnabled;
      _currentCredits = credits;
      _preloadQuantity = quantity;
    });

    if (_selectedAI == 'ollama') {
      _fetchOllamaModels();
    }
  }

  Future<void> _fetchOllamaModels() async {
    setState(() => _loadingModels = true);
    try {
      final ollamaService = OllamaService();
      _ollamaModels = await ollamaService.listModels();
      if (_ollamaModels.isEmpty) {
        _ollamaModels = ['llama2'];
      }
      if (!_ollamaModels.contains(_modeloOllama)) {
        _modeloOllama = _ollamaModels.first;
      }
    } catch (e) {
      _ollamaModels = ['llama2'];
      _modeloOllama = 'llama2';
      setState(() {
        status = 'Erro ao carregar modelos Ollama: $e';
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => status = '');
        }
      });
    }
    setState(() => _loadingModels = false);
  }

  Future<void> _salvarConfiguracoes() async {
    final apiKey = apiKeyController.text.trim();
    if (apiKey.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', apiKey);
    await prefs.setString('selected_ai', _selectedAI);
    await prefs.setString('modelo_ollama', _modeloOllama);

    setState(() {
      status = '✅ Configurações salvas com sucesso!';
    });

    // Limpar status após alguns segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => status = '');
      }
    });
  }

  Future<void> testarConexao() async {
    setState(() => carregando = true);
    try {
      if (_selectedAI == 'gemini') {
        final geminiService =
            GeminiService(apiKey: apiKeyController.text.trim());
        final isAvailable = await geminiService.isServiceAvailable();
        status = isAvailable
            ? '✅ Conexão com Gemini funcionando!'
            : '❌ Erro na conexão com Gemini.';
      } else {
        final ollamaService = OllamaService(defaultModel: _modeloOllama);
        final isAvailable = await ollamaService.isServiceAvailable();
        status = isAvailable
            ? '✅ Conexão com Ollama funcionando!'
            : '❌ Erro na conexão com Ollama.';
      }
    } catch (e) {
      status = '❌ Erro ao testar conexão: $e';
    }
    setState(() => carregando = false);

    // Limpar status após alguns segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => status = '');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header responsivo
                const ResponsiveHeader(
                  title: 'Configurações',
                  subtitle: 'Configure os serviços de IA e preferências',
                  showBackButton: true,
                ),

                // Conteúdo principal
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 80 : (isTablet ? 40 : 20),
                    ),
                    child: Column(
                      children: [
                        // Seleção de serviço
                        _buildServiceSelector(isTablet),
                        SizedBox(height: isTablet ? 30 : 20),

                        // Configuração do Gemini
                        if (_selectedAI == 'gemini') ...[
                          _buildGeminiConfig(isTablet),
                          SizedBox(height: isTablet ? 30 : 20),
                        ],

                        // Configuração do Ollama
                        if (_selectedAI == 'ollama') ...[
                          _buildOllamaConfig(isTablet),
                          SizedBox(height: isTablet ? 30 : 20),
                        ],

                        // Configurações de Precarregamento
                        _buildPreloadConfig(isTablet),
                        SizedBox(height: isTablet ? 30 : 20),

                        // Botões de ação
                        _buildActionButtons(isTablet),
                        SizedBox(height: isTablet ? 30 : 20),

                        // Status
                        if (status.isNotEmpty) ...[
                          _buildStatusCard(isTablet),
                          SizedBox(height: isTablet ? 30 : 20),
                        ],

                        // Informações adicionais
                        _buildInfoSection(isTablet),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceSelector(bool isTablet) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecionar Serviço de IA',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.darkTextPrimaryColor,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedAI = 'gemini'),
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                  child: Container(
                    padding: EdgeInsets.all(isTablet ? 20 : 16),
                    decoration: BoxDecoration(
                      color: _selectedAI == 'gemini'
                          ? AppTheme.primaryColor.withValues(alpha: 0.2)
                          : AppTheme.darkSurfaceColor,
                      borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                      border: Border.all(
                        color: _selectedAI == 'gemini'
                            ? AppTheme.primaryColor
                            : AppTheme.darkBorderColor,
                        width: _selectedAI == 'gemini' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: isTablet ? 60 : 50,
                          height: isTablet ? 60 : 50,
                          decoration: BoxDecoration(
                            color: _selectedAI == 'gemini'
                                ? AppTheme.primaryColor
                                : AppTheme.darkBorderColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: isTablet ? 28 : 24,
                          ),
                        ),
                        SizedBox(height: isTablet ? 12 : 8),
                        Text(
                          'Google Gemini',
                          style: AppTheme.bodyLarge.copyWith(
                            color: _selectedAI == 'gemini'
                                ? AppTheme.primaryColor
                                : AppTheme.darkTextPrimaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: isTablet ? 4 : 2),
                        Text(
                          'Serviço em nuvem',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.darkTextSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedAI = 'ollama');
                    _fetchOllamaModels();
                  },
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                  child: Container(
                    padding: EdgeInsets.all(isTablet ? 20 : 16),
                    decoration: BoxDecoration(
                      color: _selectedAI == 'ollama'
                          ? AppTheme.secondaryColor.withValues(alpha: 0.2)
                          : AppTheme.darkSurfaceColor,
                      borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                      border: Border.all(
                        color: _selectedAI == 'ollama'
                            ? AppTheme.secondaryColor
                            : AppTheme.darkBorderColor,
                        width: _selectedAI == 'ollama' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: isTablet ? 60 : 50,
                          height: isTablet ? 60 : 50,
                          decoration: BoxDecoration(
                            color: _selectedAI == 'ollama'
                                ? AppTheme.secondaryColor
                                : AppTheme.darkBorderColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.computer_rounded,
                            color: Colors.white,
                            size: isTablet ? 28 : 24,
                          ),
                        ),
                        SizedBox(height: isTablet ? 12 : 8),
                        Text(
                          'Ollama',
                          style: AppTheme.bodyLarge.copyWith(
                            color: _selectedAI == 'ollama'
                                ? AppTheme.secondaryColor
                                : AppTheme.darkTextPrimaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: isTablet ? 4 : 2),
                        Text(
                          'Execução local',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.darkTextSecondaryColor,
                          ),
                        ),
                      ],
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

  Widget _buildGeminiConfig(bool isTablet) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.primaryColor,
                size: isTablet ? 24 : 20,
              ),
              SizedBox(width: isTablet ? 12 : 8),
              Text(
                'Configuração do Google Gemini',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.darkTextPrimaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            'Chave da API',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.darkTextPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          ModernTextField(
            hint: 'Digite sua chave da API do Google Gemini',
            controller: apiKeyController,
            prefixIcon: Icons.key_rounded,
            obscureText: true,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Container(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
              border: Border.all(
                color: AppTheme.infoColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_rounded,
                  color: AppTheme.infoColor,
                  size: isTablet ? 20 : 18,
                ),
                SizedBox(width: isTablet ? 12 : 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Como obter sua chave API:',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.infoColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: isTablet ? 8 : 4),
                      Text(
                        '1. Acesse https://makersuite.google.com/app/apikey\n'
                        '2. Faça login com sua conta Google\n'
                        '3. Crie uma nova API key\n'
                        '4. Cole a chave no campo acima',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOllamaConfig(bool isTablet) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.computer_rounded,
                color: AppTheme.secondaryColor,
                size: isTablet ? 24 : 20,
              ),
              SizedBox(width: isTablet ? 12 : 8),
              Text(
                'Configuração do Ollama',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.darkTextPrimaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            'Modelo',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.darkTextPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: AppTheme.darkSurfaceColor,
              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
              border: Border.all(
                color: AppTheme.darkBorderColor,
                width: 1.5,
              ),
            ),
            child: _loadingModels
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _modeloOllama,
                      isExpanded: true,
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.darkTextPrimaryColor,
                      ),
                      dropdownColor: AppTheme.darkSurfaceColor,
                      icon: Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      items: _ollamaModels.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _modeloOllama = newValue;
                          });
                        }
                      },
                    ),
                  ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Container(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
              border: Border.all(
                color: AppTheme.warningColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: AppTheme.warningColor,
                  size: isTablet ? 20 : 18,
                ),
                SizedBox(width: isTablet ? 12 : 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Requisitos do Ollama:',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.warningColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: isTablet ? 8 : 4),
                      Text(
                        '• Ollama deve estar instalado e rodando\n'
                        '• Servidor local em http://localhost:11434\n'
                        '• Modelo selecionado deve estar baixado',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreloadConfig(bool isTablet) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Precarregamento de Perguntas',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.darkTextPrimaryColor,
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          
          // Switch para habilitar precarregamento
          Container(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: AppTheme.darkSurfaceColor,
              borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
              border: Border.all(
                color: AppTheme.darkBorderColor,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modo Precarregamento Inteligente',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.darkTextPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: isTablet ? 4 : 2),
                      Text(
                        'Prioriza perguntas precarregadas nos quizzes',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                        ),
                      ),
                      if (_preloadEnabled) ...[
                        SizedBox(height: isTablet ? 8 : 4),
                        Row(
                          children: [
                            Icon(
                              Icons.stars_rounded,
                              color: AppTheme.primaryColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Créditos disponíveis: $_currentCredits',
                              style: AppTheme.bodySmall.copyWith(
                                color: _currentCredits > 0 
                                  ? AppTheme.successColor 
                                  : AppTheme.warningColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Switch(
                  value: _preloadEnabled,
                  onChanged: (value) async {
                    await PreloadService.setPreloadEnabled(value);
                    setState(() {
                      _preloadEnabled = value;
                    });
                  },
                  activeThumbColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
          
          // Controle de quantidade (só aparece se preload estiver ativo)
          if (_preloadEnabled) ...[
            SizedBox(height: isTablet ? 16 : 12),
            Container(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              decoration: BoxDecoration(
                color: AppTheme.darkSurfaceColor,
                borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                border: Border.all(
                  color: AppTheme.darkBorderColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quantidade de perguntas',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.darkTextPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$_preloadQuantity',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primaryColor,
                      inactiveTrackColor: AppTheme.darkBorderColor,
                      thumbColor: AppTheme.primaryColor,
                      overlayColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: _preloadQuantity.toDouble(),
                      min: 10,
                      max: 200,
                      divisions: 19, // Divisões de 10 em 10
                      onChanged: (value) async {
                        final newQuantity = value.round();
                        await PreloadService.setPreloadQuantity(newQuantity);
                        setState(() {
                          _preloadQuantity = newQuantity;
                        });
                      },
                    ),
                  ),
                  Text(
                    'Define quantos créditos serão gerados (10-200)',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.darkTextSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Botão para iniciar precarregamento manual
          if (_preloadEnabled) ...[
            SizedBox(height: isTablet ? 16 : 12),
            SizedBox(
              width: double.infinity,
              child: ModernButton(
                text: 'Iniciar Precarregamento Agora',
                onPressed: _startManualPreload,
                isPrimary: false,
                icon: Icons.auto_awesome_rounded,
              ),
            ),
          ],
          
          // Informações sobre o precarregamento
          SizedBox(height: isTablet ? 16 : 12),
          Container(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.primaryColor,
                  size: isTablet ? 20 : 18,
                ),
                SizedBox(width: isTablet ? 12 : 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Como funciona:',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: isTablet ? 8 : 4),
                      Text(
                        '• Quantidade configurável (10-200 perguntas)\n'
                        '• Cada pergunta usada do cache consome 1 crédito\n'
                        '• Prioriza sempre perguntas precarregadas nos quizzes\n'
                        '• Recarrega automaticamente quando créditos acabam\n'
                        '• Inclui um mini-jogo durante o carregamento\n'
                        '• Só funciona quando a IA está online',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startManualPreload() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PreloadScreen(
          selectedAI: _selectedAI,
          apiKey: _selectedAI == 'gemini' ? apiKeyController.text.trim() : null,
          ollamaModel: _selectedAI == 'ollama' ? _modeloOllama : null,
          onComplete: () async {
            Navigator.of(context).pop();
            // Recarrega os créditos após o precarregamento
            final credits = await PreloadService.getCredits();
            setState(() {
              _currentCredits = credits;
            });
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: ModernButton(
            text: 'Salvar Configurações',
            icon: Icons.save_rounded,
            onPressed: _salvarConfiguracoes,
            isPrimary: true,
          ),
        ),
        SizedBox(width: isTablet ? 16 : 12),
        Expanded(
          child: ModernButton(
            text: 'Testar Conexão',
            icon: Icons.wifi_find_rounded,
            onPressed: testarConexao,
            isLoading: carregando,
            isPrimary: false,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(bool isTablet) {
    final isSuccess = status.contains('✅');
    final isError = status.contains('❌');

    Color statusColor = AppTheme.infoColor;
    if (isSuccess) statusColor = AppTheme.successColor;
    if (isError) statusColor = AppTheme.errorColor;

    return ModernCard(
      child: Row(
        children: [
          Icon(
            isSuccess
                ? Icons.check_circle_rounded
                : isError
                    ? Icons.error_rounded
                    : Icons.info_rounded,
            color: statusColor,
            size: isTablet ? 24 : 20,
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Text(
              status,
              style: AppTheme.bodyLarge.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(bool isTablet) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_rounded,
                color: AppTheme.primaryColor,
                size: isTablet ? 24 : 20,
              ),
              SizedBox(width: isTablet ? 12 : 8),
              Text(
                'Informações Importantes',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.darkTextPrimaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          _buildInfoItem(
            'Privacidade',
            'Suas chaves de API são armazenadas localmente no dispositivo',
            Icons.security_rounded,
            isTablet,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          _buildInfoItem(
            'Modo Offline',
            'Se nenhum serviço estiver disponível, o app funcionará offline',
            Icons.offline_bolt_rounded,
            isTablet,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          _buildInfoItem(
            'Performance',
            'Gemini oferece maior precisão, Ollama oferece maior privacidade',
            Icons.speed_rounded,
            isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
      String title, String description, IconData icon, bool isTablet) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isTablet ? 40 : 32,
          height: isTablet ? 40 : 32,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: isTablet ? 20 : 16,
          ),
        ),
        SizedBox(width: isTablet ? 16 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.darkTextPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: isTablet ? 4 : 2),
              Text(
                description,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.darkTextSecondaryColor,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
