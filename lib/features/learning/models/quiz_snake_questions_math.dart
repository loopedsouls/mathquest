import 'dart:math';

enum SnakeSpeed { lento, normal, rapido, hardcore }

class QuestionGenerator {
  final Random _random = Random();
  final Map<SnakeSpeed, int> _questionsPerLevel = {
    SnakeSpeed.lento: 10,
    SnakeSpeed.normal: 10,
    SnakeSpeed.rapido: 10,
    SnakeSpeed.hardcore: 10,
  };

  List<Map<String, dynamic>> generateQuestions(SnakeSpeed speed) {
    final questions = <Map<String, dynamic>>[];

    for (int i = 0; i < _questionsPerLevel[speed]!; i++) {
      questions.add(_generateQuestionForSpeed(speed));
    }

    return questions;
  }

  Map<String, dynamic> _generateQuestionForSpeed(SnakeSpeed speed) {
    switch (speed) {
      case SnakeSpeed.lento:
        return _generateBasicArithmetic();
      case SnakeSpeed.normal:
        return _generateGeometryFractions();
      case SnakeSpeed.rapido:
        return _generateAlgebra();
      case SnakeSpeed.hardcore:
        return _generateCalculus();
    }
  }

  Map<String, dynamic> _generateBasicArithmetic() {
    final operations = ['+', '-', '×', '÷'];
    final operation = operations[_random.nextInt(operations.length)];

    int num1, num2, answer;
    String question, explanation;

    switch (operation) {
      case '+':
        num1 = _random.nextInt(20) + 1;
        num2 = _random.nextInt(20) + 1;
        answer = num1 + num2;
        question = 'Quanto é $num1 + $num2?';
        explanation = '$num1 + $num2 = $answer';
        break;
      case '-':
        num1 = _random.nextInt(20) + 10;
        num2 = _random.nextInt(num1) + 1;
        answer = num1 - num2;
        question = 'Quanto é $num1 - $num2?';
        explanation = '$num1 - $num2 = $answer';
        break;
      case '×':
        num1 = _random.nextInt(10) + 1;
        num2 = _random.nextInt(10) + 1;
        answer = num1 * num2;
        question = 'Qual é o resultado de $num1 × $num2?';
        explanation = '$num1 × $num2 = $answer';
        break;
      default: // ÷
        answer = _random.nextInt(10) + 1;
        num2 = _random.nextInt(10) + 1;
        num1 = answer * num2;
        question = 'Quanto é $num1 ÷ $num2?';
        explanation = '$num1 ÷ $num2 = $answer';
        break;
    }

    final options = _generateOptions(answer, 4, 0, 200);
    final types = ['multipla_escolha', 'verdadeiro_falso', 'complete_frase'];
    final type = types[_random.nextInt(types.length)];

    if (type == 'verdadeiro_falso') {
      final isTrue = _random.nextBool();
      final statement = isTrue
          ? '$answer é o resultado correto de $num1 $operation $num2'
          : '${answer + _random.nextInt(5) + 1} é o resultado correto de $num1 $operation $num2';
      return {
        'pergunta': 'Verdadeiro ou falso: $statement.',
        'resposta_correta': isTrue ? 'Verdadeiro' : 'Falso',
        'tipo': type,
        'explicacao': explanation,
      };
    } else if (type == 'complete_frase') {
      return {
        'pergunta': 'Complete a frase: $num1 $operation $num2 = ___',
        'resposta_correta': answer.toString(),
        'tipo': type,
        'explicacao': explanation,
      };
    } else {
      return {
        'pergunta': question,
        'opcoes': options.map((o) => o.toString()).toList(),
        'resposta_correta': answer.toString(),
        'tipo': type,
        'explicacao': explanation,
      };
    }
  }

  Map<String, dynamic> _generateGeometryFractions() {
    final questionTypes = ['area', 'perimeter', 'fraction', 'angle'];
    final type = questionTypes[_random.nextInt(questionTypes.length)];

    switch (type) {
      case 'area':
        return _generateAreaQuestion();
      case 'perimeter':
        return _generatePerimeterQuestion();
      case 'fraction':
        return _generateFractionQuestion();
      default: // angle
        return _generateAngleQuestion();
    }
  }

