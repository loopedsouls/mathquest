import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_components.dart';
import '../models/progresso_usuario.dart';
import '../models/modulo_bncc.dart';
import '../models/matematica.dart';
import '../services/progresso_service.dart';
import '../screens/chat_screen.dart';

// Configuração para o programador - definir como false na produção
// ATENÇÃO: Manter como 'false' em produção para respeitar o sistema de progressão
// Definir como 'true' apenas durante desenvolvimento/testes
const bool debugUnlockAllModules = true;

class ModulosScreen extends StatefulWidget {
  final bool isOfflineMode;
  final List<Map<String, dynamic>> exerciciosOffline;

  const ModulosScreen({
    super.key,
    required this.isOfflineMode,
    required this.exerciciosOffline,
  });

  @override
  State<ModulosScreen> createState() => _ModulosScreenState();
}

class _ModulosScreenState extends State<ModulosScreen>
    with TickerProviderStateMixin {
  ProgressoUsuario? _progresso;
  String _cursoSelecionado = 'Matemática Básica';
  bool _carregando = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Estado para controlar visualização
  bool _mostrarChat = false;
  ModuloBNCC? _moduloSelecionado;
  String? _assuntoSelecionado;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _carregarProgresso();
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _carregarProgresso() async {
    try {
      final progresso = await ProgressoService.carregarProgresso();
      setState(() {
        _progresso = progresso;
        _carregando = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _carregando = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar progresso: $e')),
        );
      }
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
          child: _carregando
              ? _buildLoadingScreen()
              : _mostrarChat
                  ? _buildChatView()
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildMobileLayout(),
                    ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 20),
          Text(
            'Carregando seu progresso...',
            style: TextStyle(
              color: AppTheme.darkTextSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildHeader(),
        _buildUnidadesSeletor(),
        Expanded(
          child: _buildModulosGrid(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ResponsiveHeader(
          title: 'Módulos de Estudos',
          subtitle: _progresso != null
              ? 'Nível: ${_progresso!.nivelUsuario.nome} ${_progresso!.nivelUsuario.emoji}'
              : 'Carregando...',
          showBackButton: true,
        ),
      ],
    );
  }

  Widget _buildUnidadesSeletor() {
    final cursos = Matematica.cursos.keys.toList();

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cursos.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final curso = cursos[index];
          final isSelected = curso == _cursoSelecionado;
          final progresso =
              _progresso?.calcularProgressoPorUnidade(curso) ?? 0.0;

          return GestureDetector(
            onTap: () {
              setState(() {
                _cursoSelecionado = curso;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryLightColor
                        ],
                      )
                    : null,
                color: isSelected ? null : AppTheme.darkSurfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor.withValues(alpha: 0.5)
                      : AppTheme.darkBorderColor.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getCursoIcon(curso),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        curso,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.darkTextPrimaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Barra de progresso mais elegante
                  Container(
                    width: 40,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.3)
                          : AppTheme.darkBorderColor.withValues(alpha: 0.5),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progresso,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color:
                              isSelected ? Colors.white : AppTheme.primaryColor,
                        ),
                      ),
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

  String _getCursoIcon(String curso) {
    switch (curso) {
      case 'Matemática Básica':
        return '🔢';
      case 'Geometria':
        return '📐';
      case 'Álgebra':
        return '🔤';
      case 'Trigonometria':
        return '📏';
      case 'Cálculo':
        return '∫';
      case 'Outros':
        return '📚';
      default:
        return '�';
    }
  }

  Widget _buildModulosGrid() {
    final assuntos = Matematica.cursos[_cursoSelecionado]?.keys.toList() ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        itemCount: assuntos.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final assunto = assuntos[index];
          return _buildAssuntoCard(assunto);
        },
      ),
    );
  }

  Widget _buildAssuntoCard(String assunto) {
    // Primeiro tentar mapeamento direto
    final moduloMapeado = _mapearAssuntoParaModulo(assunto);

    ModuloBNCC? modulo;
    if (moduloMapeado != null) {
      modulo = moduloMapeado;
    } else {
      // Fallback: Buscar módulos relacionados com melhor correspondência
      final modulosRelacionados =
          ModulosBNCCData.obterTodosModulos().where((modulo) {
        final assuntoLower = assunto.toLowerCase();
        final tituloLower = modulo.titulo.toLowerCase();
        final descricaoLower = modulo.descricao.toLowerCase();

        // Verificar correspondência exata primeiro
        if (tituloLower.contains(assuntoLower) ||
            tituloLower.contains(assuntoLower.replaceAll(' ', ''))) {
          return true;
        }

        // Verificar se alguma palavra do assunto está no título
        final palavrasAssunto = assuntoLower.split(' ');
        for (final palavra in palavrasAssunto) {
          if (palavra.length > 3 && tituloLower.contains(palavra)) {
            return true;
          }
        }

        // Verificar na descrição
        for (final palavra in palavrasAssunto) {
          if (palavra.length > 3 && descricaoLower.contains(palavra)) {
            return true;
          }
        }

        return false;
      }).toList();

      modulo =
          modulosRelacionados.isNotEmpty ? modulosRelacionados.first : null;
    }

    // Debug: imprimir assuntos sem módulos correspondentes
    if (modulo == null && debugUnlockAllModules) {
      print('⚠️ Assunto sem módulo correspondente: "$assunto"');
      print('   Módulos encontrados: 0');
    }

    // Obter os subtópicos do assunto
    final subtemas = Matematica.cursos[_cursoSelecionado]?[assunto] ?? [];
    final subtemasPreview = subtemas.take(3).toList();
    final subtemasTexto = subtemasPreview.isNotEmpty
        ? subtemasPreview.join(', ')
        : 'Conteúdo a ser definido';

    if (_progresso == null || modulo == null) {
      return _buildAssuntoCardSimples(assunto, subtemasTexto);
    }

    final isCompleto = _progresso!.modulosCompletos[modulo.unidadeTematica]
            ?[modulo.anoEscolar] ??
        false;
    final isDesbloqueado = debugUnlockAllModules ||
        _progresso!
            .moduloDesbloqueado(modulo.unidadeTematica, modulo.anoEscolar);

    return ModernCard(
      hasGlow: isDesbloqueado,
      child: InkWell(
        onTap: isDesbloqueado ? () => _iniciarAssunto(assunto, modulo!) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícone de status
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCompleto
                        ? [
                            AppTheme.successColor,
                            AppTheme.successColor.withValues(alpha: 0.7)
                          ]
                        : isDesbloqueado
                            ? [
                                AppTheme.primaryColor,
                                AppTheme.primaryLightColor
                              ]
                            : [
                                AppTheme.darkBorderColor,
                                AppTheme.darkBorderColor
                              ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompleto
                      ? Icons.emoji_events_rounded
                      : isDesbloqueado
                          ? Icons.play_circle_filled_rounded
                          : Icons.lock_rounded,
                  color: isDesbloqueado
                      ? Colors.white
                      : AppTheme.darkTextSecondaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Conteúdo principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assunto,
                      style: AppTheme.headingMedium.copyWith(
                        fontSize: 16,
                        color: isDesbloqueado
                            ? AppTheme.darkTextPrimaryColor
                            : AppTheme.darkTextSecondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtemasTexto,
                      style: AppTheme.bodySmall.copyWith(
                        fontSize: 12,
                        color: AppTheme.darkTextSecondaryColor,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Status badge
              if (isDesbloqueado) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleto
                        ? AppTheme.successColor.withValues(alpha: 0.2)
                        : AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCompleto
                          ? AppTheme.successColor
                          : AppTheme.primaryColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isCompleto ? '✓ Completo' : 'Disponível',
                    style: TextStyle(
                      color: isCompleto
                          ? AppTheme.successColor
                          : AppTheme.primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.darkTextSecondaryColor,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssuntoCardSimples(String assunto, String subtemasTexto) {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.darkBorderColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.book_rounded,
                color: AppTheme.darkTextSecondaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assunto,
                    style: AppTheme.headingMedium.copyWith(
                      fontSize: 16,
                      color: AppTheme.darkTextPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtemasTexto,
                    style: AppTheme.bodySmall.copyWith(
                      fontSize: 12,
                      color: AppTheme.darkTextSecondaryColor,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.darkTextSecondaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _iniciarAssunto(String assunto, ModuloBNCC modulo) {
    setState(() {
      _assuntoSelecionado = assunto;
      _moduloSelecionado = modulo;
      _mostrarChat = true;
    });
  }

  ModuloBNCC? _mapearAssuntoParaModulo(String assunto) {
    // Mapeamento direto entre assuntos dos cursos e módulos BNCC
    final mapeamento = {
      'Frações': 'Números Racionais',
      'Divisibilidade': 'Números Naturais e Inteiros',
      'Equações do 1º grau com uma variável': 'Equações do 1º Grau',
      'Equações do 1º grau com duas variáveis': 'Sistemas de Equações',
      'Inequações do 1º grau': 'Equações do 1º Grau',
      'Potenciação': 'Potenciação e Radiciação',
      'Radiciação': 'Potenciação e Radiciação',
      'Razões': 'Números Racionais',
      'Proporções': 'Números Racionais',
      'Algarismos romanos': 'Números Naturais e Inteiros',
      'Grandezas proporcionais': 'Números Racionais',
      'Regra de três': 'Números Racionais',
      'Dízimas periódicas': 'Números Racionais',
      'Porcentagem': 'Números Racionais',
      'Números decimais': 'Números Racionais',
      'Médias': 'Números Racionais',
      'Números racionais': 'Números Racionais',
      'Tabelas': 'Números Naturais e Inteiros',
      'Operações com números racionais decimais': 'Números Racionais',
      'Ângulos': 'Figuras Geométricas',
      'Triângulos': 'Figuras Geométricas',
      'Quadriláteros': 'Figuras Geométricas',
      'Polígonos': 'Figuras Geométricas',
      'Círculos': 'Círculo e Circunferência',
      'Áreas': 'Área de Figuras Planas',
      'Perímetros': 'Área de Figuras Planas',
      'Volumes': 'Volume de Sólidos',
      'Unidades de medida': 'Unidades de Medida',
      'Transformações geométricas': 'Transformações Geométricas',
      'Simetria': 'Transformações Geométricas',
      'Congruência': 'Transformações Geométricas',
      'Semelhança': 'Transformações Geométricas',
      'Trigonometria básica': 'Teorema de Pitágoras',
      'Razões trigonométricas': 'Teorema de Pitágoras',
      'Funções': 'Funções e Equações do 2º Grau',
      'Equações do 2º grau': 'Funções e Equações do 2º Grau',
      'Inequações do 2º grau': 'Funções e Equações do 2º Grau',
      'Funções quadráticas': 'Funções e Equações do 2º Grau',
      'Sequências': 'Sequências e Regularidades',
      'Progressões': 'Sequências e Regularidades',
      'Matrizes': 'Números Reais',
      'Determinantes': 'Números Reais',
      'Sistemas lineares': 'Sistemas de Equações',
      'Vetores': 'Números Reais',
      'Geometria analítica': 'Funções e Equações do 2º Grau',
      'Cônicas': 'Funções e Equações do 2º Grau',
      'Limites': 'Números Reais',
      'Derivadas': 'Números Reais',
      'Integrais': 'Números Reais',
      'Equações diferenciais': 'Números Reais',
    };

    final tituloMapeado = mapeamento[assunto];
    if (tituloMapeado != null) {
      // Buscar módulo com o título mapeado
      final modulos = ModulosBNCCData.obterTodosModulos();
      try {
        return modulos.firstWhere(
          (modulo) => modulo.titulo == tituloMapeado,
        );
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  Widget _buildChatView() {
    if (_moduloSelecionado == null) {
      return _buildMobileLayout();
    }

    final prompt = _criarPromptParaModulo(_moduloSelecionado!);

    return ChatScreen(
      mode: ChatMode.module,
      modulo: _moduloSelecionado,
      progresso: _progresso,
      isOfflineMode: widget.isOfflineMode,
      promptPreconfigurado: prompt,
      onBackPressed: () {
        setState(() {
          _mostrarChat = false;
          _moduloSelecionado = null;
        });
      },
    );
  }

  String _criarPromptParaModulo(ModuloBNCC modulo) {
    // Obter os subtópicos do assunto selecionado
    final subtemas = (_assuntoSelecionado != null &&
            Matematica.cursos[_cursoSelecionado] != null)
        ? Matematica.cursos[_cursoSelecionado]![_assuntoSelecionado!] ?? []
        : [];

    final subtemasTexto = subtemas.isNotEmpty
        ? '\n**Subtópicos a serem ensinados:**\n${subtemas.map((subtema) => '- $subtema').join('\n')}'
        : '';

    return '''
Você é um tutor de matemática especializado na BNCC, especificamente no módulo "${modulo.titulo}" 
do ${modulo.anoEscolar}, unidade temática "${modulo.unidadeTematica}".

**Descrição do módulo:** ${modulo.descricao}

**Assunto selecionado:** ${_assuntoSelecionado ?? 'Nenhum assunto específico'}$subtemasTexto

**Sua função:**
- Seja um tutor paciente e encorajador
- Use linguagem adequada para alunos de ${modulo.anoEscolar}
- Forneça explicações claras e exemplos práticos
- Foque nos conceitos específicos deste módulo
- Ajude o aluno a entender os exercícios e problemas relacionados

**Instruções importantes:**
- Sempre use formatação Markdown para organizar suas respostas
- Use LaTeX para fórmulas matemáticas quando necessário
- Seja específico sobre os conteúdos da BNCC para este módulo
- Incentive o aluno com mensagens positivas
- Adapte a complexidade das explicações ao nível do aluno

**Contexto adicional:**
- Este módulo faz parte do curso: $_cursoSelecionado
- O aluno está estudando conteúdos de ${modulo.anoEscolar}
- Foque em tornar o aprendizado prazeroso e acessível
''';
  }
}
