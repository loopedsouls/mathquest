import 'gemini_service.dart';

class TutorService {
  /// Gera história avançada para visual novel usando contexto, personagem e tema
  Future<Map<String, dynamic>> gerarHistoriaAvancada({
    required String prompt,
    required Map<String, dynamic> contexto,
    required String personagem,
    required String tema,
  }) async {
    final fullPrompt = '''
Você é o narrador de uma visual novel.
Personagem principal: "$personagem"
Tema: "$tema"
Contexto do jogo: ${contexto.toString()}
$prompt
Gere o próximo trecho da história e 3 opções de escolha para o jogador. Responda SOMENTE com o bloco JSON abaixo, sem explicações, sem texto extra. Delimite o JSON entre <json> e </json>:
<json>
{
  "historia": "Texto da história...",
  "opcoes": ["Opção 1", "Opção 2", "Opção 3"]
}
</json>
''';
    final resposta = await geminiService.sendPrompt(fullPrompt);
    try {
      final json = resposta.contains('{')
          ? resposta.substring(resposta.indexOf('{'))
          : resposta;
      return Map<String, dynamic>.from(geminiService.parseJson(json));
    } catch (e) {
      return {'historia': resposta, 'opcoes': []};
    }
  }

  final GeminiService geminiService;

  TutorService({String? apiKey})
      : geminiService = GeminiService(apiKey: apiKey);

  /// Gera pergunta de qualquer área
  Future<String> gerarPergunta(
      {required String area, required String nivelDificuldade}) async {
    String prompt;
    switch (area.toLowerCase()) {
      case 'matemática':
        prompt = '''
Crie uma pergunta de matemática de nível $nivelDificuldade.
Pode ser sobre operações, problemas, lógica ou raciocínio matemático.
Inclua apenas a pergunta, sem a resposta.
''';
        break;
      case 'quiz':
        prompt = '''
Crie uma pergunta de conhecimento geral de nível $nivelDificuldade.
Pode ser sobre história, geografia, ciências, cultura ou atualidades.
Inclua apenas a pergunta, sem a resposta.
''';
        break;
      case 'lógica':
        prompt = '''
Crie um desafio de lógica ou raciocínio lógico de nível $nivelDificuldade.
Pode ser um enigma, sequência lógica ou problema de dedução.
Inclua apenas o desafio, sem a resposta.
''';
        break;
      case 'forca':
        prompt = '''
Escolha uma palavra de dificuldade $nivelDificuldade para o jogo da forca.
Não revele a palavra, apenas informe a quantidade de letras e uma dica.
Formato: "Palavra com X letras. Dica: ..."
''';
        break;
      case 'palavras cruzadas':
        prompt = '''
Crie uma pista para palavras cruzadas de nível $nivelDificuldade.
Informe a dica e a quantidade de letras da resposta.
Formato: "Dica: ... (X letras)"
''';
        break;
      case 'adivinhação':
        prompt = '''
Crie um desafio de adivinhação de nível $nivelDificuldade.
Pode ser sobre objetos, animais, lugares ou pessoas.
Inclua apenas a pergunta, sem a resposta.
''';
        break;
      default:
        prompt = '''
Crie uma pergunta de $area de nível $nivelDificuldade.
Inclua apenas a pergunta, sem a resposta.
''';
    }
    return await geminiService.sendPrompt(prompt);
  }

  /// Gera história e opções iniciais para visual novel
  Future<Map<String, dynamic>> gerarHistoriaGemini() async {
    const prompt = '''
Você é o narrador de uma visual novel. Gere o próximo trecho da história e 3 opções de escolha para o jogador, em formato JSON:
{
  "historia": "Texto da história...",
  "opcoes": ["Opção 1", "Opção 2", "Opção 3"]
}
''';
    final resposta = await geminiService.sendPrompt(prompt);
    try {
      final json = resposta.contains('{')
          ? resposta.substring(resposta.indexOf('{'))
          : resposta;
      return Map<String, dynamic>.from(geminiService.parseJson(json));
    } catch (e) {
      return {'historia': resposta, 'opcoes': []};
    }
  }

  /// Gera explicação para resposta errada de qualquer área
  Future<String> gerarExplicacao({
    required String area,
    required String pergunta,
    required String respostaUsuario,
    required String respostaCorreta,
  }) async {
    final prompt = '''
Pergunta de $area: "$pergunta"
Resposta do usuário: "$respostaUsuario"
Resposta correta: "$respostaCorreta"

Forneça uma explicação clara e didática de:
1. Por que a resposta do usuário está incorreta
2. Como chegar à resposta correta, passo a passo
3. A resposta correta

Seja encorajador e educativo na explicação.
''';
    return await geminiService.sendPrompt(prompt);
  }

  /// Envia escolha do jogador e recebe próximo trecho e opções
  Future<Map<String, dynamic>> enviarEscolhaGemini(String escolha) async {
    final prompt = '''
Você é o narrador de uma visual novel. O jogador escolheu: "$escolha". Gere o próximo trecho da história e 3 opções de escolha para o jogador, em formato JSON:
{
  "historia": "Texto da história...",
  "opcoes": ["Opção 1", "Opção 2", "Opção 3"]
}
''';
    final resposta = await geminiService.sendPrompt(prompt);
    try {
      final json = resposta.contains('{')
          ? resposta.substring(resposta.indexOf('{'))
          : resposta;
      return Map<String, dynamic>.from(geminiService.parseJson(json));
    } catch (e) {
      return {'historia': resposta, 'opcoes': []};
    }
  }

  /// Verifica se a resposta está correta e obtém a resposta correta para qualquer área
  Future<Map<String, dynamic>> verificarResposta(
      {required String area,
      required String pergunta,
      required String resposta}) async {
    final prompt = '''
Pergunta de $area: "$pergunta"
Resposta do usuário: "$resposta"

Analise se a resposta está correta e forneça a resposta correta.

Responda no seguinte formato JSON:
{
  "correta": true/false,
  "resposta_correta": "valor correto",
  "explicacao_breve": "explicação concisa se estiver incorreta"
}

Seja preciso na análise.
''';
    try {
      final resultado = await geminiService.sendPrompt(prompt);
      final isCorrect = resultado.toLowerCase().contains('"correta": true') ||
          resultado.toLowerCase().contains('correta');
      return {
        'correta': isCorrect,
        'resposta_completa': resultado,
      };
    } catch (e) {
      return {
        'correta': false,
        'resposta_completa': 'Erro ao verificar resposta: $e',
      };
    }
  }
}
