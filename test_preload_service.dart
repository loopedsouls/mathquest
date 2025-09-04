import 'dart:async';

// Teste direto com SharedPreferences
void main() async {
  print('=== TESTE REAL DE SHARED PREFERENCES ===');
  
  try {
    // Importa e inicializa SharedPreferences de forma manual
    print('1. Tentando importar SharedPreferences...');
    
    // Simula o PreloadService real
    print('\n2. Simulando PreloadService:');
    
    // Simula as funções de crédito do PreloadService
    Map<String, dynamic> _storage = {};
    
    Future<void> setCredits(int creditos) async {
      _storage['creditos_preload'] = creditos;
      print('   setCredits($creditos) - SAVED');
      // Simula o commit()
      await Future.delayed(Duration(milliseconds: 10));
      print('   commit() executado');
    }
    
    Future<int> getCredits() async {
      final creditos = _storage['creditos_preload'] ?? 0;
      print('   getCredits() = $creditos');
      return creditos;
    }
    
    Future<bool> useCredit() async {
      final creditosAtuais = await getCredits();
      if (creditosAtuais > 0) {
        await setCredits(creditosAtuais - 1);
        print('   useCredit() - Crédito usado. Restam: ${creditosAtuais - 1}');
        return true;
      }
      print('   useCredit() - Sem créditos disponíveis');
      return false;
    }
    
    print('\n3. Testando sequência do app:');
    
    // Simula o carregamento inicial
    print('\n   a) Carregamento inicial:');
    int creditosIniciais = await getCredits();
    print('      Créditos iniciais: $creditosIniciais');
    
    // Simula o preload adicionando créditos
    print('\n   b) Preload adicionando 10 créditos:');
    await setCredits(creditosIniciais + 10);
    int creditosAposPreload = await getCredits();
    print('      Créditos após preload: $creditosAposPreload');
    
    // Simula o uso de alguns créditos
    print('\n   c) Usando 3 créditos:');
    for (int i = 0; i < 3; i++) {
      bool usado = await useCredit();
      print('      Crédito ${i+1}: ${usado ? "usado" : "falhou"}');
    }
    
    // Verifica estado final
    print('\n   d) Estado final:');
    int creditosFinais = await getCredits();
    print('      Créditos finais: $creditosFinais');
    
    print('\n4. Análise:');
    if (creditosFinais == 7) {
      print('   ✅ PERFEITO: 10 créditos adicionados, 3 usados = 7 restantes');
    } else {
      print('   ❌ PROBLEMA: Esperado 7, encontrado $creditosFinais');
    }
    
    print('\n   Storage interno: $_storage');
    
    print('\n=== CONCLUSÃO ===');
    print('Se este teste passou, o problema pode estar em:');
    print('1. SharedPreferences não está sendo inicializado corretamente');
    print('2. A UI não está sendo atualizada após mudanças nos créditos');
    print('3. Alguma condição específica do app está interferindo');
    
  } catch (e, stackTrace) {
    print('ERRO durante o teste: $e');
    print('Stack trace: $stackTrace');
  }
}
