# Firebase App Check - Configuração Completa

## 🔐 Impressão Digital SHA-256 (Debug)

```
FB:C5:E1:59:65:8C:6D:6C:2A:5F:07:B8:49:3F:A9:36:13:49:C5:D5:8C:07:64:CD:00:EB:B6:F3:9D:ED:29:52
```

## 📋 Passo a Passo no Firebase Console:

### 1. Acesso ao Console

- Acesse [Firebase Console](https://console.firebase.google.com/)
- Selecione seu projeto **MathQuest**
- Vá para **App Check** no menu lateral

### 2. Registrar Aplicativo Android

- Clique em **"Registrar aplicativo"**
- Escolha **Android**
- Selecione seu app da lista

### 3. Configurar Play Integrity

- **Provedor**: Selecione **"Play Integrity"**
- **Impressão digital SHA-256**: Cole a impressão acima
- **Vida útil do token**: Configure para **1 hora**

### 4. Aceitar Termos

✅ Aceite os **Termos de Serviço das APIs do Google**
✅ Aceite os **Termos de Serviço da API Play Integrity**

### 5. Configurações Avançadas (Opcional)

- **Modo de Imposição**: Deixe desabilitado durante desenvolvimento
- **Relatórios**: Habilite para monitoramento

## ✅ SDK Já Configurado

O SDK do Firebase App Check já foi adicionado ao projeto:

```yaml
# pubspec.yaml
dependencies:
  firebase_app_check: ^0.3.2+10
```

```dart
// main.dart
await FirebaseAppCheck.instance.activate();
```

## 🚀 Próximos Passos:

### Durante Desenvolvimento:

1. ✅ Registrar no Firebase Console (usar impressão SHA-256 acima)
2. ✅ SDK instalado e configurado
3. 🔄 Testar o app em modo debug
4. 📊 Verificar métricas no console

### Para Produção:

1. **Gerar certificado de produção**
2. **Extrair nova impressão SHA-256**
3. **Adicionar no Firebase Console**
4. **Ativar modo de imposição**

## 🔑 Comando para Certificado de Produção:

```powershell
& "D:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -alias <seu_alias> -keystore "caminho\para\release.keystore" -storepass <sua_senha>
```

## ⚠️ Notas Importantes:

- App Check é **opcional** durante desenvolvimento
- **Sempre teste** antes de ativar modo de imposição
- **Mantenha backup** das impressões digitais
- **Monitor metrics** no Firebase Console

## 🛠️ Troubleshooting:

- Se App Check falhar no Windows: **Normal** (não suportado)
- Erros de validação: Verifique impressão digital
- Problemas de conexão: Verifique configuração do projeto

---

**Status**: ✅ Configuração completa pronta para uso
