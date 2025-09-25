import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../services/ia_service.dart';
import '../services/preload_service.dart';
import '../services/cache_ia_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_components.dart';

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
  final bool _aiAvailable = false;

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

    if (kDebugMode) {
      print(
          '🔧 Configurações carregadas - Créditos: $credits, Preload: $preloadEnabled');
    }

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
    if (apiKey.isEmpty && _selectedAI == 'gemini') return;

    final prefs = await SharedPreferences.getInstance();
    if (_selectedAI == 'gemini') {
      await prefs.setString('gemini_api_key', apiKey);
    }
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

        // Teste detalhado
        final testResult = await geminiService.testApiDetailed();

        if (testResult['success']) {
          status = '✅ Gemini API funcionando!\n'
              '🤖 Resposta: ${testResult['response']}\n'
              '🔑 Key: ${testResult['apiKey']}';
        } else {
          final errorType = testResult['errorType'] ?? 'UNKNOWN';
          String errorMessage = '';

          switch (errorType) {
            case 'INVALID_API_KEY':
              errorMessage = '❌ API Key inválida ou expirada\n'
                  '💡 Verifique se a key está correta no Google AI Studio';
              break;
            case 'QUOTA_EXCEEDED':
              errorMessage = '❌ Cota da API excedida\n'
                  '💡 Aguarde ou use uma nova API key';
              break;
            case 'NETWORK_ERROR':
              errorMessage = '❌ Erro de conexão\n'
                  '💡 Verifique sua conexão com a internet';
              break;
            default:
              errorMessage = '❌ Erro: ${testResult['error']}';
          }

          status = errorMessage;
        }
      } else if (_selectedAI == 'ollama') {
        final ollamaService = OllamaService(defaultModel: _modeloOllama);
        final isAvailable = await ollamaService.isServiceAvailable();
        status = isAvailable
            ? '✅ Conexão com Ollama funcionando!'
            : '❌ Erro na conexão com Ollama.';
      } else if (_selectedAI == 'flutter_gemma') {
        final flutterGemmaService = FlutterGemmaService();
        final isAvailable = await flutterGemmaService.isServiceAvailable();
        status = isAvailable
            ? '✅ Flutter Gemma funcionando!'
            : '❌ Erro no Flutter Gemma.';
      }
    } catch (e) {
      status = '❌ Erro ao testar conexão: $e';
    }
    setState(() => carregando = false);

    // Limpar status após 8 segundos (mais tempo para ler o status detalhado)
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() => status = '');
      }
    });
  }

  Future<void> _limparCache() async {
    // Confirmar ação com o usuário
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurfaceColor,
        title: Text(
          'Limpar Cache',
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.darkTextPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Tem certeza que deseja limpar todas as perguntas precarregadas? '
          'Esta ação não pode ser desfeita.',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.darkTextSecondaryColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.darkTextSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Limpar',
              style: TextStyle(color: AppTheme.warningColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => carregando = true);
      try {
        await CacheIAService.limparTodoCache();
        await _recarregarCreditos(); // Atualiza os créditos na interface
        setState(() {
          status = '🗑️ Cache limpo com sucesso!';
        });
      } catch (e) {
        setState(() {
          status = '❌ Erro ao limpar cache: $e';
        });
      } finally {
        setState(() => carregando = false);
      }

      // Limpar status após alguns segundos
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => status = '');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 1200;
                return isDesktop
                    ? _buildDesktopLayout()
                    : _buildMobileTabletLayout();
              },
            ),
          ),
        ),
      ),
    );
  }

  // Layout para mobile e tablet
  Widget _buildMobileTabletLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final maxWidth = isMobile ? double.infinity : 600.0;
    final horizontalPadding = isMobile ? 16.0 : 24.0;

    return Column(
      children: [
        // Header responsivo
        const ResponsiveHeader(
          title: 'Configurações',
          subtitle: 'Configure os serviços de IA e preferências',
          showBackButton: true,
        ),

        // Conteúdo principal
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isMobile ? 12 : 16,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: _buildServiceSelector(
                          isMobile, isTablet, false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Layout otimizado para desktop
  Widget _buildDesktopLayout() {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
    final isDesktop = screenSize.width >= 1200;

    // Calcula padding responsivo
    double horizontalPadding = 16;
    if (isTablet) horizontalPadding = 32;
    if (isDesktop) horizontalPadding = 64;

    // Calcula largura máxima do conteúdo
    double maxWidth = double.infinity;
    if (isDesktop) maxWidth = 1000;
    if (isTablet) maxWidth = 800;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar com navegação das seções
        Container(
          width: 280,
          height: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.darkSurfaceColor.withValues(alpha: 0.5),
            border: Border(
              right: BorderSide(
                color: AppTheme.darkBorderColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header da sidebar
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configurações',
                        style: TextStyle(
                          color: AppTheme.darkTextPrimaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Sistema de IA',
                        style: TextStyle(
                          color: AppTheme.darkTextSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Status da configuração atual
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkBackgroundColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.darkBorderColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuração Atual',
                      style: TextStyle(
                        color: AppTheme.darkTextPrimaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getServiceStatusColor(),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getServiceName(_selectedAI),
                            style: TextStyle(
                              color: AppTheme.darkTextSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_currentCredits > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '$_currentCredits créditos disponíveis',
                        style: TextStyle(
                          color: AppTheme.successColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Ações rápidas
              Text(
                'AÇÕES RÁPIDAS',
                style: TextStyle(
                  color: AppTheme.darkTextSecondaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              _buildQuickAction(
                icon: Icons.wifi_find_rounded,
                title: 'Testar Conexão',
                subtitle: 'Verificar conectividade',
                onTap: () {}, // TODO: implementar testar conexão
              ),
              const SizedBox(height: 8),
              _buildQuickAction(
                icon: Icons.analytics_rounded,
                title: 'Teste Detalhado',
                subtitle: 'Diagnóstico completo',
                onTap: _mostrarTesteDetalhado,
              ),
              const SizedBox(height: 8),
              _buildQuickAction(
                icon: Icons.save_rounded,
                title: 'Salvar Config',
                subtitle: 'Manter configurações',
                onTap: _salvarConfiguracoes,
              ),
              if (_preloadEnabled) ...[
                const SizedBox(height: 8),
                _buildQuickAction(
                  icon: Icons.delete_sweep_rounded,
                  title: 'Limpar Cache',
                  subtitle: 'Remove dados temporários',
                  onTap: _limparCache,
                ),
              ],

              const Spacer(),

              // Informações de uso
              if (status.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor().withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getStatusIcon(),
                            color: _getStatusColor(),
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Status',
                            style: TextStyle(
                              color: _getStatusColor(),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status.replaceAll(RegExp(r'[✅❌🗑️]'), '').trim(),
                        style: TextStyle(
                          color: AppTheme.darkTextSecondaryColor,
                          fontSize: 10,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
          ),
            
          ),
          // Conteúdo principal
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: isMobile ? 12 : 16,
                  ),
                  child: Column(
                    children: [
                      // Seleção de serviço
                      _buildServiceSelector(
                          isMobile, isTablet, isDesktop),
                      SizedBox(
                          height: isMobile ? 16 : (isTablet ? 20 : 24)),

                      // Configuração do Gemini
                      if (_selectedAI == 'gemini') ...[
                        _buildGeminiConfig(isMobile, isTablet, isDesktop),
                        SizedBox(
                            height: isMobile ? 16 : (isTablet ? 20 : 24)),
                      ],

                      // Configuração do Ollama
                      if (_selectedAI == 'ollama') ...[
                        _buildOllamaConfig(isMobile, isTablet, isDesktop),
                        SizedBox(
                            height: isMobile ? 16 : (isTablet ? 20 : 24)),
                      ],

                      // Configuração do Flutter Gemma
                      if (_selectedAI == 'flutter_gemma') ...[
                        _buildFlutterGemmaConfig(
                            isMobile, isTablet, isDesktop),
                        SizedBox(
                            height: isMobile ? 16 : (isTablet ? 20 : 24)),
                      ],

                      // Configurações de Precarregamento
                      _buildPreloadConfig(isMobile, isTablet, isDesktop),
                      SizedBox(
                          height: isMobile ? 16 : (isTablet ? 20 : 24)),

                      // Botões de ação
                      _buildActionButtons(isMobile, isTablet, isDesktop),
                      SizedBox(
                          height: isMobile ? 16 : (isTablet ? 20 : 24)),

                      // Status
                      if (status.isNotEmpty) ...[
                        _buildStatusCard(isMobile, isTablet, isDesktop),
                        SizedBox(
                            height: isMobile ? 16 : (isTablet ? 20 : 24)),
                      ],

                      // Informações adicionais
                      _buildInfoSection(isMobile, isTablet, isDesktop),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSelector(bool isMobile, bool isTablet, bool isDesktop) {
    // Calcula tamanhos responsivos
    final cardPadding = isMobile ? 12.0 : (isTablet ? 16.0 : 20.0);
    final iconSize = isMobile ? 40.0 : (isTablet ? 48.0 : 56.0);
    final iconInternalSize = isMobile ? 20.0 : (isTablet ? 24.0 : 28.0);
    final borderRadius = isMobile ? 8.0 : (isTablet ? 12.0 : 16.0);
    final spacing = isMobile ? 8.0 : (isTablet ? 12.0 : 16.0);

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecionar Serviço de IA',
            style: (isMobile ? AppTheme.bodyLarge : AppTheme.headingMedium)
                .copyWith(
              color: AppTheme.darkTextPrimaryColor,
              fontSize: isMobile ? 16 : (isTablet ? 18 : 20),
            ),
          ),
          SizedBox(height: spacing),

          // Layout responsivo: grid para desktop, coluna para mobile
          if (isDesktop)
            Row(
              children: [
                Expanded(
                    child: _buildServiceCard('gemini', cardPadding, iconSize,
                        iconInternalSize, borderRadius, spacing, isMobile)),
                SizedBox(width: spacing),
                Expanded(
                    child: _buildServiceCard('ollama', cardPadding, iconSize,
                        iconInternalSize, borderRadius, spacing, isMobile)),
                SizedBox(width: spacing),
                Expanded(
                    child: _buildServiceCard(
                        'flutter_gemma',
                        cardPadding,
                        iconSize,
                        iconInternalSize,
                        borderRadius,
                        spacing,
                        isMobile)),
              ],
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _buildServiceCard(
                            'gemini',
                            cardPadding,
                            iconSize,
                            iconInternalSize,
                            borderRadius,
                            spacing,
                            isMobile)),
                    SizedBox(width: spacing),
                    Expanded(
                        child: _buildServiceCard(
                            'ollama',
                            cardPadding,
                            iconSize,
                            iconInternalSize,
                            borderRadius,
                            spacing,
                            isMobile)),
                  ],
                ),
                SizedBox(height: spacing),
                _buildServiceCard('flutter_gemma', cardPadding, iconSize,
                    iconInternalSize, borderRadius, spacing, isMobile),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
      String serviceType,
      double padding,
      double iconSize,
      double iconInternalSize,
      double borderRadius,
      double spacing,
      bool isMobile) {
    String title, subtitle;
    IconData icon;
    Color color;

    switch (serviceType) {
      case 'gemini':
        title = 'Google Gemini';
        subtitle = 'Serviço em nuvem';
        icon = Icons.auto_awesome_rounded;
        color = AppTheme.primaryColor;
        break;
      case 'ollama':
        title = 'Ollama';
        subtitle = 'Execução local';
        icon = Icons.computer_rounded;
        color = AppTheme.secondaryColor;
        break;
      case 'flutter_gemma':
        title = 'Flutter Gemma';
        subtitle = 'IA local no Android';
        icon = Icons.smartphone_rounded;
        color = AppTheme.accentColor;
        break;
      default:
        return const SizedBox.shrink();
    }

    final isSelected = _selectedAI == serviceType;

    return InkWell(
      onTap: () {
        setState(() => _selectedAI = serviceType);
        if (serviceType == 'ollama') _fetchOllamaModels();
      },
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : AppTheme.darkSurfaceColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: isSelected ? color : AppTheme.darkBorderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: isSelected ? color : AppTheme.darkBorderColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: iconInternalSize,
              ),
            ),
            SizedBox(height: spacing * 0.75),
            Text(
              title,
              style: AppTheme.bodyMedium.copyWith(
                color: isSelected ? color : AppTheme.darkTextPrimaryColor,
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 12 : 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing * 0.25),
            Text(
              subtitle,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.darkTextSecondaryColor,
                fontSize: isMobile ? 10 : 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeminiConfig(bool isMobile, bool isTablet, bool isDesktop) {
    final spacing = isMobile ? 8.0 : (isTablet ? 12.0 : 16.0);
    final iconSize = isMobile ? 18.0 : (isTablet ? 20.0 : 24.0);
    final borderRadius = isMobile ? 8.0 : (isTablet ? 10.0 : 12.0);

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.primaryColor,
                size: iconSize,
              ),
              SizedBox(width: spacing),
              Text(
                'Configuração do Google Gemini',
                style: (isMobile ? AppTheme.bodyLarge : AppTheme.headingMedium)
                    .copyWith(
                  color: AppTheme.darkTextPrimaryColor,
                  fontSize: isMobile ? 14 : (isTablet ? 16 : 18),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing * 1.5),
          Text(
            'Chave da API',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.darkTextPrimaryColor,
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 12 : 14,
            ),
          ),
          SizedBox(height: spacing),
          ModernTextField(
            hint: 'Digite sua chave da API do Google Gemini',
            controller: apiKeyController,
            prefixIcon: Icons.key_rounded,
            obscureText: true,
          ),
          SizedBox(height: spacing),
          Container(
            padding: EdgeInsets.all(spacing),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(borderRadius),
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
                  size: iconSize,
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Como obter sua chave API:',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.infoColor,
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 11 : 12,
                        ),
                      ),
                      SizedBox(height: spacing * 0.5),
                      Text(
                        '1. Acesse https://makersuite.google.com/app/apikey\n'
                        '2. Faça login com sua conta Google\n'
                        '3. Crie uma nova API key\n'
                        '4. Cole a chave no campo acima',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                          height: 1.4,
                          fontSize: isMobile ? 10 : 11,
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

  Widget _buildOllamaConfig(bool isMobile, bool isTablet, bool isDesktop) {
    final spacing = isMobile ? 8.0 : (isTablet ? 12.0 : 16.0);
    final iconSize = isMobile ? 18.0 : (isTablet ? 20.0 : 24.0);
    final borderRadius = isMobile ? 8.0 : (isTablet ? 10.0 : 12.0);

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.computer_rounded,
                color: AppTheme.secondaryColor,
                size: iconSize,
              ),
              SizedBox(width: spacing),
              Text(
                'Configuração do Ollama',
                style: (isMobile ? AppTheme.bodyLarge : AppTheme.headingMedium)
                    .copyWith(
                  color: AppTheme.darkTextPrimaryColor,
                  fontSize: isMobile ? 14 : (isTablet ? 16 : 18),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing * 1.5),
          Text(
            'Modelo',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.darkTextPrimaryColor,
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 12 : 14,
            ),
          ),
          SizedBox(height: spacing),
          Container(
            padding: EdgeInsets.symmetric(horizontal: spacing),
            decoration: BoxDecoration(
              color: AppTheme.darkSurfaceColor,
              borderRadius: BorderRadius.circular(borderRadius * 1.5),
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
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.darkTextPrimaryColor,
                        fontSize: isMobile ? 12 : 14,
                      ),
                      dropdownColor: AppTheme.darkSurfaceColor,
                      icon: Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      items: _ollamaModels.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 14,
                            ),
                          ),
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
          SizedBox(height: spacing),
          Container(
            padding: EdgeInsets.all(spacing),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(borderRadius),
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
                  size: iconSize,
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Requisitos do Ollama:',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.warningColor,
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 11 : 12,
                        ),
                      ),
                      SizedBox(height: spacing * 0.5),
                      Text(
                        '• Ollama deve estar instalado e rodando\n'
                        '• Servidor local em http://localhost:11434\n'
                        '• Modelo selecionado deve estar baixado',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                          height: 1.4,
                          fontSize: isMobile ? 10 : 11,
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

  Widget _buildFlutterGemmaConfig(
      bool isMobile, bool isTablet, bool isDesktop) {
    final spacing = isMobile ? 8.0 : (isTablet ? 12.0 : 16.0);
    final iconSize = isMobile ? 18.0 : (isTablet ? 20.0 : 24.0);
    final borderRadius = isMobile ? 8.0 : (isTablet ? 10.0 : 12.0);

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.smartphone_rounded,
                color: AppTheme.accentColor,
                size: iconSize,
              ),
              SizedBox(width: spacing),
              Text(
                'Configuração do Flutter Gemma',
                style: (isMobile ? AppTheme.bodyLarge : AppTheme.headingMedium)
                    .copyWith(
                  color: AppTheme.darkTextPrimaryColor,
                  fontSize: isMobile ? 14 : (isTablet ? 16 : 18),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing * 1.5),

          // Status do modelo
          FutureBuilder<Map<String, dynamic>>(
            future: _getFlutterGemmaStatus(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final modelInfo = snapshot.data ?? {};
              final exists = modelInfo['exists'] ?? false;
              final size = modelInfo['sizeFormatted'] ?? '0 B';

              return Container(
                padding: EdgeInsets.all(spacing),
                decoration: BoxDecoration(
                  color: exists
                      ? AppTheme.successColor.withValues(alpha: 0.1)
                      : AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: exists
                        ? AppTheme.successColor.withValues(alpha: 0.3)
                        : AppTheme.warningColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      exists ? Icons.check_circle_rounded : Icons.download_rounded,
                      color: exists ? AppTheme.successColor : AppTheme.warningColor,
                      size: iconSize,
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exists ? 'Modelo Carregado' : 'Modelo Não Encontrado',
                            style: AppTheme.bodyMedium.copyWith(
                              color: exists ? AppTheme.successColor : AppTheme.warningColor,
                              fontWeight: FontWeight.w600,
                              fontSize: isMobile ? 12 : 14,
                            ),
                          ),
                          SizedBox(height: spacing * 0.25),
                          Text(
                            exists
                                ? 'Tamanho: $size - Pronto para uso'
                                : 'Clique em "Baixar Modelo" para configurar',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.darkTextSecondaryColor,
                              fontSize: isMobile ? 10 : 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          SizedBox(height: spacing),

          // Botões de ação
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: isMobile ? 40 : (isTablet ? 44 : 48),
                  child: ElevatedButton.icon(
                    onPressed: carregando ? null : _baixarModeloGemma,
                    icon: Icon(
                      Icons.download_rounded,
                      size: isMobile ? 14 : (isTablet ? 16 : 18),
                    ),
                    label: Text(
                      'Baixar Modelo',
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 11 : 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: SizedBox(
                  height: isMobile ? 40 : (isTablet ? 44 : 48),
                  child: ElevatedButton.icon(
                    onPressed: carregando ? null : _testarFlutterGemma,
                    icon: Icon(
                      Icons.play_arrow_rounded,
                      size: isMobile ? 14 : (isTablet ? 16 : 18),
                    ),
                    label: Text(
                      'Testar',
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 11 : 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      foregroundColor: AppTheme.primaryColor,
                      elevation: 0,
                      side: BorderSide(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: spacing),

          Container(
            padding: EdgeInsets.all(spacing),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: AppTheme.infoColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.infoColor,
                  size: iconSize,
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IA Local no Android',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.infoColor,
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 11 : 12,
                        ),
                      ),
                      SizedBox(height: spacing * 0.5),
                      Text(
                        '• Executa diretamente no dispositivo Android\n'
                        '• Não requer conexão com internet após configuração\n'
                        '• Melhor privacidade e segurança dos dados\n'
                        '• Recomendado modelo: Gemma 3 1B para melhor performance\n'
                        '• Funciona apenas em dispositivos Android',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                          height: 1.4,
                          fontSize: isMobile ? 10 : 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing),
          Container(
            padding: EdgeInsets.all(spacing),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(borderRadius),
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
                  size: iconSize,
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuração Necessária:',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.warningColor,
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 11 : 12,
                        ),
                      ),
                      SizedBox(height: spacing * 0.5),
                      Text(
                        '• Baixar modelo Gemma do HuggingFace ou Kaggle\n'
                        '• Carregar modelo no app via assets ou rede\n'
                        '• Requer Android com pelo menos 4GB RAM\n'
                        '• Primeira configuração pode demorar alguns minutos',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                          height: 1.4,
                          fontSize: isMobile ? 10 : 11,
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

  Widget _buildPreloadConfig(bool isMobile, bool isTablet, bool isDesktop) {
    final spacing = isMobile ? 8.0 : (isTablet ? 12.0 : 16.0);
    final iconSize = isMobile ? 18.0 : (isTablet ? 20.0 : 24.0);
    final borderRadius = isMobile ? 8.0 : (isTablet ? 10.0 : 12.0);

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Precarregamento de Perguntas',
            style: (isMobile ? AppTheme.bodyLarge : AppTheme.headingMedium)
                .copyWith(
              color: AppTheme.darkTextPrimaryColor,
              fontSize: isMobile ? 14 : (isTablet ? 16 : 18),
            ),
          ),
          SizedBox(height: spacing),

          // Informações sobre créditos atuais
          Container(
            padding: EdgeInsets.all(spacing),
            decoration: BoxDecoration(
              color: _currentCredits > 0
                  ? AppTheme.successColor.withValues(alpha: 0.1)
                  : AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: _currentCredits > 0
                    ? AppTheme.successColor.withValues(alpha: 0.3)
                    : AppTheme.warningColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _currentCredits > 0
                      ? Icons.inventory_rounded
                      : Icons.warning_rounded,
                  color: _currentCredits > 0
                      ? AppTheme.successColor
                      : AppTheme.warningColor,
                  size: iconSize,
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Perguntas Precarregadas',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.darkTextPrimaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                      SizedBox(height: spacing * 0.25),
                      Text(
                        _currentCredits > 0
                            ? '$_currentCredits pergunta${_currentCredits != 1 ? 's' : ''} disponível${_currentCredits != 1 ? 'eis' : ''}'
                            : 'Nenhuma pergunta precarregada',
                        style: AppTheme.bodySmall.copyWith(
                          color: _currentCredits > 0
                              ? AppTheme.successColor
                              : AppTheme.warningColor,
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 11 : 12,
                        ),
                      ),
                      SizedBox(height: spacing * 0.25),
                      Text(
                        _currentCredits > 0
                            ? 'Cada pergunta usada é removida do cache'
                            : 'Inicie o precarregamento para criar perguntas',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                          fontSize: isMobile ? 10 : 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Switch para habilitar precarregamento
          SizedBox(height: spacing),
          Container(
            padding: EdgeInsets.all(spacing),
            decoration: BoxDecoration(
              color: AppTheme.darkSurfaceColor,
              borderRadius: BorderRadius.circular(borderRadius),
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
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.darkTextPrimaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                      SizedBox(height: spacing * 0.25),
                      Text(
                        'Prioriza perguntas precarregadas nos quizzes',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                          fontSize: isMobile ? 10 : 11,
                        ),
                      ),
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
                  activeTrackColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),

          // Controle de quantidade (só aparece se preload estiver ativo)
          if (_preloadEnabled) ...[
            SizedBox(height: spacing),
            Container(
              padding: EdgeInsets.all(spacing),
              decoration: BoxDecoration(
                color: AppTheme.darkSurfaceColor,
                borderRadius: BorderRadius.circular(borderRadius),
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
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.darkTextPrimaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                      Text(
                        '$_preloadQuantity',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing * 0.75),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primaryColor,
                      inactiveTrackColor: AppTheme.darkBorderColor,
                      thumbColor: AppTheme.primaryColor,
                      overlayColor:
                          AppTheme.primaryColor.withValues(alpha: 0.2),
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
                      fontSize: isMobile ? 10 : 11,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Botão para iniciar precarregamento manual
          if (_preloadEnabled) ...[
            SizedBox(height: spacing * 0.75),
            SizedBox(
              width: double.infinity,
              height: isMobile ? 44 : (isTablet ? 52 : 56),
              child: ElevatedButton.icon(
                onPressed: carregando ? null : _limparCache,
                icon: Icon(
                  Icons.delete_sweep_rounded,
                  color: AppTheme.warningColor,
                  size: isMobile ? 16 : (isTablet ? 18 : 20),
                ),
                label: Text(
                  'Limpar Perguntas Precarregadas',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 11 : 12,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warningColor.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.warningColor,
                  elevation: 0,
                  side: BorderSide(
                    color: AppTheme.warningColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
              ),
            ),
          ],

          // Informações sobre o precarregamento
          SizedBox(height: spacing),
          Container(
            padding: EdgeInsets.all(spacing),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(borderRadius),
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
                  size: iconSize,
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sistema de Créditos:',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 11 : 12,
                        ),
                      ),
                      SizedBox(height: spacing * 0.5),
                      Text(
                        '• 1 pergunta precarregada = 1 crédito\n'
                        '• Cada pergunta usada é removida do cache\n'
                        '• Quando os créditos acabam, usa IA em tempo real\n'
                        '• Precarregamento: 10-200 perguntas por vez\n'
                        '• Mini-jogo disponível durante o processo\n'
                        '• Requer IA online para funcionar',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                          height: 1.4,
                          fontSize: isMobile ? 10 : 11,
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

  
  Widget _buildActionButtons(bool isMobile, bool isTablet, bool isDesktop) {
    final spacing = isMobile ? 8.0 : (isTablet ? 12.0 : 16.0);

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
        SizedBox(width: spacing),
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

  Widget _buildStatusCard(bool isMobile, bool isTablet, bool isDesktop) {
    final spacing = isMobile ? 8.0 : (isTablet ? 12.0 : 16.0);
    final iconSize = isMobile ? 18.0 : (isTablet ? 20.0 : 24.0);

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
            size: iconSize,
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Text(
              status,
              style: AppTheme.bodyMedium.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(bool isMobile, bool isTablet, bool isDesktop) {
    final spacing = isMobile ? 8.0 : (isTablet ? 12.0 : 16.0);
    final iconSize = isMobile ? 18.0 : (isTablet ? 20.0 : 24.0);

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_rounded,
                color: AppTheme.primaryColor,
                size: iconSize,
              ),
              SizedBox(width: spacing),
              Text(
                'Informações Importantes',
                style: (isMobile ? AppTheme.bodyLarge : AppTheme.headingMedium)
                    .copyWith(
                  color: AppTheme.darkTextPrimaryColor,
                  fontSize: isMobile ? 14 : (isTablet ? 16 : 18),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing * 1.5),
          _buildInfoItem(
            'Privacidade',
            'Suas chaves de API são armazenadas localmente no dispositivo',
            Icons.security_rounded,
            isMobile,
            isTablet,
            isDesktop,
          ),
          SizedBox(height: spacing),
          _buildInfoItem(
            'Modo Offline',
            'Se nenhum serviço estiver disponível, o app funcionará offline',
            Icons.offline_bolt_rounded,
            isMobile,
            isTablet,
            isDesktop,
          ),
          SizedBox(height: spacing),
          _buildInfoItem(
            'Performance',
            'Gemini oferece maior precisão, Ollama oferece maior privacidade',
            Icons.speed_rounded,
            isMobile,
            isTablet,
            isDesktop,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String description, IconData icon,
      bool isMobile, bool isTablet, bool isDesktop) {
    final spacing = isMobile ? 8.0 : (isTablet ? 12.0 : 16.0);
    final iconSize = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);
    final containerSize = isMobile ? 28.0 : (isTablet ? 32.0 : 40.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: iconSize,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.darkTextPrimaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
              SizedBox(height: spacing * 0.25),
              Text(
                description,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.darkTextSecondaryColor,
                  height: 1.4,
                  fontSize: isMobile ? 10 : 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _getFlutterGemmaStatus() async {
    try {
      final gemmaService = FlutterGemmaService(
        onStatusUpdate: (status) {
          setState(() => this.status = status);
        },
        onDownloadProgress: (progress) {
          // Pode ser usado para mostrar progresso em um indicador visual
        },
      );
      return await gemmaService.getModelInfo();
    } catch (e) {
      return {
        'exists': false,
        'error': e.toString(),
      };
    }
  }

  Future<void> _baixarModeloGemma() async {
    setState(() => carregando = true);

    try {
      final gemmaService = FlutterGemmaService(
        onStatusUpdate: (status) {
          setState(() => this.status = status);
        },
        onDownloadProgress: (progress) {
          // Atualizar UI com progresso se necessário
          setState(() {});
        },
      );

      final success = await gemmaService.forceDownloadModel();
      if (success) {
        setState(() {
          status = '✅ Modelo baixado com sucesso!';
        });
      } else {
        setState(() {
          status = '❌ Falha no download do modelo';
        });
      }
    } catch (e) {
      setState(() {
        status = '❌ Erro no download: $e';
      });
    } finally {
      setState(() => carregando = false);
    }

    // Limpar status após alguns segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => status = '');
      }
    });
  }

  Future<void> _testarFlutterGemma() async {
    setState(() => carregando = true);

    try {
      final gemmaService = FlutterGemmaService(
        onStatusUpdate: (status) {
          setState(() => this.status = status);
        },
      );

      final isAvailable = await gemmaService.isServiceAvailable();
      if (isAvailable) {
        // Testar uma geração simples
        final response = await gemmaService.generate('Olá, teste de funcionamento');
        setState(() {
          status = '✅ Flutter Gemma funcionando! Resposta: ${response.substring(0, min(50, response.length))}...';
        });
      } else {
        setState(() {
          status = '❌ Flutter Gemma não está disponível';
        });
      }
    } catch (e) {
      setState(() {
        status = '❌ Erro no teste: $e';
      });
    } finally {
      setState(() => carregando = false);
    }

    // Limpar status após alguns segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => status = '');
      }
    });
  }

  Future<void> _mostrarTesteDetalhado() async {
    if (_selectedAI != 'gemini') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Teste detalhado disponível apenas para Gemini'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Dialog de loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurfaceColor,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Executando teste detalhado...',
              style: TextStyle(color: AppTheme.darkTextPrimaryColor),
            ),
          ],
        ),
      ),
    );

    try {
      final geminiService = GeminiService(apiKey: apiKeyController.text.trim());
      final result = await geminiService.testApiDetailed();

      if (!mounted) return;
      Navigator.pop(context); // Fechar dialog de loading

      // Mostrar resultado detalhado
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.darkSurfaceColor,
          title: Row(
            children: [
              Icon(
                result['success'] ? Icons.check_circle : Icons.error,
                color: result['success']
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
              ),
              const SizedBox(width: 8),
              Text(
                result['success'] ? 'Teste Bem-sucedido' : 'Teste Falhou',
                style: TextStyle(
                  color: AppTheme.darkTextPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailItem('🔑 API Key', result['apiKey']),
                _buildDetailItem('🤖 Modelo', result['model']),
                _buildDetailItem('⏰ Timestamp', result['timestamp']),
                if (result['success']) ...[
                  _buildDetailItem('✅ Status', 'Funcionando perfeitamente'),
                  _buildDetailItem('📥 Resposta', result['response'] ?? 'N/A'),
                ] else ...[
                  _buildDetailItem(
                      '❌ Tipo de Erro', result['errorType'] ?? 'UNKNOWN'),
                  _buildDetailItem('📝 Detalhes', result['error'] ?? 'N/A'),
                  if (result['errorType'] == 'INVALID_API_KEY')
                    _buildDetailItem('💡 Solução',
                        'Obtenha uma nova API key em https://aistudio.google.com'),
                  if (result['errorType'] == 'QUOTA_EXCEEDED')
                    _buildDetailItem('💡 Solução',
                        'Aguarde a renovação da cota ou use outra API key'),
                  if (result['errorType'] == 'NETWORK_ERROR')
                    _buildDetailItem(
                        '💡 Solução', 'Verifique sua conexão com a internet'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Fechar',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Fechar dialog de loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao executar teste: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.darkTextSecondaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.darkTextPrimaryColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Métodos auxiliares que estavam faltando
  Color _getServiceStatusColor() {
    return _aiAvailable ? AppTheme.successColor : AppTheme.warningColor;
  }

  String _getServiceName(String ai) {
    switch (ai) {
      case 'gemini':
        return 'Google Gemini';
      case 'ollama':
        return 'Ollama Local';
      case 'flutter_gemma':
        return 'Flutter Gemma';
      default:
        return 'Desconhecido';
    }
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkSurfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.darkBorderColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.darkTextPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.darkTextSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.darkTextSecondaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    return _aiAvailable ? AppTheme.successColor : AppTheme.warningColor;
  }

  IconData _getStatusIcon() {
    return _aiAvailable ? Icons.check_circle : Icons.warning;
  }
}
