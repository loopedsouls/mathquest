// Enumeração para velocidade da cobra
enum SnakeSpeed {
  lento,
  normal,
  rapido,
  hardcore,
}

// Classe para representar uma pergunta do quiz snake
class QuizSnakeQuestion {
  final String pergunta;
  final List<String> opcoes;
  final String respostaCorreta;
  final String explicacao;
  final String dificuldade;

  QuizSnakeQuestion({
    required this.pergunta,
    required this.opcoes,
    required this.respostaCorreta,
    required this.explicacao,
    this.dificuldade = 'médio',
  });
}

// Classe para gerenciar perguntas do quiz snake
class QuizSnakeQuestions {
  static List<QuizSnakeQuestion> getQuestions() {
    return [
      QuizSnakeQuestion(
        pergunta: "Quanto é 2 + 2?",
        opcoes: ["3", "4", "5", "6"],
        respostaCorreta: "4",
        explicacao: "2 + 2 = 4",
        dificuldade: "fácil",
      ),
      QuizSnakeQuestion(
        pergunta: "Quanto é 5 × 3?",
        opcoes: ["12", "15", "18", "20"],
        respostaCorreta: "15",
        explicacao: "5 × 3 = 15",
        dificuldade: "médio",
      ),
      QuizSnakeQuestion(
        pergunta: "Quanto é 12 ÷ 3?",
        opcoes: ["2", "3", "4", "5"],
        respostaCorreta: "4",
        explicacao: "12 ÷ 3 = 4",
        dificuldade: "médio",
      ),
    ];
  }
}
