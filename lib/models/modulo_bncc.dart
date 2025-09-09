class ModuloBNCC {
  final String unidadeTematica;
  final String subcategoria;
  final String subSubcategoria;
  final String anoEscolar;
  final String titulo;
  final String descricao;
  final List<String> habilidades;
  final List<String> objetivos;
  final int exerciciosNecessarios;
  final double taxaAcertoMinima;
  final List<String> prerequisitos;
  final String codigoBNCC;

  ModuloBNCC({
    required this.unidadeTematica,
    required this.subcategoria,
    required this.subSubcategoria,
    required this.anoEscolar,
    required this.titulo,
    required this.descricao,
    required this.habilidades,
    required this.objetivos,
    this.exerciciosNecessarios = 5,
    this.taxaAcertoMinima = 0.8,
    this.prerequisitos = const [],
    required this.codigoBNCC,
  });

  String get identificador =>
      '${unidadeTematica}_${subcategoria}_${subSubcategoria}_$anoEscolar';

  Map<String, dynamic> toJson() {
    return {
      'unidadeTematica': unidadeTematica,
      'subcategoria': subcategoria,
      'subSubcategoria': subSubcategoria,
      'anoEscolar': anoEscolar,
      'titulo': titulo,
      'descricao': descricao,
      'habilidades': habilidades,
      'objetivos': objetivos,
      'exerciciosNecessarios': exerciciosNecessarios,
      'taxaAcertoMinima': taxaAcertoMinima,
      'prerequisitos': prerequisitos,
      'codigoBNCC': codigoBNCC,
    };
  }

  factory ModuloBNCC.fromJson(Map<String, dynamic> json) {
    return ModuloBNCC(
      unidadeTematica: json['unidadeTematica'],
      subcategoria: json['subcategoria'] ??
          json['unidadeTematica'], // Fallback para compatibilidade
      subSubcategoria: json['subSubcategoria'] ??
          json['subcategoria'] ??
          json['unidadeTematica'], // Fallback para compatibilidade
      anoEscolar: json['anoEscolar'],
      titulo: json['titulo'],
      descricao: json['descricao'],
      habilidades: List<String>.from(json['habilidades']),
      objetivos: List<String>.from(json['objetivos']),
      exerciciosNecessarios: json['exerciciosNecessarios'] ?? 5,
      taxaAcertoMinima: json['taxaAcertoMinima'] ?? 0.8,
      prerequisitos: List<String>.from(json['prerequisitos'] ?? []),
      codigoBNCC: json['codigoBNCC'],
    );
  }
}