  Map<String, dynamic> _generateAreaQuestion() {
    final shapes = ['square', 'rectangle', 'triangle'];
    final shape = shapes[_random.nextInt(shapes.length)];

    int side, length, width, base, height, answer;
    String question, explanation;

    switch (shape) {
      case 'square':
        side = _random.nextInt(10) + 1;
        answer = side * side;
        question = 'Qual é a área de um quadrado com lado $side cm?';
        explanation =
            'Área do quadrado = lado × lado = $side × $side = $answer cm²';
        break;
      case 'rectangle':
        length = _random.nextInt(10) + 1;
        width = _random.nextInt(10) + 1;
        answer = length * width;
        question =
            'Qual é a área de um retângulo com comprimento $length cm e largura $width cm?';
        explanation =
            'Área do retângulo = comprimento × largura = $length × $width = $answer cm²';
        break;
      default: // triangle
        base = _random.nextInt(10) + 1;
        height = _random.nextInt(10) + 1;
        answer = (base * height) ~/ 2;
        question =
            'Qual é a área de um triângulo com base $base cm e altura $height cm?';
        explanation =
            'Área do triângulo = (base × altura) / 2 = ($base × $height) / 2 = $answer cm²';
        break;
    }

    final options = _generateOptions(answer, 4, 0, 200);
    return {
      'pergunta': question,
      'opcoes': options.map((o) => '$o cm²').toList(),
      'resposta_correta': '$answer cm²',
      'tipo': 'multipla_escolha',
      'explicacao': explanation,
    };
  }

  Map<String, dynamic> _generatePerimeterQuestion() {
    final shapes = ['square', 'rectangle'];
    final shape = shapes[_random.nextInt(shapes.length)];

    int side, length, width, answer;
    String question, explanation;

    if (shape == 'square') {
      side = _random.nextInt(10) + 1;
      answer = 4 * side;
      question = 'Qual é o perímetro de um quadrado com lado $side cm?';
      explanation = 'Perímetro do quadrado = 4 × lado = 4 × $side = $answer cm';
    } else {
      length = _random.nextInt(10) + 1;
      width = _random.nextInt(10) + 1;
      answer = 2 * (length + width);
      question =
          'Qual é o perímetro de um retângulo com comprimento $length cm e largura $width cm?';
      explanation =
          'Perímetro do retângulo = 2 × (comprimento + largura) = 2 × ($length + $width) = $answer cm';
    }

    final options = _generateOptions(answer, 4, 0, 100);
    return {
      'pergunta': question,
      'opcoes': options.map((o) => '$o cm').toList(),
      'resposta_correta': '$answer cm',
      'tipo': 'multipla_escolha',
      'explicacao': explanation,
    };
  }

  Map<String, dynamic> _generateFractionQuestion() {
    final operations = ['+', '-', '×', '÷'];
    final operation = operations[_random.nextInt(operations.length)];

    int num1, den1, num2, den2, resultNum, resultDen;
    String question, explanation;

    num1 = _random.nextInt(5) + 1;
    den1 = _random.nextInt(5) + 2;
    num2 = _random.nextInt(5) + 1;
    den2 = _random.nextInt(5) + 2;

    // Ensure denominators are different for more interesting questions
    while (den1 == den2) {
      den2 = _random.nextInt(5) + 2;
    }

    switch (operation) {
      case '+':
        resultNum = num1 * den2 + num2 * den1;
        resultDen = den1 * den2;
        question = 'Quanto é $num1/$den1 + $num2/$den2?';
        explanation = '$num1/$den1 + $num2/$den2 = $resultNum/$resultDen';
        break;
      case '-':
        resultNum = num1 * den2 - num2 * den1;
        resultDen = den1 * den2;
        question = 'Quanto é $num1/$den1 - $num2/$den2?';
        explanation = '$num1/$den1 - $num2/$den2 = $resultNum/$resultDen';
        break;
      case '×':
        resultNum = num1 * num2;
        resultDen = den1 * den2;
        question = 'Quanto é $num1/$den1 × $num2/$den2?';
        explanation = '$num1/$den1 × $num2/$den2 = $resultNum/$resultDen';
        break;
      default: // ÷
        resultNum = num1 * den2;
        resultDen = den1 * num2;
        question = 'Quanto é $num1/$den1 ÷ $num2/$den2?';
        explanation = '$num1/$den1 ÷ $num2/$den2 = $resultNum/$resultDen';
        break;
    }

    // Simplify fraction
    final gcd = _gcd(resultNum.abs(), resultDen.abs());
    resultNum ~/= gcd;
    resultDen ~/= gcd;

    final answer = '$resultNum/$resultDen';
    final options = _generateFractionOptions(resultNum, resultDen, 4);

    return {
      'pergunta': question,
      'opcoes': options,
      'resposta_correta': answer,
      'tipo': 'multipla_escolha',
      'explicacao': explanation,
    };
  }

