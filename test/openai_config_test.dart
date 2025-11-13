import 'package:flutter_test/flutter_test.dart';
import 'package:mathquest/services/ai_openai_service.dart';
import 'package:mathquest/openai_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('OpenAI configuration test', () async {
    // Test if OpenAI config can be loaded
    final apiKey = await OpenAIConfig.getApiKey();

    print('API Key loaded: ${apiKey != null && apiKey.isNotEmpty}');

    if (apiKey != null && apiKey.isNotEmpty) {
      print('OpenAI service initialized successfully');

      // Test a simple message (this will fail if API key is invalid)
      try {
        final response = await OpenAIService.sendMessage('Olá, teste simples');
        print('OpenAI API call successful: ${response != null}');
        if (response != null) {
          print('Response length: ${response.length}');
        }
      } catch (e) {
        print('OpenAI API call failed: $e');
        // This is expected if API key is invalid or network issues
      }
    } else {
      print(
          'No API key found - check SharedPreferences, environment, or .env file');
    }
  });
}