class ModulosBNCCData {
  static final Map<String, List<ModuloBNCC>> _modulos = {
    'Números': [
      ModuloBNCC(
        unidadeTematica: 'Números',
        subcategoria: 'Números Naturais',
        subSubcategoria: 'Conceitos fundamentais de números naturais',
        anoEscolar: '6º ano',
        titulo: 'Números Naturais - Conceitos Fundamentais',
        descricao:
            'Conceitos fundamentais de números naturais, propriedades e operações básicas.',
        habilidades: [
          'EF06MA01',
          'EF06MA02',
        ],
        objetivos: [
          'Compreender números naturais',
          'Identificar propriedades dos números naturais',
          'Realizar operações básicas'
        ],
        codigoBNCC: 'EF06MA',
      ),
      ModuloBNCC(
        unidadeTematica: 'Números',
        subcategoria: 'Números Naturais',
        subSubcategoria: 'Números Inteiros',
        anoEscolar: '6º ano',
        titulo: 'Números Inteiros',
        descricao: 'Introdução aos números inteiros, positivos e negativos.',
        habilidades: [
          'EF06MA03',
        ],
        objetivos: [
          'Compreender números inteiros',
          'Representar números na reta numérica',
          'Comparar números inteiros'
        ],
        codigoBNCC: 'EF06MA',
      ),
      ModuloBNCC(
        unidadeTematica: 'Números',
        subcategoria: 'Números Naturais',
        subSubcategoria: 'Múltiplos',
        anoEscolar: '6º ano',
        titulo: 'Múltiplos e Divisores',
        descricao: 'Conceito de múltiplos e divisores, MMC e MDC.',
        habilidades: [
          'EF06MA04',
          'EF06MA05',
        ],
        objetivos: [
          'Identificar múltiplos de um número',
          'Encontrar divisores de um número',
          'Calcular MMC e MDC'
        ],
        codigoBNCC: 'EF06MA',
      ),
      ModuloBNCC(
        unidadeTematica: 'Números',
        subcategoria: 'Números Naturais',
        subSubcategoria: 'Divisores',
        anoEscolar: '6º ano',
        titulo: 'Divisores e Fatores',
        descricao:
            'Conceito de divisores, fatores primos e decomposição em fatores primos.',
        habilidades: [
          'EF06MA06',
          'EF06MA07',
        ],
        objetivos: [
          'Identificar divisores de um número',
          'Reconhecer números primos',
          'Decompor números em fatores primos'
        ],
        codigoBNCC: 'EF06MA',
      ),
      ModuloBNCC(
        unidadeTematica: 'Números',
        subcategoria: 'Frações e Decimais',
        subSubcategoria: 'Números Racionais',
        anoEscolar: '7º ano',
        titulo: 'Números Racionais',
        descricao:
            'Números racionais, operações com frações e decimais, porcentagem.',
        habilidades: [
          'EF07MA01',
          'EF07MA02',
          'EF07MA03',
          'EF07MA04',
          'EF07MA05',
          'EF07MA06'
        ],
        objetivos: [
          'Compreender números racionais',
          'Realizar operações com frações',
          'Calcular porcentagens',
          'Resolver problemas do cotidiano'
        ],
        prerequisitos: ['Números_Números Naturais e Inteiros_6º ano'],
        codigoBNCC: 'EF07MA',
      ),
      ModuloBNCC(
        unidadeTematica: 'Números',
        subcategoria: 'Potenciação e Radiciação',
        subSubcategoria: 'Potenciação e Radiciação',
        anoEscolar: '8º ano',
        titulo: 'Potenciação e Radiciação',
        descricao:
            'Dízimas periódicas, potenciação e radiciação, notação científica.',
        habilidades: ['EF08MA01', 'EF08MA02', 'EF08MA03', 'EF08MA04'],
        objetivos: [
          'Compreender dízimas periódicas',
          'Dominar potenciação e radiciação',
          'Usar notação científica',
          'Resolver problemas com potências'
        ],
        prerequisitos: ['Números_Frações e Decimais_7º ano'],
        codigoBNCC: 'EF08MA',
      ),
      ModuloBNCC(
        unidadeTematica: 'Números',
        subcategoria: 'Números Reais',
        subSubcategoria: 'Números Reais',
        anoEscolar: '9º ano',
        titulo: 'Números Reais',
        descricao: 'Números irracionais, números reais, aproximações.',
        habilidades: ['EF09MA01', 'EF09MA02', 'EF09MA03'],
        objetivos: [
          'Compreender números irracionais',
          'Trabalhar com números reais',
          'Realizar aproximações',
          'Localizar números na reta'
        ],
        prerequisitos: ['Números_Potenciação e Radiciação_8º ano'],
        codigoBNCC: 'EF09MA',
      ),
    ],
    'Álgebra': [
      ModuloBNCC(
        unidadeTematica: 'Álgebra',
        subcategoria: 'Sequências e Padrões',
        subSubcategoria: 'Sequências e Padrões',
        anoEscolar: '6º ano',
        titulo: 'Sequências e Regularidades',
        descricao: 'Sequências numéricas, regularidades e padrões.',
        habilidades: ['EF06MA12', 'EF06MA13', 'EF06MA14'],
        objetivos: [
          'Identificar sequências numéricas',
          'Reconhecer regularidades',
          'Continuar sequências',
          'Criar padrões'
        ],
        codigoBNCC: 'EF06MA',
      ),
      ModuloBNCC(
        unidadeTematica: 'Álgebra',
        subcategoria: 'Equações Lineares',
        subSubcategoria: 'Equações Lineares',
        anoEscolar: '7º ano',
        titulo: 'Equações do 1º Grau',
        descricao: 'Linguagem algébrica, equações do 1º grau.',
        habilidades: [
          'EF07MA13',
          'EF07MA14',
          'EF07MA15',
          'EF07MA16',
          'EF07MA17',
          'EF07MA18'
        ],
        objetivos: [
          'Compreender linguagem algébrica',
          'Resolver equações do 1º grau',
          'Traduzir problemas para equações',
          'Interpretar soluções'
        ],
        prerequisitos: ['Álgebra_Sequências e Padrões_6º ano'],
        codigoBNCC: 'EF07MA',
      ),
      ModuloBNCC(
        unidadeTematica: 'Álgebra',
        subcategoria: 'Sistemas de Equações',
        subSubcategoria: 'Sistemas de Equações',
        anoEscolar: '8º ano',
        titulo: 'Sistemas de Equações',
        descricao:
            'Equações do 1º grau com duas incógnitas, sistemas de equações.',
        habilidades: ['EF08MA06', 'EF08MA07', 'EF08MA08'],
        objetivos: [
          'Resolver sistemas de equações',
          'Interpretar graficamente',
          'Aplicar em problemas reais',
          'Compreender soluções'
        ],
        prerequisitos: ['Álgebra_Equações Lineares_7º ano'],
        codigoBNCC: 'EF08MA',
      ),
      ModuloBNCC(
        unidadeTematica: 'Álgebra',
        subcategoria: 'Funções e Equações Quadráticas',
        subSubcategoria: 'Funções e Equações Quadráticas',
        anoEscolar: '9º ano',
        titulo: 'Funções e Equações do 2º Grau',
        descricao: 'Equações do 2º grau, funções.',
        habilidades: [
          'EF09MA04',
          'EF09MA05',
          'EF09MA06',
          'EF09MA07',
          'EF09MA08',
          'EF09MA09'
        ],
        objetivos: [
          'Resolver equações do 2º grau',
          'Compreender funções',
          'Interpretar gráficos',
          'Modelar situações'
        ],
        prerequisitos: ['Álgebra_Sistemas de Equações_8º ano'],
        codigoBNCC: 'EF09MA',
      ),
    ],
    'Geometria': [
      ModuloBNCC(
        unidadeTematica: 'Geometria',
        subcategoria: 'Figuras Geométricas',
        subSubcategoria: 'Figuras Geométricas',
        anoEscolar: '6º ano',
        titulo: 'Figuras Geométricas',
        descricao: 'Figuras geométricas espaciais e planas, vistas ortogonais.',
        habilidades: ['EF06MA15', 'EF06MA16', 'EF06MA17'],
        objetivos: [
          'Reconhecer figuras geométricas',
          'Compreender vistas ortogonais',
          'Classificar polígonos',
          'Relacionar 2D e 3D'
        ],
        codigoBNCC: 'EF06MA',
      ),
      ModuloBNCC(
        unidadeTematica: 'Geometria',
        subcategoria: 'Transformações Geométricas',
        subSubcategoria: 'Transformações Geométricas',
        anoEscolar: '7º ano',
        titulo: 'Transformações Geométricas',
        descricao: 'Transformações geométricas, simetrias.',
        habilidades: ['EF07MA19', 'EF07MA20', 'EF07MA21'],
        objetivos: [
          'Aplicar transformações',
          'Reconhecer simetrias',
          'Construir figuras',
          'Compreender congruência'
        ],
        prerequisitos: ['Geometria_Figuras Geométricas_6º ano'],
        codigoBNCC: 'EF07MA',
      ),
      ModuloBNCC(
        unidadeTematica: 'Geometria',
        subcategoria: 'Teorema de Pitágoras',
        subSubcategoria: 'Teorema de Pitágoras',
        anoEscolar: '8º ano',
        titulo: 'Teorema de Pitágoras',
        descricao: 'Congruência e semelhança, Teorema de Pitágoras.',
        habilidades: ['EF08MA11', 'EF08MA12', 'EF08MA13'],
        objetivos: [
          'Compreender congruência',
          'Aplicar Teorema de Pitágoras',
          'Reconhecer semelhança',
          'Resolver problemas geométricos'
        ],
        prerequisitos: ['Geometria_Transformações Geométricas_7º ano'],
        codigoBNCC: 'EF08MA',
      ),
      ModuloBNCC(
        unidadeTematica: 'Geometria',
        subcategoria: 'Círculo e Circunferência',
        subSubcategoria: 'Círculo e Circunferência',
        anoEscolar: '9º ano',
        titulo: 'Círculo e Circunferência',
        descricao:
            'Relações métricas no triângulo retângulo, círculo e circunferência.',
        habilidades: ['EF09MA13', 'EF09MA14', 'EF09MA15', 'EF09MA16'],
        objetivos: [
          'Aplicar relações métricas',
          'Compreender círculo',
          'Calcular comprimento e área',
          'Resolver problemas complexos'
        ],
        prerequisitos: ['Geometria_Teorema de Pitágoras_8º ano'],
        codigoBNCC: 'EF09MA',
      ),
    ],
    'Grandezas e Medidas': [
      ModuloBNCC(
        unidadeTematica: 'Grandezas e Medidas',
        subcategoria: 'Unidades de Medida',
        subSubcategoria: 'Unidades de Medida',
        anoEscolar: '6º ano',
        titulo: 'Unidades de Medida',
        descricao: 'Unidades de medida, área e perímetro.',
        habilidades: [
          'EF06MA24',
          'EF06MA25',
          'EF06MA26',
          'EF06MA27',
          'EF06MA28',
          'EF06MA29'
        ],
        objetivos: [
          'Compreender unidades de medida',
          'Calcular área e perímetro',
          'Converter unidades',
          'Resolver problemas práticos'
        ],
        codigoBNCC: 'EF06MA',
      ),
      ModuloBNCC(
        unidadeTematica: 'Grandezas e Medidas',
        subcategoria: 'Área de Figuras Planas',
        subSubcategoria: 'Área de Figuras Planas',
        anoEscolar: '7º ano',
        titulo: 'Área de Figuras Planas',
        descricao: 'Cálculo de área de figuras planas.',
        habilidades: ['EF07MA30', 'EF07MA31', 'EF07MA32'],
        objetivos: [
          'Calcular área de figuras',
          'Aplicar fórmulas',
          'Decompor figuras complexas',
          'Resolver problemas reais'
        ],
        prerequisitos: ['Grandezas e Medidas_Unidades de Medida_6º ano'],
        codigoBNCC: 'EF07MA',
      ),
      ModuloBNCC(
        unidadeTematica: 'Grandezas e Medidas',
        subcategoria: 'Volume e Capacidade',
        subSubcategoria: 'Volume e Capacidade',
        anoEscolar: '8º ano',
        titulo: 'Volume de Sólidos',
        descricao: 'Volume de prismas e cilindros.',
        habilidades: ['EF08MA20', 'EF08MA21'],
        objetivos: [
          'Calcular volume de prismas',
          'Calcular volume de cilindros',
          'Compreender capacidade',
          'Aplicar em situações reais'
        ],
        prerequisitos: ['Grandezas e Medidas_Área de Figuras Planas_7º ano'],
        codigoBNCC: 'EF08MA',
      ),
      ModuloBNCC(
        unidadeTematica: 'Grandezas e Medidas',
        subcategoria: 'Trigonometria Básica',
        subSubcategoria: 'Trigonometria Básica',
        anoEscolar: '9º ano',
        titulo: 'Volumes Complexos',
        descricao: 'Volume de pirâmides, cones e esferas.',
        habilidades: ['EF09MA19', 'EF09MA20', 'EF09MA21'],
        objetivos: [
          'Calcular volume de pirâmides',
          'Calcular volume de cones',
          'Calcular volume de esferas',
          'Resolver problemas complexos'
        ],
        prerequisitos: ['Grandezas e Medidas_Volume e Capacidade_8º ano'],
        codigoBNCC: 'EF09MA',
      ),
    ],
    'Probabilidade e Estatística': [
      ModuloBNCC(
        unidadeTematica: 'Probabilidade e Estatística',
        subcategoria: 'Leitura e Interpretação de Gráficos',
        subSubcategoria: 'Leitura e Interpretação de Gráficos',
        anoEscolar: '6º ano',
        titulo: 'Leitura de Gráficos',
        descricao: 'Leitura e interpretação de gráficos e tabelas.',
        habilidades: [
          'EF06MA30',
          'EF06MA31',
          'EF06MA32',
          'EF06MA33',
          'EF06MA34'
        ],
        objetivos: [
          'Ler gráficos e tabelas',
          'Interpretar dados',
          'Criar representações',
          'Analisar informações'
        ],
        codigoBNCC: 'EF06MA',
      ),
      ModuloBNCC(
        unidadeTematica: 'Probabilidade e Estatística',
        subcategoria: 'Medidas de Tendência Central',
        subSubcategoria: 'Medidas de Tendência Central',
        anoEscolar: '7º ano',
        titulo: 'Pesquisa Estatística',
        descricao: 'Pesquisa estatística, medidas de tendência central.',
        habilidades: ['EF07MA35', 'EF07MA36', 'EF07MA37'],
        objetivos: [
          'Planejar pesquisas',
          'Calcular média, moda, mediana',
          'Interpretar resultados',
          'Comunicar descobertas'
        ],
        prerequisitos: [
          'Probabilidade e Estatística_Leitura e Interpretação de Gráficos_6º ano'
        ],
        codigoBNCC: 'EF07MA',
      ),
      ModuloBNCC(
        unidadeTematica: 'Probabilidade e Estatística',
        subcategoria: 'Probabilidade',
        subSubcategoria: 'Probabilidade',
        anoEscolar: '8º ano',
        titulo: 'Probabilidade',
        descricao: 'Princípio multiplicativo, probabilidade.',
        habilidades: ['EF08MA22', 'EF08MA23'],
        objetivos: [
          'Aplicar princípio multiplicativo',
          'Calcular probabilidades',
          'Compreender aleatoriedade',
          'Fazer previsões'
        ],
        prerequisitos: [
          'Probabilidade e Estatística_Medidas de Tendência Central_7º ano'
        ],
        codigoBNCC: 'EF08MA',
      ),
      ModuloBNCC(
        unidadeTematica: 'Probabilidade e Estatística',
        subcategoria: 'Análise de Dados',
        subSubcategoria: 'Análise de Dados',
        anoEscolar: '9º ano',
        titulo: 'Análise de Dados',
        descricao: 'Análise de gráficos, planejamento de pesquisas.',
        habilidades: ['EF09MA22', 'EF09MA23'],
        objetivos: [
          'Analisar gráficos complexos',
          'Planejar pesquisas avançadas',
          'Interpretar criticamente',
          'Tomar decisões baseadas em dados'
        ],
        prerequisitos: ['Probabilidade e Estatística_Probabilidade_8º ano'],
        codigoBNCC: 'EF09MA',
      ),
    ],
  };

