# Modo de Precarregamento de Perguntas

## Visão Geral

O modo de precarregamento é uma funcionalidade avançada que gera 100 perguntas diversas com o modelo de IA escolhido ao iniciar o aplicativo. Durante o processo de carregamento, um mini-jogo divertido ("Math Bubble Pop") mantém o usuário entretido.

## Como Ativar

1. Abra o aplicativo
2. Vá para **Configurações** ⚙️
3. Na seção **"Precarregamento de Perguntas"**
4. Ative o switch **"Precarregar 100 perguntas"**
5. Opcionalmente, clique em **"Iniciar Precarregamento Agora"** para executar imediatamente

## Como Funciona

### Ativação Automática
- Quando habilitado, o precarregamento ocorre automaticamente:
  - Na primeira inicialização após ativar
  - A cada 24 horas quando o app é aberto
  - Apenas se há uma configuração válida de IA (Gemini com API key ou Ollama rodando)

### Processo de Precarregamento
1. **Verificação**: O app verifica se deve executar o precarregamento
2. **Tela de Jogo**: Se necessário, mostra a tela do Math Bubble Pop
3. **Geração**: Gera 100 perguntas variadas em segundo plano
4. **Cache**: Armazena as perguntas no banco de dados local
5. **Conclusão**: Retorna para a tela principal

### Math Bubble Pop - Mini-Jogo
Durante o precarregamento, o usuário joga um jogo divertido:

- **Objetivo**: Estourar bolhas com a resposta correta para problemas matemáticos
- **Pontuação**: +10 pontos para respostas corretas, -20 pontos para incorretas
- **Vidas**: 3 vidas, perdendo uma a cada erro
- **Bolhas**: Aparecem a cada 3 segundos com respostas verdadeiras e falsas
- **Dificuldade**: Problemas simples de soma e subtração

## Benefícios

### Performance
- **Velocidade**: Quizzes carregam instantaneamente usando perguntas pré-geradas
- **Fluidez**: Experiência mais suave sem esperas durante o uso
- **Eficiência**: Reduz drasticamente o tempo de resposta da IA

### Variedade
- **Cobertura**: Gera perguntas para diferentes:
  - Unidades (números, álgebra, geometria, etc.)
  - Anos escolares (1º, 2º, 3º ano)
  - Níveis de dificuldade (fácil, médio)
  - Tipos de quiz (múltipla escolha, V/F, completar)

### Experiência do Usuário
- **Entretenimento**: Mini-jogo torna a espera divertida
- **Transparência**: Progresso visível durante o carregamento
- **Flexibilidade**: Pode ser ativado/desativado a qualquer momento

## Configurações Técnicas

### Requisitos
- **Para Gemini**: API key válida configurada
- **Para Ollama**: Serviço rodando em `http://localhost:11434`
- **Armazenamento**: ~50-100MB de espaço para cache
- **Conectividade**: Internet durante o precarregamento

### Parâmetros
- **Total de Perguntas**: 100 (fixo)
- **Frequência**: A cada 24 horas
- **Timeout**: 10 falhas máximas antes de parar
- **Cache**: Renovado automaticamente

### Distribuição das Perguntas
- **12 tópicos diferentes** cobrindo toda a base BNCC
- **3 tipos de quiz** para máxima variedade
- **2-3 níveis de dificuldade** por tópico
- **Distribuição aleatória** durante a geração

## Gerenciamento

### Monitoramento
- Progresso em tempo real durante o carregamento
- Status detalhado na tela de precarregamento
- Estatísticas básicas disponíveis

### Controle Manual
- **Iniciar Agora**: Força um novo precarregamento
- **Ativar/Desativar**: Controle total sobre a funcionalidade
- **Reset**: Limpar cache existente (se necessário)

### Tratamento de Erros
- **Falhas de IA**: Continua tentando até o limite
- **Problemas de Rede**: Retorna graciosamente à tela principal
- **Cache Corrompido**: Regenera automaticamente

## Impacto na Performance

### Benefícios
- ✅ Quizzes carregam 10x mais rápido
- ✅ Reduz uso de tokens da API
- ✅ Funciona offline após precarregamento
- ✅ Experiência consistente

### Considerações
- ⚠️ Usa mais armazenamento local
- ⚠️ Processo inicial pode levar 5-10 minutos
- ⚠️ Requer configuração adequada da IA
- ⚠️ Consome dados durante o precarregamento

## Solução de Problemas

### Precarregamento Não Inicia
1. Verificar se está habilitado nas configurações
2. Confirmar configuração válida de IA
3. Verificar conexão de internet
4. Tentar iniciar manualmente

### Erros Durante o Processo
- **"API Key não configurada"**: Configurar chave do Gemini
- **"Ollama não está rodando"**: Iniciar serviço Ollama
- **"Erro de conexão"**: Verificar internet e configurações

### Performance Lenta
- Verificar se cache está sendo usado corretamente
- Limpar cache antigo se necessário
- Verificar espaço de armazenamento disponível

## Código Técnico

### Arquivos Principais
- `lib/services/preload_service.dart` - Lógica de precarregamento
- `lib/screens/preload_screen.dart` - Interface com mini-jogo
- `lib/widgets/app_initializer.dart` - Gerenciamento de inicialização

### Configuração
- Armazenada em `SharedPreferences`
- Chave: `preload_enabled`
- Timestamp: `last_preload_timestamp`

### Cache
- Utiliza tabela existente de cache de perguntas
- Integração com `DatabaseService`
- Renovação automática baseada em timestamp
