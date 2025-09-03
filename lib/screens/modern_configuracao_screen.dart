import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_components.dart';
import '../services/gemini_service.dart';
import '../services/ollama_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModernConfiguracaoScreen extends StatefulWidget {
  const ModernConfiguracaoScreen({super.key});

  @override
  State<ModernConfiguracaoScreen> createState() =>
      _ModernConfiguracaoScreenState();
}

class _ModernConfiguracaoScreenState extends State<ModernConfiguracaoScreen>
    with TickerProviderStateMixin {
  final TextEditingController apiKeyController = TextEditingController();
  bool carregando = false;
  String status = '';
  bool _useGeminiDefault = true;
  String _modeloOllama = 'llama2';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _carregarConfiguracoes();
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
    final useGemini = prefs.getBool('use_gemini') ?? true;
    final modeloOllama = prefs.getString('modelo_ollama') ?? 'llama2';

    if (apiKey != null) {
      apiKeyController.text = apiKey;
    } else {
      apiKeyController.text = 'AIzaSyAiNcBfK0i7P6qPuqfhbT3ijZgHJKyW0xo';
    }

    setState(() {
      _useGeminiDefault = useGemini;
      _modeloOllama = modeloOllama;
    });
  }

  Future<void> _salvarConfiguracoes() async {
    final apiKey = apiKeyController.text.trim();
    if (apiKey.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', apiKey);
    await prefs.setBool('use_gemini', _useGeminiDefault);
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
      if (_useGeminiDefault) {
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
                        if (_useGeminiDefault) ...[
                          _buildGeminiConfig(isTablet),
                          SizedBox(height: isTablet ? 30 : 20),
                        ],

                        // Configuração do Ollama
                        if (!_useGeminiDefault) ...[
                          _buildOllamaConfig(isTablet),
                          SizedBox(height: isTablet ? 30 : 20),
                        ],

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
                  onTap: () => setState(() => _useGeminiDefault = true),
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                  child: Container(
                    padding: EdgeInsets.all(isTablet ? 20 : 16),
                    decoration: BoxDecoration(
                      color: _useGeminiDefault
                          ? AppTheme.primaryColor.withOpacity(0.2)
                          : AppTheme.darkSurfaceColor,
                      borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                      border: Border.all(
                        color: _useGeminiDefault
                            ? AppTheme.primaryColor
                            : AppTheme.darkBorderColor,
                        width: _useGeminiDefault ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: isTablet ? 60 : 50,
                          height: isTablet ? 60 : 50,
                          decoration: BoxDecoration(
                            color: _useGeminiDefault
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
                            color: _useGeminiDefault
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
                  onTap: () => setState(() => _useGeminiDefault = false),
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                  child: Container(
                    padding: EdgeInsets.all(isTablet ? 20 : 16),
                    decoration: BoxDecoration(
                      color: !_useGeminiDefault
                          ? AppTheme.secondaryColor.withOpacity(0.2)
                          : AppTheme.darkSurfaceColor,
                      borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                      border: Border.all(
                        color: !_useGeminiDefault
                            ? AppTheme.secondaryColor
                            : AppTheme.darkBorderColor,
                        width: !_useGeminiDefault ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: isTablet ? 60 : 50,
                          height: isTablet ? 60 : 50,
                          decoration: BoxDecoration(
                            color: !_useGeminiDefault
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
                            color: !_useGeminiDefault
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
              color: AppTheme.infoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
              border: Border.all(
                color: AppTheme.infoColor.withOpacity(0.3),
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
            child: DropdownButtonHideUnderline(
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
                items: ['llama2', 'codellama', 'mistral', 'neural-chat']
                    .map((String value) {
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
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
              border: Border.all(
                color: AppTheme.warningColor.withOpacity(0.3),
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
            color: AppTheme.primaryColor.withOpacity(0.2),
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
