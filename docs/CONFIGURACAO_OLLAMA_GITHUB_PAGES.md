# Configuração do Ollama para GitHub Pages

Este guia explica como configurar o Ollama no PC local para aceitar requisições da aplicação hospedada no GitHub Pages.

## Problema

Por padrão, o Ollama executa apenas em `localhost:11434` e não aceita requisições de origens externas (CORS). Quando a aplicação está hospedada no GitHub Pages, ela precisa acessar o Ollama rodando no PC do usuário.

## Solução

### 1. Configurar CORS no Ollama

O Ollama precisa ser configurado para aceitar requisições de origens externas.

#### No Windows (PowerShell como Administrador):

```powershell
# Parar o serviço Ollama se estiver rodando
Stop-Service -Name "Ollama" -ErrorAction SilentlyContinue

# Definir variável de ambiente para permitir CORS
[Environment]::SetEnvironmentVariable("OLLAMA_ORIGINS", "*", "Machine")

# Ou para ser mais específico (recomendado):
[Environment]::SetEnvironmentVariable("OLLAMA_ORIGINS", "https://*.github.io,http://localhost:*", "Machine")

# Reiniciar o serviço
Start-Service -Name "Ollama"
```

#### No Linux/macOS:

```bash
# Adicionar ao ~/.bashrc ou ~/.zshrc
export OLLAMA_ORIGINS="https://*.github.io,http://localhost:*"

# Ou executar diretamente:
OLLAMA_ORIGINS="*" ollama serve
```

### 2. Verificar se está funcionando

Após configurar, você pode testar se está funcionando:

```bash
# Testar se o Ollama está aceitando requisições
curl -X GET http://localhost:11434/api/tags
```

### 3. Configuração Alternativa (Mais Segura)

Se você quiser ser mais específico sobre quais domínios podem acessar:

```powershell
# Permitir apenas seu GitHub Pages e localhost
[Environment]::SetEnvironmentVariable("OLLAMA_ORIGINS", "https://seuusuario.github.io,http://localhost:*", "Machine")
```

## Como Funciona na Aplicação

A aplicação agora possui:

1. **SmartAIService**: Detecta automaticamente se o Ollama está disponível
2. **Fallback Automático**: Se Ollama não estiver disponível, usa Gemini
3. **Cache de Status**: Evita verificar o Ollama constantemente
4. **Timeout Configurado**: Não trava se o Ollama não estiver respondendo

### Uso no Código:

```dart
// Ao invés de usar OllamaService ou GeminiService diretamente
final aiService = SmartAIService();

// Isso tentará Ollama primeiro, depois Gemini automaticamente
final resposta = await aiService.generate("Sua pergunta");

// Verificar qual serviço está sendo usado
final servicoAtual = await aiService.getCurrentService();
print("Usando: $servicoAtual"); // "Ollama Local" ou "Gemini Cloud"
```

## Benefícios

1. **Funciona Offline**: Se o usuário tem Ollama instalado, funciona sem internet
2. **Fallback Automático**: Se Ollama não está disponível, usa Gemini automaticamente
3. **Melhor Performance**: Ollama local é mais rápido que APIs na nuvem
4. **Privacidade**: Dados ficam no PC do usuário quando usa Ollama local

## Instruções para o Usuário Final

Para usuários que quiserem usar o Ollama local:

1. Instale o Ollama: `winget install Ollama.Ollama`
2. Configure CORS (execute como administrador):
   ```powershell
   [Environment]::SetEnvironmentVariable("OLLAMA_ORIGINS", "*", "Machine")
   ```
3. Reinicie o Ollama
4. Instale um modelo: `ollama pull llama3.2`
5. Acesse a aplicação no GitHub Pages - ela detectará o Ollama automaticamente!

Se não configurar o Ollama, a aplicação funcionará normalmente usando Gemini.
