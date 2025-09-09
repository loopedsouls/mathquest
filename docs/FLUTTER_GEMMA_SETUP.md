# Configuração do Flutter Gemma

## Visão Geral
O Flutter Gemma permite executar modelos de IA Gemma diretamente no dispositivo Android, proporcionando:
- **Privacidade**: Processamento local, sem envio de dados para servidores
- **Velocidade**: Respostas mais rápidas após carregamento inicial
- **Offline**: Funciona sem conexão com internet após configuração

## Requisitos
- Dispositivo Android com pelo menos 4GB de RAM
- Android API 24+ (Android 7.0)
- Espaço de armazenamento: 2-8GB dependendo do modelo

## Modelos Recomendados

### Para dispositivos com 4-6GB RAM:
- **Gemma 3 1B**: Modelo compacto e eficiente
- **Gemma 3 270M**: Ultra-compacto para dispositivos com menos recursos

### Para dispositivos com 8GB+ RAM:
- **Gemma 2B**: Melhor qualidade de resposta
- **Gemma 3 Nano**: Suporte multimodal (texto + imagem)

## Configuração Passo a Passo

### 1. Baixar Modelo
Escolha uma das opções:

#### Opção A: Kaggle (Recomendado)
1. Acesse [Kaggle Gemma Models](https://www.kaggle.com/models/google/gemma/frameworks/tfLite/)
2. Baixe o modelo `.tflite` (ex: `gemma-1.1-2b-it-gpu-int4.tflite`)

#### Opção B: HuggingFace
1. Acesse [HuggingFace Gemma](https://huggingface.co/google/gemma-2b-it)
2. Baixe o modelo em formato TensorFlow Lite

### 2. Preparar o Modelo no App

#### Método 1: Assets (Desenvolvimento)
```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/models/gemma-model.tflite
```

#### Método 2: Download via Rede (Produção)
```dart
// Exemplo de carregamento
final modelManager = FlutterGemmaPlugin.instance.modelManager;
await modelManager.downloadModelFromNetwork(
  'https://seu-servidor.com/modelo.tflite'
);
```

### 3. Configurar no App

1. Vá para **Configurações** no app
2. Selecione **Flutter Gemma** como serviço de IA
3. O app tentará carregar o modelo automaticamente

## Troubleshooting

### Problemas Comuns

**Erro de Memória Insuficiente:**
- Use um modelo menor (270M ou 1B)
- Feche outros apps antes de usar
- Reinicie o dispositivo

**Modelo não Carrega:**
- Verifique se o arquivo está no formato correto (.tflite)
- Confirme que há espaço suficiente no dispositivo
- Verifique as permissões de armazenamento

**Performance Lenta:**
- Use GPU acceleration se disponível
- Modelos quantizados (int4/int8) são mais rápidos
- Considere usar CPU backend para modelos pequenos

### Logs de Debug
```bash
# Ver logs durante desenvolvimento
flutter logs --device-id [DEVICE_ID]
```

## Configurações Avançadas

### GPU vs CPU
- **GPU**: Melhor para modelos grandes (2B+)
- **CPU**: Mais estável para modelos pequenos (270M, 1B)

### Otimização de Memória
```dart
// Configurações recomendadas
final model = await FlutterGemmaPlugin.instance.createModel(
  modelType: ModelType.gemmaIt,
  preferredBackend: PreferredBackend.cpu, // ou gpu
  maxTokens: 256, // Reduzir para economizar memória
);
```

## Links Úteis
- [Flutter Gemma GitHub](https://github.com/DenisovAV/flutter_gemma)
- [Documentação Oficial](https://pub.dev/packages/flutter_gemma)
- [Gemma Models - Kaggle](https://www.kaggle.com/models/google/gemma)
- [MediaPipe GenAI](https://developers.google.com/mediapipe/solutions/genai)

## Suporte
Para problemas específicos:
1. Verifique os logs do Flutter
2. Consulte a documentação do flutter_gemma
3. Abra uma issue no repositório do plugin
