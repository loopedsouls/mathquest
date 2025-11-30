import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/lesson_model.dart';
import '../models/question_model.dart';
import 'lesson_repository.dart';

/// Implementation of LessonRepository with local storage
class LessonRepositoryImpl implements LessonRepository {
  static const String _unlockedLessonsKey = 'unlocked_lessons';
  static const String _cachedQuestionsKey = 'cached_questions';

  /// Singleton instance
  static final LessonRepositoryImpl _instance = LessonRepositoryImpl._internal();
  factory LessonRepositoryImpl() => _instance;
  LessonRepositoryImpl._internal();

  /// Sample lessons data aligned with BNCC
  final List<LessonModel> _lessons = [
    // ==================== 6º ANO ====================
    // 6º Ano - Números
    const LessonModel(
      id: 'numeros_6_1',
      title: 'Números Naturais',
      description: 'Operações básicas com números naturais',
      schoolYear: '6º ano',
      thematicUnit: 'Números',
      bnccCode: 'EF06MA01',
      order: 1,
      objectives: ['Compreender números naturais', 'Realizar operações básicas'],
      estimatedMinutes: 15,
      difficulty: 'fácil',
      isLocked: false,
      totalQuestions: 5,
    ),
    const LessonModel(
      id: 'numeros_6_2',
      title: 'Múltiplos e Divisores',
      description: 'Identificação de múltiplos e divisores',
      schoolYear: '6º ano',
      thematicUnit: 'Números',
      bnccCode: 'EF06MA05',
      order: 2,
      prerequisites: ['numeros_6_1'],
      objectives: ['Identificar múltiplos', 'Encontrar divisores'],
      estimatedMinutes: 20,
      difficulty: 'médio',
      isLocked: true,
      totalQuestions: 5,
    ),
    const LessonModel(
      id: 'numeros_6_3',
      title: 'Frações',
      description: 'Compreensão e operações com frações',
      schoolYear: '6º ano',
      thematicUnit: 'Números',
      bnccCode: 'EF06MA07',
      order: 3,
      prerequisites: ['numeros_6_2'],
      objectives: ['Entender frações', 'Comparar frações'],
      estimatedMinutes: 25,
      difficulty: 'médio',
      isLocked: true,
      totalQuestions: 5,
    ),
    const LessonModel(
      id: 'numeros_6_4',
      title: 'Números Decimais',
      description: 'Operações com números decimais',
      schoolYear: '6º ano',
      thematicUnit: 'Números',
      bnccCode: 'EF06MA11',
      order: 4,
      prerequisites: ['numeros_6_3'],
      objectives: ['Operar com decimais', 'Converter frações em decimais'],
      estimatedMinutes: 20,
      difficulty: 'médio',
      isLocked: true,
      totalQuestions: 5,
    ),
    // 6º Ano - Álgebra
    const LessonModel(
      id: 'algebra_6_1',
      title: 'Expressões Numéricas',
      description: 'Resolução de expressões numéricas',
      schoolYear: '6º ano',
      thematicUnit: 'Álgebra',
      bnccCode: 'EF06MA14',
      order: 1,
      objectives: ['Resolver expressões', 'Aplicar ordem das operações'],
      estimatedMinutes: 20,
      difficulty: 'médio',
      isLocked: false,
      totalQuestions: 5,
    ),
    const LessonModel(
      id: 'algebra_6_2',
      title: 'Propriedades da Igualdade',
      description: 'Princípios de equivalência e igualdade',
      schoolYear: '6º ano',
      thematicUnit: 'Álgebra',
      bnccCode: 'EF06MA15',
      order: 2,
      prerequisites: ['algebra_6_1'],
      objectives: ['Compreender igualdade', 'Resolver equações simples'],
      estimatedMinutes: 20,
      difficulty: 'médio',
      isLocked: true,
      totalQuestions: 5,
    ),
    const LessonModel(
      id: 'algebra_6_3',
      title: 'Sequências Numéricas',
      description: 'Padrões e sequências',
      schoolYear: '6º ano',
      thematicUnit: 'Álgebra',
      bnccCode: 'EF06MA16',
      order: 3,
      prerequisites: ['algebra_6_2'],
      objectives: ['Identificar padrões', 'Continuar sequências'],
      estimatedMinutes: 15,
      difficulty: 'fácil',
      isLocked: true,
      totalQuestions: 5,
    ),
    // 6º Ano - Geometria
    const LessonModel(
      id: 'geometria_6_1',
      title: 'Figuras Geométricas Planas',
      description: 'Polígonos e suas propriedades',
      schoolYear: '6º ano',
      thematicUnit: 'Geometria',
      bnccCode: 'EF06MA17',
      order: 1,
      objectives: ['Identificar polígonos', 'Classificar figuras planas'],
      estimatedMinutes: 20,
      difficulty: 'fácil',
      isLocked: false,
      totalQuestions: 5,
    ),
    const LessonModel(
      id: 'geometria_6_2',
      title: 'Perímetro e Área',
      description: 'Cálculo de perímetro e área',
      schoolYear: '6º ano',
      thematicUnit: 'Geometria',
      bnccCode: 'EF06MA24',
      order: 2,
      prerequisites: ['geometria_6_1'],
      objectives: ['Calcular perímetro', 'Calcular área de figuras simples'],
      estimatedMinutes: 25,
      difficulty: 'médio',
      isLocked: true,
      totalQuestions: 5,
    ),
    const LessonModel(
      id: 'geometria_6_3',
      title: 'Simetria',
      description: 'Eixos de simetria e figuras simétricas',
      schoolYear: '6º ano',
      thematicUnit: 'Geometria',
      bnccCode: 'EF06MA22',
      order: 3,
      prerequisites: ['geometria_6_2'],
      objectives: ['Identificar eixos de simetria', 'Desenhar figuras simétricas'],
      estimatedMinutes: 15,
      difficulty: 'fácil',
      isLocked: true,
      totalQuestions: 5,
    ),
    // 6º Ano - Grandezas e Medidas
    const LessonModel(
      id: 'grandezas_6_1',
      title: 'Unidades de Medida',
      description: 'Comprimento, massa e capacidade',
      schoolYear: '6º ano',
      thematicUnit: 'Grandezas e Medidas',
      bnccCode: 'EF06MA24',
      order: 1,
      objectives: ['Converter unidades', 'Resolver problemas com medidas'],
      estimatedMinutes: 20,
      difficulty: 'médio',
      isLocked: false,
      totalQuestions: 5,
    ),
    const LessonModel(
      id: 'grandezas_6_2',
      title: 'Medidas de Tempo',
      description: 'Horas, minutos e segundos',
      schoolYear: '6º ano',
      thematicUnit: 'Grandezas e Medidas',
      bnccCode: 'EF06MA25',
      order: 2,
      prerequisites: ['grandezas_6_1'],
      objectives: ['Converter unidades de tempo', 'Calcular intervalos'],
      estimatedMinutes: 15,
      difficulty: 'fácil',
      isLocked: true,
      totalQuestions: 5,
    ),
    // 6º Ano - Probabilidade e Estatística
    const LessonModel(
      id: 'estatistica_6_1',
      title: 'Leitura de Gráficos',
      description: 'Interpretação de gráficos e tabelas',
      schoolYear: '6º ano',
      thematicUnit: 'Probabilidade e Estatística',
      bnccCode: 'EF06MA31',
      order: 1,
      objectives: ['Ler gráficos', 'Interpretar dados'],
      estimatedMinutes: 20,
      difficulty: 'fácil',
      isLocked: false,
      totalQuestions: 5,
    ),
    const LessonModel(
      id: 'estatistica_6_2',
      title: 'Média Aritmética',
      description: 'Cálculo e interpretação da média',
      schoolYear: '6º ano',
      thematicUnit: 'Probabilidade e Estatística',
      bnccCode: 'EF06MA32',
      order: 2,
      prerequisites: ['estatistica_6_1'],
      objectives: ['Calcular média', 'Interpretar média em contextos'],
      estimatedMinutes: 15,
      difficulty: 'médio',
      isLocked: true,
      totalQuestions: 5,
    ),
    // ==================== 7º ANO ====================
    // 7º Ano - Números
    const LessonModel(
      id: 'numeros_7_1',
      title: 'Números Inteiros',
      description: 'Operações com números inteiros',
      schoolYear: '7º ano',
      thematicUnit: 'Números',
      bnccCode: 'EF07MA04',
      order: 1,
      objectives: ['Compreender números negativos', 'Realizar operações com inteiros'],
      estimatedMinutes: 20,
      difficulty: 'médio',
      isLocked: false,
      totalQuestions: 5,
    ),
    const LessonModel(
      id: 'numeros_7_2',
      title: 'Números Racionais',
      description: 'Operações com números racionais',
      schoolYear: '7º ano',
      thematicUnit: 'Números',
      bnccCode: 'EF07MA10',
      order: 2,
      prerequisites: ['numeros_7_1'],
      objectives: ['Operar com frações', 'Converter entre formas'],
      estimatedMinutes: 25,
      difficulty: 'médio',
      isLocked: true,
      totalQuestions: 5,
    ),
    const LessonModel(
      id: 'numeros_7_3',
      title: 'Porcentagem',
      description: 'Cálculos com porcentagem',
      schoolYear: '7º ano',
      thematicUnit: 'Números',
      bnccCode: 'EF07MA02',
      order: 3,
      prerequisites: ['numeros_7_2'],
      objectives: ['Calcular porcentagens', 'Resolver problemas com porcentagem'],
      estimatedMinutes: 20,
      difficulty: 'médio',
      isLocked: true,
      totalQuestions: 5,
    ),
    // 7º Ano - Álgebra
    const LessonModel(
      id: 'algebra_7_1',
      title: 'Expressões Algébricas',
      description: 'Introdução à linguagem algébrica',
      schoolYear: '7º ano',
      thematicUnit: 'Álgebra',
      bnccCode: 'EF07MA13',
      order: 1,
      objectives: ['Escrever expressões', 'Simplificar expressões'],
      estimatedMinutes: 20,
      difficulty: 'médio',
      isLocked: false,
      totalQuestions: 5,
    ),
    const LessonModel(
      id: 'algebra_7_2',
      title: 'Equações do 1º Grau',
      description: 'Resolução de equações de primeiro grau',
      schoolYear: '7º ano',
      thematicUnit: 'Álgebra',
      bnccCode: 'EF07MA18',
      order: 2,
      prerequisites: ['algebra_7_1'],
      objectives: ['Resolver equações', 'Verificar soluções'],
      estimatedMinutes: 25,
      difficulty: 'médio',
      isLocked: true,
      totalQuestions: 5,
    ),
    const LessonModel(
      id: 'algebra_7_3',
      title: 'Inequações',
      description: 'Desigualdades e inequações simples',
      schoolYear: '7º ano',
      thematicUnit: 'Álgebra',
      bnccCode: 'EF07MA19',
      order: 3,
      prerequisites: ['algebra_7_2'],
      objectives: ['Resolver inequações', 'Representar soluções'],
      estimatedMinutes: 20,
      difficulty: 'difícil',
      isLocked: true,
      totalQuestions: 5,
    ),
    // 7º Ano - Geometria
    const LessonModel(
      id: 'geometria_7_1',
      title: 'Ângulos',
      description: 'Medição e classificação de ângulos',
      schoolYear: '7º ano',
      thematicUnit: 'Geometria',
      bnccCode: 'EF07MA23',
      order: 1,
      objectives: ['Medir ângulos', 'Classificar ângulos'],
      estimatedMinutes: 20,
      difficulty: 'fácil',
      isLocked: false,
      totalQuestions: 5,
    ),
    const LessonModel(
      id: 'geometria_7_2',
      title: 'Triângulos',
      description: 'Propriedades e classificação de triângulos',
      schoolYear: '7º ano',
      thematicUnit: 'Geometria',
      bnccCode: 'EF07MA24',
      order: 2,
      prerequisites: ['geometria_7_1'],
      objectives: ['Classificar triângulos', 'Calcular soma dos ângulos'],
      estimatedMinutes: 20,
      difficulty: 'médio',
      isLocked: true,
      totalQuestions: 5,
    ),
    // 7º Ano - Grandezas e Medidas
    const LessonModel(
      id: 'grandezas_7_1',
      title: 'Área de Figuras Compostas',
      description: 'Cálculo de áreas de figuras compostas',
      schoolYear: '7º ano',
      thematicUnit: 'Grandezas e Medidas',
      bnccCode: 'EF07MA31',
      order: 1,
      objectives: ['Decompor figuras', 'Calcular áreas compostas'],
      estimatedMinutes: 25,
      difficulty: 'médio',
      isLocked: false,
      totalQuestions: 5,
    ),
    // 7º Ano - Probabilidade e Estatística
    const LessonModel(
      id: 'estatistica_7_1',
      title: 'Probabilidade Básica',
      description: 'Introdução à probabilidade',
      schoolYear: '7º ano',
      thematicUnit: 'Probabilidade e Estatística',
      bnccCode: 'EF07MA34',
      order: 1,
      objectives: ['Calcular probabilidades', 'Entender eventos'],
      estimatedMinutes: 20,
      difficulty: 'médio',
      isLocked: false,
      totalQuestions: 5,
    ),
    // ==================== 8º ANO ====================
    // 8º Ano - Números
    const LessonModel(
      id: 'numeros_8_1',
      title: 'Potenciação',
      description: 'Potências e propriedades',
      schoolYear: '8º ano',
      thematicUnit: 'Números',
      bnccCode: 'EF08MA01',
      order: 1,
      objectives: ['Calcular potências', 'Aplicar propriedades'],
      estimatedMinutes: 25,
      difficulty: 'médio',
      isLocked: false,
      totalQuestions: 5,
    ),
    const LessonModel(
      id: 'numeros_8_2',
      title: 'Radiciação',
      description: 'Raízes e propriedades',
      schoolYear: '8º ano',
      thematicUnit: 'Números',
      bnccCode: 'EF08MA02',
      order: 2,
      prerequisites: ['numeros_8_1'],
      objectives: ['Calcular raízes', 'Simplificar radicais'],
      estimatedMinutes: 25,
      difficulty: 'médio',
      isLocked: true,
      totalQuestions: 5,
    ),
    const LessonModel(
      id: 'numeros_8_3',
      title: 'Notação Científica',
      description: 'Representação de números grandes e pequenos',
      schoolYear: '8º ano',
      thematicUnit: 'Números',
      bnccCode: 'EF08MA03',
      order: 3,
      prerequisites: ['numeros_8_2'],
      objectives: ['Usar notação científica', 'Converter números'],
      estimatedMinutes: 20,
      difficulty: 'médio',
      isLocked: true,
      totalQuestions: 5,
    ),
    // 8º Ano - Álgebra
    const LessonModel(
      id: 'algebra_8_1',
      title: 'Monômios e Polinômios',
      description: 'Operações com monômios e polinômios',
      schoolYear: '8º ano',
      thematicUnit: 'Álgebra',
      bnccCode: 'EF08MA06',
      order: 1,
      objectives: ['Identificar monômios', 'Operar com polinômios'],
      estimatedMinutes: 25,
      difficulty: 'médio',
      isLocked: false,
      totalQuestions: 5,
    ),
    const LessonModel(
      id: 'algebra_8_2',
      title: 'Produtos Notáveis',
      description: 'Quadrado da soma e diferença',
      schoolYear: '8º ano',
      thematicUnit: 'Álgebra',
      bnccCode: 'EF08MA07',
      order: 2,
      prerequisites: ['algebra_8_1'],
      objectives: ['Aplicar produtos notáveis', 'Expandir expressões'],
      estimatedMinutes: 25,
      difficulty: 'difícil',
      isLocked: true,
      totalQuestions: 5,
    ),
    const LessonModel(
      id: 'algebra_8_3',
      title: 'Fatoração',
      description: 'Fatoração de expressões algébricas',
      schoolYear: '8º ano',
      thematicUnit: 'Álgebra',
      bnccCode: 'EF08MA08',
      order: 3,
      prerequisites: ['algebra_8_2'],
      objectives: ['Fatorar expressões', 'Identificar fatores comuns'],
      estimatedMinutes: 25,
      difficulty: 'difícil',
      isLocked: true,
      totalQuestions: 5,
    ),
    // 8º Ano - Geometria
    const LessonModel(
      id: 'geometria_8_1',
      title: 'Teorema de Pitágoras',
      description: 'Aplicação do teorema de Pitágoras',
      schoolYear: '8º ano',
      thematicUnit: 'Geometria',
      bnccCode: 'EF08MA14',
      order: 1,
      objectives: ['Aplicar Pitágoras', 'Resolver problemas'],
      estimatedMinutes: 25,
      difficulty: 'médio',
      isLocked: false,
      totalQuestions: 5,
    ),
    const LessonModel(
      id: 'geometria_8_2',
      title: 'Transformações Geométricas',
      description: 'Translação, rotação e reflexão',
      schoolYear: '8º ano',
      thematicUnit: 'Geometria',
      bnccCode: 'EF08MA15',
      order: 2,
      prerequisites: ['geometria_8_1'],
      objectives: ['Identificar transformações', 'Aplicar transformações'],
      estimatedMinutes: 20,
      difficulty: 'médio',
      isLocked: true,
      totalQuestions: 5,
    ),
    // 8º Ano - Grandezas e Medidas
    const LessonModel(
      id: 'grandezas_8_1',
      title: 'Volume de Sólidos',
      description: 'Cálculo de volume de prismas e cilindros',
      schoolYear: '8º ano',
      thematicUnit: 'Grandezas e Medidas',
      bnccCode: 'EF08MA19',
      order: 1,
      objectives: ['Calcular volumes', 'Resolver problemas'],
      estimatedMinutes: 25,
      difficulty: 'médio',
      isLocked: false,
      totalQuestions: 5,
    ),
    // 8º Ano - Probabilidade e Estatística
    const LessonModel(
      id: 'estatistica_8_1',
      title: 'Medidas de Tendência Central',
      description: 'Média, moda e mediana',
      schoolYear: '8º ano',
      thematicUnit: 'Probabilidade e Estatística',
      bnccCode: 'EF08MA23',
      order: 1,
      objectives: ['Calcular medidas', 'Interpretar dados'],
      estimatedMinutes: 20,
      difficulty: 'médio',
      isLocked: false,
      totalQuestions: 5,
    ),
    // ==================== 9º ANO ====================
    // 9º Ano - Números
    const LessonModel(
      id: 'numeros_9_1',
      title: 'Números Reais',
      description: 'Conjunto dos números reais',
      schoolYear: '9º ano',
      thematicUnit: 'Números',
      bnccCode: 'EF09MA01',
      order: 1,
      objectives: ['Compreender números reais', 'Localizar na reta'],
      estimatedMinutes: 20,
      difficulty: 'médio',
      isLocked: false,
      totalQuestions: 5,
    ),
    const LessonModel(
      id: 'numeros_9_2',
      title: 'Números Irracionais',
      description: 'Identificação e operações',
      schoolYear: '9º ano',
      thematicUnit: 'Números',
      bnccCode: 'EF09MA02',
      order: 2,
      prerequisites: ['numeros_9_1'],
      objectives: ['Identificar irracionais', 'Operar com irracionais'],
      estimatedMinutes: 25,
      difficulty: 'difícil',
      isLocked: true,
      totalQuestions: 5,
    ),
    // 9º Ano - Álgebra
    const LessonModel(
      id: 'algebra_9_1',
      title: 'Equações do 2º Grau',
      description: 'Resolução por Bhaskara',
      schoolYear: '9º ano',
      thematicUnit: 'Álgebra',
      bnccCode: 'EF09MA09',
      order: 1,
      objectives: ['Aplicar Bhaskara', 'Resolver equações'],
      estimatedMinutes: 30,
      difficulty: 'difícil',
      isLocked: false,
      totalQuestions: 5,
    ),
    const LessonModel(
      id: 'algebra_9_2',
      title: 'Funções',
      description: 'Introdução às funções',
      schoolYear: '9º ano',
      thematicUnit: 'Álgebra',
      bnccCode: 'EF09MA06',
      order: 2,
      prerequisites: ['algebra_9_1'],
      objectives: ['Compreender funções', 'Representar graficamente'],
      estimatedMinutes: 25,
      difficulty: 'difícil',
      isLocked: true,
      totalQuestions: 5,
    ),
    const LessonModel(
      id: 'algebra_9_3',
      title: 'Função Afim',
      description: 'Função do primeiro grau',
      schoolYear: '9º ano',
      thematicUnit: 'Álgebra',
      bnccCode: 'EF09MA07',
      order: 3,
      prerequisites: ['algebra_9_2'],
      objectives: ['Analisar função afim', 'Construir gráficos'],
      estimatedMinutes: 25,
      difficulty: 'difícil',
      isLocked: true,
      totalQuestions: 5,
    ),
    // 9º Ano - Geometria
    const LessonModel(
      id: 'geometria_9_1',
      title: 'Semelhança de Triângulos',
      description: 'Casos de semelhança',
      schoolYear: '9º ano',
      thematicUnit: 'Geometria',
      bnccCode: 'EF09MA12',
      order: 1,
      objectives: ['Identificar semelhança', 'Calcular medidas'],
      estimatedMinutes: 25,
      difficulty: 'médio',
      isLocked: false,
      totalQuestions: 5,
    ),
    const LessonModel(
      id: 'geometria_9_2',
      title: 'Razões Trigonométricas',
      description: 'Seno, cosseno e tangente',
      schoolYear: '9º ano',
      thematicUnit: 'Geometria',
      bnccCode: 'EF09MA13',
      order: 2,
      prerequisites: ['geometria_9_1'],
      objectives: ['Calcular razões', 'Resolver triângulos'],
      estimatedMinutes: 30,
      difficulty: 'difícil',
      isLocked: true,
      totalQuestions: 5,
    ),
    // 9º Ano - Grandezas e Medidas
    const LessonModel(
      id: 'grandezas_9_1',
      title: 'Área e Volume',
      description: 'Área de círculo e volume de cones e esferas',
      schoolYear: '9º ano',
      thematicUnit: 'Grandezas e Medidas',
      bnccCode: 'EF09MA16',
      order: 1,
      objectives: ['Calcular áreas circulares', 'Calcular volumes'],
      estimatedMinutes: 25,
      difficulty: 'médio',
      isLocked: false,
      totalQuestions: 5,
    ),
    // 9º Ano - Probabilidade e Estatística
    const LessonModel(
      id: 'estatistica_9_1',
      title: 'Análise de Dados',
      description: 'Análise crítica de pesquisas estatísticas',
      schoolYear: '9º ano',
      thematicUnit: 'Probabilidade e Estatística',
      bnccCode: 'EF09MA22',
      order: 1,
      objectives: ['Analisar pesquisas', 'Interpretar estatísticas'],
      estimatedMinutes: 20,
      difficulty: 'médio',
      isLocked: false,
      totalQuestions: 5,
    ),
  ];

