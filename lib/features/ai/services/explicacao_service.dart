import 'package:flutter/foundation.dart';
import '../../data/service/database_service.dart';
import 'dart:convert';

class ExplicacaoService {
  static const String _tableName = 'historico_explicacoes';

  /// Salva uma explicação no histórico
  static Future<void> salvarExplicacao({
    required String unidade,
    required String ano,
    required String pergunta,
    required String respostaUsuario,
    required String respostaCorreta,
    required String explicacao,
    String? topicoEspecifico,
    String usuarioId = 'default',
  }) async {
    try {
      final db = await DatabaseService.database;

      // Verifica se a tabela existe, se não, cria
      await _criarTabelaSeNecessario(db);

      final dados = {
        'usuario_id': usuarioId,
        'unidade': unidade,
        'ano': ano,
        'topico_especifico': topicoEspecifico ?? _extrairTopico(pergunta),
        'pergunta': pergunta,
        'resposta_usuario': respostaUsuario,
        'resposta_correta': respostaCorreta,
        'explicacao': explicacao,
        'data_erro': DateTime.now().toIso8601String(),
        'visualizada': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      await db.insert(_tableName, dados);

      if (kDebugMode) {
        print('💡 Explicação salva no histórico: $unidade - $ano');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao salvar explicação: $e');
      }
    }
  }

  /// Cria a tabela de histórico se não existir
  static Future<void> _criarTabelaSeNecessario(db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id TEXT NOT NULL DEFAULT 'default',
        unidade TEXT NOT NULL,
        ano TEXT NOT NULL,
        topico_especifico TEXT,
        pergunta TEXT NOT NULL,
        resposta_usuario TEXT NOT NULL,
        resposta_correta TEXT NOT NULL,
        explicacao TEXT NOT NULL,
        data_erro TEXT NOT NULL,
        visualizada BOOLEAN NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Cria índices para performance
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_explicacoes_unidade ON $_tableName(usuario_id, unidade, ano)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_explicacoes_topico ON $_tableName(topico_especifico)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_explicacoes_data ON $_tableName(data_erro)');
  }

  /// Extrai o tópico da pergunta (análise simples)
  static String _extrairTopico(String pergunta) {
    final perguntaLower = pergunta.toLowerCase();

    // Palavras-chave para identificar tópicos
    final topicos = {
      'Adição': ['soma', 'somar', 'adicionar', '+', 'mais'],
      'Subtração': ['subtração', 'subtrair', 'diferença', '-', 'menos'],
      'Multiplicação': [
        'multiplicação',
        'multiplicar',
        'produto',
        '×',
        'vezes'
      ],
      'Divisão': ['divisão', 'dividir', 'quociente', '÷', 'por'],
      'Frações': [
        'fração',
        'frac',
        'numerador',
        'denominador',
        '/',
        'meio',
        'terço'
      ],
      'Porcentagem': ['%', 'porcento', 'porcentagem', 'desconto'],
      'Álgebra': ['x', 'y', 'incógnita', 'equação', 'resolve', 'vale'],
      'Geometria': [
        'área',
        'perímetro',
        'volume',
        'quadrado',
        'círculo',
        'triângulo',
        'retângulo'
      ],
      'Estatística': ['média', 'moda', 'mediana', 'gráfico', 'dados'],
      'Probabilidade': ['probabilidade', 'chance', 'evento', 'possível'],
    };

    for (final entry in topicos.entries) {
      for (final palavra in entry.value) {
        if (perguntaLower.contains(palavra)) {
          return entry.key;
        }
      }
    }

    return 'Matemática Geral';
  }

  /// Obtém o histórico de explicações por unidade
  static Future<List<Map<String, dynamic>>> obterHistoricoPorUnidade({
    required String unidade,
    String? ano,
    String usuarioId = 'default',
    int limite = 50,
  }) async {
    try {
      final db = await DatabaseService.database;
      await _criarTabelaSeNecessario(db);

      String whereClause = 'usuario_id = ? AND unidade = ?';
      List<dynamic> whereArgs = [usuarioId, unidade];

      if (ano != null) {
        whereClause += ' AND ano = ?';
        whereArgs.add(ano);
      }

      final results = await db.query(
        _tableName,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'data_erro DESC',
        limit: limite,
      );

      return results.map((row) => Map<String, dynamic>.from(row)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao obter histórico por unidade: $e');
      }
      return [];
    }
  }

  /// Obtém o histórico por tópico específico
  static Future<List<Map<String, dynamic>>> obterHistoricoPorTopico({
    required String topico,
    String usuarioId = 'default',
    int limite = 50,
  }) async {
    try {
      final db = await DatabaseService.database;
      await _criarTabelaSeNecessario(db);

      final results = await db.query(
        _tableName,
        where: 'usuario_id = ? AND topico_especifico = ?',
        whereArgs: [usuarioId, topico],
        orderBy: 'data_erro DESC',
        limit: limite,
      );

      return results.map((row) => Map<String, dynamic>.from(row)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao obter histórico por tópico: $e');
      }
      return [];
    }
  }

  /// Obtém estatísticas de erros por tema
  static Future<Map<String, dynamic>> obterEstatisticasPorTema({
    String usuarioId = 'default',
  }) async {
    try {
      final db = await DatabaseService.database;
      await _criarTabelaSeNecessario(db);

      // Contagem por unidade
      final unidadeResults = await db.rawQuery('''
        SELECT unidade, COUNT(*) as total_erros
        FROM $_tableName 
        WHERE usuario_id = ?
        GROUP BY unidade
        ORDER BY total_erros DESC
      ''', [usuarioId]);

      // Contagem por tópico específico
      final topicoResults = await db.rawQuery('''
        SELECT topico_especifico, COUNT(*) as total_erros
        FROM $_tableName 
        WHERE usuario_id = ?
        GROUP BY topico_especifico
        ORDER BY total_erros DESC
      ''', [usuarioId]);

      // Erros recentes (últimos 7 dias)
      final dataLimite =
          DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
      final recentesResults = await db.rawQuery('''
        SELECT COUNT(*) as erros_recentes
        FROM $_tableName 
        WHERE usuario_id = ? AND data_erro >= ?
      ''', [usuarioId, dataLimite]);

      return {
        'erros_por_unidade': unidadeResults,
        'erros_por_topico': topicoResults,
        'erros_ultimos_7_dias': recentesResults.first['erros_recentes'] ?? 0,
        'total_explicacoes': await _contarTotalExplicacoes(usuarioId),
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao obter estatísticas: $e');
      }
      return {};
    }
  }

  /// Marca explicações como visualizadas
  static Future<void> marcarComoVisualizadas({
    required List<int> ids,
    String usuarioId = 'default',
  }) async {
    try {
      final db = await DatabaseService.database;
      await _criarTabelaSeNecessario(db);

      final idsString = ids.join(',');
      await db.rawUpdate('''
        UPDATE $_tableName 
        SET visualizada = 1 
        WHERE id IN ($idsString) AND usuario_id = ?
      ''', [usuarioId]);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao marcar como visualizadas: $e');
      }
    }
  }

