import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../services/personagem_service.dart';
import '../models/personagem_model.dart';

class CharacterCollectionScreen extends StatefulWidget {
  const CharacterCollectionScreen({super.key});

  @override
  State<CharacterCollectionScreen> createState() => _CharacterCollectionScreenState();
}

class _CharacterCollectionScreenState extends State<CharacterCollectionScreen> {
  List<Personagem> _personagens = [];
  Personagem? _selecionado;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final service = PersonagemService();
    await service.inicializar();

    setState(() {
      _personagens = service.obterColecaoPersonagens();
      _selecionado = service.obterPersonagemSelecionado();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Coleção de Personagens')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coleção de Personagens'),
        actions: [
          IconButton(
            icon: const Icon(Icons.casino),
            onPressed: _abrirGacha,
            tooltip: 'Gacha',
          ),
        ],
      ),
      body: Column(
        children: [
          // Personagem selecionado
          if (_selecionado != null) _buildPersonagemSelecionado(),

          // Lista de personagens
          Expanded(
            child: _personagens.isEmpty
                ? _buildColecaoVazia()
                : _buildListaPersonagens(),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonagemSelecionado() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.modernCardDark,
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Color(int.parse(_selecionado!.raridade.cor.replaceAll('#', '0xFF'))),
            child: Text(
              _selecionado!.nome[0],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selecionado!.nome,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_selecionado!.raridade.nome} • ${_selecionado!.tipo.nome}',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                Text(
                  'Nível ${_selecionado!.nivel} • EXP: ${_selecionado!.experiencia}/${_selecionado!.experienciaParaProximoNivel}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: _selecionado!.podeEvoluir ? _evoluirPersonagem : null,
            color: _selecionado!.podeEvoluir ? Colors.yellow : Colors.grey,
            tooltip: 'Evoluir',
          ),
        ],
      ),
    );
  }

  Widget _buildColecaoVazia() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Nenhum personagem ainda',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _abrirGacha,
            child: const Text('Tentar Gacha'),
          ),
        ],
      ),
    );
  }

  Widget _buildListaPersonagens() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _personagens.length,
      itemBuilder: (context, index) {
        final personagem = _personagens[index];
        final isSelecionado = personagem.id == _selecionado?.id;

        return GestureDetector(
          onTap: () => _selecionarPersonagem(personagem),
          child: Container(
            decoration: BoxDecoration(
              color: isSelecionado ? Colors.blue.withOpacity(0.2) : Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelecionado ? Colors.blue : Colors.grey[600]!,
                width: isSelecionado ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(int.parse(personagem.raridade.cor.replaceAll('#', '0xFF'))),
                  child: Text(
                    personagem.nome[0],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  personagem.nome,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Text(
                  personagem.raridade.nome,
                  style: TextStyle(
                    color: Color(int.parse(personagem.raridade.cor.replaceAll('#', '0xFF'))),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  'Nv. ${personagem.nivel}',
                  style: const TextStyle(fontSize: 12),
                ),
                if (personagem.evoluido)
                  const Icon(Icons.star, color: Colors.yellow, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selecionarPersonagem(Personagem personagem) async {
    final service = PersonagemService();
    await service.inicializar();

    try {
      await service.selecionarPersonagem(personagem.id);
      setState(() {
        _selecionado = personagem;
      });
      AppTheme.showSuccessSnackBar(context, '${personagem.nome} selecionado!');
    } catch (e) {
      AppTheme.showErrorSnackBar(context, 'Erro ao selecionar personagem');
    }
  }

  Future<void> _abrirGacha() async {
    final service = PersonagemService();
    await service.inicializar();

    if (service.perfilAtual == null || service.perfilAtual!.moedas < 50) {
      AppTheme.showErrorSnackBar(context, 'Moedas insuficientes! (50 necessárias)');
      return;
    }

    final personagem = await service.fazerGacha();

    if (personagem != null) {
      setState(() {
        _personagens = service.obterColecaoPersonagens();
      });

      // Mostrar animação de gacha
      _mostrarResultadoGacha(personagem);
    } else {
      AppTheme.showErrorSnackBar(context, 'Erro no gacha');
    }
  }

  void _mostrarResultadoGacha(Personagem personagem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Novo Personagem!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Color(int.parse(personagem.raridade.cor.replaceAll('#', '0xFF'))),
              child: Text(
                personagem.nome[0],
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              personagem.nome,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              personagem.raridade.nome,
              style: TextStyle(
                color: Color(int.parse(personagem.raridade.cor.replaceAll('#', '0xFF'))),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(personagem.descricao),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _evoluirPersonagem() async {
    if (_selecionado == null) return;

    final service = PersonagemService();
    await service.inicializar();

    final sucesso = await service.evoluirPersonagem(_selecionado!.id);

    if (sucesso) {
      setState(() {
        _selecionado = service.obterPersonagemSelecionado();
        _personagens = service.obterColecaoPersonagens();
      });
      AppTheme.showSuccessSnackBar(context, '${_selecionado!.nome} evoluiu!');
    } else {
      AppTheme.showErrorSnackBar(context, 'Erro na evolução');
    }
  }
}