  Map<String, dynamic> _generateAngleQuestion() {
    final angleTypes = ['right', 'acute', 'obtuse'];
    final type = angleTypes[_random.nextInt(angleTypes.length)];

    int measure;
    String question, explanation;

    switch (type) {
      case 'right':
        measure = 90;
        question = 'Qual é a medida de um ângulo reto?';
        explanation = 'Um ângulo reto mede 90°.';
        break;
      case 'acute':
        measure = _random.nextInt(89) + 1;
        question = 'Qual é a medida de um ângulo agudo?';
        explanation = 'Um ângulo agudo mede menos de 90°. Este mede $measure°.';
        break;
      default: // obtuse
        measure = _random.nextInt(89) + 91;
        question = 'Qual é a medida de um ângulo obtuso?';
        explanation = 'Um ângulo obtuso mede mais de 90°. Este mede $measure°.';
        break;
    }

    final options = _generateOptions(measure, 4, 1, 180);
    return {
      'pergunta': question,
      'opcoes': options.map((o) => '$o°').toList(),
      'resposta_correta': '$measure°',
      'tipo': 'multipla_escolha',
      'explicacao': explanation,
    };
  }

  Map<String, dynamic> _generateAlgebra() {
    final questionTypes = ['linear', 'quadratic', 'exponential', 'logarithm'];
    final type = questionTypes[_random.nextInt(questionTypes.length)];

    switch (type) {
      case 'linear':
        return _generateLinearEquation();
      case 'quadratic':
        return _generateQuadraticEquation();
      case 'exponential':
        return _generateExponentialQuestion();
      default: // logarithm
        return _generateLogarithmQuestion();
    }
  }

  Map<String, dynamic> _generateLinearEquation() {
    final a = _random.nextInt(5) + 1;
    final b = _random.nextInt(10) + 1;
    final c = _random.nextInt(20) + 1;

    final answer = (c - b) / a;
    final isInteger = answer == answer.toInt();

    String question, explanation;
    if (isInteger) {
      final intAnswer = answer.toInt();
      question = 'Resolva para x: ${a}x + $b = $c';
      explanation =
          '${a}x + $b = $c → ${a}x = ${c - b} → x = ${c - b}/$a = $intAnswer';
      return {
        'pergunta': question,
        'opcoes': _generateOptions(intAnswer, 4, -10, 20)
            .map((o) => 'x = $o')
            .toList(),
        'resposta_correta': 'x = $intAnswer',
        'tipo': 'multipla_escolha',
        'explicacao': explanation,
      };
    } else {
      question = 'Resolva para x: ${a}x + $b = $c';
      explanation =
          '${a}x + $b = $c → ${a}x = ${c - b} → x = ${c - b}/$a = $answer';
      return {
        'pergunta': question,
        'opcoes': _generateOptions((answer * 10).toInt(), 4, -100, 200)
            .map((o) => 'x = ${(o / 10).toStringAsFixed(1)}')
            .toList(),
        'resposta_correta': 'x = ${answer.toStringAsFixed(1)}',
        'tipo': 'multipla_escolha',
        'explicacao': explanation,
      };
    }
  }

