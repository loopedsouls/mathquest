# MathQuest - Módulo de Matemática

## Descrição

O módulo de matemática é uma feature do MathQuest dedicada ao ensino e prática de conceitos matemáticos para estudantes do ensino médio brasileiro, alinhado com a BNCC (Base Nacional Comum Curricular).

## Funcionalidades

- **Dashboard**: Navegação principal com acesso a diferentes ferramentas matemáticas
- **Exercícios**: Geração e resolução de exercícios personalizados
- **Simulador Interativo**: Visualização gráfica de funções quadráticas com sliders para coeficientes
- **Conversão de Matrizes**: Ferramenta para operações com matrizes
- **Classificação de Imagem**: Uso de IA para identificar objetos em imagens (integrado com Google ML Kit)
- **Biblioteca de Conceitos**: Acesso a conceitos matemáticos organizados
- **Editor de Representação**: Ferramenta para criar representações visuais
- **Comunidade**: Espaço para interação entre estudantes
- **Perfil**: Gerenciamento de perfil do usuário
- **Recursos**: Materiais adicionais de apoio

## Serviços

- **FirebaseAIService**: Integração com IA para geração de exercícios e explicações
- **DatabaseService**: Persistência local com SQLite
- **ImageClassificationService**: Classificação de imagens usando ML Kit
- **ArxivService**: Busca de artigos científicos
- **GeminiService**: Integração com modelos Gemini (experimental)

## Integração no App

O módulo está parcialmente integrado no app principal. As telas principais podem ser acessadas através do dashboard do MathQuest, mas algumas funcionalidades ainda estão em desenvolvimento separado (ver `examples/` para versões de teste).

Para integração completa:
1. Adicionar rotas no `main.dart` principal
2. Conectar com o sistema de progresso global
3. Sincronizar dados com Firestore

## Estrutura Detalhada de Arquivos

### Models
- `concept.dart`: Modelo para conceitos matemáticos (título, descrição, fórmulas)
- `exercise.dart`: Estrutura de exercícios (pergunta, opções, resposta correta, dificuldade)
- `forum_post.dart`: Posts do fórum da comunidade
- `user_profile.dart`: Perfil do usuário com progresso e preferências

### Screens
- `community_screen.dart`: Tela de comunidade para interação entre estudantes
- `concept_library_screen.dart`: Biblioteca organizada de conceitos por unidade BNCC
- `dashboard_screen.dart`: Dashboard principal com navegação rail para todas as ferramentas
- `exercise_bank_screen.dart`: Banco de exercícios disponíveis
- `exercise_screen.dart`: Tela de resolução de exercícios com feedback
- `image_classification_screen.dart`: Classificação de imagens usando ML Kit
- `interactive_simulator_screen.dart`: Simulador gráfico de funções quadráticas
- `mapeamento_sistematico.dart`: Navegação sistemática entre telas
- `math_topics.dart`: Lista de tópicos matemáticos
- `mathstateofart.dart`: Estado da arte em matemática (pesquisa)
- `matrix_conversion_screen.dart`: Conversão e operações com matrizes
- `myhomepage.dart`: Página inicial personalizada
- `profile_screen.dart`: Perfil e configurações do usuário
- `representation_editor_screen.dart`: Editor para representações visuais
- `resources_screen.dart`: Recursos adicionais (artigos, PDFs)

### Services
- `arxiv_service.dart`: Busca e integração com arXiv para artigos científicos
- `export_service.dart`: Exportação de dados (PDF, relatórios)
- `gemini_service.dart`: Integração com modelos Gemini (experimental)
- `image_classification_service.dart`: Serviço de classificação de imagens
- `ollama_service.dart`: Integração com Ollama (IA local)
- `saved_articles_service.dart`: Gerenciamento de artigos salvos

### Widgets
- `algebra_editor.dart`: Editor de álgebra com entrada de fórmulas
- `concept_card.dart`: Card para exibir conceitos
- `exercise_tile.dart`: Tile para exercícios na lista
- `forum_post.dart`: Componente para posts do fórum
- `graph_editor.dart`: Editor de gráficos
- `interactive_chart.dart`: Gráfico interativo (usando fl_chart)

### View
- `article_viewer.dart`: Visualizador de artigos científicos
- `pdf_viewer.dart`: Visualizador de PDFs

### Examples
- `main.dart`: App de teste com dashboard básico
- `main_2.dart`: Versão alternativa com navegação diferente
- `main_3.dart`: Versão experimental

### Datasets
Pasta com dados de teste para treinamento de modelos:
- `acerto/` e `acertos/`: Exemplos de respostas corretas
- `erro/` e `erros/`: Exemplos de respostas incorretas
- `teste/`: Dados de teste

## Dependências Específicas

- `syncfusion_flutter_charts`: Para gráficos interativos
- `google_ml_kit`: Para classificação de imagens
- `image_picker`: Para seleção de imagens
- `flutter_math_fork`: Para renderização de fórmulas matemáticas

## Notebooks de Pesquisa

Notebooks Jupyter com experimentos em Python estão disponíveis em `docs/math_notebooks/` para referência, mas não fazem parte do código Dart do app.