  /// Obtém tópicos com mais erros (pontos fracos)
  static Future<List<Map<String, dynamic>>> obterPontosFracos({
    String usuarioId = 'default',
    int limite = 5,
  }) async {
    try {
      final db = await DatabaseService.database;
      await _criarTabelaSeNecessario(db);

      final results = await db.rawQuery('''
        SELECT 
          topico_especifico,
          COUNT(*) as total_erros,
          MAX(data_erro) as ultimo_erro,
          unidade,
          ano
        FROM $_tableName 
        WHERE usuario_id = ?
        GROUP BY topico_especifico, unidade, ano
        HAVING total_erros >= 2
        ORDER BY total_erros DESC, ultimo_erro DESC
        LIMIT ?
      ''', [usuarioId, limite]);

      return results.map((row) => Map<String, dynamic>.from(row)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao obter pontos fracos: $e');
      }
      return [];
    }
  }

  /// Obtém sugestões de revisão baseadas nos erros
  static Future<List<Map<String, String>>> obterSugestoesRevisao({
    String usuarioId = 'default',
  }) async {
    try {
      final pontosFracos = await obterPontosFracos(usuarioId: usuarioId);
      List<Map<String, String>> sugestoes = [];

      for (final ponto in pontosFracos) {
        final topico = ponto['topico_especifico'] as String;
        final totalErros = ponto['total_erros'] as int;
        final unidade = ponto['unidade'] as String;
        final ano = ponto['ano'] as String;

        sugestoes.add({
          'tipo': 'revisar_topico',
          'titulo': 'Revisar $topico',
          'descricao': '$totalErros erros em $unidade - $ano',
          'prioridade': totalErros >= 5 ? 'alta' : 'media',
          'unidade': unidade,
          'ano': ano,
          'topico': topico,
        });
      }

      return sugestoes;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao obter sugestões: $e');
      }
      return [];
    }
  }

  /// Busca explicações por texto
  static Future<List<Map<String, dynamic>>> buscarExplicacoes({
    required String termo,
    String usuarioId = 'default',
    int limite = 20,
  }) async {
    try {
      final db = await DatabaseService.database;
      await _criarTabelaSeNecessario(db);

      final results = await db.query(
        _tableName,
        where: '''
          usuario_id = ? AND (
            pergunta LIKE ? OR 
            explicacao LIKE ? OR 
            topico_especifico LIKE ?
          )
        ''',
        whereArgs: [usuarioId, '%$termo%', '%$termo%', '%$termo%'],
        orderBy: 'data_erro DESC',
        limit: limite,
      );

      return results.map((row) => Map<String, dynamic>.from(row)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao buscar explicações: $e');
      }
      return [];
    }
  }

  /// Conta total de explicações
  static Future<int> _contarTotalExplicacoes(String usuarioId) async {
    try {
      final db = await DatabaseService.database;
      final result = await db.rawQuery('''
        SELECT COUNT(*) as total 
        FROM $_tableName 
        WHERE usuario_id = ?
      ''', [usuarioId]);

      return result.first['total'] as int;
    } catch (e) {
      return 0;
    }
  }

  /// Limpa histórico antigo (mais de X dias)
  static Future<void> limparHistoricoAntigo({
    int diasParaManter = 90,
    String usuarioId = 'default',
  }) async {
    try {
      final db = await DatabaseService.database;
      await _criarTabelaSeNecessario(db);

      final dataLimite = DateTime.now()
          .subtract(Duration(days: diasParaManter))
          .toIso8601String();

      final deletedRows = await db.delete(
        _tableName,
        where: 'usuario_id = ? AND data_erro < ?',
        whereArgs: [usuarioId, dataLimite],
      );

      if (kDebugMode) {
        print('🗑️ $deletedRows explicações antigas removidas');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao limpar histórico antigo: $e');
      }
    }
  }

  /// Exporta histórico para JSON (backup)
  static Future<String> exportarHistorico({
    String usuarioId = 'default',
  }) async {
    try {
      final db = await DatabaseService.database;
      await _criarTabelaSeNecessario(db);

      final results = await db.query(
        _tableName,
        where: 'usuario_id = ?',
        whereArgs: [usuarioId],
        orderBy: 'data_erro DESC',
      );

      final export = {
        'export_date': DateTime.now().toIso8601String(),
        'total_explicacoes': results.length,
        'explicacoes': results,
      };

      return jsonEncode(export);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao exportar histórico: $e');
      }
      return jsonEncode({'error': 'Erro ao exportar'});
    }
  }
}
