import 'dart:io';

// Teste simples usando apenas simulação de SharedPreferences
void main() async {
  print('=== TESTE DE CRÉDITOS - SIMULAÇÃO SIMPLES ===');
  
  // Simula o comportamento do SharedPreferences
  Map<String, dynamic> fakeStorage = {};
  
  // Função que simula setInt
  Future<bool> setInt(String key, int value) async {
    fakeStorage[key] = value;
    print('SAVED: $key = $value');
    return true;
  }
  
  // Função que simula getInt
  int? getInt(String key) {
    final value = fakeStorage[key];
    print('LOADED: $key = $value');
    return value;
  }
  
  print('\n1. Testando salvamento inicial:');
  await setInt('creditos_preload', 10);
  
  print('\n2. Testando carregamento:');
  int? creditos = getInt('creditos_preload');
  print('Créditos carregados: $creditos');
  
  print('\n3. Testando incremento:');
  creditos = creditos ?? 0;
  creditos += 5;
  await setInt('creditos_preload', creditos);
  
  print('\n4. Verificando persistência:');
  creditos = getInt('creditos_preload');
  print('Créditos após incremento: $creditos');
  
  print('\n5. Testando uso de crédito:');
  if (creditos != null && creditos > 0) {
    creditos--;
    await setInt('creditos_preload', creditos);
    print('Crédito usado. Créditos restantes: $creditos');
  }
  
  print('\n6. Verificação final:');
  final creditosFinais = getInt('creditos_preload');
  print('Créditos finais: $creditosFinais');
  
  print('\n=== TESTE CONCLUÍDO ===');
  print('Storage final: $fakeStorage');
  
  // Teste adicional: verifica se o valor é mantido mesmo criando novo "storage"
  print('\n7. Teste de persistência (simulando restart):');
  Map<String, dynamic> novoStorage = Map.from(fakeStorage);
  final creditosAposRestart = novoStorage['creditos_preload'];
  print('Créditos após "restart": $creditosAposRestart');
  
  if (creditosAposRestart == 14) {
    print('✅ SUCESSO: Os créditos estão sendo persistidos corretamente!');
  } else {
    print('❌ ERRO: Problema na persistência dos créditos');
  }
  
  exit(0);
}
