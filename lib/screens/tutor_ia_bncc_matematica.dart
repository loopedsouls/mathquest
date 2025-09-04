import 'package:flutter/material.dart';

class BnccIaTutorMatematicaScreen extends StatelessWidget {
  const BnccIaTutorMatematicaScreen({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> unidadesTematicas = const [
    {
      'titulo': 'Números',
      'anos': [
        '6º ano: Números naturais e inteiros, múltiplos e divisores, frações e decimais',
        '7º ano: Números racionais, operações com frações e decimais, porcentagem',
        '8º ano: Dízimas periódicas, potenciação e radiciação, notação científica',
        '9º ano: Números irracionais, números reais, aproximações',
      ],
    },
    {
      'titulo': 'Álgebra',
      'anos': [
        '6º ano: Sequências numéricas, regularidades',
        '7º ano: Linguagem algébrica, equações do 1º grau',
        '8º ano: Equações do 1º grau com duas incógnitas, sistemas de equações',
        '9º ano: Equações do 2º grau, funções',
      ],
    },
    {
      'titulo': 'Geometria',
      'anos': [
        '6º ano: Figuras geométricas espaciais e planas, vistas ortogonais',
        '7º ano: Transformações geométricas, simetrias',
        '8º ano: Congruência e semelhança, Teorema de Pitágoras',
        '9º ano: Relações métricas no triângulo retângulo, círculo e circunferência',
      ],
    },
    {
      'titulo': 'Grandezas e Medidas',
      'anos': [
        '6º ano: Unidades de medida, área e perímetro',
        '7º ano: Cálculo de área de figuras planas',
        '8º ano: Volume de prismas e cilindros',
        '9º ano: Volume de pirâmides, cones e esferas',
      ],
    },
    {
      'titulo': 'Probabilidade e Estatística',
      'anos': [
        '6º ano: Leitura e interpretação de gráficos e tabelas',
        '7º ano: Pesquisa estatística, medidas de tendência central',
        '8º ano: Princípio multiplicativo, probabilidade',
        '9º ano: Análise de gráficos, planejamento de pesquisas',
      ],
    },
  ];

  final List<String> competenciasEspecificas = const [
    'Reconhecer a Matemática como ciência humana',
    'Desenvolver o raciocínio lógico',
    'Compreender relações entre conceitos',
    'Fazer observações sistemáticas',
    'Utilizar processos e ferramentas matemáticas',
    'Enfrentar situações-problema',
    'Desenvolver projetos que abordem questões de urgência social',
    'Interagir com seus pares de forma cooperativa',
  ];

  final List<String> orientacoesPedagogicas = const [
    'Conexão entre unidades: Trabalhar as 5 unidades de forma integrada, não isolada',
    'Progressão espiral: Retomar conceitos com maior complexidade a cada ano',
    'Contextualização: Conectar conceitos matemáticos com situações do cotidiano',
    'Resolução de problemas: Priorizar estratégias de resolução antes de procedimentos mecânicos',
    'Tecnologia: Integrar recursos digitais como ferramentas de aprendizagem',
    'Argumentação: Incentivar justificativas e comunicação matemática',
    'Diversidade de representações: Usar múltiplas formas de representar conceitos (gráfica, algébrica, numérica, geométrica)',
  ];

  final List<String> focoAprendizagem = const [
    'Compreensão conceitual antes da memorização',
    'Conexões entre diferentes áreas da Matemática',
    'Desenvolvimento do pensamento algébrico desde o 6º ano',
    'Uso crítico de dados e informações estatísticas',
    'Visualização e manipulação de objetos geométricos',
    'Estimativas e aproximações antes de cálculos exatos',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BNCC IA Tutor - Matemática'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Unidades Temáticas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          ...unidadesTematicas.map((unidade) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ExpansionTile(
                  title: Text(unidade['titulo'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: (unidade['anos'] as List<String>)
                      .map((ano) => ListTile(title: Text(ano)))
                      .toList(),
                ),
              )),
          const SizedBox(height: 24),
          const Text(
            'Competências Específicas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          ...competenciasEspecificas.map((comp) => ListTile(
                leading: const Icon(Icons.check),
                title: Text(comp),
              )),
          const SizedBox(height: 24),
          const Text(
            'Orientações Pedagógicas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          ...orientacoesPedagogicas.map((ori) => ListTile(
                leading: const Icon(Icons.lightbulb),
                title: Text(ori),
              )),
          const SizedBox(height: 24),
          const Text(
            'Foco na Aprendizagem Significativa',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          ...focoAprendizagem.map((foco) => ListTile(
                leading: const Icon(Icons.star),
                title: Text(foco),
              )),
        ],
      ),
    );
  }
}