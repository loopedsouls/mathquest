import 'dart:convert';

enum NivelUsuario {
  iniciante, // Completou módulos apenas do 6º Ano
  intermediario, // Completou módulos do 6º e 7º Ano
  avancado, // Completou módulos do 6º ao 8º Ano
  especialista // Completou todos os módulos do 6º ao 9º Ano
}

class ProgressoUsuario {
  // Mapa: unidade temática -> ano escolar -> completo
  Map<String, Map<String, bool>> modulosCompletos;
  NivelUsuario nivelUsuario;
  Map<String, int> pontosPorUnidade;
  Map<String, int> exerciciosCorretosConsecutivos;
  Map<String, double> taxaAcertoPorModulo;
  DateTime ultimaAtualizacao;
  int totalExerciciosRespondidos;
  int totalExerciciosCorretos;

  // Novos campos para acompanhar progresso das aulas
  Map<String, int>
      totalAulasPorModulo; // chave: "unidade_ano" -> total de aulas
  Map<String, int>
      aulasComplementadasPorModulo; // chave: "unidade_ano" -> aulas completadas

  ProgressoUsuario({
    Map<String, Map<String, bool>>? modulosCompletos,
    this.nivelUsuario = NivelUsuario.iniciante,
    Map<String, int>? pontosPorUnidade,
    Map<String, int>? exerciciosCorretosConsecutivos,
    Map<String, double>? taxaAcertoPorModulo,
    DateTime? ultimaAtualizacao,
    this.totalExerciciosRespondidos = 0,
    this.totalExerciciosCorretos = 0,
    Map<String, int>? totalAulasPorModulo,
    Map<String, int>? aulasComplementadasPorModulo,
  })  : modulosCompletos = modulosCompletos ?? _criarEstruturabradrao(),
        pontosPorUnidade = pontosPorUnidade ?? {},
        exerciciosCorretosConsecutivos = exerciciosCorretosConsecutivos ?? {},
        taxaAcertoPorModulo = taxaAcertoPorModulo ?? {},
        ultimaAtualizacao = ultimaAtualizacao ?? DateTime.now(),
        totalAulasPorModulo = totalAulasPorModulo ?? {},
        aulasComplementadasPorModulo = aulasComplementadasPorModulo ?? {};

  // Cria estrutura padrão com todas as unidades e anos
  static Map<String, Map<String, bool>> _criarEstruturabradrao() {
    const unidades = [
      'Números',
      'Álgebra',
      'Geometria',
      'Grandezas e Medidas',
      'Probabilidade e Estatística'
    ];
    const anos = ['6º ano', '7º ano', '8º ano', '9º ano'];

    Map<String, Map<String, bool>> estrutura = {};
    for (String unidade in unidades) {
      estrutura[unidade] = {};
      for (String ano in anos) {
        estrutura[unidade]![ano] = false;
      }
    }
    return estrutura;
  }

  // Calcula o nível do usuário baseado nos módulos completos
  NivelUsuario calcularNivel() {
    Map<String, int> anosPorUnidade = {};

    // Conta quantos anos cada unidade tem completos
    for (String unidade in modulosCompletos.keys) {
      int anosCompletos = 0;
      for (String ano in ['6º ano', '7º ano', '8º ano', '9º ano']) {
        if (modulosCompletos[unidade]![ano] == true) {
          anosCompletos =
              ['6º ano', '7º ano', '8º ano', '9º ano'].indexOf(ano) + 1;
        } else {
          break; // Para na primeira falha (progressão sequencial)
        }
      }
      anosPorUnidade[unidade] = anosCompletos;
    }

    // Determina o nível baseado no menor progresso entre as unidades
    int menorProgresso = anosPorUnidade.values.reduce((a, b) => a < b ? a : b);

    switch (menorProgresso) {
      case 0:
        return NivelUsuario.iniciante;
      case 1:
        return NivelUsuario.iniciante;
      case 2:
        return NivelUsuario.intermediario;
      case 3:
        return NivelUsuario.avancado;
      case 4:
        return NivelUsuario.especialista;
      default:
        return NivelUsuario.iniciante;
    }
  }

