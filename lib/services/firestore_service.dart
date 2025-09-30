import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/progresso_usuario.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Referências das coleções
  CollectionReference get _progressoCollection => _firestore.collection('progresso_usuario');
  CollectionReference get _estatisticasCollection => _firestore.collection('estatisticas_modulo');
  CollectionReference get _cacheIACollection => _firestore.collection('cache_ia');
  CollectionReference get _conquistasCollection => _firestore.collection('conquistas_usuario');

  // === MÉTODOS DE PROGRESSO ===

  Future<void> salvarProgresso(ProgressoUsuario progresso) async {
    if (_userId == null) throw Exception('Usuário não autenticado');

    final docRef = _progressoCollection.doc(_userId);
    final dados = {
      'modulosCompletos': progresso.modulosCompletos,
      'nivelUsuario': progresso.nivelUsuario.index,
      'pontosPorUnidade': progresso.pontosPorUnidade,
      'exerciciosCorretosConsecutivos': progresso.exerciciosCorretosConsecutivos,
      'taxaAcertoPorModulo': progresso.taxaAcertoPorModulo,
      'ultimaAtualizacao': progresso.ultimaAtualizacao.toIso8601String(),
      'totalExerciciosRespondidos': progresso.totalExerciciosRespondidos,
      'totalExerciciosCorretos': progresso.totalExerciciosCorretos,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(dados, SetOptions(merge: true));
  }

  Future<ProgressoUsuario?> carregarProgresso() async {
    if (_userId == null) return null;

    final docRef = _progressoCollection.doc(_userId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) return null;

    final data = snapshot.data() as Map<String, dynamic>;

    return ProgressoUsuario(
      modulosCompletos: Map<String, Map<String, bool>>.from(
        (data['modulosCompletos'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, Map<String, bool>.from(value as Map<String, dynamic>)),
        ) ?? {},
      ),
      nivelUsuario: NivelUsuario.values[data['nivelUsuario'] ?? 0],
      pontosPorUnidade: Map<String, int>.from(data['pontosPorUnidade'] ?? {}),
      exerciciosCorretosConsecutivos: Map<String, int>.from(data['exerciciosCorretosConsecutivos'] ?? {}),
      taxaAcertoPorModulo: Map<String, double>.from(data['taxaAcertoPorModulo'] ?? {}),
      ultimaAtualizacao: DateTime.parse(data['ultimaAtualizacao']),
      totalExerciciosRespondidos: data['totalExerciciosRespondidos'] ?? 0,
      totalExerciciosCorretos: data['totalExerciciosCorretos'] ?? 0,
    );
  }

  // === MÉTODOS DE ESTATÍSTICAS ===

  Future<void> salvarEstatisticaModulo({
    required String unidade,
    required String ano,
    required int corretas,
    required int total,
    required double tempoMedio,
    DateTime? ultimaTentativa,
  }) async {
    if (_userId == null) throw Exception('Usuário não autenticado');

    final docId = '${_userId}_${unidade}_$ano';
    final docRef = _estatisticasCollection.doc(docId);

    final dados = {
      'usuarioId': _userId,
      'unidade': unidade,
      'ano': ano,
      'corretas': corretas,
      'total': total,
      'tempoMedio': tempoMedio,
      'ultimaTentativa': ultimaTentativa?.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(dados, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> carregarEstatisticas() async {
    if (_userId == null) return [];

    final query = _estatisticasCollection.where('usuarioId', isEqualTo: _userId);
    final snapshot = await query.get();

    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  // === MÉTODOS DE CACHE IA ===

  Future<void> salvarCacheIA({
    required String chaveCache,
    required String unidade,
    required String ano,
    required String tipoQuiz,
    required String dificuldade,
    required String pergunta,
    String? opcoes,
    required String respostaCorreta,
    String? explicacao,
    required String fonteIA,
  }) async {
    final docRef = _cacheIACollection.doc(chaveCache);

    final dados = {
      'chaveCache': chaveCache,
      'unidade': unidade,
      'ano': ano,
      'tipoQuiz': tipoQuiz,
      'dificuldade': dificuldade,
      'pergunta': pergunta,
      'opcoes': opcoes,
      'respostaCorreta': respostaCorreta,
      'explicacao': explicacao,
      'fonteIA': fonteIA,
      'hits': FieldValue.increment(1),
      'lastUsed': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(dados, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> buscarCacheIA(String chaveCache) async {
    final docRef = _cacheIACollection.doc(chaveCache);
    final snapshot = await docRef.get();

    if (!snapshot.exists) return null;

    // Incrementar hits
    await docRef.update({'hits': FieldValue.increment(1), 'lastUsed': FieldValue.serverTimestamp()});

    return snapshot.data() as Map<String, dynamic>?;
  }

  Future<List<Map<String, dynamic>>> buscarCacheIAParams({
    required String unidade,
    required String ano,
    required String tipoQuiz,
    required String dificuldade,
  }) async {
    final query = _cacheIACollection
        .where('unidade', isEqualTo: unidade)
        .where('ano', isEqualTo: ano)
        .where('tipoQuiz', isEqualTo: tipoQuiz)
        .where('dificuldade', isEqualTo: dificuldade)
        .orderBy('lastUsed', descending: true)
        .limit(10);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  // === MÉTODOS DE CONQUISTAS ===

  Future<void> salvarConquista({
    required String conquistaId,
    required DateTime dataConquista,
  }) async {
    if (_userId == null) throw Exception('Usuário não autenticado');

    final docId = '${_userId}_$conquistaId';
    final docRef = _conquistasCollection.doc(docId);

    final dados = {
      'usuarioId': _userId,
      'conquistaId': conquistaId,
      'dataConquista': dataConquista.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(dados, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> carregarConquistas() async {
    if (_userId == null) return [];

    final query = _conquistasCollection.where('usuarioId', isEqualTo: _userId);
    final snapshot = await query.get();

    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  // === MÉTODO DE MIGRAÇÃO ===

  Future<void> migrarDadosLocais({
    required ProgressoUsuario? progresso,
    required List<Map<String, dynamic>> estatisticas,
    required List<Map<String, dynamic>> conquistas,
  }) async {
    if (_userId == null) throw Exception('Usuário não autenticado');

    // Migrar progresso
    if (progresso != null) {
      await salvarProgresso(progresso);
    }

    // Migrar estatísticas
    for (final estat in estatisticas) {
      await salvarEstatisticaModulo(
        unidade: estat['unidade'],
        ano: estat['ano'],
        corretas: estat['corretas'],
        total: estat['total'],
        tempoMedio: estat['tempo_medio'],
        ultimaTentativa: estat['ultima_tentativa'] != null
            ? DateTime.parse(estat['ultima_tentativa'])
            : null,
      );
    }

    // Migrar conquistas
    for (final conquista in conquistas) {
      await salvarConquista(
        conquistaId: conquista['conquista_id'],
        dataConquista: DateTime.parse(conquista['data_conquista']),
      );
    }
  }
}