  Map<String, dynamic> _generateQuadraticEquation() {
    final a = _random.nextInt(3) + 1;
    final b = _random.nextInt(10) - 5;
    final c = _random.nextInt(10) - 5;

    final discriminant = b * b - 4 * a * c;
    final sqrtDisc = sqrt(discriminant);

    String question, explanation;
    if (discriminant >= 0 && sqrtDisc == sqrtDisc.toInt()) {
      final root1 = (-b + sqrtDisc.toInt()) ~/ (2 * a);
      final root2 = (-b - sqrtDisc.toInt()) ~/ (2 * a);
      question = 'Quais são as raízes de $a x² + $b x + $c = 0?';
      explanation =
          'Usando Bhaskara: x = (-$b ± √($b² - 4×$a×$c)) / (2×$a) = (-$b ± √$discriminant) / ${2 * a} = $root1, $root2';
      return {
        'pergunta': question,
        'opcoes': [
          'x = $root1, x = $root2',
          'x = ${-root1}, x = ${-root2}',
          'x = ${root1 + 1}, x = ${root2 + 1}',
          'x = ${root1 - 1}, x = ${root2 - 1}',
        ],
        'resposta_correta': 'x = $root1, x = $root2',
        'tipo': 'multipla_escolha',
        'explicacao': explanation,
      };
    } else {
      question = 'Qual é o discriminante de $a x² + $b x + $c = 0?';
      explanation = 'Discriminante = b² - 4ac = $b² - 4×$a×$c = $discriminant';
      final options = _generateOptions(discriminant, 4, -50, 100);
      return {
        'pergunta': question,
        'opcoes': options.map((o) => o.toString()).toList(),
        'resposta_correta': discriminant.toString(),
        'tipo': 'multipla_escolha',
        'explicacao': explanation,
      };
    }
  }

  Map<String, dynamic> _generateExponentialQuestion() {
    final base = _random.nextInt(5) + 2;
    final exponent = _random.nextInt(4) + 2;
    final answer = pow(base, exponent).toInt();

    final question = 'Quanto é $base^$exponent?';
    final explanation =
        '$base^$exponent = ${List.generate(exponent, (_) => base).join(' × ')} = $answer';

    final options = _generateOptions(answer, 4, 1, 1000);
    return {
      'pergunta': question,
      'opcoes': options.map((o) => o.toString()).toList(),
      'resposta_correta': answer.toString(),
      'tipo': 'multipla_escolha',
      'explicacao': explanation,
    };
  }

  Map<String, dynamic> _generateLogarithmQuestion() {
    final base = _random.nextInt(3) + 2; // 2 or 3
    final exponent = _random.nextInt(4) + 1; // 1-4
    final number = pow(base, exponent).toInt();

    final answer = exponent;
    final question = 'Quanto é log_$base($number)?';
    final explanation =
        'log_$base($number) = $answer porque $base^$answer = $number';

    final options = _generateOptions(answer, 4, 0, 10);
    return {
      'pergunta': question,
      'opcoes': options.map((o) => o.toString()).toList(),
      'resposta_correta': answer.toString(),
      'tipo': 'multipla_escolha',
      'explicacao': explanation,
    };
  }

  Map<String, dynamic> _generateCalculus() {
    final questionTypes = ['derivative', 'integral', 'limit'];
    final type = questionTypes[_random.nextInt(questionTypes.length)];

    switch (type) {
      case 'derivative':
        return _generateDerivativeQuestion();
      case 'integral':
        return _generateIntegralQuestion();
      default: // limit
        return _generateLimitQuestion();
    }
  }

  Map<String, dynamic> _generateDerivativeQuestion() {
    final functions = ['x^2', 'x^3', 'sin(x)', 'cos(x)', 'e^x'];
    final func = functions[_random.nextInt(functions.length)];

    String question, answer, explanation;

    switch (func) {
      case 'x^2':
        question = 'Qual é a derivada de x²?';
        answer = '2x';
        explanation = 'd/dx(x²) = 2x';
        break;
      case 'x^3':
        question = 'Qual é a derivada de x³?';
        answer = '3x²';
        explanation = 'd/dx(x³) = 3x²';
        break;
      case 'sin(x)':
        question = 'Qual é a derivada de sin(x)?';
        answer = 'cos(x)';
        explanation = 'd/dx(sin(x)) = cos(x)';
        break;
      case 'cos(x)':
        question = 'Qual é a derivada de cos(x)?';
        answer = '-sin(x)';
        explanation = 'd/dx(cos(x)) = -sin(x)';
        break;
      default: // e^x
        question = 'Qual é a derivada de e^x?';
        answer = 'e^x';
        explanation = 'd/dx(e^x) = e^x';
        break;
    }

    final options = [answer, 'x', '1', '0', 'ln(x)'];
    return {
      'pergunta': question,
      'opcoes': options,
      'resposta_correta': answer,
      'tipo': 'multipla_escolha',
      'explicacao': explanation,
    };
  }

