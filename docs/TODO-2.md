# TODO-2.md - Implementações Pendentes

## 📋 Status Atual vs. Funcionalidades do TODO.md

### ✅ **JÁ IMPLEMENTADO**

#### Sistema de Quiz Básico
- ✅ 3 tipos de quiz funcionais (Múltipla Escolha, Verdadeiro/Falso, Complete a Frase)
- ✅ Geração de perguntas com IA (Gemini e Ollama)
- ✅ Sistema de feedback interativo
- ✅ Histórico de respostas com SharedPreferences
- ✅ Modo offline com perguntas pré-definidas
- ✅ Configurações de IA (troca entre Gemini/Ollama)
- ✅ Sistema de dificuldade adaptativa básico (4 níveis: fácil, médio, difícil, expert)
- ✅ Interface responsiva (mobile, tablet, desktop)
- ✅ Estatísticas básicas (taxa de acerto, exercícios respondidos)

#### Conteúdo BNCC
- ✅ Tela informativa sobre unidades temáticas da BNCC
- ✅ Estrutura de dados das 5 unidades temáticas definidas
- ✅ Competências específicas listadas

---

## ❌ **FUNCIONALIDADES FALTANTES (PRIORIDADE ALTA)**

### 1. **Sistema de Progressão por Módulos BNCC** 🎯
**Status:** NÃO IMPLEMENTADO  
**Descrição:** O sistema atual só tem dificuldade adaptativa simples. Falta:

#### 1.1 Modelo de Dados de Progressão
```dart
// Estrutura necessária para tracking de progresso
class ProgressoUsuario {
  Map<String, Map<String, bool>> modulosCompletos; // unidade -> ano -> completo
  int nivelUsuario; // Iniciante, Intermediário, Avançado, Especialista
  Map<String, int> pontosPorUnidade;
  DateTime ultimaAtualizacao;
}
```

#### 1.2 Tela de Seleção de Módulos
- **Arquivo a criar:** `lib/screens/modulos_screen.dart`
- Interface para escolher:
  - Unidade Temática (Números, Álgebra, Geometria, Grandezas, Probabilidade)
  - Ano Escolar (6º, 7º, 8º, 9º)
  - Visualização do progresso atual

#### 1.3 Sistema de Desbloqueio Progressivo
- Módulos só desbloqueiam após completar pré-requisitos
- Lógica de progressão sequencial por ano

#### 1.4 Indicadores Visuais de Progresso
- Tabela de progresso como mostrada no TODO.md
- Badges/conquistas por módulo completo
- Barra de progresso geral

### 2. **Sistema de Níveis de Usuário** 📊
**Status:** PARCIAL (só existe dificuldade adaptativa básica)  
**Implementar:**

#### 2.1 Cálculo de Nível Baseado em Módulos
```dart
enum NivelUsuario {
  iniciante,    // Completou módulos apenas do 6º Ano
  intermediario, // Completou módulos do 6º e 7º Ano  
  avancado,     // Completou módulos do 6º ao 8º Ano
  especialista  // Completou todos os módulos do 6º ao 9º Ano
}
```

#### 2.2 Ajuste de Dificuldade por Nível
- Perguntas mais complexas para níveis avançados
- Contextos mais elaborados
- Múltiplas etapas de resolução

### 3. **Tracking de Conclusão de Módulos** 📈
**Status:** NÃO IMPLEMENTADO  
**Implementar:**

#### 3.1 Critérios de Conclusão
- X exercícios corretos consecutivos
- Taxa de acerto mínima (ex: 80%)
- Tempo limite por módulo

#### 3.2 Persistência de Progresso
- Salvar progresso no SharedPreferences
- Estrutura de dados robusta para recuperação

#### 3.3 Validação de Conclusão
- Sistema que determina quando um módulo foi "dominado"
- Certificação de conclusão

---

## ❌ **FUNCIONALIDADES FALTANTES (PRIORIDADE MÉDIA)**

### 4. **Geração Contextualizada por BNCC** 🎯
**Status:** PARCIAL (IA gera perguntas, mas não segue estrutura BNCC)  
**Implementar:**

#### 4.1 Prompts Específicos por Unidade/Ano
- Templates de prompt para cada combinação unidade+ano
- Exemplos específicos da BNCC por módulo

