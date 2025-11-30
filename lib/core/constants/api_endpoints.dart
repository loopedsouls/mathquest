/// API endpoints for external services
class ApiEndpoints {
  ApiEndpoints._();

  // Firebase
  static const String firebaseProjectId = 'mathquest-firebase';

  // Ollama (local)
  static const String ollamaBaseUrl = 'http://localhost:11434';
  static const String ollamaGenerate = '$ollamaBaseUrl/api/generate';
  static const String ollamaModels = '$ollamaBaseUrl/api/tags';

  // Google AI Studio (Gemini)
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com';
  static const String geminiGenerate = '$geminiBaseUrl/v1beta/models/gemini-1.5-flash:generateContent';

  // OpenAI
  static const String openaiBaseUrl = 'https://api.openai.com/v1';
  static const String openaiChat = '$openaiBaseUrl/chat/completions';

  // ArXiv API
  static const String arxivBaseUrl = 'http://export.arxiv.org/api';
  static const String arxivSearch = '$arxivBaseUrl/query';

  // HuggingFace (for models)
  static const String huggingFaceBaseUrl = 'https://huggingface.co';

  // Kaggle (for models)
  static const String kaggleBaseUrl = 'https://www.kaggle.com';
}
