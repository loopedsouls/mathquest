import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../widgets/core_modern_components_widget.dart';
import '../../../widgets/math_tools_item_visualization_helper_widget.dart';
import '../../../widgets/core_mixins_widget.dart';
import '../models/user_character_model.dart';
import '../services/user_character_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin, LoadingStateMixin, AnimationMixin {
  final PersonagemService _personagemService = PersonagemService();
  PerfilPersonagem? _perfil;
  List<ItemPersonalizacao> _todosItens = [];
  List<ItemPersonalizacao> _inventario = [];

  String _categoriaFiltro = 'todos'; // Para filtrar itens por categoria

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _inicializar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _inicializar() async {
    await executeWithLoadingAndError(() async {
      await _personagemService.inicializar();
      _perfil = _personagemService.perfilAtual;
      _todosItens = _personagemService.getTodosItens();
      _inventario = _personagemService.getInventario();

      animationController.forward();
    }, 'Erro ao carregar perfil');
  }

  Future<void> _equiparItem(ItemPersonalizacao item) async {
    final sucesso = await _personagemService.equiparItem(item.id);
    if (sucesso && mounted) {
      setState(() {
        _perfil = _personagemService.perfilAtual;
      });
      AppTheme.showSuccessSnackBar(context, '${item.nome} equipado!');
    }
  }

  Future<void> _comprarItem(ItemPersonalizacao item) async {
    final sucesso = await _personagemService.comprarItem(item.id);
    if (sucesso && mounted) {
      setState(() {
        _perfil = _personagemService.perfilAtual;
        _inventario = _personagemService.getInventario();
        _todosItens = _personagemService.getTodosItens();
      });
      AppTheme.showSuccessSnackBar(context, '${item.nome} comprado!');
    } else if (mounted) {
      AppTheme.showErrorSnackBar(context, 'Não foi possível comprar o item');
    }
  }

  Future<void> _editarNome() async {
    final controller = TextEditingController(text: _perfil?.nome ?? '');

    final novoNome = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurfaceColor,
        title: Text(
          'Editar Nome',
          style: TextStyle(color: AppTheme.darkTextPrimaryColor),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: AppTheme.darkTextPrimaryColor),
          decoration: InputDecoration(
            hintText: 'Digite o novo nome',
            hintStyle: TextStyle(color: AppTheme.darkTextHintColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.darkBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: TextStyle(color: AppTheme.darkTextSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: AppTheme.elevatedButtonStyle,
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (novoNome != null && novoNome.isNotEmpty) {
      final sucesso = await _personagemService.atualizarNome(novoNome);
      if (sucesso && mounted) {
        setState(() {
          _perfil = _personagemService.perfilAtual;
        });
        AppTheme.showSuccessSnackBar(context, 'Nome atualizado!');
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.darkBackgroundColor,
              AppTheme.darkSurfaceColor.withValues(alpha: 0.3),
              AppTheme.darkBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: isLoading ? _buildLoadingScreen() : _buildContent(),
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
            'Carregando perfil...',
            style: TextStyle(
              color: AppTheme.darkTextSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPersonagemTab(),
                _buildInventarioTab(),
                _buildLojaTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meu Perfil',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkTextPrimaryColor,
                      ),
                    ),
                    Text(
                      'Personalize seu personagem',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.darkTextSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Moedas
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.accentColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: AppTheme.accentColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_perfil?.moedas ?? 0}',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorderColor.withValues(alpha: 0.5),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.person), text: 'Personagem'),
          Tab(icon: Icon(Icons.inventory), text: 'Inventário'),
          Tab(icon: Icon(Icons.store), text: 'Loja'),
        ],
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.darkTextSecondaryColor,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
    );
  }

  Widget _buildPersonagemTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPerfilCard(),
          const SizedBox(height: 20),
          _buildPersonagemPreview(),
          const SizedBox(height: 20),
          _buildItensEquipados(),
        ],
      ),
    );
  }

  Widget _buildPerfilCard() {
    return ModernCard(
      child: Column(
        children: [
          Row(
            children: [
              // Avatar circular
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  ),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _perfil?.nome ?? 'Matemático',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _editarNome,
                          icon: Icon(
                            Icons.edit,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Nível ${_perfil?.nivel ?? 1}',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Barra de experiência
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Experiência',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${_perfil?.experiencia ?? 0} / ${_perfil?.experienciaParaProximoNivel ?? 1000} XP',
                              style: TextStyle(
                                color: AppTheme.darkTextSecondaryColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.darkBorderColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor:
                                (_perfil?.progressoNivel ?? 0).clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor,
                                    AppTheme.accentColor
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonagemPreview() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview do Personagem',
            style: TextStyle(
              color: AppTheme.darkTextPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ItemVisualizationHelper.buildPersonagemCompleto(
              itensEquipados: _perfil?.itensEquipados ?? {},
              width: 220,
              height: 320,
              nome: _perfil?.nome ?? 'Matemático',
              interactive: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItensEquipados() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Itens Equipados',
            style: TextStyle(
              color: AppTheme.darkTextPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...(['cabeca', 'corpo', 'pernas', 'acessorio'].map((categoria) {
            final itemEquipado = _perfil?.getItemEquipado(categoria);
            final item = itemEquipado != null
                ? _todosItens.firstWhere((i) => i.id == itemEquipado)
                : null;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.darkBorderColor,
                      ),
                    ),
                    child: Icon(
                      ItemVisualizationHelper.getIconeCategoria(categoria),
                      color: item != null
                          ? AppTheme.primaryColor
                          : AppTheme.darkTextSecondaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getNomeCategoria(categoria),
                          style: TextStyle(
                            color: AppTheme.darkTextPrimaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          item?.nome ?? 'Nenhum item equipado',
                          style: TextStyle(
                            color: item != null
                                ? AppTheme.darkTextSecondaryColor
                                : AppTheme.darkTextHintColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList()),
        ],
      ),
    );
  }

  Widget _buildInventarioTab() {
    return Column(
      children: [
        _buildCategoriaFilter(),
        Expanded(
          child: _buildInventarioGrid(),
        ),
      ],
    );
  }

  Widget _buildLojaTab() {
    final itensLoja = _todosItens.where((item) => !item.desbloqueado).toList();

    return Column(
      children: [
        _buildCategoriaFilter(),
        Expanded(
          child: _buildLojaGrid(itensLoja),
        ),
      ],
    );
  }

  Widget _buildCategoriaFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['todos', 'cabeca', 'corpo', 'pernas', 'acessorio']
              .map((categoria) {
            final isSelected = _categoriaFiltro == categoria;
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_getNomeCategoria(categoria)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _categoriaFiltro = categoria;
                  });
                },
                backgroundColor: AppTheme.darkSurfaceColor,
                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                checkmarkColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.darkTextSecondaryColor,
                ),
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.darkBorderColor,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInventarioGrid() {
    List<ItemPersonalizacao> itensFiltrados = _inventario;

    if (_categoriaFiltro != 'todos') {
      itensFiltrados = _inventario
          .where((item) => item.categoria == _categoriaFiltro)
          .toList();
    }

    if (itensFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppTheme.darkTextSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum item encontrado',
              style: TextStyle(
                color: AppTheme.darkTextSecondaryColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: itensFiltrados.length,
      itemBuilder: (context, index) {
        return _buildItemCard(itensFiltrados[index], isInventario: true);
      },
    );
  }

  Widget _buildLojaGrid(List<ItemPersonalizacao> itensLoja) {
    List<ItemPersonalizacao> itensFiltrados = itensLoja;

    if (_categoriaFiltro != 'todos') {
      itensFiltrados = itensLoja
          .where((item) => item.categoria == _categoriaFiltro)
          .toList();
    }

    if (itensFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 64,
              color: AppTheme.darkTextSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum item disponível',
              style: TextStyle(
                color: AppTheme.darkTextSecondaryColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: itensFiltrados.length,
      itemBuilder: (context, index) {
        return _buildItemCard(itensFiltrados[index], isInventario: false);
      },
    );
  }

  Widget _buildItemCard(ItemPersonalizacao item, {required bool isInventario}) {
    final isEquipado = _perfil?.getItemEquipado(item.categoria) == item.id;
    final podeComprar = _perfil?.podeComprarItem(item.preco) ?? false;
    final possuido = _perfil?.possuiItem(item.id) ?? false;

    return ItemVisualizationHelper.buildItemCard(
      nome: item.nome,
      categoria: item.categoria,
      raridade: item.raridade,
      preco: item.preco,
      desbloqueado: item.desbloqueado || possuido,
      equipado: isEquipado,
      possuido: possuido,
      condicaoDesbloqueio: item.condicaoDesbloqueio,
      onTap: () {
        if (isInventario || possuido) {
          _equiparItem(item);
        } else if (podeComprar) {
          _comprarItem(item);
        }
      },
    );
  }

  String _getNomeCategoria(String categoria) {
    switch (categoria) {
      case 'todos':
        return 'Todos';
      case 'cabeca':
        return 'Cabeça';
      case 'corpo':
        return 'Corpo';
      case 'pernas':
        return 'Pernas';
      case 'acessorio':
        return 'Acessórios';
      default:
        return categoria;
    }
  }
}
