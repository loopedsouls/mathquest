# TODO: Integração com Firebase

Este arquivo descreve as etapas para integrar o Firebase ao projeto MathQuest.

## Etapas de Integração

1.  **Criar um Projeto no Firebase:**
    *   Acesse o [Console do Firebase](https://console.firebase.google.com/).
    *   Crie um novo projeto chamado `MathQuest`.
    *   Siga as instruções para configurar o projeto.

2.  **Configurar para cada Plataforma:**

    *   **Android:**
        *   Adicione um app Android no console do Firebase.
        *   Siga o assistente de configuração para baixar o arquivo `google-services.json` e coloque-o em `android/app/`.
        *   Adicione as dependências do Firebase ao `android/build.gradle.kts` e `android/app/build.gradle.kts`.

    *   **iOS:**
        *   Adicione um app iOS no console do Firebase.
        *   Siga o assistente de configuração para baixar o arquivo `GoogleService-Info.plist` e coloque-o em `ios/Runner/`.
        *   Use o Xcode para adicionar o arquivo ao projeto Runner.

    *   **Web:**
        *   Adicione um app Web no console do Firebase.
        *   Copie o snippet de configuração do Firebase.
        *   Adicione o snippet ao `web/index.html`.

3.  **Adicionar Dependências do FlutterFire:**
    *   Adicione as seguintes dependências ao `pubspec.yaml`:
        ```yaml
        dependencies:
          flutter:
            sdk: flutter
          firebase_core: ^<latest_version>
          firebase_auth: ^<latest_version>
          cloud_firestore: ^<latest_version>
          firebase_analytics: ^<latest_version>
        ```
    *   Execute `flutter pub get`.

4.  **Inicializar o Firebase no App:**
    *   No `lib/main.dart`, inicialize o Firebase antes de `runApp()`:
        ```dart
        import 'package:firebase_core/firebase_core.dart';
        import 'firebase_options.dart'; // Gerado pelo FlutterFire CLI

        void main() async {
          WidgetsFlutterBinding.ensureInitialized();
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          runApp(MyApp());
        }
        ```
    *   Use o FlutterFire CLI para gerar o `firebase_options.dart`:
        ```bash
        flutterfire configure
        ```

5.  **Integrar Funcionalidades do Firebase:**
    *   **Autenticação:** Implementar login com Email/Senha e/ou provedores OAuth (Google, etc.) usando `firebase_auth`.
    *   **Banco de Dados:** Migrar o banco de dados local (SQLite) para o Cloud Firestore para sincronização de dados na nuvem. Isso inclui:
        *   Progresso do usuário.
        *   Histórico de conversas.
        *   Conquistas.
    *   **Analytics:** Rastrear eventos importantes do app com `firebase_analytics` para entender o comportamento do usuário.
    *   **Crashlytics:** Configurar o Firebase Crashlytics para monitorar e corrigir falhas no aplicativo.
    *   **Remote Config:** Usar o Remote Config para permitir atualizações de configurações do app sem a necessidade de uma nova versão (ex: dificuldade de quizzes, mensagens de UI).

## Próximos Passos Imediatos

- [ ] Criar o projeto no Firebase Console.
- [ ] Configurar o app para Android e adicionar o `google-services.json`.
- [ ] Adicionar as dependências do Firebase no `pubspec.yaml`.
- [ ] Executar `flutterfire configure` para gerar as opções de inicialização.
- [ ] Modificar `lib/main.dart` para inicializar o Firebase.
