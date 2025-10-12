```markdown
# Para implementar: Mensagem inicial e opções ao iniciar módulo

Ao clicar em **Começar** no módulo, implemente o seguinte fluxo:

1. **Mensagem inicial gerada por IA**
    - A IA deve apresentar um resumo do que será aprendido no módulo.
    - A quantidade de aulas é definida pela IA (apenas uma vez por módulo).
    - Exemplo de mensagem:
      > "Neste módulo você aprenderá sobre frações, operações básicas e aplicações no cotidiano. O módulo possui 4 aulas."

2. **Exibir 3 opções clicáveis depois da mensagem inicial**
    - **Quiz do conteúdo**: Inicia um quiz sobre o tema do módulo.
    - **Aula 1** (ou próxima aula, caso já tenha visto a anterior): Inicia a aula correspondente.
    - **Curiosidades do assunto**: Mostra curiosidades relacionadas ao tema do módulo.

3. **Progresso do módulo na appbar do chat e no dashboard screen**
    - A porcentagem de progresso é baseada na quantidade de aulas definida pela IA.
    - Ao terminar todas as aulas, marque o módulo como concluído no progresso do usuário.

> **Observação:** O fluxo deve ser integrado à tela de chat, exibindo a mensagem inicial e as opções como botões interativos.
```