# Sistema de Booster de Dificuldade - MathQuest

## Visão Geral

O **Sistema de Booster de Dificuldade** é uma funcionalidade avançada que complementa o sistema adaptativo existente, projetada para evitar que alunos fiquem entediados com questões muito fáceis ao responderem rapidamente.

## Como Funciona

### **Detecção de Respostas Rápidas**

O sistema monitora o tempo de resposta de cada questão e compara com limites predefinidos por nível de dificuldade:

- **Fácil**: Menos de 8 segundos
- **Médio**: Menos de 12 segundos
- **Difícil**: Menos de 18 segundos

### **Ativação do Booster**

Quando um aluno responde **corretamente** em tempo inferior ao limite:

1. **Nível do booster aumenta** (+1)
2. **Tempo é registrado** no histórico
3. **Sistema ajusta dificuldade** na próxima questão

### **Níveis do Booster**

- **Nível 1-2 (Moderado)**: Aumenta um nível de dificuldade
  - Fácil → Médio
  - Médio → Difícil
- **Nível 3+ (Forte)**: Pula um nível de dificuldade
  - Fácil → Difícil
  - Médio → Difícil

### **Redução Gradual**

- Respostas em tempo normal **reduzem o booster** (-1)
- Evita manter dificuldade artificialmente alta
- Permite ajuste natural baseado na performance

## Implementação Técnica

### **Novos Parâmetros na API**

```dart
// Registrar resposta com tempo
await PerformanceService.registrarResposta(
  acertou: true,
  dificuldade: 'fácil',
  tipoQuiz: 'multipla_escolha',
  tempoRespostaSegundos: 6, // NOVO parâmetro
);
```

### **Métodos Adicionais**

```dart
// Obter nível atual do booster
int nivel = await PerformanceService.obterNivelBooster();

// Obter histórico de tempos rápidos
List<Map<String, dynamic>> tempos =
    await PerformanceService.obterTemposRapidos();
```

### **Dados nas Estatísticas**

As estatísticas agora incluem:

- `nivel_booster`: Nível atual do booster
- Tempos de resposta registrados
- Histórico de ativações do booster

## Benefícios Pedagógicos

### **Engajamento**

- Alunos avançados não ficam presos em níveis fáceis
- Detecção automática de competência superior

### **Motivação**

- Recompensa respostas rápidas com desafios maiores
- Mantém fluxo de aprendizado otimizado

### **Adaptabilidade**

- Funciona em conjunto com o sistema adaptivo existente
- Ajustes automáticos baseados em performance real

## Exemplo de Uso

```
Cenário: Aluno respondendo questões de nível "Fácil"

1. Questão 1: Resposta correta em 5s → Booster +1
2. Questão 2: Nível "Médio" (devido ao booster)
3. Questão 3: Resposta correta em 15s → Booster -1
4. Questão 4: Volta ao nível determinado pelo algoritmo base
```

## Configurações

### **Limites de Tempo** (ajustáveis no código)

```dart
Map<String, int> limitesTempoRapido = {
  'fácil': 8,     // segundos
  'médio': 12,    // segundos
  'difícil': 18,  // segundos
};
```

### **Histórico**

- Mantém até **20 tempos rápidos** recentes
- Integrado com o histórico geral de performance
- Resetado junto com outras estatísticas

## Impacto no Sistema

✅ **Compatibilidade Total**: Funciona com código existente  
✅ **Parâmetro Opcional**: `tempoRespostaSegundos` é opcional  
✅ **Sem Breaking Changes**: Não afeta funcionalidades existentes  
✅ **Performance**: Operações leves e otimizadas

O sistema está pronto para uso imediato e proporcionará uma experiência de aprendizado mais dinâmica e engajante para todos os níveis de alunos.
