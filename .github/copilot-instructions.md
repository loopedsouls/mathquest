# MathQuest - AI Coding Agent Instructions

## Project Overview

**MathQuest** is a Flutter-based adaptive mathematics tutoring system for Brazilian middle school students (6th-9th grade), aligned with BNCC (Brazilian National Common Curricular Base) standards. The app provides intelligent quiz generation, progress tracking, gamification, and both online (Firebase AI/Gemini) and offline capabilities.

## Core Architecture

### Tech Stack

- **Frontend**: Flutter 3.1.3+ (cross-platform: Web, Desktop, Mobile)
- **Backend**: Firebase suite (Auth, Firestore, Analytics, Crashlytics, Remote Config, App Check)
- **AI**: Firebase AI (Gemini 1.5 Flash) for exercise generation and explanations
- **Local Storage**: SQLite (via sqflite_common_ffi) with migration from SharedPreferences
- **Theme**: Material 3 with custom dark theme as default

### Key Services Architecture

Services are located in `lib/services/` and follow singleton patterns:

1. **FirebaseAIService** (`firebase_ai_service.dart`): Gemini integration for generating exercises, explanations, hints, and feedback. All prompts are contextualized for BNCC standards and age-appropriate language.

2. **DatabaseService** (`database_service.dart`): SQLite operations with automatic desktop support (Windows/Linux/macOS via sqflite_ffi). Handles progress, statistics, AI cache, and achievements.

3. **ProgressoServiceV2** (`progresso_service.dart`): Manages user progress with automatic migration from SharedPreferences to SQLite. Tracks module completion, user level, and accuracy rates.

4. **GamificacaoService** (`gamificacao_service.dart`): Achievement system with streaks, time-based rewards, and module completion tracking.

5. **AuthService** (`auth_service.dart`): Firebase Authentication wrapper with error handling in Portuguese.

6. **FirestoreService** (`firestore_service.dart`): Cloud persistence layer for syncing local SQLite data.

### BNCC Module Structure

All content follows `ModuloBNCC` model (`lib/models/modulo_bncc.dart`):

- **5 Thematic Units**: Números, Álgebra, Geometria, Grandezas e Medidas, Probabilidade e Estatística
- **Hierarchical**: Unit → Subcategory → Sub-subcategory → Year (6º-9º)
- **Prerequisites**: Modules can declare dependencies on earlier year modules
- **Progression**: User level advances based on completed modules per year

### Data Flow Pattern

```
User Action → Screen → Service → DatabaseService (SQLite) → (Optional) FirestoreService (Cloud)
                           ↓
                    FirebaseAIService (for AI features)
```

## Critical Conventions

### File Organization

- **Screens**: `lib/screens/` - All UI screens with `*_screen.dart` naming
- **Models**: `lib/models/` - Data structures (ProgressoUsuario, ModuloBNCC, Conquista, etc.)
- **Services**: `lib/services/` - Business logic and external integrations
- **Widgets**: `lib/widgets/` - Reusable UI components (e.g., app_initializer.dart, modern_components.dart)
- **Theme**: `lib/theme/app_theme.dart` - Centralized color scheme and text styles
- **Unused**: `lib/unused/` - Deprecated code kept for reference

### State Management

- **StatefulWidgets** with local state for screens
- **Service singletons** for shared state (cached in memory, persisted to SQLite)
- **SharedPreferences** for simple config (AI preferences, last sync time)
- **No external state management** library (no Provider, Riverpod, BLoC)

### Firebase Integration

- Initialized in `main.dart` with error handling for platforms where services may fail (Windows)
- **App Check**: Activated with graceful degradation
- **Crashlytics**: Enabled but doesn't block on failure
- **Remote Config**: Configured with 1-hour minimum fetch interval
- **FirebaseAIService**: Always check `isAvailable` before use; fallback to offline mode

### SQLite Migration Pattern

When adding new tables or columns:

1. Update `_databaseVersion` in `database_service.dart`
2. Implement migration in `_onUpgrade` method
3. Add corresponding service methods
4. Test migration from previous version

### AI Integration

- **Primary**: Firebase AI (Gemini 1.5 Flash) for personalized content
- **Prompt structure**: Always include year, BNCC unit, difficulty level, and age-appropriate language instruction
- **Caching**: Store generated questions in SQLite (`cache_ia` table) to reduce API calls
- **Fallback**: If Firebase AI unavailable, use cached questions or pre-defined content

### Theme Usage

- **Always dark theme** by default (`ThemeMode.dark` in main.dart)
- Use `AppTheme` constants for colors: `AppTheme.primaryColor`, `AppTheme.darkBackgroundColor`, etc.
- Modern design with glassmorphism (`modernGlassCard`), shadows (`cardShadow`), and gradients
- **Avoid `withOpacity`**: Use `withValues(alpha: 0.0-1.0)` for Flutter 3.x compatibility
- Snackbars: Use `AppTheme.showSuccessSnackBar()`, `showErrorSnackBar()`, etc.

### Error Handling

- **User-facing errors**: Display in Portuguese with `AppTheme.showErrorSnackBar()`
- **Debug logging**: Use `if (kDebugMode) { print(...) }` from `package:flutter/foundation.dart`
- **Firebase failures**: Wrap in try-catch with graceful degradation
- **SQLite errors**: Log but don't crash; fallback to in-memory data

## Development Workflows

### Running the App

```powershell
# Web (GitHub Pages compatible)
flutter run -d chrome

# Desktop (Windows)
flutter run -d windows

# Build APK
flutter build apk --debug
```

