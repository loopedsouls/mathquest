# Adaptive Check - Tutor de Matemática com IA Gemini

Um aplicativo Flutter que oferece tutoria de matemática adaptativa usando a API do Google Gemini.

## 🚀 Características

- **Tutoria Adaptativa**: O nível de dificuldade se ajusta automaticamente baseado no desempenho
- **IA Generativa**: Usa o Google Gemini para gerar perguntas e explicações personalizadas
- **Interface Nativa**: Design Cupertino para uma experiência iOS nativa
- **Histórico de Atividades**: Acompanhe seu progresso ao longo do tempo
- **Explicações Detalhadas**: Receba explicações claras quando errar uma questão

## 📋 Pré-requisitos

- Flutter SDK (>=3.1.3)
- Dart SDK
- Chave API do Google Gemini

## 🔧 Configuração

### 1. Obter Chave API do Gemini

1. Vá para [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Faça login com sua conta Google
3. Clique em "Create API Key"
4. Copie a chave gerada

### 2. Instalação

```bash
# Clone o repositório
git clone <url-do-repositorio>
cd adaptivecheck

# Instale as dependências
flutter pub get

# Execute o aplicativo
flutter run
```

### 3. Configuração da API

1. Abra o aplicativo
2. Na tela inicial, clique em "Configurações"
3. Cole sua chave API do Gemini no campo apropriado
4. Clique em "Salvar API Key"
5. Teste a conexão clicando em "Testar Conexão"
6. Se tudo estiver funcionando, clique em "Iniciar Jogo"

## 🎮 Como Usar

1. **Início**: Na tela inicial, clique em "Iniciar Jogo"
2. **Perguntas**: O aplicativo gerará perguntas de matemática baseadas no seu nível atual
3. **Resposta**: Digite sua resposta no campo de texto
4. **Verificação**: Clique em "Verificar" para ver se acertou
5. **Explicação**: Se errar, clique em "Ver Explicação" para entender o conceito
6. **Progresso**: O nível de dificuldade se ajusta automaticamente:
   - ✅ Acertou: Nível aumenta
   - ❌ Errou: Nível diminui
7. **Nova Pergunta**: Clique em "Nova Pergunta" para continuar

## 📱 Níveis de Dificuldade

- **Fácil**: Operações básicas (adição, subtração, multiplicação, divisão)
- **Médio**: Frações, percentagens, equações simples
- **Difícil**: Álgebra, geometria, problemas complexos
- **Expert**: Problemas avançados e conceitos matemáticos complexos

## 🏗️ Estrutura do Projeto

```
lib/
├── main.dart                 # Ponto de entrada do aplicativo
├── game_screen.dart         # Telas principais (início, configuração, jogo)
├── gemini_service.dart      # Serviço para integração com Google Gemini
└── math_tutor_service.dart  # Lógica de tutoria matemática
```

## 🔄 Migração do Ollama para Gemini

Este projeto foi migrado do Ollama (IA local) para o Google Gemini (IA em nuvem). As principais mudanças incluem:

- ✅ Substituição do `OllamaService` por `GeminiService`
- ✅ Atualização da interface de configuração
- ✅ Melhoria na geração de perguntas e explicações
- ✅ Configuração mais simples (apenas chave API necessária)

## 🛠️ Dependências Principais

- `flutter`: Framework de desenvolvimento
- `google_generative_ai`: Integração com Google Gemini
- `shared_preferences`: Armazenamento local de configurações
- `http`: Requisições HTTP

## 📝 Notas de Desenvolvimento

### Serviços

- **GeminiService**: Gerencia a comunicação com a API do Google Gemini
- **MathTutorService**: Contém a lógica de negócio para tutoria matemática
- **Configurações**: Armazenadas localmente usando SharedPreferences

### Interface

- Design baseado em Cupertino (estilo iOS)
- Animações suaves para feedback visual
- Cores adaptáveis baseadas no resultado (verde para correto, vermelho para incorreto)

## 🚨 Segurança

- A chave API é armazenada localmente no dispositivo
- Recomenda-se não compartilhar a chave API
- Use controles de acesso da Google Cloud para limitar o uso da API se necessário

## 📞 Suporte

Para problemas ou dúvidas:
1. Verifique se sua chave API está correta
2. Certifique-se de ter conexão com a internet
3. Verifique se a API do Gemini está ativa em sua conta Google

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.



