import 'package:shared_preferences/shared_preferences.dart';

// Teste simples para verificar SharedPreferences
void main() async {
  print('🧪 Iniciando teste de SharedPreferences...');
  
  // Constante do PreloadService
  const String creditsKey = 'preload_credits';
  
  try {
    // Teste 1: Salvar créditos
    print('📝 Teste 1: Salvando 100 créditos...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(creditsKey, 100);
    print('✅ Créditos salvos');
    
    // Teste 2: Ler créditos
    print('📖 Teste 2: Lendo créditos...');
    final savedCredits = prefs.getInt(creditsKey) ?? 0;
    print('💰 Créditos lidos: $savedCredits');
    
    if (savedCredits == 100) {
      print('✅ Teste PASSOU: Créditos foram salvos e lidos corretamente');
    } else {
      print('❌ Teste FALHOU: Esperado 100, obtido $savedCredits');
    }
    
    // Teste 3: Commit e re-ler
    print('🔄 Teste 3: Usando commit e relendo...');
    await prefs.setInt(creditsKey, 85);
    await prefs.commit();
    
    // Nova instância para simular reinício
    final prefs2 = await SharedPreferences.getInstance();
    final rereadCredits = prefs2.getInt(creditsKey) ?? 0;
    print('💰 Créditos após commit e nova instância: $rereadCredits');
    
    if (rereadCredits == 85) {
      print('✅ Teste PASSOU: Commit funcionou corretamente');
    } else {
      print('❌ Teste FALHOU: Esperado 85, obtido $rereadCredits');
    }
    
    // Teste 4: Verificar todas as chaves
    print('🔍 Teste 4: Verificando chaves...');
    final keys = prefs2.getKeys();
    print('🗝️ Chaves encontradas: ${keys.toList()}');
    
    if (keys.contains(creditsKey)) {
      print('✅ Chave $creditsKey encontrada');
    } else {
      print('❌ Chave $creditsKey NÃO encontrada');
    }
    
    print('🎯 Teste de SharedPreferences concluído!');
    
  } catch (e, stackTrace) {
    print('❌ Erro durante o teste: $e');
    print('Stack trace: $stackTrace');
  }
}
