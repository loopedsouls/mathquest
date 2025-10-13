# MathQuest - AI Coding Agent Instructions

## Project Overview

**MathQuest** is a Flutter adaptive mathematics tutoring system for Brazilian middle school students (6º-9º ano), aligned with BNCC curriculum standards. Supports Web, Desktop (Windows/Linux/macOS), and Mobile with online (Firebase AI/Gemini) and offline capabilities.

## Architecture: Feature-Based Structure

### Directory Organization

```
lib/features/
  ├── ai/              # BNCC module definitions, AI services
  ├── analytics/       # Analytics tracking
  ├── community/       # Community features
  ├── core/            # Theme (app_theme.dart), shared widgets
  ├── data/            # Data layer: DatabaseService, FirebaseAIService, FirestoreService
  ├── educational_content/  # Educational resources (arXiv, concepts)
  ├── learning/        # Quiz logic, gamification, exercises
  ├── math_tools/      # Math utilities
  ├── navigation/      # Navigation screens
  └── user/            # Auth, progress tracking, user models
```

**Key pattern**: Services are in `features/*/service/`, models in `features/*/models/`, screens throughout features.

### Core Services (Singletons)

1. **FirebaseAIService** (`features/data/service/firebase_ai_service.dart`)
   - Gemini 1.5 Flash integration for exercises, explanations, hints
   - Always check `FirebaseAIService.isAvailable` before use
   - Returns `null` on Linux or if Firebase unavailable

2. **DatabaseService** (`features/data/service/database_service.dart`)
   - SQLite with automatic desktop support via `sqflite_common_ffi`
   - Tables: `progresso_usuario`, `estatisticas_modulo`, `cache_ia`, `conquistas_usuario`
   - Platform detection: `_initializeDatabaseFactory()` handles Windows/Linux/macOS

3. **ProgressoServiceV2** (`features/user/services/progresso_service.dart`)
   - Migrates SharedPreferences → SQLite automatically (one-time via `_migratedKey`)
   - Caches `ProgressoUsuario` in memory (`_progressoCache`)
   - Core method: `carregarProgresso()` - always use this, not direct DB access

4. **GamificacaoService** (`features/learning/service/gamificacao_service.dart`)
   - Streak tracking, achievement unlocking
   - Uses SharedPreferences for lightweight data + DatabaseService for persistence

5. **AuthService** (`features/user/service/auth_service.dart`)
   - Wraps Firebase Auth with Linux platform checks
   - All methods return gracefully on unsupported platforms

### BNCC Content Structure

**Definition**: `features/ai/modulo_bncc.dart` (`ModuloBNCC` class + `ModulosBNCCData` static data)

```dart
ModuloBNCC {
  unidadeTematica: 'Números' | 'Álgebra' | 'Geometria' | 'Grandezas e Medidas' | 'Probabilidade e Estatística'
  subcategoria: e.g., 'Números Naturais e Inteiros'
  subSubcategoria: e.g., 'Números Naturais e Inteiros'
  anoEscolar: '6º ano' | '7º ano' | '8º ano' | '9º ano'
  prerequisitos: ['unidade_subcategoria_ano'] // Enforces sequential learning
  codigoBNCC: e.g., 'EF06MA'
}
```

**User Progression**: `ProgressoUsuario` (`features/user/models/progresso_user_model.dart`) tracks:
- `modulosCompletos`: Map<unidade, Map<ano, bool>>
- `nivelUsuario`: Calculated from sequential completion (iniciante → especialista)

## Platform-Specific Patterns

### Firebase Initialization (main.dart)

```dart
bool firebaseAvailable = !Platform.isLinux; // Global flag

void main() async {
  if (firebaseAvailable) {
    await Firebase.initializeApp(...);
    // Try-catch all Firebase services (AppCheck, Crashlytics, RemoteConfig)
    // App continues if any fail
  }
}
```

**Critical**: Always wrap Firebase calls in platform checks or `isAvailable` checks.

### SQLite Desktop Support

```dart
// DatabaseService pattern
static Future<void> _initializeDatabaseFactory() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
```

**When adding tables/columns**:
1. Increment `_databaseVersion` in `database_service.dart`
2. Add migration in `_onUpgrade(Database db, int oldVersion, int newVersion)`
3. Test migration from previous version

## Theme System (features/core/app_theme.dart)

**Default**: Dark theme (`ThemeMode.dark` in main.dart)

### Critical Color Usage

```dart
// ✅ Correct (Flutter 3.x)
Color.fromRGBO(255, 255, 255, 0.8).withValues(alpha: 0.5)

// ❌ Incorrect (deprecated)
Color.fromRGBO(255, 255, 255, 0.8).withOpacity(0.5)
```

### Common UI Patterns

```dart
// Modern card
Container(decoration: AppTheme.modernCardDark, ...)

// Gradients
LinearGradient(colors: AppTheme.modernGradient1, ...)

// Shadows
boxShadow: AppTheme.softShadow

// Snackbars
AppTheme.showSuccessSnackBar(context, 'Mensagem')
AppTheme.showErrorSnackBar(context, 'Erro')
```

## AI Integration Workflow