#### 4.2 Validação de Conteúdo BNCC
- Verificar se perguntas geradas estão alinhadas com habilidades específicas
- Códigos de habilidade BNCC nas perguntas

### 5. **Relatórios de Progresso** 📊
**Status:** BÁSICO (só estatísticas simples)  
**Implementar:**

#### 5.1 Tela de Relatórios Detalhados
- **Arquivo a criar:** `lib/screens/relatorios_screen.dart`
- Progresso por unidade temática
- Tempo investido por módulo
- Pontos fracos identificados

#### 5.2 Recomendações Inteligentes
- Sugestão de módulos para revisar
- Identificação de lacunas de aprendizado

### 6. **Sistema de Gamificação** 🏆
**Status:** NÃO IMPLEMENTADO  
**Implementar:**

#### 6.1 Sistema de Pontos
- Pontos por módulo completo
- Bonificações por sequências de acertos
- Penalidades por tempo excessivo

#### 6.2 Conquistas/Badges
- Badge por unidade temática completa
- Badge por nível alcançado
- Badge por streaks de acertos

---

## ❌ **FUNCIONALIDADES FALTANTES (PRIORIDADE BAIXA)**

### 7. **Modo Professor** 👩‍🏫
**Status:** NÃO IMPLEMENTADO  
**Implementar:**

#### 8.1 Geração de PDF
- Exercícios para impressão
- Gabaritos separados
- Material de estudo offline


---

## 🗂️ **ESTRUTURA DE ARQUIVOS A CRIAR**

```
lib/
├── models/
│   ├── progresso_usuario.dart         # Modelo de dados de progresso
│   ├── modulo_bncc.dart              # Estrutura de módulos BNCC
│   ├── conquista.dart                # Sistema de badges/conquistas
│   └── relatorio.dart                # Modelos de relatório
├── screens/
│   ├── modulos_screen.dart           # Seleção de módulos
│   ├── progresso_screen.dart         # Visualização de progresso
│   ├── relatorios_screen.dart        # Relatórios detalhados
│   ├── conquistas_screen.dart        # Badges e conquistas
├── services/
│   ├── progresso_service.dart        # Lógica de progressão
│   ├── modulo_service.dart           # Gerenciamento de módulos
│   ├── gamificacao_service.dart      # Sistema de pontos/badges
│   └── relatorio_service.dart        # Geração de relatórios
└── widgets/
    ├── modulo_card.dart              # Card de módulo
    ├── progresso_widget.dart         # Widget de progresso
    ├── badge_widget.dart             # Widget de conquista
    └── relatorio_chart.dart          # Gráficos de progresso
```

---

## 🎯 **PRÓXIMOS PASSOS RECOMENDADOS**

### Fase 1: Sistema de Módulos (1-2 semanas)
1. Criar modelo de dados `progresso_usuario.dart`
2. Implementar `modulos_screen.dart` com seleção de unidades/anos
3. Adicionar persistência de progresso por módulo
4. Implementar critérios de conclusão de módulo

### Fase 2: Sistema de Níveis (1 semana)
1. Implementar lógica de cálculo de nível baseado em módulos completos
2. Ajustar dificuldade de perguntas baseado no nível
3. Adicionar indicadores visuais de nível

### Fase 3: Gamificação Básica (1 semana)
1. Implementar sistema de pontos
2. Criar conquistas básicas
3. Adicionar feedback visual para progressão

### Fase 4: Relatórios (1 semana)
1. Criar tela de relatórios detalhados
2. Implementar recomendações inteligentes
3. Adicionar gráficos de progresso

---

## 📝 **NOTAS TÉCNICAS**

### Dependências Adicionais Necessárias
```yaml
dependencies:
  # Para gráficos de progresso
  fl_chart: ^0.65.0
  
  # Para geração de PDF (modo desplugado)
  pdf: ^3.10.7
  printing: ^5.11.1
  
  # Para melhor gerenciamento de estado
  provider: ^6.1.1
  
  # Para persistência mais robusta
  sqflite: ^2.3.0
```

### Considerações de Performance
- Usar `sqflite` para dados de progresso mais complexos (substituir SharedPreferences)
- Implementar cache para perguntas geradas
- Otimizar carregamento de módulos com lazy loading

### Considerações UX/UI
- Manter consistência visual com tema atual
- Adicionar animações suaves para progressão
- Feedback haptic para conquistas
- Modo escuro já implementado ✅
