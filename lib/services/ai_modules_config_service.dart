import 'package:shared_preferences/shared_preferences.dart';

/// Serviço para gerenciar a configuração de módulos habilitados/desabilitados
class ModulosConfigService {
  static const String _modulosHabilitadosKey = 'modulos_habilitados';

  /// Lista de todos os módulos disponíveis por categoria baseada nas features do projeto
  static const Map<String, List<String>> modulosDisponiveis = {
    'Dashboard': ['navigation_dashboard'],
    'Módulos BNCC': ['ai_modulos_bncc'],
    'Quiz': ['learning_quiz'],
    'Chat IA': ['ai_chat'],
    'Perfil': ['user_perfil'],
    'Conquistas': ['user_conquistas'],
    'Ajuda': ['ai_ajuda'],
    'Relatórios': ['analytics_relatorios'],
    'Firebase AI Test': ['ai_firebase_ai_test'],
    'Personagem 3D': ['user_personagem_3d'],
  };

  /// Retorna todos os IDs de módulos disponíveis
  static List<String> get todosModulosIds {
    return modulosDisponiveis.values.expand((ids) => ids).toList();
  }

  /// Retorna os módulos habilitados (por padrão, todos estão habilitados)
  static Future<List<String>> getModulosHabilitados() async {
    final prefs = await SharedPreferences.getInstance();
    final habilitados = prefs.getStringList(_modulosHabilitadosKey);

    // Se não há configuração salva, retorna todos os módulos como habilitados
    if (habilitados == null) {
      return todosModulosIds;
    }

    return habilitados;
  }

  /// Salva a lista de módulos habilitados
  static Future<void> salvarModulosHabilitados(
      List<String> modulosHabilitados) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_modulosHabilitadosKey, modulosHabilitados);
  }

  /// Verifica se um módulo está habilitado
  static Future<bool> isModuloHabilitado(String moduloId) async {
    final habilitados = await getModulosHabilitados();
    return habilitados.contains(moduloId);
  }

  /// Habilita um módulo específico
  static Future<void> habilitarModulo(String moduloId) async {
    final habilitados = await getModulosHabilitados();
    if (!habilitados.contains(moduloId)) {
      habilitados.add(moduloId);
      await salvarModulosHabilitados(habilitados);
    }
  }

  /// Desabilita um módulo específico
  static Future<void> desabilitarModulo(String moduloId) async {
    final habilitados = await getModulosHabilitados();
    if (habilitados.contains(moduloId)) {
      habilitados.remove(moduloId);
      await salvarModulosHabilitados(habilitados);
    }
  }

  /// Alterna o estado de um módulo (habilitado/desabilitado)
  static Future<void> toggleModulo(String moduloId) async {
    final habilitado = await isModuloHabilitado(moduloId);
    if (habilitado) {
      await desabilitarModulo(moduloId);
    } else {
      await habilitarModulo(moduloId);
    }
  }

  /// Habilita todos os módulos
  static Future<void> habilitarTodos() async {
    await salvarModulosHabilitados(todosModulosIds);
  }

  /// Desabilita todos os módulos
  static Future<void> desabilitarTodos() async {
    await salvarModulosHabilitados([]);
  }

  /// Reseta para a configuração padrão (todos habilitados)
  static Future<void> resetarParaPadrao() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_modulosHabilitadosKey);
  }
}
