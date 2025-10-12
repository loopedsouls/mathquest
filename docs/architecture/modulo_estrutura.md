## Estrutura do Módulo

O `modulo_screen` não direciona diretamente para o quiz. Em vez disso, ele apresenta um chat com a IA, que oferece um resumo geral do conteúdo e pergunta ao usuário o que deseja aprender. Além disso, existe um modo gerador de atividades conforme o ano escolar, utilizando a mesma mecânica dos quizzes.

### Funcionalidades

- **Chat com IA:**  
    - Resumo do conteúdo do módulo.
    - Pergunta ao usuário sobre o interesse de aprendizado.
- **Gerador de Atividades:**  
    - Seleção do ano escolar.
    - Geração de atividades personalizadas usando a lógica dos quizzes.

### Fluxo de Navegação

1. Usuário acessa o `modulo_screen`.
2. Chat com IA é iniciado.
3. Usuário escolhe entre receber um resumo, aprender um tópico específico ou gerar atividades.
4. Caso escolha gerar atividades, seleciona o ano e recebe questões no formato de quiz.
