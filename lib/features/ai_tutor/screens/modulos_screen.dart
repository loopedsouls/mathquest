import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../../widgets/modern_components.dart';
import '../../user/models/progresso_user_model.dart';
import '../modulo_bncc.dart';
import '../matematica.dart';
import '../../user/services/progresso_service.dart';
import 'chat_screen.dart';

// Configuração para o programador - definir como false na produção
// ATENÇÃO: Manter como 'false' em produção para respeitar o sistema de progressão
// Definir como 'true' apenas durante desenvolvimento/testes
const bool debugUnlockAllModules = false;

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
    final screenWidth = MediaQuery.of(context).size.width;
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
        child: _carregando
            ? _buildLoadingScreen()
            : _mostrarChat
                ? _buildChatView()
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: isDesktop
                        ? _buildDesktopLayout()
                        : SafeArea(child: _buildMobileLayout()),
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
    List<String> cursos = Matematica.cursos.keys.toList();

    // Ordenar: desbloqueados primeiro, depois bloqueados
    cursos.sort((a, b) {
      final aDesbloqueado = _cursoEstaDesbloqueado(a);
      final bDesbloqueado = _cursoEstaDesbloqueado(b);

      if (aDesbloqueado && !bDesbloqueado) return -1;
      if (!aDesbloqueado && bDesbloqueado) return 1;
      return 0; // mantém ordem original se ambos têm mesmo status
    });

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
    final todosAssuntos =
        Matematica.cursos[_cursoSelecionado]?.keys.toList() ?? [];

    // Separar assuntos em disponíveis e bloqueados
    final assuntosDisponiveis = <String>[];
    final assuntosBloqueados = <String>[];

    for (final assunto in todosAssuntos) {
      final modulo = _mapearAssuntoParaModulo(assunto);
      if (modulo != null && _progresso != null) {
        final preRequisitosAtendidos = _verificarPreRequisitos(modulo);
        final isDesbloqueado = _progresso!.moduloDesbloqueado(
                modulo.unidadeTematica, modulo.anoEscolar) &&
            preRequisitosAtendidos;

        if (isDesbloqueado) {
          assuntosDisponiveis.add(assunto);
        } else {
          assuntosBloqueados.add(assunto);
        }
      } else {
        // Se não encontrou módulo ou não tem progresso, considera como bloqueado
        assuntosBloqueados.add(assunto);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        children: [
          // Seção de Disponíveis
          if (assuntosDisponiveis.isNotEmpty) ...[
            _buildSecaoHeader('Disponíveis', Icons.play_circle_rounded,
                AppTheme.primaryColor),
            const SizedBox(height: 8),
            ...assuntosDisponiveis.map((assunto) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildAssuntoCard(assunto),
                )),
          ],

          // Divider entre seções
          if (assuntosDisponiveis.isNotEmpty &&
              assuntosBloqueados.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppTheme.darkBorderColor.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Seção de Bloqueados
          if (assuntosBloqueados.isNotEmpty) ...[
            _buildSecaoHeader('Bloqueados', Icons.lock_rounded,
                AppTheme.darkTextSecondaryColor),
            const SizedBox(height: 8),
            ...assuntosBloqueados.map((assunto) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildAssuntoCard(assunto),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildSecaoHeader(String titulo, IconData icone, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            icone,
            color: cor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            titulo,
            style: AppTheme.headingMedium.copyWith(
              fontSize: 16,
              color: cor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cor.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssuntoCard(String assunto) {
    // Buscar módulo relacionado ao assunto
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

    // Se não encontrou módulo, mostrar card simples
    if (modulo == null) {
      final subtemas = Matematica.cursos[_cursoSelecionado]?[assunto] ?? [];
      final subtemasPreview = subtemas.take(3).toList();
      final subtemasTexto = subtemasPreview.isNotEmpty
          ? subtemasPreview.join(', ')
          : 'Conteúdo a ser definido';

      return _buildAssuntoCardSimples(assunto, subtemasTexto);
    }

    // Verificar se o usuário tem progresso carregado
    if (_progresso == null) {
      return _buildAssuntoCardBloqueado(assunto, 'Carregando progresso...');
    }

    // Verificar pré-requisitos do módulo
    final preRequisitosAtendidos = _verificarPreRequisitos(modulo);
    final isDesbloqueado = _progresso!
            .moduloDesbloqueado(modulo.unidadeTematica, modulo.anoEscolar) &&
        preRequisitosAtendidos;

    // Obter os subtópicos do assunto
    final subtemas = Matematica.cursos[_cursoSelecionado]?[assunto] ?? [];
    final subtemasPreview = subtemas.take(3).toList();
    final subtemasTexto = subtemasPreview.isNotEmpty
        ? subtemasPreview.join(', ')
        : 'Conteúdo a ser definido';

    final isCompleto = _progresso!.modulosCompletos[modulo.unidadeTematica]
            ?[modulo.anoEscolar] ??
        false;

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
                      isDesbloqueado
                          ? subtemasTexto
                          : _getMensagemBloqueio(modulo),
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
                  Icons.lock_rounded,
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

  Widget _buildAssuntoCardBloqueado(String assunto, String mensagem) {
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
                Icons.lock_rounded,
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
                      color: AppTheme.darkTextSecondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mensagem,
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
              Icons.lock_rounded,
              color: AppTheme.darkTextSecondaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  bool _verificarPreRequisitos(ModuloBNCC modulo) {
    if (modulo.prerequisitos.isEmpty) {
      return true; // Sem pré-requisitos
    }

    // Verificar se todos os pré-requisitos foram atendidos
    for (final prerequisito in modulo.prerequisitos) {
      // Aqui você pode implementar a lógica específica de pré-requisitos
      // Por enquanto, vamos considerar que módulos básicos não têm pré-requisitos complexos
      if (prerequisito.isNotEmpty) {
        // Verificar se o módulo pré-requisito foi completado
        final moduloPreReq = ModulosBNCCData.obterTodosModulos()
            .where((m) =>
                m.titulo.contains(prerequisito) ||
                m.unidadeTematica.contains(prerequisito))
            .toList();

        if (moduloPreReq.isNotEmpty) {
          final preReqCompleto =
              _progresso?.modulosCompletos[moduloPreReq.first.unidadeTematica]
                      ?[moduloPreReq.first.anoEscolar] ??
                  false;

          if (!preReqCompleto) {
            return false;
          }
        }
      }
    }

    return true;
  }

  String _getMensagemBloqueio(ModuloBNCC modulo) {
    final anos = ['6º ano', '7º ano', '8º ano', '9º ano'];
    final indiceAno = anos.indexOf(modulo.anoEscolar);

    if (indiceAno == 0) {
      return 'Disponível em breve';
    }

    final anoAnterior = anos[indiceAno - 1];
    return 'Complete os módulos de $anoAnterior primeiro';
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
      'Teoria dos Conjuntos': 'Números Naturais e Inteiros',
      'Geometria plana': 'Figuras Geométricas',
      'Medidas de superfície': 'Área de Figuras Planas',
      'Medidas de volume': 'Volume de Sólidos',
      'Medidas de capacidade': 'Unidades de Medida',
      'Medidas de massa': 'Unidades de Medida',
      'Medidas de tempo': 'Unidades de Medida',
      'Medidas de comprimento': 'Unidades de Medida',
      'Semelhança de Polígonos': 'Transformações Geométricas',
      'Geometria espacial': 'Volume de Sólidos',
      'Geometria analítica - Retas': 'Funções e Equações do 2º Grau',
      'Geometria analítica - Circunferência': 'Círculo e Circunferência',
      'Geometria analítica - Cônicas': 'Funções e Equações do 2º Grau',
      'Análise Combinatória': 'Sequências e Regularidades',
      'Produtos notáveis': 'Números Racionais',
      'Binômio de Newton': 'Sequências e Regularidades',
      'Função do 1º grau ou função afim': 'Funções e Equações do 2º Grau',
      'Função quadrática': 'Funções e Equações do 2º Grau',
      'Números complexos': 'Números Reais',
      'Conjuntos numéricos': 'Números Naturais e Inteiros',
      'Trigonometria': 'Teorema de Pitágoras',
      'Equações trigonométricas': 'Teorema de Pitágoras',
      'Inequações trigonométricas': 'Teorema de Pitágoras',
      'Funções logarítmica e exponencial': 'Números Reais',
      'Séries e sequências': 'Sequências e Regularidades',
      'Função exponencial': 'Números Reais',
      'Função logarítmica': 'Números Reais',
      'Função modular': 'Números Reais',
      'Probabilidade': 'Sequências e Regularidades',
      'Logaritmos': 'Números Reais',
      'Tabelas Avançadas': 'Números Naturais e Inteiros',
      'Matemática Financeira': 'Sequências e Regularidades',
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

  bool _cursoEstaDesbloqueado(String curso) {
    if (_progresso == null) return false;

    // Mapeamento direto: nível do usuário -> cursos disponíveis
    final nivelUsuario = _progresso!.nivelUsuario.index;
    final cursosPorNivel = {
      0: ['Matemática Básica'], // Iniciante
      1: ['Matemática Básica', 'Geometria'], // Intermediário
      2: ['Matemática Básica', 'Geometria', 'Álgebra'], // Avançado
      3: [
        'Matemática Básica',
        'Geometria',
        'Álgebra',
        'Trigonometria',
        'Cálculo',
        'Outros'
      ], // Especialista
    };

    // Verificar se o curso está disponível para o nível atual do usuário
    final cursosDisponiveis = cursosPorNivel[nivelUsuario] ?? [];
    return cursosDisponiveis.contains(curso);
  }

  Widget _buildDesktopLayout() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar esquerda com informações e navegação
          Container(
            width: 350,
            decoration: BoxDecoration(
              color: AppTheme.darkSurfaceColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.darkBorderColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header da sidebar
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Módulos de Estudos',
                        style: TextStyle(
                          color: AppTheme.darkTextPrimaryColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_progresso != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Nível: ${_progresso!.nivelUsuario.nome} ${_progresso!.nivelUsuario.emoji}',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Seletor de cursos
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CURSOS DISPONÍVEIS',
                        style: TextStyle(
                          color: AppTheme.darkTextSecondaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...Matematica.cursos.keys.map((curso) {
                        final isSelected = curso == _cursoSelecionado;
                        final isUnlocked = _cursoEstaDesbloqueado(curso);
                        final progresso =
                            _progresso?.calcularProgressoPorUnidade(curso) ??
                                0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: isUnlocked
                                  ? () {
                                      setState(() {
                                        _cursoSelecionado = curso;
                                      });
                                    }
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                          .withValues(alpha: 0.1)
                                      : (isUnlocked
                                          ? Colors.transparent
                                          : AppTheme.darkBackgroundColor
                                              .withValues(alpha: 0.3)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected
                                      ? Border.all(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.3))
                                      : Border.all(
                                          color: AppTheme.darkBorderColor
                                              .withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          isUnlocked
                                              ? Icons.school_rounded
                                              : Icons.lock_rounded,
                                          color: isSelected
                                              ? AppTheme.primaryColor
                                              : (isUnlocked
                                                  ? AppTheme
                                                      .darkTextPrimaryColor
                                                  : AppTheme
                                                      .darkTextSecondaryColor),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            curso,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? AppTheme.primaryColor
                                                  : (isUnlocked
                                                      ? AppTheme
                                                          .darkTextPrimaryColor
                                                      : AppTheme
                                                          .darkTextSecondaryColor),
                                              fontSize: 14,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (isUnlocked && progresso > 0) ...[
                                      const SizedBox(height: 8),
                                      LinearProgressIndicator(
                                        value: progresso / 100,
                                        backgroundColor:
                                            AppTheme.darkBorderColor,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          isSelected
                                              ? AppTheme.primaryColor
                                              : AppTheme.successColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${progresso.toInt()}% concluído',
                                        style: TextStyle(
                                          color:
                                              AppTheme.darkTextSecondaryColor,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),

                const Spacer(),

                // Estatísticas no rodapé
                if (_progresso != null)
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            AppTheme.darkBackgroundColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              AppTheme.darkBorderColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                '${_progresso!.totalExerciciosCorretos}',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Acertos',
                                style: TextStyle(
                                  color: AppTheme.darkTextSecondaryColor,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: AppTheme.darkBorderColor,
                          ),
                          Column(
                            children: [
                              Text(
                                '${_progresso!.totalExerciciosRespondidos}',
                                style: TextStyle(
                                  color: AppTheme.warningColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Total',
                                style: TextStyle(
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
              ],
            ),
          ),

          const SizedBox(width: 24),

          // Área principal com módulos em grid
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.darkSurfaceColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.darkBorderColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header da área principal
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _cursoSelecionado,
                                style: TextStyle(
                                  color: AppTheme.darkTextPrimaryColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Selecione um módulo para começar',
                                style: TextStyle(
                                  color: AppTheme.darkTextSecondaryColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Grid de módulos
                  Expanded(
                    child: _buildModulosGrid(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