  static List<String> obterSubSubcategoriasPorSubcategoria(
      String unidade, String subcategoria) {
    final modulos = _modulos[unidade]
            ?.where((modulo) => modulo.subcategoria == subcategoria)
            .toList() ??
        [];
    return modulos.map((modulo) => modulo.subSubcategoria).toSet().toList();
  }

  static List<ModuloBNCC> obterModulosPorSubSubcategoria(
      String unidade, String subcategoria, String subSubcategoria) {
    return _modulos[unidade]
            ?.where((modulo) =>
                modulo.subcategoria == subcategoria &&
                modulo.subSubcategoria == subSubcategoria)
            .toList() ??
        [];
  }

  static List<ModuloBNCC> obterModulosPorUnidade(String unidade) {
    return _modulos[unidade] ?? [];
  }

  static ModuloBNCC? obterModulo(String unidade, String ano,
      [String? subcategoria, String? subSubcategoria]) {
    if (subcategoria != null && subSubcategoria != null) {
      return _modulos[unidade]?.firstWhere(
        (modulo) =>
            modulo.anoEscolar == ano &&
            modulo.subcategoria == subcategoria &&
            modulo.subSubcategoria == subSubcategoria,
        orElse: () => throw Exception('Módulo não encontrado'),
      );
    } else if (subcategoria != null) {
      return _modulos[unidade]?.firstWhere(
        (modulo) =>
            modulo.anoEscolar == ano && modulo.subcategoria == subcategoria,
        orElse: () => throw Exception('Módulo não encontrado'),
      );
    } else {
      return _modulos[unidade]?.firstWhere(
        (modulo) => modulo.anoEscolar == ano,
        orElse: () => throw Exception('Módulo não encontrado'),
      );
    }
  }

  static List<String> obterSubcategoriasPorUnidade(String unidade) {
    final modulos = _modulos[unidade] ?? [];
    return modulos.map((modulo) => modulo.subcategoria).toSet().toList();
  }

  static List<ModuloBNCC> obterModulosPorSubcategoria(
      String unidade, String subcategoria) {
    return _modulos[unidade]
            ?.where((modulo) => modulo.subcategoria == subcategoria)
            .toList() ??
        [];
  }

  static List<String> obterUnidadesTematicas() {
    return _modulos.keys.toList();
  }

  static List<String> obterAnosEscolares() {
    return ['6º ano', '7º ano', '8º ano', '9º ano'];
  }

  static List<ModuloBNCC> obterTodosModulos() {
    List<ModuloBNCC> todos = [];
    for (List<ModuloBNCC> modulos in _modulos.values) {
      todos.addAll(modulos);
    }
    return todos;
  }
}