### Deployment to GitHub Pages

Use `deploy.ps1` script (PowerShell):

```powershell
.\deploy.ps1
```

- Builds web with `--base-href /mathquest/`
- Uses git worktree to avoid branch switching
- Only commits if changes detected

### Code Quality

```powershell
# Always run before committing
flutter analyze
```

- `analysis_options.yaml` extends `package:flutter_lints/flutter.yaml`
- `avoid_print` is ignored (intentional for debugging)

### Firebase Setup (Manual)

- **Web**: Add Firebase config snippet to `web/index.html`
- **iOS**: Add `GoogleService-Info.plist` to `ios/Runner/`
- **Android**: Already configured with `google-services.json`

## Common Patterns & Examples

### Creating a New Quiz Screen

```dart
// 1. Extend StatefulWidget in lib/screens/
class MyQuizScreen extends StatefulWidget {
  final String unidade;
  final String ano;
  const MyQuizScreen({super.key, required this.unidade, required this.ano});
  @override
  State<MyQuizScreen> createState() => _MyQuizScreenState();
}

// 2. Load progress in initState
@override
void initState() {
  super.initState();
  _carregarProgresso();
}

Future<void> _carregarProgresso() async {
  final progresso = await ProgressoServiceV2.carregarProgresso();
  setState(() { /* update UI */ });
}

// 3. Use FirebaseAIService for questions
final exercicio = await FirebaseAIService.gerarExercicioPersonalizado(
  unidade: widget.unidade,
  ano: widget.ano,
  dificuldade: 'médio',
  tipo: 'multipla_escolha',
);

// 4. Cache in SQLite
if (exercicio != null) {
  await DatabaseService.salvarPerguntaCache(
    unidade: widget.unidade,
    ano: widget.ano,
    tipoQuiz: 'multipla_escolha',
    dificuldade: 'médio',
    pergunta: exercicio['pergunta'],
    opcoes: exercicio['opcoes'],
    respostaCorreta: exercicio['resposta_correta'],
    fonteIA: 'firebase_ai',
  );
}
```

### Adding a New Achievement

```dart
// 1. Define in lib/models/conquista.dart (add to static list)
static final Conquista minhaConquista = Conquista(
  id: 'minha_conquista',
  titulo: 'Título',
  descricao: 'Descrição',
  icone: Icons.star,
  categoria: 'progresso',
  condicao: 'Complete X módulos',
);

// 2. Check in GamificacaoService
static Future<List<Conquista>> _verificarMinhaConquista() async {
  final progresso = await ProgressoServiceV2.carregarProgresso();
  if (progresso != null && /* condição */) {
    return [Conquista.minhaConquista];
  }
  return [];
}

// 3. Call in registrarRespostaCorreta or verificarConquistasModuloCompleto
novasConquistas.addAll(await _verificarMinhaConquista());
```

### Styling with AppTheme

```dart
// Card with modern styling
Container(
  decoration: AppTheme.modernCardDark, // or modernCard for light
  padding: EdgeInsets.all(AppTheme.padding),
  child: Text(
    'Conteúdo',
    style: AppTheme.headingMedium.copyWith(color: AppTheme.darkTextPrimary),
  ),
)

// Button
ElevatedButton(
  style: AppTheme.elevatedButtonStyle,
  onPressed: () {},
  child: Text('Botão'),
)

// Gradient background
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: AppTheme.modernGradient1,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
)
```

## Testing Strategy

- **Manual testing**: Primary approach for UI flows
- **Firebase AI testing**: Use `teste_firebase_ai_screen.dart` (accessible from main menu)
- **Unit tests**: Not currently implemented (add to `test/` if needed)
- **Platform testing**: Always test on Windows (desktop) and Web (GitHub Pages) before deploying

## Key Files to Reference

- **Entry point**: `lib/main.dart` - Firebase initialization, theme setup, auth wrapper
- **Navigation**: `lib/screens/start_screen.dart` - Main dashboard after login
- **Module data**: `lib/models/modulo_bncc.dart` - All BNCC curriculum content
- **Progress tracking**: `lib/services/progresso_service.dart` - Core progression logic
- **DB schema**: `lib/services/database_service.dart` - SQLite table definitions
- **Theme system**: `lib/theme/app_theme.dart` - All colors, text styles, shadows

## Don't Do

- Don't use `withOpacity()` - use `withValues(alpha:)` instead
- Don't add new state management libraries - use existing patterns
- Don't execute `flutter run` or `flutter build` in response to user requests (per modus.instructions.md)
- Don't bypass SQLite migration - always increment version and add migration code
- Don't assume Firebase AI is available - always check and provide fallback
- Don't modify BNCC module structure without understanding prerequisites and progression logic

## Quick Reference Commands

```powershell
# Analyze code quality (always run this!)
flutter analyze

# Deploy to GitHub Pages
.\deploy.ps1

# Clean build
flutter clean; flutter pub get

# Check SQLite database stats
# (Use DatabaseService.obterEstatisticasGerais() in code)
```

## Questions to Ask When Stuck

1. Does this screen need Firebase Auth? (Most do - check `AuthWrapper`)
2. Should this data be cached in SQLite? (Quiz questions, progress - yes; temporary UI state - no)
3. Is this BNCC-aligned? (Check against `ModuloBNCC` definitions)
4. Does this work offline? (Firebase AI requires fallback; SQLite works always)
5. Is the theme consistent? (Use `AppTheme` constants, not hardcoded colors)