  Map<String, dynamic> _generateIntegralQuestion() {
    final functions = ['x', 'x^2', 'e^x', '1/x'];
    final func = functions[_random.nextInt(functions.length)];

    String question, answer, explanation;

    switch (func) {
      case 'x':
        question = 'Qual é a integral de x dx?';
        answer = 'x²/2';
        explanation = '∫ x dx = x²/2 + C';
        break;
      case 'x^2':
        question = 'Qual é a integral de x² dx?';
        answer = 'x³/3';
        explanation = '∫ x² dx = x³/3 + C';
        break;
      case 'e^x':
        question = 'Qual é a integral de e^x dx?';
        answer = 'e^x';
        explanation = '∫ e^x dx = e^x + C';
        break;
      default: // 1/x
        question = 'Qual é a integral de 1/x dx?';
        answer = 'ln|x|';
        explanation = '∫ 1/x dx = ln|x| + C';
        break;
    }

    final options = [answer, 'x', 'x²', 'e^x', 'ln(x)'];
    return {
      'pergunta': question,
      'opcoes': options,
      'resposta_correta': answer,
      'tipo': 'multipla_escolha',
      'explicacao': explanation,
    };
  }

  Map<String, dynamic> _generateLimitQuestion() {
    final limitTypes = ['polynomial', 'rational'];
    final type = limitTypes[_random.nextInt(limitTypes.length)];

    String question, answer, explanation;

    if (type == 'polynomial') {
      final a = _random.nextInt(5) + 1;
      final b = _random.nextInt(10);
      question = 'Qual é o limite de ${a}x + $b quando x → ∞?';
      answer = '∞';
      explanation = 'O limite de uma função linear quando x → ∞ é ∞.';
    } else {
      final num1 = _random.nextInt(5) + 1;
      final num2 = _random.nextInt(5) + 1;
      final den1 = _random.nextInt(5) + 1;
      final den2 = _random.nextInt(5) + 1;
      question =
          'Qual é o limite de ($num1 x + $num2)/($den1 x + $den2) quando x → ∞?';
      answer = '${num1 ~/ _gcd(num1, den1)}/${den1 ~/ _gcd(num1, den1)}';
      explanation =
          'Para limites de funções racionais, divide numerador e denominador pelo termo de maior grau.';
    }

    final options = [answer, '0', '1', '∞', '-∞'];
    return {
      'pergunta': question,
      'opcoes': options,
      'resposta_correta': answer,
      'tipo': 'multipla_escolha',
      'explicacao': explanation,
    };
  }

  List<int> _generateOptions(int correct, int count, int min, int max) {
    final options = <int>{correct};

    while (options.length < count) {
      final option = _random.nextInt(max - min) + min;
      if (option != correct) {
        options.add(option);
      }
    }

    return options.toList()..shuffle(_random);
  }

  List<String> _generateFractionOptions(int num, int den, int count) {
    final options = <String>{'$num/$den'};

    while (options.length < count) {
      final newNum = num + _random.nextInt(5) - 2;
      final newDen = den + _random.nextInt(5) - 2;
      if (newNum > 0 && newDen > 0 && '$newNum/$newDen' != '$num/$den') {
        options.add('$newNum/$newDen');
      }
    }

    return options.toList()..shuffle(_random);
  }

  int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a;
  }
}

// Mantém compatibilidade com o código existente
const Map<SnakeSpeed, List<Map<String, dynamic>>> quizSnakeQuestions = {};

// Função para obter questões dinâmicas
List<Map<String, dynamic>> getQuizSnakeQuestions(SnakeSpeed speed) {
  final generator = QuestionGenerator();
  return generator.generateQuestions(speed);
}