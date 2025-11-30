# MathQuest - AI Coding Agent Instructions

## Project Overview

**MathQuest** is a Flutter adaptive math tutoring system for Brazilian students (6º-9º ano), aligned with BNCC. Targets Web, Desktop (Windows/Linux/macOS), and Mobile with Firebase + offline support.

## Architecture: Clean Architecture

```
lib/
├── app/           # App config, routes, theme (AppTheme, AppColors, AppTextStyles)
├── core/          # Constants, errors, extensions, network utils
├── data/          # Data layer: datasources, models, repositories
│   ├── datasources/local/   # DatabaseService (SQLite), GamificationService
│   ├── datasources/remote/  # FirebaseService, AIService (OpenAI API)
│   ├── models/              # Data models (UserModel, ProgressModel, etc.)
│   └── repositories/        # Repository implementations (AuthRepositoryImpl)
├── domain/        # Entities, use cases (business logic contracts)
├── l10n/          # Localization (pt, en, es)
└── presentation/  # UI: screens, widgets, providers
    └── screens/   # auth/, home/, gameplay/, profile/, settings/, etc.
```

## Core Services & Data Flow

### AI Service ([firebase_service.dart](lib/data/datasources/remote/firebase_service.dart))
- Uses OpenAI API (gpt-3.5-turbo) for exercises, explanations, hints
- Check `AIService.isAvailable` before use (requires API key in `.env`)
- Methods: `gerarExercicioPersonalizado()`, `gerarExplicacaoMatematica()`, `avaliarResposta()`, `gerarDica()`

### Database Service ([data_database_service.dart](lib/data/datasources/local/data_database_service.dart))
- SQLite with desktop FFI support (`sqflite_common_ffi`)
- Tables: `progresso_usuario`, `estatisticas_modulo`, `cache_ia`, `conquistas_usuario`, `personagens_usuario`
- **Adding tables**: Increment `_databaseVersion`, add migration in `_onUpgrade()`

### Auth Repository ([auth_repository_impl.dart](lib/data/repositories/auth_repository_impl.dart))
- Firebase Auth with Google Sign-In
- Platform check: `_isFirebaseAvailable` returns false on Linux

## Platform-Specific Patterns

### Firebase Availability ([main.dart](lib/main.dart))
```dart
bool get firebaseAvailable => !Platform.isLinux && !kIsWeb ? true : kIsWeb;
// Always wrap Firebase calls in availability checks
if (firebaseAvailable) { await Firebase.initializeApp(...); }
```

### Desktop SQLite Initialization
```dart
if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
```

## Theme System ([app/theme/](lib/app/theme/))

- **Default**: Dark theme (`ThemeMode.dark`)
- Use `AppTheme`, `AppColors`, `AppTextStyles` - never hardcode colors
- **Critical**: Use `withValues(alpha: 0.5)` NOT `withOpacity(0.5)` (deprecated)

```dart
AppTheme.showSuccessSnackBar(context, 'Mensagem')
AppTheme.showErrorSnackBar(context, 'Erro')
Container(decoration: AppTheme.modernCardDark)
```

## State Management

**No external libraries** - vanilla StatefulWidget pattern:
```dart
class _MyScreenState extends State<MyScreen> {
  @override void initState() { super.initState(); _loadData(); }
  Future<void> _loadData() async {
    final data = await SomeService.getData();
    setState(() => _data = data);
  }
}
```

## AI Exercise Generation

```dart
// 1. Check availability
if (!AIService.isAvailable) { /* use cached content */ return; }

// 2. Generate exercise with BNCC context
final exercicio = await AIService.gerarExercicioPersonalizado(
  unidade: 'Números',       // BNCC unit
  ano: '6º ano',            // Grade level
  dificuldade: 'médio',     // fácil | médio | difícil
  tipo: 'multipla_escolha', // Exercise type
);

// 3. Cache result in SQLite
await DatabaseService.salvarPerguntaCache(...);
```

## Developer Workflow

### Before Committing
```bash
flutter analyze  # REQUIRED - catches common issues
```

### Web Deployment
```powershell
./deploy.ps1  # Builds with --base-href /mathquest/, deploys to gh-pages
```

### Environment Setup
Create `.env` file with `OPENAI_API_KEY=your_key` for AI features.

## Error Handling

- User-facing messages in **Portuguese**
- Use `AppTheme.showErrorSnackBar(context, 'Mensagem de erro')`
- Always check `context.mounted` before showing snackbars after async
- Firebase services may fail on Windows/Linux - wrap in try-catch, continue execution

## Anti-Patterns

- ❌ `withOpacity()` → ✅ `withValues(alpha:)`
- ❌ `flutter run/build` in agent responses → ✅ Use `flutter analyze` only
- ❌ Adding state management libs → ✅ Use StatefulWidget patterns
- ❌ Hardcoding colors → ✅ Use `AppTheme`/`AppColors`
- ❌ Assuming Firebase available → ✅ Check `firebaseAvailable`/`isAvailable`
- ❌ Skip SQLite migrations → ✅ Increment `_databaseVersion`