```dart
// 1. Check availability
if (!FirebaseAIService.isAvailable) {
  // Use cached questions from DatabaseService or fallback content
  return;
}

// 2. Generate with BNCC context
final exercicio = await FirebaseAIService.gerarExercicioPersonalizado(
  unidade: 'Números',
  ano: '6º ano',
  dificuldade: 'médio', // fácil | médio | difícil
  tipo: 'multipla_escolha', // verdadeiro_falso | completar
);

// 3. Cache result
if (exercicio != null) {
  await DatabaseService.salvarPerguntaCache(
    chaveCache: '${unidade}_${ano}_${tipo}_${dificuldade}_${timestamp}',
    unidade: unidade,
    ano: ano,
    tipoQuiz: tipo,
    dificuldade: dificuldade,
    pergunta: exercicio['pergunta'],
    opcoes: jsonEncode(exercicio['opcoes']),
    respostaCorreta: exercicio['resposta_correta'],
    fonteIA: 'firebase_ai',
  );
}
```

**Prompt structure** (always include):
- Year level (6º-9º ano)
- BNCC unit
- Difficulty level
- Age-appropriate language instruction ("linguagem apropriada para a idade")

## State Management Pattern

**No external libraries** (no Provider, BLoC, Riverpod).

### Screen pattern
```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  ProgressoUsuario? _progresso;
  
  @override
  void initState() {
    super.initState();
    _carregarDados();
  }
  
  Future<void> _carregarDados() async {
    final progresso = await ProgressoServiceV2.carregarProgresso();
    setState(() => _progresso = progresso);
  }
}
```

## Deployment

### GitHub Pages (Web)

```bash
# Run PowerShell script (handles everything)
./deploy.ps1
```

**What it does**:
1. Builds web with `--base-href /mathquest/`
2. Uses git worktree to avoid branch switching
3. Only commits if changes detected (checks `git status --porcelain`)

### Before Committing

```bash
flutter analyze  # Always run - catches common issues
```

**Note**: `avoid_print` is disabled in `analysis_options.yaml` (intentional for debugging).

## Common Tasks

### Adding New Achievement

1. Define in `features/user/conquista.dart` static list:
```dart
static final Conquista novaConquista = Conquista(
  id: 'id_unico',
  titulo: 'Título',
  descricao: 'Descrição',
  icone: Icons.star,
  categoria: 'progresso', // progresso | streak | tempo | modulos
  condicao: 'Condição legível',
);
```

2. Add check in `GamificacaoService`:
```dart
static Future<List<Conquista>> _verificarNovaConquista() async {
  final progresso = await ProgressoServiceV2.carregarProgresso();
  if (/* condição */) return [Conquista.novaConquista];
  return [];
}
```

3. Call in `registrarRespostaCorreta()` or `verificarConquistasModuloCompleto()`

### Creating New Quiz Screen

```dart
// 1. Load progress in initState
final progresso = await ProgressoServiceV2.carregarProgresso();

// 2. Generate or retrieve questions
final exercicio = await FirebaseAIService.gerarExercicioPersonalizado(...);

// 3. Track answer
await ProgressoServiceV2.registrarResposta(
  unidade: 'Números',
  ano: '6º ano',
  correta: true,
);

// 4. Check achievements
final conquistas = await GamificacaoService.registrarRespostaCorreta(
  unidade: 'Números',
  ano: '6º ano',
  tempoResposta: 10, // seconds
);
```

## Error Handling

### User-facing errors (Portuguese)
```dart
try {
  await operation();
} catch (e) {
  if (context.mounted) {
    AppTheme.showErrorSnackBar(context, 'Erro ao realizar operação');
  }
}
```

### Debug logging
```dart
import 'package:flutter/foundation.dart';

if (kDebugMode) {
  print('Debug info: $data');
}
```

### Firebase graceful degradation
```dart
try {
  await FirebaseCrashlytics.instance.recordError(...);
} catch (e) {
  // Firebase services may fail on Windows/Linux - continue execution
  if (kDebugMode) print('Firebase error: $e');
}
```

## Anti-Patterns (Don't Do)

- ❌ Don't use `withOpacity()` → Use `withValues(alpha:)`
- ❌ Don't call `flutter run`/`flutter build` in agent responses (per modus.instructions.md)
- ❌ Don't add state management libraries → Use existing patterns
- ❌ Don't skip SQLite migrations → Always increment version
- ❌ Don't assume Firebase AI availability → Check `isAvailable`
- ❌ Don't hardcode colors → Use `AppTheme` constants
- ❌ Don't modify BNCC modules without checking prerequisites chain

## Quick Debugging

**Problem**: Firebase not working
- Check `firebaseAvailable` flag in main.dart
- Verify platform is not Linux (Firebase disabled)
- Check console for initialization errors (wrapped in try-catch)

**Problem**: Progress not saving
- Verify migration ran (`_migratedKey` in SharedPreferences)
- Check `DatabaseService.database` initialized
- Confirm `ProgressoServiceV2.salvarProgresso()` called

**Problem**: AI not generating questions
- Check `FirebaseAIService.isAvailable`
- Fallback to `DatabaseService.buscarPerguntaCache()` or pre-defined content
- Verify prompt includes all required context (year, unit, difficulty)