  /// Sample questions aligned with lessons
  final Map<String, List<QuestionModel>> _questionsByLesson = {
    'numeros_6_1': [
      const QuestionModel(
        id: 'q1_numeros_6_1',
        lessonId: 'numeros_6_1',
        question: 'Qual é o resultado de 15 + 27?',
        type: QuestionType.multipleChoice,
        options: ['32', '42', '52', '62'],
        correctAnswer: '42',
        explanation: '15 + 27 = 42. Somamos unidades (5+7=12, escrevemos 2 e levamos 1) e depois dezenas (1+2+1=4).',
        difficulty: 'fácil',
        thematicUnit: 'Números',
        schoolYear: '6º ano',
      ),
      const QuestionModel(
        id: 'q2_numeros_6_1',
        lessonId: 'numeros_6_1',
        question: 'Quanto é 8 × 7?',
        type: QuestionType.multipleChoice,
        options: ['54', '56', '48', '64'],
        correctAnswer: '56',
        explanation: '8 × 7 = 56. Uma forma de lembrar: 7 × 8 = 56 (os números 5, 6, 7, 8 em sequência).',
        difficulty: 'fácil',
        thematicUnit: 'Números',
        schoolYear: '6º ano',
      ),
      const QuestionModel(
        id: 'q3_numeros_6_1',
        lessonId: 'numeros_6_1',
        question: 'Qual é o resultado de 100 - 37?',
        type: QuestionType.multipleChoice,
        options: ['73', '67', '63', '53'],
        correctAnswer: '63',
        explanation: '100 - 37 = 63. Podemos calcular: 100 - 40 = 60, depois 60 + 3 = 63.',
        difficulty: 'fácil',
        thematicUnit: 'Números',
        schoolYear: '6º ano',
      ),
      const QuestionModel(
        id: 'q4_numeros_6_1',
        lessonId: 'numeros_6_1',
        question: 'Qual é o resultado de 144 ÷ 12?',
        type: QuestionType.multipleChoice,
        options: ['10', '11', '12', '13'],
        correctAnswer: '12',
        explanation: '144 ÷ 12 = 12. Podemos verificar: 12 × 12 = 144.',
        difficulty: 'fácil',
        thematicUnit: 'Números',
        schoolYear: '6º ano',
      ),
      const QuestionModel(
        id: 'q5_numeros_6_1',
        lessonId: 'numeros_6_1',
        question: 'Quanto é 25 + 38?',
        type: QuestionType.multipleChoice,
        options: ['53', '63', '73', '83'],
        correctAnswer: '63',
        explanation: '25 + 38 = 63. Somamos: 5 + 8 = 13 (escrevemos 3, levamos 1), depois 2 + 3 + 1 = 6.',
        difficulty: 'fácil',
        thematicUnit: 'Números',
        schoolYear: '6º ano',
      ),
    ],
    'numeros_6_2': [
      const QuestionModel(
        id: 'q1_numeros_6_2',
        lessonId: 'numeros_6_2',
        question: 'Qual é o menor múltiplo comum de 4 e 6?',
        type: QuestionType.multipleChoice,
        options: ['6', '12', '24', '36'],
        correctAnswer: '12',
        explanation: 'Os múltiplos de 4 são: 4, 8, 12, 16... Os múltiplos de 6 são: 6, 12, 18... O menor comum é 12.',
        difficulty: 'médio',
        thematicUnit: 'Números',
        schoolYear: '6º ano',
      ),
      const QuestionModel(
        id: 'q2_numeros_6_2',
        lessonId: 'numeros_6_2',
        question: 'Qual número é divisor de 20?',
        type: QuestionType.multipleChoice,
        options: ['3', '6', '7', '5'],
        correctAnswer: '5',
        explanation: '20 ÷ 5 = 4, sem resto. Portanto, 5 é divisor de 20.',
        difficulty: 'médio',
        thematicUnit: 'Números',
        schoolYear: '6º ano',
      ),
      const QuestionModel(
        id: 'q3_numeros_6_2',
        lessonId: 'numeros_6_2',
        question: 'Quais são todos os divisores de 12?',
        type: QuestionType.multipleChoice,
        options: ['1, 2, 3, 4, 6, 12', '1, 2, 4, 6, 12', '2, 3, 4, 6', '1, 3, 4, 12'],
        correctAnswer: '1, 2, 3, 4, 6, 12',
        explanation: 'Os divisores de 12 são os números que dividem 12 exatamente: 12÷1=12, 12÷2=6, 12÷3=4, 12÷4=3, 12÷6=2, 12÷12=1.',
        difficulty: 'médio',
        thematicUnit: 'Números',
        schoolYear: '6º ano',
      ),
      const QuestionModel(
        id: 'q4_numeros_6_2',
        lessonId: 'numeros_6_2',
        question: '15 é múltiplo de qual número?',
        type: QuestionType.multipleChoice,
        options: ['4', '6', '5', '7'],
        correctAnswer: '5',
        explanation: '15 ÷ 5 = 3, sem resto. Portanto, 15 é múltiplo de 5 (15 = 5 × 3).',
        difficulty: 'médio',
        thematicUnit: 'Números',
        schoolYear: '6º ano',
      ),
      const QuestionModel(
        id: 'q5_numeros_6_2',
        lessonId: 'numeros_6_2',
        question: 'Qual é o MDC (Máximo Divisor Comum) de 18 e 24?',
        type: QuestionType.multipleChoice,
        options: ['2', '3', '6', '12'],
        correctAnswer: '6',
        explanation: 'Divisores de 18: 1,2,3,6,9,18. Divisores de 24: 1,2,3,4,6,8,12,24. O maior comum é 6.',
        difficulty: 'médio',
        thematicUnit: 'Números',
        schoolYear: '6º ano',
      ),
    ],
    'algebra_6_1': [
      const QuestionModel(
        id: 'q1_algebra_6_1',
        lessonId: 'algebra_6_1',
        question: 'Qual é o resultado de 3 + 4 × 2?',
        type: QuestionType.multipleChoice,
        options: ['14', '11', '10', '9'],
        correctAnswer: '11',
        explanation: 'Primeiro fazemos a multiplicação: 4 × 2 = 8. Depois a soma: 3 + 8 = 11.',
        difficulty: 'médio',
        thematicUnit: 'Álgebra',
        schoolYear: '6º ano',
      ),
      const QuestionModel(
        id: 'q2_algebra_6_1',
        lessonId: 'algebra_6_1',
        question: 'Qual é o resultado de (5 + 3) × 2?',
        type: QuestionType.multipleChoice,
        options: ['11', '13', '16', '10'],
        correctAnswer: '16',
        explanation: 'Primeiro resolvemos o parêntese: 5 + 3 = 8. Depois multiplicamos: 8 × 2 = 16.',
        difficulty: 'médio',
        thematicUnit: 'Álgebra',
        schoolYear: '6º ano',
      ),
      const QuestionModel(
        id: 'q3_algebra_6_1',
        lessonId: 'algebra_6_1',
        question: 'Quanto é 20 ÷ 4 + 3 × 2?',
        type: QuestionType.multipleChoice,
        options: ['11', '13', '16', '8'],
        correctAnswer: '11',
        explanation: 'Primeiro multiplicação e divisão: 20 ÷ 4 = 5 e 3 × 2 = 6. Depois soma: 5 + 6 = 11.',
        difficulty: 'médio',
        thematicUnit: 'Álgebra',
        schoolYear: '6º ano',
      ),
      const QuestionModel(
        id: 'q4_algebra_6_1',
        lessonId: 'algebra_6_1',
        question: 'Qual é o resultado de 2 × (10 - 4)?',
        type: QuestionType.multipleChoice,
        options: ['16', '12', '8', '14'],
        correctAnswer: '12',
        explanation: 'Primeiro o parêntese: 10 - 4 = 6. Depois multiplicamos: 2 × 6 = 12.',
        difficulty: 'médio',
        thematicUnit: 'Álgebra',
        schoolYear: '6º ano',
      ),
      const QuestionModel(
        id: 'q5_algebra_6_1',
        lessonId: 'algebra_6_1',
        question: 'Qual é o resultado de 18 ÷ (2 + 4)?',
        type: QuestionType.multipleChoice,
        options: ['13', '6', '3', '9'],
        correctAnswer: '3',
        explanation: 'Primeiro o parêntese: 2 + 4 = 6. Depois dividimos: 18 ÷ 6 = 3.',
        difficulty: 'médio',
        thematicUnit: 'Álgebra',
        schoolYear: '6º ano',
      ),
    ],
    'numeros_7_1': [
      const QuestionModel(
        id: 'q1_numeros_7_1',
        lessonId: 'numeros_7_1',
        question: 'Qual é o resultado de -5 + 8?',
        type: QuestionType.multipleChoice,
        options: ['-13', '-3', '3', '13'],
        correctAnswer: '3',
        explanation: '-5 + 8 = 3. Quando somamos um positivo maior que o negativo, o resultado é positivo.',
        difficulty: 'médio',
        thematicUnit: 'Números',
        schoolYear: '7º ano',
      ),
      const QuestionModel(
        id: 'q2_numeros_7_1',
        lessonId: 'numeros_7_1',
        question: 'Quanto é (-3) × (-4)?',
        type: QuestionType.multipleChoice,
        options: ['-12', '-7', '7', '12'],
        correctAnswer: '12',
        explanation: 'Negativo × negativo = positivo. Então (-3) × (-4) = 12.',
        difficulty: 'médio',
        thematicUnit: 'Números',
        schoolYear: '7º ano',
      ),
      const QuestionModel(
        id: 'q3_numeros_7_1',
        lessonId: 'numeros_7_1',
        question: 'Qual é o resultado de -10 - 5?',
        type: QuestionType.multipleChoice,
        options: ['-15', '-5', '5', '15'],
        correctAnswer: '-15',
        explanation: '-10 - 5 = -15. Subtrair é o mesmo que somar o oposto: -10 + (-5) = -15.',
        difficulty: 'médio',
        thematicUnit: 'Números',
        schoolYear: '7º ano',
      ),
      const QuestionModel(
        id: 'q4_numeros_7_1',
        lessonId: 'numeros_7_1',
        question: 'Quanto é (-20) ÷ 4?',
        type: QuestionType.multipleChoice,
        options: ['-5', '-16', '5', '16'],
        correctAnswer: '-5',
        explanation: 'Negativo ÷ positivo = negativo. Então (-20) ÷ 4 = -5.',
        difficulty: 'médio',
        thematicUnit: 'Números',
        schoolYear: '7º ano',
      ),
      const QuestionModel(
        id: 'q5_numeros_7_1',
        lessonId: 'numeros_7_1',
        question: 'Qual número está entre -3 e 1 na reta numérica?',
        type: QuestionType.multipleChoice,
        options: ['-4', '2', '-1', '3'],
        correctAnswer: '-1',
        explanation: 'Na reta numérica, -1 está entre -3 e 1. A ordem é: -3, -2, -1, 0, 1.',
        difficulty: 'médio',
        thematicUnit: 'Números',
        schoolYear: '7º ano',
      ),
    ],
  };