  // Marca um módulo como completo
  void completarModulo(String unidade, String ano) {
    modulosCompletos[unidade]![ano] = true;
    ultimaAtualizacao = DateTime.now();
    nivelUsuario = calcularNivel();

    // Adiciona pontos
    pontosPorUnidade[unidade] = (pontosPorUnidade[unidade] ?? 0) + 100;
  }

  // Define o total de aulas para um módulo
  void definirTotalAulas(String unidade, String ano, int totalAulas) {
    final chaveModulo = '${unidade}_$ano';
    totalAulasPorModulo[chaveModulo] = totalAulas;
    ultimaAtualizacao = DateTime.now();
  }

  // Completa uma aula do módulo
  void completarAula(String unidade, String ano) {
    final chaveModulo = '${unidade}_$ano';
    aulasComplementadasPorModulo[chaveModulo] =
        (aulasComplementadasPorModulo[chaveModulo] ?? 0) + 1;

    // Verifica se todas as aulas foram completadas para marcar o módulo como completo
    final totalAulas = totalAulasPorModulo[chaveModulo] ?? 0;
    final aulasCompletas = aulasComplementadasPorModulo[chaveModulo] ?? 0;

    if (totalAulas > 0 && aulasCompletas >= totalAulas) {
      completarModulo(unidade, ano);
    }

    ultimaAtualizacao = DateTime.now();
  }

  // Obtém a próxima aula de um módulo
  int obterProximaAula(String unidade, String ano) {
    final chaveModulo = '${unidade}_$ano';
    final aulasCompletas = aulasComplementadasPorModulo[chaveModulo] ?? 0;
    return aulasCompletas + 1;
  }

  // Calcula o progresso das aulas de um módulo (0.0 a 1.0)
  double calcularProgressoAulas(String unidade, String ano) {
    final chaveModulo = '${unidade}_$ano';
    final totalAulas = totalAulasPorModulo[chaveModulo] ?? 0;
    final aulasCompletas = aulasComplementadasPorModulo[chaveModulo] ?? 0;

    return totalAulas > 0 ? aulasCompletas / totalAulas : 0.0;
  }

  // Verifica se um módulo está desbloqueado
  bool moduloDesbloqueado(String unidade, String ano) {
    const anos = ['6º ano', '7º ano', '8º ano', '9º ano'];
    int indiceAno = anos.indexOf(ano);

    // 6º ano sempre desbloqueado
    if (indiceAno == 0) return true;

    // Próximo ano só desbloqueia se o anterior estiver completo
    String anoAnterior = anos[indiceAno - 1];
    return modulosCompletos[unidade]![anoAnterior] == true;
  }

  // Calcula progresso geral (0.0 a 1.0)
  double calcularProgressoGeral() {
    int totalModulos = 0;
    int modulosCompletosCount = 0;

    for (Map<String, bool> anos in modulosCompletos.values) {
      for (bool completo in anos.values) {
        totalModulos++;
        if (completo) modulosCompletosCount++;
      }
    }

    return totalModulos > 0 ? modulosCompletosCount / totalModulos : 0.0;
  }

  // Calcula progresso por unidade
  double calcularProgressoPorUnidade(String unidade) {
    if (!modulosCompletos.containsKey(unidade)) return 0.0;

    int totalAnos = modulosCompletos[unidade]!.length;
    int anosCompletos =
        modulosCompletos[unidade]!.values.where((c) => c).length;

    return totalAnos > 0 ? anosCompletos / totalAnos : 0.0;
  }

  // Serialização para JSON
  Map<String, dynamic> toJson() {
    return {
      'modulosCompletos': modulosCompletos,
      'nivelUsuario': nivelUsuario.index,
      'pontosPorUnidade': pontosPorUnidade,
      'exerciciosCorretosConsecutivos': exerciciosCorretosConsecutivos,
      'taxaAcertoPorModulo': taxaAcertoPorModulo,
      'ultimaAtualizacao': ultimaAtualizacao.toIso8601String(),
      'totalExerciciosRespondidos': totalExerciciosRespondidos,
      'totalExerciciosCorretos': totalExerciciosCorretos,
      'totalAulasPorModulo': totalAulasPorModulo,
      'aulasComplementadasPorModulo': aulasComplementadasPorModulo,
    };
  }

