import 'package:flutter/material.dart';

class MathTopics extends StatelessWidget {
  final Function(String)? onTopicSelected;

  const MathTopics({super.key, this.onTopicSelected});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMobile ? 'Tópicos Populares' : 'Popular Math Topics on arXiv',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3A8A),
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 2 : 3,
              crossAxisSpacing: isMobile ? 8 : 12,
              mainAxisSpacing: isMobile ? 8 : 12,
              childAspectRatio: isMobile ? 2.5 : 3,
            ),
            itemCount: _mathTopics.length,
            itemBuilder: (context, index) {
              final topic = _mathTopics[index];
              return _buildTopicCard(topic, isMobile);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(Map<String, String> topic, bool isMobile) {
    return Card(
      elevation: isMobile ? 1 : 2,
      child: InkWell(
        onTap: () => onTopicSelected?.call(topic['query']!),
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 8 : 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                const Color(0xFF3B82F6).withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                topic['title']!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 11 : 14,
                  color: const Color(0xFF1E3A8A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!isMobile) ...[
                const SizedBox(height: 4),
                Text(
                  topic['description']!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static final List<Map<String, String>> _mathTopics = [
    {
      'title': 'Number Theory',
      'query': 'number theory',
      'description': 'Prime numbers, cryptography, Diophantine equations'
    },
    {
      'title': 'Algebraic Geometry',
      'query': 'algebraic geometry',
      'description': 'Varieties, schemes, moduli spaces'
    },
    {
      'title': 'Differential Geometry',
      'query': 'differential geometry',
      'description': 'Manifolds, curvature, topology'
    },
    {
      'title': 'Functional Analysis',
      'query': 'functional analysis',
      'description': 'Banach spaces, operators, spectral theory'
    },
    {
      'title': 'Topology',
      'query': 'topology',
      'description': 'Algebraic topology, geometric topology'
    },
    {
      'title': 'Combinatorics',
      'query': 'combinatorics',
      'description': 'Graph theory, enumeration, extremal problems'
    },
    {
      'title': 'Probability Theory',
      'query': 'probability theory',
      'description': 'Stochastic processes, random matrices'
    },
    {
      'title': 'Mathematical Physics',
      'query': 'mathematical physics',
      'description': 'Quantum field theory, statistical mechanics'
    },
    {
      'title': 'Dynamical Systems',
      'query': 'dynamical systems',
      'description': 'Chaos theory, ergodic theory, bifurcations'
    },
    {
      'title': 'Partial Differential Equations',
      'query': 'partial differential equations',
      'description': 'PDE theory, numerical methods, applications'
    },
    {
      'title': 'Representation Theory',
      'query': 'representation theory',
      'description': 'Group representations, Lie algebras'
    },
    {
      'title': 'Logic',
      'query': 'mathematical logic',
      'description': 'Model theory, set theory, proof theory'
    },
    {
      'title': 'Optimization',
      'query': 'optimization',
      'description': 'Convex optimization, discrete optimization'
    },
    {
      'title': 'Algebraic Topology',
      'query': 'algebraic topology',
      'description': 'Homotopy theory, homology, cohomology'
    },
    {
      'title': 'Category Theory',
      'query': 'category theory',
      'description': 'Topos theory, higher categories'
    },
    {
      'title': 'Complex Analysis',
      'query': 'complex analysis',
      'description': 'Holomorphic functions, Riemann surfaces'
    },
    {
      'title': 'Harmonic Analysis',
      'query': 'harmonic analysis',
      'description': 'Fourier analysis, wavelets, time-frequency'
    },
    {
      'title': 'K-Theory',
      'query': 'k-theory',
      'description': 'Topological K-theory, algebraic K-theory'
    },
    {
      'title': 'Quantum Algebra',
      'query': 'quantum algebra',
      'description': 'Quantum groups, Hopf algebras'
    },
    {
      'title': 'Information Theory',
      'query': 'information theory',
      'description': 'Coding theory, entropy, compression'
    },
    {
      'title': 'Machine Learning Theory',
      'query': 'machine learning theory',
      'description': 'Statistical learning, neural networks'
    },
    {
      'title': 'Computational Geometry',
      'query': 'computational geometry',
      'description': 'Algorithms, mesh generation, visualization'
    },
    {
      'title': 'Game Theory',
      'query': 'game theory',
      'description': 'Nash equilibria, mechanism design'
    },
    {
      'title': 'Cryptography',
      'query': 'cryptography',
      'description': 'Public key, lattice-based, post-quantum'
    },
  ];
}
