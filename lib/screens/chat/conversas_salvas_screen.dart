import 'package:flutter/material.dart';
import '../../../models/conversa.dart';
import '../../../services/conversa_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/modern_components.dart';
import '../chat_screen.dart';

class ConversasSalvasScreen extends StatefulWidget {
  const ConversasSalvasScreen({super.key});

  @override
  State<ConversasSalvasScreen> createState() => _ConversasSalvasScreenState();
}

class _ConversasSalvasScreenState extends State<ConversasSalvasScreen> {
  List<Conversa> _conversas = [];
  bool _isLoading = true;
  String _filtroContexto = 'todos';

  @override
  void initState() {
    super.initState();
    _carregarConversas();
  }

  Future<void> _carregarConversas() async {
    setState(() => _isLoading = true);

    try {
      final conversas = await ConversaService.listarConversas();
      setState(() {
        _conversas = conversas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Conversa> get _conversasFiltradas {
    if (_filtroContexto == 'todos') {
      return _conversas;
    } else if (_filtroContexto == 'geral') {
      return _conversas.where((c) => c.contexto == 'geral').toList();
    } else {
      return _conversas.where((c) => c.contexto != 'geral').toList();
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
              _buildFiltros(isTablet),
              Expanded(
                child: _buildListaConversas(isTablet),
              ),
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
              Icons.history_rounded,
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
                  'Conversas Salvas',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: isTablet ? 18 : 16,
                  ),
                ),
                Text(
                  '${_conversasFiltradas.length} conversas',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.darkTextSecondaryColor,
                    fontSize: isTablet ? 12 : 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros(bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: isTablet ? 16 : 12,
      ),
      child: Row(
        children: [
          Text(
            'Filtrar: ',
            style: AppTheme.bodyMedium.copyWith(
              fontSize: isTablet ? 14 : 12,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFiltroChip('todos', 'Todas', isTablet),
                  const SizedBox(width: 8),
                  _buildFiltroChip('geral', 'Chat Geral', isTablet),
                  const SizedBox(width: 8),
                  _buildFiltroChip('modulos', 'Módulos', isTablet),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String valor, String label, bool isTablet) {
    final isSelected = _filtroContexto == valor;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filtroContexto = valor;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 8 : 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.darkSurfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? AppTheme.primaryColor : AppTheme.darkBorderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.darkTextSecondaryColor,
            fontSize: isTablet ? 12 : 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildListaConversas(bool isTablet) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final conversas = _conversasFiltradas;

    if (conversas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: isTablet ? 80 : 60,
              color: AppTheme.darkTextSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma conversa encontrada',
              style: AppTheme.headingSmall.copyWith(
                color: AppTheme.darkTextSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Inicie uma conversa com a IA para que ela apareça aqui',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.darkTextSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: isTablet ? 16 : 12,
      ),
      itemCount: conversas.length,
      itemBuilder: (context, index) {
        final conversa = conversas[index];
        return _buildConversaCard(conversa, isTablet);
      },
    );
  }

  Widget _buildConversaCard(Conversa conversa, bool isTablet) {
    final ultimaMensagem = conversa.mensagens.isNotEmpty
        ? conversa.mensagens.last.text
        : 'Conversa vazia';

    return Container(
        margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
        child: ModernCard(
          child: InkWell(
            onTap: () => _abrirConversa(conversa),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: isTablet ? 40 : 32,
                        height: isTablet ? 40 : 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: conversa.contexto == 'geral'
                                ? [
                                    AppTheme.primaryColor,
                                    AppTheme.primaryLightColor
                                  ]
                                : [AppTheme.accentColor, AppTheme.successColor],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          conversa.contexto == 'geral'
                              ? Icons.smart_toy_rounded
                              : Icons.school_rounded,
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
                              conversa.titulo,
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: isTablet ? 16 : 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              conversa.contexto == 'geral'
                                  ? 'Chat Geral'
                                  : conversa.contexto,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.darkTextSecondaryColor,
                                fontSize: isTablet ? 12 : 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _deletarConversa(conversa),
                        icon: const Icon(Icons.delete_outline_rounded),
                        iconSize: isTablet ? 20 : 18,
                        tooltip: 'Deletar conversa',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ultimaMensagem,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.darkTextSecondaryColor,
                      fontSize: isTablet ? 13 : 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${conversa.mensagens.length} mensagens',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                          fontSize: isTablet ? 11 : 10,
                        ),
                      ),
                      Text(
                        _formatarData(conversa.ultimaAtualizacao),
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                          fontSize: isTablet ? 11 : 10,
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
      return '${diferenca.inDays} dias atrás';
    } else {
      return '${data.day}/${data.month}/${data.year}';
    }
  }

  void _abrirConversa(Conversa conversa) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          mode: ChatMode.general,
          conversaInicial: conversa,
        ),
      ),
    );
  }

  Future<void> _deletarConversa(Conversa conversa) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurfaceColor,
        title: Text(
          'Deletar Conversa',
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Tem certeza que deseja deletar a conversa "${conversa.titulo}"?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.darkTextSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await ConversaService.deletarConversa(conversa.id);
      _carregarConversas();
    }
  }
}