  @override
  Future<List<LessonModel>> getAllLessons() async {
    return List.unmodifiable(_lessons);
  }

  @override
  Future<List<LessonModel>> getLessonsBySchoolYear(String schoolYear) async {
    return _lessons.where((l) => l.schoolYear == schoolYear).toList();
  }

  @override
  Future<List<LessonModel>> getLessonsByThematicUnit(String thematicUnit) async {
    return _lessons.where((l) => l.thematicUnit == thematicUnit).toList();
  }

  @override
  Future<LessonModel?> getLessonById(String lessonId) async {
    try {
      return _lessons.firstWhere((l) => l.id == lessonId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<LessonModel>> getNextLessonsForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedIds = prefs.getStringList(_unlockedLessonsKey) ?? ['numeros_6_1', 'algebra_6_1', 'numeros_7_1'];
    
    return _lessons.where((l) => unlockedIds.contains(l.id)).toList();
  }

  @override
  Future<List<QuestionModel>> getLessonQuestions(String lessonId) async {
    // First try to get from in-memory data
    final questions = _questionsByLesson[lessonId];
    if (questions != null && questions.isNotEmpty) {
      return List.unmodifiable(questions);
    }

    // Then try cached questions
    final cached = await _getCachedQuestionsForLesson(lessonId);
    if (cached.isNotEmpty) {
      return cached;
    }

    // Return default questions if nothing found
    return _getDefaultQuestions(lessonId);
  }

  Future<List<QuestionModel>> _getCachedQuestionsForLesson(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString('${_cachedQuestionsKey}_$lessonId');
    if (cachedJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(cachedJson);
      return decoded.map((q) => QuestionModel.fromJson(q)).toList();
    } catch (_) {
      return [];
    }
  }

  List<QuestionModel> _getDefaultQuestions(String lessonId) {
    // Generate basic default questions
    return [
      QuestionModel(
        id: 'default_1_$lessonId',
        lessonId: lessonId,
        question: 'Quanto é 10 + 5?',
        type: QuestionType.multipleChoice,
        options: const ['10', '15', '20', '25'],
        correctAnswer: '15',
        explanation: '10 + 5 = 15',
        difficulty: 'fácil',
        thematicUnit: 'Números',
        schoolYear: '6º ano',
      ),
      QuestionModel(
        id: 'default_2_$lessonId',
        lessonId: lessonId,
        question: 'Quanto é 6 × 4?',
        type: QuestionType.multipleChoice,
        options: const ['20', '22', '24', '26'],
        correctAnswer: '24',
        explanation: '6 × 4 = 24',
        difficulty: 'fácil',
        thematicUnit: 'Números',
        schoolYear: '6º ano',
      ),
      QuestionModel(
        id: 'default_3_$lessonId',
        lessonId: lessonId,
        question: 'Quanto é 50 - 18?',
        type: QuestionType.multipleChoice,
        options: const ['28', '32', '38', '42'],
        correctAnswer: '32',
        explanation: '50 - 18 = 32',
        difficulty: 'fácil',
        thematicUnit: 'Números',
        schoolYear: '6º ano',
      ),
      QuestionModel(
        id: 'default_4_$lessonId',
        lessonId: lessonId,
        question: 'Quanto é 36 ÷ 6?',
        type: QuestionType.multipleChoice,
        options: const ['4', '5', '6', '7'],
        correctAnswer: '6',
        explanation: '36 ÷ 6 = 6',
        difficulty: 'fácil',
        thematicUnit: 'Números',
        schoolYear: '6º ano',
      ),
      QuestionModel(
        id: 'default_5_$lessonId',
        lessonId: lessonId,
        question: 'Quanto é 7 × 8?',
        type: QuestionType.multipleChoice,
        options: const ['54', '56', '58', '64'],
        correctAnswer: '56',
        explanation: '7 × 8 = 56',
        difficulty: 'fácil',
        thematicUnit: 'Números',
        schoolYear: '6º ano',
      ),
    ];
  }

  @override
  Future<QuestionModel?> generateAIQuestion({
    required String lessonId,
    required String thematicUnit,
    required String schoolYear,
    required String difficulty,
  }) async {
    // AI generation would go here - for now return null
    // In production, this would call FirebaseAIService
    return null;
  }

  @override
  Future<List<QuestionModel>> getCachedQuestions({
    required String thematicUnit,
    required String schoolYear,
    int limit = 10,
  }) async {
    final allQuestions = _questionsByLesson.values.expand((q) => q).toList();
    return allQuestions
        .where((q) => q.thematicUnit == thematicUnit && q.schoolYear == schoolYear)
        .take(limit)
        .toList();
  }

  @override
  Future<void> cacheQuestion(QuestionModel question) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_cachedQuestionsKey}_${question.lessonId}';
    
    final existingJson = prefs.getString(key);
    List<QuestionModel> existing = [];
    
    if (existingJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(existingJson);
        existing = decoded.map((q) => QuestionModel.fromJson(q)).toList();
      } catch (_) {
        // Ignore errors
      }
    }
    
    // Add new question if not duplicate
    if (!existing.any((q) => q.id == question.id)) {
      existing.add(question);
      await prefs.setString(key, jsonEncode(existing.map((q) => q.toJson()).toList()));
    }
  }

  @override
  Future<bool> isLessonUnlocked(String userId, String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedIds = prefs.getStringList(_unlockedLessonsKey) ?? ['numeros_6_1', 'algebra_6_1', 'numeros_7_1'];
    return unlockedIds.contains(lessonId);
  }

  @override
  Future<void> unlockLesson(String userId, String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedIds = prefs.getStringList(_unlockedLessonsKey) ?? ['numeros_6_1', 'algebra_6_1', 'numeros_7_1'];
    
    if (!unlockedIds.contains(lessonId)) {
      unlockedIds.add(lessonId);
      await prefs.setStringList(_unlockedLessonsKey, unlockedIds);
    }
  }
}
