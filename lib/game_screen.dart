import 'package:flutter/material.dart';
import 'math_tutor_service.dart';
import 'ollama_service.dart';

class OllamaConfigScreen extends StatefulWidget {
  const OllamaConfigScreen({super.key});

  @override
  State<OllamaConfigScreen> createState() => _OllamaConfigScreenState();
}

class _OllamaConfigScreenState extends State<OllamaConfigScreen> {
  final OllamaService ollamaService = OllamaService();
  final TextEditingController modeloController = TextEditingController();
  bool carregando = false;
  String status = '';
  List<String> modelos = [];

  @override
  void initState() {
    super.initState();
    carregarModelos();
  }

  Future<void> carregarModelos() async {
    setState(() => carregando = true);
    try {
      modelos = await ollamaService.listModels();
      status = 'Modelos carregados.';
    } catch (e) {
      status = 'Erro ao conectar Ollama: $e';
    }
    setState(() => carregando = false);
  }

  Future<void> testarConexao() async {
    setState(() => carregando = true);
    final rodando = await ollamaService.isOllamaRunning();
    status = rodando ? 'Ollama está rodando.' : 'Ollama não está rodando.';
    setState(() => carregando = false);
  }

  Future<void> instalarModelo() async {
    final modelo = modeloController.text.trim();
    if (modelo.isEmpty) return;
    setState(() => carregando = true);
    try {
      await ollamaService.installModel(modelo);
      status = 'Modelo "$modelo" instalado.';
      await carregarModelos();
    } catch (e) {
      status = 'Erro ao instalar modelo: $e';
    }
    setState(() => carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuração do Ollama')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: carregando
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Modelos instalados:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: modelos.map((m) => Chip(label: Text(m))).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: modeloController,
                    decoration: const InputDecoration(
                        labelText: 'Nome do modelo para instalar'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: instalarModelo,
                        child: const Text('Instalar Modelo'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: testarConexao,
                        child: const Text('Testar Conexão'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(status, style: const TextStyle(color: Colors.blue)),
                ],
              ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final String modelo;
  const GameScreen({super.key, required this.modelo});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late MathTutorService tutorService;
  String pergunta = '';
  String explicacao = '';
  bool carregando = false;

  @override
  void initState() {
    super.initState();
    tutorService = MathTutorService(modelo: widget.modelo);
    gerarNovaPergunta();
  }

  Future<void> gerarNovaPergunta() async {
    setState(() => carregando = true);
    pergunta =
        await tutorService.gerarPergunta('Crie uma pergunta de matemática.');
    explicacao = '';
    setState(() => carregando = false);
  }

  Future<void> mostrarExplicacao() async {
    setState(() => carregando = true);
    explicacao = await tutorService
        .gerarExplicacao('Explique o conceito da pergunta: $pergunta');
    setState(() => carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jogo de Matemática')),
      body: Center(
        child: carregando
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(pergunta, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: mostrarExplicacao,
                    child: const Text('Mostrar Explicação'),
                  ),
                  if (explicacao.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(explicacao, style: const TextStyle(fontSize: 16)),
                  ],
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: gerarNovaPergunta,
                    child: const Text('Nova Pergunta'),
                  ),
                ],
              ),
      ),
    );
  }
}
