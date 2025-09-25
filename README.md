## 🎯 Objetivo do Sistema

Ensinar Matemática de forma adaptativa e personalizada para alunos do Ensino Fundamental 2, usando BNCC. Permitir atividades desplugadas, com suporte digital opcional para monitoramento e feedback. Gerar tutoria inteligente usando IA generativa para criar exercícios, problemas contextualizados, dicas, explicações passo a passo e avaliações.

## 🧩 Funcionalidades Principais

### Geração de Conteúdo Inteligente

- Exercícios matemáticos adaptados ao nível do aluno
- Problemas contextualizados com temas do dia a dia
- Explicações passo a passo com linguagem simples

### Monitoramento do Aprendizado

- Registro de desempenho por tópico ou habilidade
- Sugestão de revisões para pontos fracos

### Feedback Interativo

- Feedback positivo e corretivo automatizado
- Recomendações personalizadas de exercícios

### Modo Desplugado

- Impressão de materiais gerados
- Atividades offline para execução em sala ou em casa

### Suporte a Professores

- Planejamento de aulas com base no desempenho da turma
- Relatórios detalhados de progresso

## 🛠️ Tecnologias Utilizadas

- **Frontend**: Flutter (app multiplataforma) - funciona em Web, Desktop, Mobile
- **IA Generativa**: SmartAI Service com fallback automático:
  - 🖥️ **Ollama Local**: Processamento no PC do usuário (offline, privado)
  - ☁️ **Google Gemini**: Processamento na nuvem (sempre disponível)
- **Hospedagem**: GitHub Pages (funciona mesmo conectando ao Ollama local)

### 🚀 Como Funciona a IA Híbrida

A aplicação tenta conectar ao **Ollama rodando no PC local** primeiro. Se não estiver disponível, automaticamente usa o **Google Gemini** na nuvem. Isso oferece:

- ✅ **Melhor Performance**: Ollama local é mais rápido
- ✅ **Privacidade**: Dados ficam no PC quando usa Ollama
- ✅ **Disponibilidade**: Sempre funciona com Gemini como fallback
- ✅ **Funciona no GitHub Pages**: Mesmo hospedado estaticamente

### 📋 Para Usar Ollama Local (Opcional)

1. **Instalar Ollama**: `winget install Ollama.Ollama`
2. **Configurar CORS** (PowerShell como administrador):
   ```powershell
   [Environment]::SetEnvironmentVariable("OLLAMA_ORIGINS", "*", "Machine")
   ```
3. **Instalar um modelo**: `ollama pull llama3.2`
4. **Pronto!** A aplicação detectará automaticamente

Se não configurar o Ollama, funciona perfeitamente com Gemini! 🎉

## 🌟 Benefícios do Sistema

- Personalização do ensino de Matemática
- Possibilidade de uso em locais com baixa conectividade
- Redução de carga para professores, automatizando sugestões e exercícios
- Estímulo à aprendizagem ativa e desplugada, mantendo o engajamento dos alunos
