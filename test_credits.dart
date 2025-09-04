import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Teste simples para verificar se os créditos estão sendo salvos
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kDebugMode) {
    print('🧪 Iniciando teste de créditos...');
  }
  
  // Constantes do PreloadService
  const String creditsKey = 'preload_credits';
  
  try {
    // Teste 1: Salvar créditos
    if (kDebugMode) {
      print('📝 Teste 1: Salvando 100 créditos...');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(creditsKey, 100);
    await prefs.commit();
    if (kDebugMode) {
      print('✅ Créditos salvos');
    }
    
    // Teste 2: Ler créditos
    if (kDebugMode) {
      print('📖 Teste 2: Lendo créditos...');
    }
    final savedCredits = prefs.getInt(creditsKey) ?? 0;
    if (kDebugMode) {
      print('💰 Créditos lidos: $savedCredits');
    }
    
    if (savedCredits == 100) {
      if (kDebugMode) {
        print('✅ Teste PASSOU: Créditos foram salvos e lidos corretamente');
      }
    } else {
      if (kDebugMode) {
        print('❌ Teste FALHOU: Esperado 100, obtido $savedCredits');
      }
    }
    
    // Teste 3: Atualizar créditos
    if (kDebugMode) {
      print('🔄 Teste 3: Atualizando para 95 créditos...');
    }
    await prefs.setInt(creditsKey, 95);
    await prefs.commit();
    
    final updatedCredits = prefs.getInt(creditsKey) ?? 0;
    if (kDebugMode) {
      print('💰 Créditos após atualização: $updatedCredits');
    }
    
    if (updatedCredits == 95) {
      if (kDebugMode) {
        print('✅ Teste PASSOU: Créditos foram atualizados corretamente');
      }
    } else {
      if (kDebugMode) {
        print('❌ Teste FALHOU: Esperado 95, obtido $updatedCredits');
      }
    }
    
    // Teste 4: Verificar todas as chaves salvas
    if (kDebugMode) {
      print('🔍 Teste 4: Verificando todas as chaves do SharedPreferences...');
    }
    final keys = prefs.getKeys();
    if (kDebugMode) {
      print('🗝️ Chaves encontradas: ${keys.toList()}');
    }
    
    if (keys.contains(creditsKey)) {
      print('✅ Chave $creditsKey encontrada');
    } else {
      if (kDebugMode) {
        print('❌ Chave $creditsKey NÃO encontrada');
      }
    }
    
    // Teste 5: Limpar e verificar valor padrão
    print('🧹 Teste 5: Removendo créditos e testando valor padrão...');
    await prefs.remove(creditsKey);
    await prefs.commit();
    
    final defaultCredits = prefs.getInt(creditsKey) ?? 0;
    if (kDebugMode) {
      print('💰 Créditos após remoção (padrão): $defaultCredits');
    }
    
    if (defaultCredits == 0) {
      if (kDebugMode) {
        print('✅ Teste PASSOU: Valor padrão correto após remoção');
      }
    } else {
      if (kDebugMode) {
        print('❌ Teste FALHOU: Esperado 0, obtido $defaultCredits');
      }
    }
    
    if (kDebugMode) {
      print('🎯 Teste de créditos concluído!');
    }
    
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('❌ Erro durante o teste: $e');
    }
    if (kDebugMode) {
      print('Stack trace: $stackTrace');
    }
  }
}
