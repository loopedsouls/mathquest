import 'package:flutter/material.dart';
import 'package:mathquest/features/data/service/firebase_ai_service.dart';
import 'package:mathquest/app_theme.dart';
import 'package:mathquest/widgets/modern_components.dart';

class FirebaseAiTestScreen extends StatefulWidget {
  const FirebaseAiTestScreen({super.key});

  @override
  State<FirebaseAiTestScreen> createState() => _FirebaseAiTestScreenState();
}

class _FirebaseAiTestScreenState extends State<FirebaseAiTestScreen> {
  String _resultado = 'Pronto para testar...';
  bool _testando = false;
  final TextEditingController _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _testarConexao() async {
    setState(() {
      _testando = true;
      _resultado = 'Testando conexão...';
    });

    try {
      final resultado = await FirebaseAIService.testarConexao();
      if (mounted) {
        setState(() {
          _resultado = resultado ?? 'Erro desconhecido';
          _testando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _resultado = 'Erro: $e';
          _testando = false;
        });
      }
    }
  }

  Future<void> _testarExplicacao() async {
    setState(() {
      _testando = true;
      _resultado = 'Gerando explicação matemática...';
    });

    try {
      final explicacao = await FirebaseAIService.gerarExplicacaoMatematica(
        problema: 'Quanto é 2 + 3?',
        ano: '6º ano',
        unidade: 'Números',
      );

      if (mounted) {
        setState(() {
          _resultado = explicacao ??
              'Nenhuma explicação gerada (usando fallback offline)';
          _testando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _resultado = 'Erro ao gerar explicação: $e';
          _testando = false;
        });
      }
    }
  }

  Future<void> _testarPromptPersonalizado() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um prompt primeiro!')),
      );
      return;
    }

    setState(() {
      _testando = true;
      _resultado = 'Processando prompt personalizado...';
    });

    try {
      // Como não temos um método genérico, vamos usar a explicação matemática
      final resposta = await FirebaseAIService.gerarExplicacaoMatematica(
        problema: prompt,
        ano: '8º ano',
        unidade: 'Geral',
      );

      if (mounted) {
        setState(() {
          _resultado = resposta ?? 'Nenhuma resposta gerada';
          _testando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _resultado = 'Erro: $e';
          _testando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = FirebaseAIService.getStatus();

    return Scaffold(
      backgroundColor: AppTheme.darkBackgroundColor,
      appBar: AppBar(
        title: const Text('Teste Firebase AI'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Card
              ModernCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            status['service_initialized']
                                ? Icons.check_circle
                                : Icons.error,
                            color: status['service_initialized']
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Status do Firebase AI',
                            style: AppTheme.headingSmall.copyWith(
                              color: AppTheme.darkTextPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...status.entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Text(
                                  '${entry.key}: ',
                                  style: TextStyle(
                                    color: AppTheme.darkTextSecondaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${entry.value}',
                                  style: TextStyle(
                                    color: AppTheme.darkTextPrimaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Botões de Teste
              ModernButton(
                text: 'Testar Conexão Básica',
                onPressed: _testando ? null : _testarConexao,
                isPrimary: true,
              ),
              const SizedBox(height: 12),
              ModernButton(
                text: 'Testar Explicação Matemática',
                onPressed: _testando ? null : _testarExplicacao,
                isPrimary: false,
              ),
              const SizedBox(height: 20),

              // Prompt Personalizado
              ModernCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Teste com Prompt Personalizado',
                        style: AppTheme.headingSmall.copyWith(
                          color: AppTheme.darkTextPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _promptController,
                        decoration: const InputDecoration(
                          hintText: 'Digite uma pergunta matemática...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        style: TextStyle(
                          color: AppTheme.darkTextPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ModernButton(
                        text: 'Testar Prompt',
                        onPressed:
                            _testando ? null : _testarPromptPersonalizado,
                        isPrimary: false,
                        isFullWidth: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Resultado
              ModernCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_testando)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          if (_testando) const SizedBox(width: 8),
                          Text(
                            'Resultado',
                            style: AppTheme.headingSmall.copyWith(
                              color: AppTheme.darkTextPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.darkBackgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                AppTheme.darkBorderColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _resultado,
                          style: TextStyle(
                            color: AppTheme.darkTextPrimaryColor,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Informações
              ModernCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ℹ️ Informações',
                        style: AppTheme.headingSmall.copyWith(
                          color: AppTheme.darkTextPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Se os testes falharem, o app continuará funcionando com o sistema offline\n'
                        '• A API key do Gemini deve estar configurada no Firebase Console\n'
                        '• Em desenvolvimento, alguns erros são esperados e normais',
                        style: TextStyle(
                          color: AppTheme.darkTextSecondaryColor,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
