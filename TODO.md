# MathQuest - Funcionalidades Faltantes para MVP

## 🎯 **PRIORIDADE ALTA - Essencial para MVP**

### 1. **Fluxo Interativo de Lições** 📚
**Status:** ❌ PENDENTE
**Descrição:** Implementar o sistema de lições com introdução por IA e opções clicáveis

#### Tarefas:
- [ ] Gerar mensagem inicial por IA ao iniciar módulo
- [ ] Definir dinamicamente quantidade de aulas por módulo
- [ ] Criar 3 botões interativos: Quiz, Aula, Curiosidades
- [ ] Integrar progresso de aulas na appbar e dashboard
- [ ] Marcar módulo como completo após todas as aulas

**Arquivo referência:** `docs/paraimplementar.md`

### 2. **Banco de Questões Offline** 📱
**Status:** ❌ PENDENTE
**Descrição:** Criar base de questões pré-definidas para funcionamento sem IA

#### Tarefas:
- [ ] Definir mínimo 10 questões por módulo BNCC
- [ ] Implementar variedade de dificuldades
- [ ] Cobrir todos os tópicos principais
- [ ] Sistema de cache inteligente
- [ ] Fallback automático para offline

## 🎯 **PRIORIDADE MÉDIA - Melhorias**

### 3. **Onboarding do Usuário** 👋
**Status:** ❌ PENDENTE
**Descrição:** Experiência inicial para novos usuários

#### Tarefas:
- [ ] Tutorial de primeiros passos
- [ ] Seleção de ano escolar
- [ ] Explicação do sistema de progressão
- [ ] Configuração inicial de preferências

### 4. **Animações Avançadas** ✨
**Status:** ⚠️ PARCIAL (30%)
**Descrição:** Melhorar UX com animações sofisticadas

#### Tarefas:
- [ ] Animações de entrada/saída de elementos
- [ ] Micro-interações (hover, focus)
- [ ] Loading states mais elaborados
- [ ] Hero animations entre telas
- [ ] Feedback visual aprimorado

## 🎯 **PRIORIDADE BAIXA - Futuras Versões**

### 5. **Modo Professor** 👩‍🏫
**Status:** ❌ PENDENTE
**Descrição:** Ferramentas para professores

#### Tarefas:
- [ ] Geração de PDFs de exercícios
- [ ] Gabaritos separados
- [ ] Relatórios de turma
- [ ] Material de estudo offline

### 6. **Sistema de Backup** ☁️
**Status:** ❌ PENDENTE
**Descrição:** Backup e sincronização de dados

#### Tarefas:
- [ ] Exportação/importação de dados
- [ ] Sincronização entre dispositivos
- [ ] Backup na nuvem

---

## 📊 **Status Atual do MVP**

### ✅ **IMPLEMENTADO (Estrutura Core)**
- ✅ Arquitetura Flutter com Material 3
- ✅ Sistema de módulos BNCC
- ✅ Progressão e gamificação básica
- ✅ Múltiplos tipos de quiz
- ✅ Persistência SQLite
- ✅ Modo offline (sem Firebase)
- ✅ Interface responsiva

### ❌ **FALTANDO (Funcionalidades Core)**
- ❌ Sistema de lições interativas
- ❌ Conteúdo offline pré-definido
- ❌ Onboarding do usuário

**🎯 Conclusão:** MVP tem estrutura sólida, mas precisa do fluxo de conteúdo educacional para ser funcional.

**📅 Atualizado em:** 12 de outubro de 2025
  - Estatísticas por módulo
  - Cache de IA
  - Conquistas
  - Migração de dados locais

### 📊 **Analytics, Crashlytics & Remote Config**
- ✅ **Firebase Analytics** - `FirebaseAnalyticsObserver` configurado no `MaterialApp`
- ✅ **Firebase Crashlytics** - Inicializado no main.dart para coleta de crashes
- ✅ **Firebase Remote Config** - Configurado com timeouts apropriados

### 📱 **Configuração por Plataforma**
- ✅ **Android** - `google-services.json` presente e plugin configurado
- ❌ **iOS** - Faltando `GoogleService-Info.plist` (requer Console Firebase)
- ❌ **Web** - Faltando snippet de configuração (requer Console Firebase)

### 🎯 **Funcionalidades do App**
- ✅ **App compilando** - `flutter build apk --debug` funciona
- ✅ **Análise limpa** - Apenas warnings menores sobre `withOpacity` (já corrigidos onde possível)
- ✅ **Arquitetura preparada** - Código estruturado para migração SQLite → Firestore

## 📋 **Resumo do Progresso**

**✅ 90% Completo** - Toda a lógica e infraestrutura implementada.  
**❌ 10% Restante** - Apenas configurações manuais do Console Firebase para iOS/Web.

O app agora tem **autenticação obrigatória** e está **pronto para dados na nuvem**. Usuários precisam fazer login para acessar, e todos os serviços Firebase estão integrados e funcionais, exceto as configurações específicas de iOS/Web que requerem acesso ao Console Firebase.