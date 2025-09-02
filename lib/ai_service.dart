abstract class AIService {
  Future<String> generate(String prompt);
  Future<bool> isServiceAvailable();
}
