// Stub implementation for removed BNCC module model
class ModuloBNCC {
  final String unidadeTematica;
  final String subcategoria;
  final String subSubcategoria;
  final String anoEscolar;
  final List<String> prerequisitos;
  final String codigoBNCC;
  final String titulo;
  final String descricao;

  ModuloBNCC({
    required this.unidadeTematica,
    required this.subcategoria,
    required this.subSubcategoria,
    required this.anoEscolar,
    required this.prerequisitos,
    required this.codigoBNCC,
    this.titulo = '',
    this.descricao = '',
  });

  // Stub properties for compatibility
  int get exerciciosNecessarios => 10;
  double get taxaAcertoMinima => 0.7;

  Map<String, dynamic> toJson() {
    return {
      'unidadeTematica': unidadeTematica,
      'subcategoria': subcategoria,
      'subSubcategoria': subSubcategoria,
      'anoEscolar': anoEscolar,
      'prerequisitos': prerequisitos,
      'codigoBNCC': codigoBNCC,
      'titulo': titulo,
      'descricao': descricao,
    };
  }
}

class ModulosBNCCData {
  static ModuloBNCC? obterModulo(String unidade, String ano) {
    // Return null since BNCC modules were removed
    return null;
  }

  static List<ModuloBNCC> obterTodosModulos() {
    // Return empty list since BNCC modules were removed
    return [];
  }

  static List<String> obterUnidadesTematicas() {
    return [
      'Números',
      'Álgebra',
      'Geometria',
      'Grandezas e Medidas',
      'Probabilidade e Estatística'
    ];
  }

  static List<String> obterAnosEscolares() {
    return ['6º ano', '7º ano', '8º ano', '9º ano'];
  }
}
