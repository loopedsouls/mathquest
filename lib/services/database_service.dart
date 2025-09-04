import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/progresso_usuario.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'mathquest.db';
  static const int _databaseVersion = 1;

  // Tabelas
  static const String _tableProgresso = 'progresso_usuario';
  static const String _tableEstatisticas = 'estatisticas_modulo';
  static const String _tableCacheIA = 'cache_ia';
  static const String _tableConquistas = 'conquistas_usuario';

  // Singleton pattern
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Tabela de progresso do usuário
    await db.execute('''
      CREATE TABLE $_tableProgresso (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id TEXT NOT NULL DEFAULT 'default',
        modulos_completos TEXT NOT NULL,
        nivel_usuario INTEGER NOT NULL DEFAULT 0,
        pontos_por_unidade TEXT NOT NULL,
        exercicios_corretos_consecutivos TEXT NOT NULL,
        taxa_acerto_por_modulo TEXT NOT NULL,
        ultima_atualizacao TEXT NOT NULL,
        total_exercicios_respondidos INTEGER NOT NULL DEFAULT 0,
        total_exercicios_corretos INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabela de estatísticas por módulo
    await db.execute('''
      CREATE TABLE $_tableEstatisticas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id TEXT NOT NULL DEFAULT 'default',
        unidade TEXT NOT NULL,
        ano TEXT NOT NULL,
        corretas INTEGER NOT NULL DEFAULT 0,
        total INTEGER NOT NULL DEFAULT 0,
        tempo_medio REAL NOT NULL DEFAULT 0.0,
        ultima_tentativa TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(usuario_id, unidade, ano)
      )
    ''');

    // Tabela de cache de perguntas da IA
    await db.execute('''
      CREATE TABLE $_tableCacheIA (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chave_cache TEXT NOT NULL UNIQUE,
        unidade TEXT NOT NULL,
        ano TEXT NOT NULL,
        tipo_quiz TEXT NOT NULL,
        dificuldade TEXT NOT NULL,
        pergunta TEXT NOT NULL,
        opcoes TEXT,
        resposta_correta TEXT NOT NULL,
        explicacao TEXT,
        fonte_ia TEXT NOT NULL,
        hits INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        last_used TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabela de conquistas do usuário
    await db.execute('''
      CREATE TABLE $_tableConquistas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id TEXT NOT NULL DEFAULT 'default',
        conquista_id TEXT NOT NULL,
        data_conquista TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(usuario_id, conquista_id)
      )
    ''');

    // Índices para performance
    await db.execute('CREATE INDEX idx_cache_ia_chave ON $_tableCacheIA(chave_cache)');
    await db.execute('CREATE INDEX idx_cache_ia_params ON $_tableCacheIA(unidade, ano, tipo_quiz, dificuldade)');
    await db.execute('CREATE INDEX idx_estatisticas_modulo ON $_tableEstatisticas(usuario_id, unidade, ano)');
    await db.execute('CREATE INDEX idx_conquistas_usuario ON $_tableConquistas(usuario_id, conquista_id)');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Implementar migração de dados quando necessário
    if (oldVersion < newVersion) {
      // Futuras migrações aqui
    }
  }

  // === MÉTODOS DE PROGRESSO ===

  static Future<void> salvarProgresso(ProgressoUsuario progresso, {String usuarioId = 'default'}) async {
    final db = await database;
    
    final dados = {
      'usuario_id': usuarioId,
      'modulos_completos': jsonEncode(progresso.modulosCompletos),
      'nivel_usuario': progresso.nivelUsuario.index,
      'pontos_por_unidade': jsonEncode(progresso.pontosPorUnidade),
      'exercicios_corretos_consecutivos': jsonEncode(progresso.exerciciosCorretosConsecutivos),
      'taxa_acerto_por_modulo': jsonEncode(progresso.taxaAcertoPorModulo),
      'ultima_atualizacao': progresso.ultimaAtualizacao.toIso8601String(),
      'total_exercicios_respondidos': progresso.totalExerciciosRespondidos,
      'total_exercicios_corretos': progresso.totalExerciciosCorretos,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await db.insert(
      _tableProgresso,
      dados,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<ProgressoUsuario?> carregarProgresso({String usuarioId = 'default'}) async {
    final db = await database;
    
    final results = await db.query(
      _tableProgresso,
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'updated_at DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;

    final dados = results.first;
    
    return ProgressoUsuario(
      modulosCompletos: Map<String, Map<String, bool>>.from(
        jsonDecode(dados['modulos_completos'] as String).map(
          (key, value) => MapEntry(key, Map<String, bool>.from(value)),
        ),
      ),
      nivelUsuario: NivelUsuario.values[dados['nivel_usuario'] as int],
      pontosPorUnidade: Map<String, int>.from(jsonDecode(dados['pontos_por_unidade'] as String)),
      exerciciosCorretosConsecutivos: Map<String, int>.from(jsonDecode(dados['exercicios_corretos_consecutivos'] as String)),
      taxaAcertoPorModulo: Map<String, double>.from(jsonDecode(dados['taxa_acerto_por_modulo'] as String)),
      ultimaAtualizacao: DateTime.parse(dados['ultima_atualizacao'] as String),
      totalExerciciosRespondidos: dados['total_exercicios_respondidos'] as int,
      totalExerciciosCorretos: dados['total_exercicios_corretos'] as int,
    );
  }

  // === MÉTODOS DE ESTATÍSTICAS ===

  static Future<void> salvarEstatisticasModulo({
    required String unidade,
    required String ano,
    required int corretas,
    required int total,
    double tempoMedio = 0.0,
    String usuarioId = 'default',
  }) async {
    final db = await database;
    
    final dados = {
      'usuario_id': usuarioId,
      'unidade': unidade,
      'ano': ano,
      'corretas': corretas,
      'total': total,
      'tempo_medio': tempoMedio,
      'ultima_tentativa': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await db.insert(
      _tableEstatisticas,
      dados,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, dynamic>> carregarEstatisticasModulo({
    required String unidade,
    required String ano,
    String usuarioId = 'default',
  }) async {
    final db = await database;
    
    final results = await db.query(
      _tableEstatisticas,
      where: 'usuario_id = ? AND unidade = ? AND ano = ?',
      whereArgs: [usuarioId, unidade, ano],
      limit: 1,
    );

    if (results.isEmpty) {
      return {
        'corretas': 0,
        'total': 0,
        'tempo_medio': 0.0,
        'ultima_tentativa': null,
      };
    }

    final dados = results.first;
    return {
      'corretas': dados['corretas'] as int,
      'total': dados['total'] as int,
      'tempo_medio': dados['tempo_medio'] as double,
      'ultima_tentativa': dados['ultima_tentativa'] as String?,
    };
  }

  // === MÉTODOS DE CACHE DE IA ===

  static String _gerarChaveCache({
    required String unidade,
    required String ano,
    required String tipoQuiz,
    required String dificuldade,
  }) {
    return '${unidade}_${ano}_${tipoQuiz}_$dificuldade'.toLowerCase().replaceAll(' ', '_');
  }

  static Future<Map<String, dynamic>?> buscarPerguntaCache({
    required String unidade,
    required String ano,
    required String tipoQuiz,
    required String dificuldade,
  }) async {
    final db = await database;
    final chave = _gerarChaveCache(
      unidade: unidade,
      ano: ano,
      tipoQuiz: tipoQuiz,
      dificuldade: dificuldade,
    );

    final results = await db.query(
      _tableCacheIA,
      where: 'chave_cache = ?',
      whereArgs: [chave],
      orderBy: 'RANDOM()',
      limit: 1,
    );

    if (results.isEmpty) return null;

    final dados = results.first;

    // Atualiza contadores de uso
    await db.update(
      _tableCacheIA,
      {
        'hits': (dados['hits'] as int) + 1,
        'last_used': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [dados['id']],
    );

    return {
      'pergunta': dados['pergunta'] as String,
      'opcoes': dados['opcoes'] != null ? jsonDecode(dados['opcoes'] as String) : null,
      'resposta_correta': dados['resposta_correta'] as String,
      'explicacao': dados['explicacao'] as String?,
      'fonte_ia': dados['fonte_ia'] as String,
      'hits': (dados['hits'] as int) + 1,
    };
  }

  static Future<void> salvarPerguntaCache({
    required String unidade,
    required String ano,
    required String tipoQuiz,
    required String dificuldade,
    required String pergunta,
    List<String>? opcoes,
    required String respostaCorreta,
    String? explicacao,
    required String fonteIA,
  }) async {
    final db = await database;
    final chave = _gerarChaveCache(
      unidade: unidade,
      ano: ano,
      tipoQuiz: tipoQuiz,
      dificuldade: dificuldade,
    );

    final dados = {
      'chave_cache': chave,
      'unidade': unidade,
      'ano': ano,
      'tipo_quiz': tipoQuiz,
      'dificuldade': dificuldade,
      'pergunta': pergunta,
      'opcoes': opcoes != null ? jsonEncode(opcoes) : null,
      'resposta_correta': respostaCorreta,
      'explicacao': explicacao,
      'fonte_ia': fonteIA,
      'hits': 0,
      'created_at': DateTime.now().toIso8601String(),
      'last_used': DateTime.now().toIso8601String(),
    };

    await db.insert(
      _tableCacheIA,
      dados,
      conflictAlgorithm: ConflictAlgorithm.ignore, // Ignora se já existe
    );
  }

  static Future<int> contarPerguntasCache({
    String? unidade,
    String? ano,
    String? tipoQuiz,
    String? dificuldade,
  }) async {
    final db = await database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (unidade != null) {
      whereClause += ' AND unidade = ?';
      whereArgs.add(unidade);
    }
    if (ano != null) {
      whereClause += ' AND ano = ?';
      whereArgs.add(ano);
    }
    if (tipoQuiz != null) {
      whereClause += ' AND tipo_quiz = ?';
      whereArgs.add(tipoQuiz);
    }
    if (dificuldade != null) {
      whereClause += ' AND dificuldade = ?';
      whereArgs.add(dificuldade);
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableCacheIA WHERE $whereClause',
      whereArgs,
    );

    return result.first['count'] as int;
  }

  static Future<void> limparCacheAntigo({int diasParaExpirar = 30}) async {
    final db = await database;
    final dataExpiracao = DateTime.now().subtract(Duration(days: diasParaExpirar));

    await db.delete(
      _tableCacheIA,
      where: 'last_used < ?',
      whereArgs: [dataExpiracao.toIso8601String()],
    );
  }

  // === MÉTODOS DE CONQUISTAS ===

  static Future<void> salvarConquista({
    required String conquistaId,
    required DateTime dataConquista,
    String usuarioId = 'default',
  }) async {
    final db = await database;

    final dados = {
      'usuario_id': usuarioId,
      'conquista_id': conquistaId,
      'data_conquista': dataConquista.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    };

    await db.insert(
      _tableConquistas,
      dados,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<List<String>> carregarConquistasDesbloqueadas({String usuarioId = 'default'}) async {
    final db = await database;

    final results = await db.query(
      _tableConquistas,
      columns: ['conquista_id'],
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
    );

    return results.map((row) => row['conquista_id'] as String).toList();
  }

  // === MÉTODOS UTILITÁRIOS ===

  static Future<void> resetarDados({String usuarioId = 'default'}) async {
    final db = await database;

    await db.delete(_tableProgresso, where: 'usuario_id = ?', whereArgs: [usuarioId]);
    await db.delete(_tableEstatisticas, where: 'usuario_id = ?', whereArgs: [usuarioId]);
    await db.delete(_tableConquistas, where: 'usuario_id = ?', whereArgs: [usuarioId]);
  }

  static Future<Map<String, dynamic>> obterEstatisticasGerais() async {
    final db = await database;

    final progressoCount = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableProgresso');
    final cacheCount = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableCacheIA');
    final conquistasCount = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableConquistas');
    
    final cacheSize = await db.rawQuery(
      'SELECT SUM(LENGTH(pergunta) + COALESCE(LENGTH(opcoes), 0) + LENGTH(resposta_correta)) as size FROM $_tableCacheIA'
    );

    return {
      'usuarios_registrados': progressoCount.first['count'] as int,
      'perguntas_cache': cacheCount.first['count'] as int,
      'conquistas_total': conquistasCount.first['count'] as int,
      'tamanho_cache_bytes': cacheSize.first['size'] ?? 0,
      'database_path': join(await getDatabasesPath(), _databaseName),
    };
  }

  static Future<void> fecharDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
