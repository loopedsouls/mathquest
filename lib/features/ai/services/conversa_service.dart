import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../conversa.dart';
import '../../data/service/firebase_ai_service.dart';

class ConversaService {
  static const String _chaveConversas = 'conversas_salvas';

  /// Salva uma conversa
  static Future<void> salvarConversa(Conversa conversa) async {
    final prefs = await SharedPreferences.getInstance();
    final conversas = await listarConversas();

    // Remove conversa existente com mesmo ID se houver
    conversas.removeWhere((c) => c.id == conversa.id);

    // Adiciona a conversa atualizada
    conversas.add(conversa);

    // Ordena por data de atualização (mais recente primeiro)
    conversas
        .sort((a, b) => b.ultimaAtualizacao.compareTo(a.ultimaAtualizacao));

    // Salva no SharedPreferences
    final conversasJson = conversas.map((c) => c.toJson()).toList();
    await prefs.setString(_chaveConversas, jsonEncode(conversasJson));
  }

  /// Lista todas as conversas salvas
  static Future<List<Conversa>> listarConversas() async {
    final prefs = await SharedPreferences.getInstance();
    final conversasString = prefs.getString(_chaveConversas);

    if (conversasString == null) return [];

    try {
      final conversasJson = jsonDecode(conversasString) as List;
      return conversasJson.map((json) => Conversa.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Lista conversas por contexto
  static Future<List<Conversa>> listarConversasPorContexto(
      String contexto) async {
    final todasConversas = await listarConversas();
    return todasConversas.where((c) => c.contexto == contexto).toList();
  }

  /// Deleta uma conversa
  static Future<void> deletarConversa(String id) async {
    final conversas = await listarConversas();
    conversas.removeWhere((c) => c.id == id);

    final prefs = await SharedPreferences.getInstance();
    final conversasJson = conversas.map((c) => c.toJson()).toList();
    await prefs.setString(_chaveConversas, jsonEncode(conversasJson));
  }

  /// Gera título automático usando IA
  static Future<String> gerarTituloAutomatico(
    List<ChatMessage> mensagens,
    String contexto,
  ) async {
    if (mensagens.isEmpty) return 'Nova Conversa';

    // Pega as primeiras mensagens do usuário para gerar o título
    final mensagensUsuario =
        mensagens.where((m) => m.isUser).take(3).map((m) => m.text).join(' ');

    if (mensagensUsuario.isEmpty) return 'Nova Conversa';

    try {
      final prompt = '''
Baseado na seguinte conversa de matemática, gere um título curto e descritivo (máximo 40 caracteres):

Contexto: $contexto
Mensagens do usuário: "$mensagensUsuario"

Responda apenas com o título, sem aspas ou explicações. Exemplos:
- "Equações do 2º grau"
- "Frações e divisão" 
- "Geometria - Triângulos"
- "Álgebra básica"
''';

      final titulo = await FirebaseAIService.sendMessage(prompt);

      if (titulo == null) return 'Nova Conversa';

      // Limpa e limita o título
      final tituloLimpo = titulo
          .trim()
          .replaceAll('"', '')
          .replaceAll("'", '')
          .replaceAll('\n', ' ')
          .replaceAll(RegExp(r'\s+'), ' ');

      if (tituloLimpo.length > 40) {
        return '${tituloLimpo.substring(0, 37)}...';
      }

      return tituloLimpo.isNotEmpty ? tituloLimpo : 'Nova Conversa';
    } catch (e) {
      // Se falhar, cria um título baseado nas palavras-chave
      return _criarTituloFallback(mensagensUsuario, contexto);
    }
  }

  /// Cria título fallback sem IA
  static String _criarTituloFallback(String mensagens, String contexto) {
    final palavrasChave = [
      'equação',
      'fração',
      'geometria',
      'álgebra',
      'número',
      'soma',
      'subtração',
      'multiplicação',
      'divisão',
      'raiz',
      'potência',
      'porcentagem',
      'decimal',
      'triângulo',
      'círculo',
      'área',
      'perímetro',
      'volume',
      'função',
      'gráfico'
    ];

    final mensagensLower = mensagens.toLowerCase();
    final palavraEncontrada = palavrasChave.firstWhere(
      (palavra) => mensagensLower.contains(palavra),
      orElse: () => '',
    );

    if (palavraEncontrada.isNotEmpty) {
      return 'Dúvida sobre ${palavraEncontrada.substring(0, 1).toUpperCase()}${palavraEncontrada.substring(1)}';
    }

    if (contexto != 'geral') {
      return 'Conversa - $contexto';
    }

    return 'Nova Conversa';
  }

  /// Gera ID único para conversa
  static String gerarIdConversa() {
    return 'conversa_${DateTime.now().millisecondsSinceEpoch}';
  }
}
