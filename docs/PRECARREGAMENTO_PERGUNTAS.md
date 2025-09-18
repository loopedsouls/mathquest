# Modo de Precarregamento de Perguntas com Sistema de Créditos

## Visão Geral

O modo de precarregamento é uma funcionalidade avançada que gera 100 perguntas diversas com o modelo de IA escolhido, utilizando um **sistema de créditos inteligente**. Cada precarregamento fornece 100 créditos, e cada pergunta usada do cache consome 1 crédito. Durante o processo de carregamento, um mini-jogo divertido ("Math Bubble Pop") mantém o usuário entretido.

## 🎯 Sistema de Créditos

### Como Funciona
- **Precarregamento**: Gera 100 perguntas e fornece 100 créditos
- **Consumo**: Cada pergunta respondida do cache usa 1 crédito
- **Renovação**: Quando os créditos chegam a zero, inicia novo precarregamento automaticamente
- **Verificação de IA**: Só precarrega se a IA estiver online e disponível

### Benefícios
- ✅ **Economia de Recursos**: Só gera novas perguntas quando necessário
- ✅ **Performance Otimizada**: Cache inteligente baseado em uso real
- ✅ **Verificação Automática**: Evita falhas quando IA está offline
- ✅ **Transparência**: Usuário vê quantos créditos restam

## Como Ativar

1. Abra o aplicativo
2. Vá para **Configurações** ⚙️
3. Na seção **"Precarregamento de Perguntas"**
4. Ative o switch **"Precarregar 100 perguntas"**
5. Opcionalmente, clique em **"Iniciar Precarregamento Agora"** para executar imediatamente

## Como Funciona

### Ativação Automática
- Quando habilitado, o precarregamento ocorre automaticamente:
  - **Na primeira ativação** ou quando créditos chegam a zero
  - **Verificação de IA**: Só executa se Gemini/Ollama estiver funcionando
  - **Background inteligente**: Recarrega automaticamente durante o uso normal
  - **Falha segura**: Se IA offline, aguarda até estar disponível

### Processo de Precarregamento
1. **Verificação de Créditos**: Analisa se há créditos suficientes
2. **Teste de IA**: Confirma se serviço está online e funcionando
3. **Tela de Jogo**: Se necessário, mostra a tela do Math Bubble Pop
4. **Geração**: Gera até 100 perguntas diversas em segundo plano
5. **Atribuição de Créditos**: Define créditos baseado em perguntas geradas
6. **Cache**: Armazena as perguntas no banco de dados local
7. **Conclusão**: Retorna para a tela principal com cache pronto

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
- **Eficiência**: Sistema de créditos evita geração desnecessária
- **Inteligência**: Precarrega automaticamente quando necessário
- **Economia**: Só usa API/recursos quando há demanda real

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
- **Para Gemini**: API key válida configurada e serviço online
- **Para Ollama**: Serviço rodando em `http://localhost:11434` e responsivo
- **Armazenamento**: ~50-100MB de espaço para cache
- **Conectividade**: Internet durante o precarregamento
- **Verificação Automática**: Sistema testa IA antes de precarregar

### Parâmetros
- **Total de Perguntas**: Até 100 por precarregamento
- **Sistema de Créditos**: 1 crédito = 1 pergunta do cache
- **Renovação**: Automática quando créditos chegam a zero
- **Timeout**: 10 falhas máximas antes de parar
- **Verificação**: Testa IA antes de cada precarregamento

### Distribuição das Perguntas
- **12 tópicos diferentes** cobrindo toda a base BNCC
- **3 tipos de quiz** para máxima variedade
- **2-3 níveis de dificuldade** por tópico
- **Distribuição aleatória** durante a geração

## Gerenciamento

### Monitoramento
- **Créditos**: Visualização em tempo real na tela de configurações
- **Progresso**: Acompanhamento durante o precarregamento
- **Status**: Informações detalhadas sobre o processo
- **Background**: Precarregamento automático invisível ao usuário

### Controle Manual
- **Iniciar Agora**: Força um novo precarregamento independente dos créditos
- **Ativar/Desativar**: Controle total sobre a funcionalidade
- **Visualização**: Acompanha créditos restantes nas configurações
- **Background**: Sistema funciona automaticamente sem intervenção

### Tratamento de Erros
- **IA Offline**: Aguarda até serviço estar disponível
- **Falhas de Geração**: Continua tentando até o limite
- **Problemas de Rede**: Retorna graciosamente, mantém créditos
- **Cache Corrompido**: Regenera automaticamente quando necessário
- **Créditos Zerados**: Inicia precarregamento em background

## Impacto na Performance

### Benefícios
- ✅ Quizzes carregam instantaneamente após primeiro uso
- ✅ Sistema inteligente evita desperdício de recursos
- ✅ Funciona offline após ter créditos/cache
- ✅ Precarregamento automático em background
- ✅ Verificação automática de disponibilidade da IA

### Considerações
- ⚠️ Usa mais armazenamento local para cache
- ⚠️ Processo inicial pode levar 5-10 minutos
- ⚠️ Requer IA online para funcionar
- ⚠️ Consome dados durante o precarregamento
- ⚠️ Créditos zerados pausam benefício até recarregamento

## Solução de Problemas

### Precarregamento Não Inicia
1. Verificar se está habilitado nas configurações
2. Confirmar que ainda há créditos disponíveis
3. Verificar se IA está online e funcionando
4. Tentar iniciar manualmente (ignora créditos)

### Créditos Zerados
- Sistema automaticamente inicia precarregamento em background
- Verificar se IA está disponível (Gemini/Ollama)
- Usar precarregamento manual se necessário
- Aguardar conclusão do processo automático

### Erros Durante o Processo
- **"API Key não configurada"**: Configurar chave do Gemini
- **"Ollama não está rodando"**: Iniciar serviço Ollama
- **"IA offline"**: Aguardar conectividade ou verificar configuração

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
- Chave: `preload_enabled` (boolean)
- Créditos: `preload_credits` (integer)
- Timestamp: `last_preload_timestamp` (timestamp)

### Cache
- Utiliza tabela existente de cache de perguntas
- Integração com `DatabaseService` e `CacheIAService`
- Sistema de créditos controla uso do cache
- Renovação automática baseada em consumo real
