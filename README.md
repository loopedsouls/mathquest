# Visual Novel LMM - Jogo de Conhecimento Geral com IA Gemini

Um projeto Flutter que oferece jogos de conhecimento geral integrados à API do Google Gemini.

## 🚀 Características

- **Jogos Interativos**: Quiz, perguntas e respostas, desafios de lógica, adivinhação, palavras cruzadas, entre outros
- **IA Generativa**: Utiliza Google Gemini para criar perguntas, enigmas e explicações personalizadas
- **Interface Visual Novel**: Layout inspirado em visual novels, com diálogos, escolhas e navegação intuitiva
- **Histórico de Progresso**: Acompanhe seu desempenho em diferentes jogos
- **Explicações Detalhadas**: Receba feedback e explicações sobre cada resposta
- **Configuração Dinâmica**: Tela/modal para inserir e testar a chave API Gemini

## 📋 Pré-requisitos

- Flutter (>=3.0)
- Dart
- Chave API do Google Gemini

## 🔧 Configuração

### 1. Obter Chave API do Gemini

1. Acesse [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Faça login com sua conta Google
3. Clique em "Create API Key"
4. Copie a chave gerada

### 2. Instalação

```bash
# Clone o repositório
git clone <url-do-repositorio>
cd visual-novel-lmm

# Instale dependências Flutter
flutter pub get

# Execute o projeto
flutter run
```

### 3. Configuração da API

1. Abra o app Flutter
2. No menu inicial, acesse "Configurações"
3. Cole sua chave API Gemini
4. Salve e teste a conexão

## 🎮 Como Jogar

1. **Início**: Escolha o tipo de jogo (quiz, lógica, palavras cruzadas, etc.)
2. **Perguntas/Desafios**: O app gera perguntas ou desafios usando IA Gemini
3. **Resposta**: Selecione ou digite sua resposta nas telas do app
4. **Feedback**: Veja se acertou e receba explicações
5. **Progresso**: Dificuldade ajustada conforme desempenho
6. **Novo Jogo**: Escolha outro modo ou continue jogando
7. **Histórico**: Veja suas atividades e resultados

## 📱 Tipos de Jogos

- **Quiz de Conhecimento Geral**
- **Desafios de Lógica**
- **Adivinhação de Palavras**
- **Palavras Cruzadas**
- **Perguntas e Respostas**
- **Jogo da Forca**
- **Matemática Básica**
- **Outros jogos simples gerados pela IA**

## 🏗️ Estrutura do Projeto

```
lib/
├── main.dart                 # Entrada principal do app
├── gemini_service.dart       # Integração com Google Gemini
├── screens/                  # Telas de configuração, histórico e jogos
├── assets/                   # Imagens, sons, etc.
```

## 🔄 Migração do Ren'Py para Flutter

Este projeto foi adaptado de Ren'Py para Flutter, mantendo integração com Google Gemini. Principais mudanças:

- ✅ Interface visual novel adaptada para Flutter
- ✅ Configuração da API via tela/modal
- ✅ Geração de perguntas e explicações via IA Gemini
- ✅ Histórico de progresso integrado
- ✅ Layout responsivo para mobile e desktop

## 🛠️ Dependências Principais

- `Flutter`: Framework para apps multiplataforma
- `http`: Requisições HTTP
- `google-generativeai`: Integração com Google Gemini

## 📝 Notas de Desenvolvimento

### Serviços

- **gemini_service.dart**: Gerencia comunicação com API Gemini
- **main.dart**: Lógica dos jogos e navegação
- **Configurações**: Armazenadas localmente

### Interface

- Layout visual novel com diálogos e escolhas
- Menu lateral ou inferior para navegação
- Telas de configuração e histórico como modal

## 🚨 Segurança

- Chave API armazenada localmente
- Não compartilhe sua chave API
- Use controles de acesso da Google Cloud para limitar uso

## 📞 Suporte

Para dúvidas ou problemas:
1. Verifique sua chave API
2. Certifique-se de ter conexão com a internet
3. Confirme se a API Gemini está ativa

## 📄 Licença

Este projeto está sob licença MIT. Veja o arquivo LICENSE para detalhes.