  // Desserialização do JSON
  factory ProgressoUsuario.fromJson(Map<String, dynamic> json) {
    return ProgressoUsuario(
      modulosCompletos: Map<String, Map<String, bool>>.from(
        (json['modulosCompletos'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, Map<String, bool>.from(value)),
        ),
      ),
      nivelUsuario: NivelUsuario.values[json['nivelUsuario'] ?? 0],
      pontosPorUnidade: Map<String, int>.from(json['pontosPorUnidade'] ?? {}),
      exerciciosCorretosConsecutivos:
          Map<String, int>.from(json['exerciciosCorretosConsecutivos'] ?? {}),
      taxaAcertoPorModulo:
          Map<String, double>.from(json['taxaAcertoPorModulo'] ?? {}),
      ultimaAtualizacao: DateTime.parse(
          json['ultimaAtualizacao'] ?? DateTime.now().toIso8601String()),
      totalExerciciosRespondidos: json['totalExerciciosRespondidos'] ?? 0,
      totalExerciciosCorretos: json['totalExerciciosCorretos'] ?? 0,
      totalAulasPorModulo:
          Map<String, int>.from(json['totalAulasPorModulo'] ?? {}),
      aulasComplementadasPorModulo:
          Map<String, int>.from(json['aulasComplementadasPorModulo'] ?? {}),
    );
  }

  // Converter para string (para SharedPreferences)
  String toJsonString() => jsonEncode(toJson());

  // Criar do string (de SharedPreferences)
  static ProgressoUsuario fromJsonString(String jsonString) {
    return ProgressoUsuario.fromJson(jsonDecode(jsonString));
  }

  // Obter próximo módulo recomendado
  Map<String, String>? obterProximoModulo() {
    for (String unidade in modulosCompletos.keys) {
      for (String ano in ['6º ano', '7º ano', '8º ano', '9º ano']) {
        if (!modulosCompletos[unidade]![ano]! &&
            moduloDesbloqueado(unidade, ano)) {
          return {'unidade': unidade, 'ano': ano};
        }
      }
    }
    return null; // Todos os módulos completos
  }

  // Resetar progresso (para testes)
  void resetarProgresso() {
    modulosCompletos = _criarEstruturabradrao();
    nivelUsuario = NivelUsuario.iniciante;
    pontosPorUnidade.clear();
    exerciciosCorretosConsecutivos.clear();
    taxaAcertoPorModulo.clear();
    totalExerciciosRespondidos = 0;
    totalExerciciosCorretos = 0;
    totalAulasPorModulo.clear();
    aulasComplementadasPorModulo.clear();
    ultimaAtualizacao = DateTime.now();
  }
}

// Extensions para facilitar o uso
extension NivelUsuarioExtension on NivelUsuario {
  String get nome {
    switch (this) {
      case NivelUsuario.iniciante:
        return 'Iniciante';
      case NivelUsuario.intermediario:
        return 'Intermediário';
      case NivelUsuario.avancado:
        return 'Avançado';
      case NivelUsuario.especialista:
        return 'Especialista';
    }
  }

  String get descricao {
    switch (this) {
      case NivelUsuario.iniciante:
        return 'Completou módulos apenas do 6º Ano';
      case NivelUsuario.intermediario:
        return 'Completou módulos do 6º e 7º Ano';
      case NivelUsuario.avancado:
        return 'Completou módulos do 6º ao 8º Ano';
      case NivelUsuario.especialista:
        return 'Completou todos os módulos do 6º ao 9º Ano';
    }
  }

  String get emoji {
    switch (this) {
      case NivelUsuario.iniciante:
        return '🌱';
      case NivelUsuario.intermediario:
        return '📚';
      case NivelUsuario.avancado:
        return '🎓';
      case NivelUsuario.especialista:
        return '🏆';
    }
  }
}
