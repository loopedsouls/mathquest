import 'package:flutter/material.dart';

void main() {
  runApp(const CombinaApp());
}

class CombinaApp extends StatelessWidget {
  const CombinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Combina - Análise Combinatória',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TelaInicial(),
    );
  }
}

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  TelaInicialState createState() => TelaInicialState();
}

class TelaInicialState extends State<TelaInicial> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nController = TextEditingController();
  final TextEditingController _rController = TextEditingController();

  List<List<int>> permutacoes = [];
  List<List<int>> arranjos = [];
  List<List<int>> combinacoes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Combina - Tela Inicial'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Permutações'),
            Tab(text: 'Arranjos'),
            Tab(text: 'Combinações'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInputField(_nController, 'Digite n'),
            const SizedBox(height: 8.0),
            _buildInputField(_rController, 'Digite r'),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _gerarResultados();
              },
              child: const Text('Gerar Resultados'),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildResultadoTab(permutacoes, 'Permutações'),
                  _buildResultadoTab(arranjos, 'Arranjos'),
                  _buildResultadoTab(combinacoes, 'Combinações'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String labelText) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              '$labelText: ',
              style: const TextStyle(fontSize: 18.0),
            ),
            SizedBox(
              width: 50.0,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
      ],
    );
  }

  void _gerarResultados() {
    int n = int.tryParse(_nController.text) ?? 0;
    int r = int.tryParse(_rController.text) ?? 0;

    permutacoes = _gerarResultadosList(n, r, _gerarPermutacoes);
    arranjos = _gerarResultadosList(n, r, _gerarArranjos);
    combinacoes = _gerarResultadosList(n, r, _gerarCombinacoes);

    setState(() {});
  }

  List<List<int>> _gerarResultadosList(int n, int r, List<int> Function(List<int>, int, List<int>) gerarFuncao) {
    List<List<int>> result = [];
    List<int> elementos = List.generate(n, (index) => index + 1);
    result.add(gerarFuncao(elementos, r, []));
    return result;
  }

  List<int> _gerarPermutacoes(List<int> elementos, int r, List<int> atual) {
    List<int> result = [];

    if (atual.length == r) {
      result.addAll(atual);
      return result;
    }

    for (int elemento in elementos) {
      if (!atual.contains(elemento)) {
        List<int> novaLista = List.from(atual)..add(elemento);
        result.addAll(_gerarPermutacoes(elementos, r, novaLista));
      }
    }

    return result;
  }

  List<int> _gerarArranjos(List<int> elementos, int r, List<int> atual) {
    List<int> result = [];

    if (atual.length == r) {
      result.addAll(atual);
      return result;
    }

    for (int elemento in elementos) {
      List<int> novaLista = List.from(atual)..add(elemento);
      result.addAll(_gerarArranjos(elementos, r, novaLista));
    }

    return result;
  }

  List<int> _gerarCombinacoes(List<int> elementos, int r, List<int> atual) {
    List<int> result = [];

    if (atual.length == r) {
      result.addAll(atual);
      return result;
    }

    for (int i = 0; i < elementos.length; i++) {
      List<int> novaLista = List.from(atual)..add(elementos[i]);
      result.addAll(_gerarCombinacoes(elementos.sublist(i + 1), r, novaLista));
    }

    return result;
  }

  Widget _buildResultadoTab(List<List<int>> resultados, String titulo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$titulo:',
          style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        if (resultados.isNotEmpty)
          for (List<int> item in resultados)
            ListTile(
              title: Row(
                children: item.map((numero) => _buildIcon(numero)).toList(),
              ),
            ),
        if (resultados.isEmpty)
          const Text(
            'Nenhum resultado disponível.',
            style: TextStyle(fontSize: 14.0),
          ),
      ],
    );
  }

  Widget _buildIcon(int numero) {
    IconData icon;

    switch (numero) {
      case 1:
        icon = Icons.looks_one;
        break;
      case 2:
        icon = Icons.looks_two;
        break;
      case 3:
        icon = Icons.looks_3;
        break;
      // Adicione mais casos conforme necessário

      default:
        icon = Icons.looks_4; // Ícone padrão
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Icon(icon),
          Text('($numero)'),
        ],
      ),
    );
  }
}
