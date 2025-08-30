// Widget global
import '../services/tutor_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OptionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const OptionButton({
    required this.label,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final String? apiKey;
  const GameScreen({super.key, this.apiKey});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  _GameScreenState(); // Add default unnamed constructor
  String historia = '';
  String explicacao = '';
  String feedback = '';
  bool carregando = false;
  int? respostaSelecionada;
  List<String> opcoes = [];
  List<Map<String, String>> historico = [];
  late TutorService tutorService;
// 0: Fácil, 1: Médio, 2: Difícil, 3: Expert

  void mostrarExplicacao() {
    setState(() {
      explicacao = explicacao.isNotEmpty
          ? explicacao
          : 'Explicação não disponível para esta pergunta.';
    });
  }

  Future<void> carregarHistoria() async {
    setState(() {
      carregando = true;
      respostaSelecionada = null;
      feedback = '';
    });
    // Chamada real ao Gemini via TutorService
    final resultado = await tutorService.gerarHistoriaGemini();
    setState(() {
      historia = resultado['historia'] ?? '';
      opcoes = List<String>.from(resultado['opcoes'] ?? []);
      carregando = false;
    });
  }

  Future<void> selecionarOpcao(int index) async {
    setState(() {
      carregando = true;
      respostaSelecionada = index;
    });
    // Chamada real ao Gemini via TutorService
    final resultado = await tutorService.enviarEscolhaGemini(opcoes[index]);
    setState(() {
      historia = resultado['historia'] ?? '';
      opcoes = List<String>.from(resultado['opcoes'] ?? []);
      carregando = false;
    });
  }

  @override
  void initState() {
    super.initState();
    tutorService = TutorService(apiKey: widget.apiKey);
    carregarHistoria();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fundo
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF22223B),
              // Para imagem de fundo, use:
              // image: DecorationImage(image: AssetImage('assets/bg.jpg'), fit: BoxFit.cover),
            ),
          ),
          // Personagem centralizado
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 160),
              child: SizedBox(
                width: 340,
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 480,
                    maxHeight: 480,
                  ),
                  child: Image.asset(
                    'assets/character.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[800],
                      child: const Center(
                          child: Icon(Icons.person,
                              size: 120, color: Colors.white24)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Caixa de diálogo inferior
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 48, left: 32, right: 32),
              child: Stack(
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 700),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.only(
                        left: 120, right: 32, top: 32, bottom: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          historia.isNotEmpty
                              ? historia
                              : 'Carregando história...',
                          style: const TextStyle(
                              fontSize: 22, color: Colors.black87, height: 1.3),
                        ),
                        const SizedBox(height: 18),
                        if (carregando)
                          const Center(child: CircularProgressIndicator()),
                        if (!carregando && opcoes.isNotEmpty)
                          Column(
                            children: List.generate(opcoes.length, (index) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        respostaSelecionada == index
                                            ? Colors.blueGrey[700]
                                            : Colors.blueGrey[300],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => selecionarOpcao(index),
                                  child: Text(opcoes[index]),
                                ),
                              );
                            }),
                          ),
                        if (feedback.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              feedback,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        if (explicacao.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              explicacao,
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.black87),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Aba do nome do personagem
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: 120,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Personagem',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Barra de opções inferior
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 0),
              child: Container(
                color: Colors.black.withOpacity(0.7),
                height: 38,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OptionButton(label: 'History', onTap: () {}),
                    OptionButton(label: 'Skip', onTap: () {}),
                    OptionButton(label: 'Auto', onTap: () {}),
                    OptionButton(label: 'Save', onTap: () {}),
                    OptionButton(label: 'Load', onTap: () {}),
                    OptionButton(
                      label: 'Settings',
                      onTap: () {
                        Navigator.of(context).pushNamed('/settings');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
// (Remove everything from here until the closing bracket of the duplicate build method)
// The code above is a duplicate of the widget tree already present in your first build method.
// No replacement needed; just delete this duplicate code.

// Move these functions outside of the _OptionButton class, e.g., below the _OptionButton class

  Widget buildDialogCardCupertino({
    required List<String> niveis,
    required int nivelDificuldade,
    required String pergunta,
    required TextEditingController respostaController,
    required VoidCallback verificarResposta,
    required VoidCallback gerarNovaPergunta,
    required String feedback,
    required bool? respostaCorreta,
    required VoidCallback mostrarExplicacao,
    required String explicacao,
  }) {
    // Caixa de diálogo estilo visual novel
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nível: ${niveis[nivelDificuldade].toUpperCase()}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              pergunta,
              key: ValueKey<String>(pergunta),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, height: 1.5),
            ),
          ),
          const SizedBox(height: 32),
          CupertinoTextField(
            controller: respostaController,
            placeholder: 'Sua escolha ou resposta',
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            style: const TextStyle(fontSize: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCCCCCC)),
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: verificarResposta,
            borderRadius: BorderRadius.circular(12),
            child: const Text('Enviar', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(height: 24),
          buildFeedbackSectionCupertino(
            feedback: feedback,
            respostaCorreta: respostaCorreta,
            mostrarExplicacao: mostrarExplicacao,
            explicacao: explicacao,
          ),
          const SizedBox(height: 24),
          CupertinoButton(
            onPressed: gerarNovaPergunta,
            borderRadius: BorderRadius.circular(12),
            child:
                const Text('Próximo Diálogo', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget buildFeedbackSectionCupertino({
    required String feedback,
    required bool? respostaCorreta,
    required VoidCallback mostrarExplicacao,
    required String explicacao,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (feedback.isNotEmpty)
            Text(
              feedback,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (respostaCorreta == false) ...[
            const SizedBox(height: 12),
            CupertinoButton(
              onPressed: mostrarExplicacao,
              borderRadius: BorderRadius.circular(12),
              child: const Text('Ver Explicação'),
            ),
          ],
          if (explicacao.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              explicacao,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
