# Scan Checklist

For each category: read 2-3 representative files, extract the pattern, classify as **architectural** (agnostic) or **implementation** (Flutter/Dart-specific).

---

## 1. Project Foundation

| What to check | How |
|---|---|
| Directory structure | `find lib/ -type d` -- identify organization strategy (Clean Architecture, feature-first, layer-first, MVVM) |
| Dependencies | Full `pubspec.yaml` -- note exact versions and SDK constraints |
| Analysis options | `analysis_options.yaml` -- lint rules, includes (very_good_analysis, flutter_lints), custom rules |
| Build config | `build.yaml` -- build_runner options, code gen settings |
| Flavors | Multiple main_*.dart files, Android/iOS flavor configs, dart-define usage |
| Entry point | `main.dart` -- DI init, runApp, WidgetsFlutterBinding, error handling bootstrap |
| App widget | `app.dart` / `app_widget.dart` -- MaterialApp/CupertinoApp, theme, router, localization delegates |
| Assets | pubspec.yaml assets section, fonts section, asset directory structure |

**Architectural patterns to extract:** Directory organization strategy, separation of concerns boundaries, dependency flow (domain -> data -> presentation or other).

**Implementation patterns to extract:** Specific DI setup, provider wrapping order in main.dart, build flavor configuration, analysis_options rules.

---

## 2. Architecture

| What to check | Read example of |
|---|---|
| Layer separation | Are data/domain/presentation separate? Per-feature or at root? |
| Feature structure | What goes inside each feature folder? (bloc, models, pages, widgets, repository) |
| Barrel files | Do features export via a single file? (e.g., `feature_name.dart` with exports) |
| Core / Shared | What lives in core/ or shared/ vs features/? |
| Dependency direction | Does domain depend on data? (it should NOT in Clean Architecture) |
| Abstract interfaces | Are repository contracts defined as abstract classes in domain? |

**Extract as architectural:**
```
- Clean Architecture: data/ (API + DB) -> domain/ (entities + use cases + repo interfaces) -> presentation/ (BLoC + pages + widgets)
- Dependency rule: domain has NO imports from data or presentation
- Each feature: self-contained vertical slice with its own data/domain/presentation
- Shared: core/ for cross-feature utilities (network, errors, DI, theme, extensions)
```

---

## 3. Widgets / Components

| What to check | Read example of |
|---|---|
| Widget composition | How are large screens decomposed into smaller widgets? |
| Stateless vs Stateful | Ratio and when each is used |
| Custom widgets | Shared widgets in widgets/ or components/ directory |
| Widget parameters | Named parameters, required vs optional, callback types |
| Builder pattern | Use of Builder, LayoutBuilder, BlocBuilder, Consumer |
| Widget keys | When and how Key is used |
| Const constructors | Are widgets declared with const? |

**Extract as implementation (example):**
```dart
// Reusable widget pattern
class {Entity}Card extends StatelessWidget {
  const {Entity}Card({
    super.key,
    required this.{entity},
    this.onTap,
    this.onLongPress,
  });

  final {Entity} {entity};
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text({entity}.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text({entity}.description, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 4. Data Layer

| What to check | Read example of |
|---|---|
| HTTP client | Dio/http instance -- interceptors, base URL, token injection, error handling |
| Interceptors | Auth token injection, refresh token, error transformation, logging |
| API response models | fromJson/toJson -- manual, json_serializable, or Freezed |
| DTOs vs Entities | Separate DTO (data layer) and Entity (domain layer)? Or shared models? |
| Mappers | How DTOs convert to domain entities (extension, mapper class, toEntity method) |
| Repository pattern | Abstract in domain, implementation in data -- or single concrete class? |
| Data sources | Remote + Local data sources as separate classes? |
| Error handling | How API errors become domain Failures (try/catch, Either type from dartz/fpdart) |
| Response envelope | Is there a standard API response wrapper? |

**Extract as architectural:**
```
- Repository interface in domain/, implementation in data/
- Remote + Local data sources injected into repository
- DTO -> Entity mapping via extension method or mapper class
- Errors caught in repository, returned as Either<Failure, Entity>
- Dio instance configured once with interceptors: auth, error, logging
```

**Extract as implementation (example):**
```dart
// DTO with Freezed
@freezed
class {Entity}DTO with _${Entity}DTO {
  const factory {Entity}DTO({
    required String id,
    required String name,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _{Entity}DTO;

  factory {Entity}DTO.fromJson(Map<String, dynamic> json) =>
      _${Entity}DTOFromJson(json);
}

// Mapper extension
extension {Entity}DTOMapper on {Entity}DTO {
  {Entity} toEntity() => {Entity}(
    id: id,
    name: name,
    createdAt: createdAt,
  );
}

// Repository implementation
@override
Future<Either<Failure, {Entity}>> getById(String id) async {
  try {
    final response = await remoteDataSource.getById(id);
    return Right(response.toEntity());
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  }
}
```

---

## 5. State Management

| What to check | Read example of |
|---|---|
| Library choice | BLoC/Cubit, Riverpod, Provider, GetX, MobX, or vanilla |
| BLoC: events + states | How events are defined (sealed class, Freezed union), state shape |
| BLoC: data loading | How BLoC calls repository, emits loading/success/error states |
| Cubit: methods + states | Simpler than BLoC -- methods replace events |
| Riverpod: provider types | StateNotifierProvider, FutureProvider, StreamProvider, NotifierProvider |
| Provider: ChangeNotifier | How ChangeNotifier classes are structured |
| GetX: controllers | Rx observables, .obs, Obx() |
| State restoration | How state persists across app restarts (if applicable) |
| Widget connection | BlocBuilder, BlocListener, BlocConsumer, Consumer, watch, ref.watch |

**Extract as implementation (BLoC example):**
```dart
// Events (sealed or abstract)
sealed class {Entity}Event {}
class Load{Entities} extends {Entity}Event {}
class Create{Entity} extends {Entity}Event {
  final Create{Entity}Params params;
  const Create{Entity}(this.params);
}

// States (sealed or with Freezed)
sealed class {Entity}State {}
class {Entity}Initial extends {Entity}State {}
class {Entity}Loading extends {Entity}State {}
class {Entity}Loaded extends {Entity}State {
  final List<{Entity}> items;
  const {Entity}Loaded(this.items);
}
class {Entity}Error extends {Entity}State {
  final String message;
  const {Entity}Error(this.message);
}

// BLoC
class {Entity}Bloc extends Bloc<{Entity}Event, {Entity}State> {
  final Get{Entities}UseCase _get{Entities};

  {Entity}Bloc({required Get{Entities}UseCase get{Entities}})
      : _get{Entities} = get{Entities},
        super({Entity}Initial()) {
    on<Load{Entities}>(_onLoad);
  }

  Future<void> _onLoad(Load{Entities} event, Emitter<{Entity}State> emit) async {
    emit({Entity}Loading());
    final result = await _get{Entities}();
    result.fold(
      (failure) => emit({Entity}Error(failure.message)),
      (items) => emit({Entity}Loaded(items)),
    );
  }
}
```

---

## 6. Navigation & Routing

| What to check | Read example of |
|---|---|
| Router library | GoRouter, AutoRoute, Navigator, GetX routing |
| Route definition | How routes are declared (GoRoute, @RoutePage, MaterialPageRoute) |
| Route guards / redirect | Auth checks, role-based access, redirect logic |
| Deep linking | Path parameters, query parameters, URI parsing |
| Path constants | Enum, static const, or inline strings for paths |
| Nested navigation | Shell routes, tab navigation with nested stacks |
| Transition animations | Custom page transitions |

**Extract as architectural:**
```
- Routes defined declaratively in a single router file
- Path constants as static members: {Feature}Routes.detail
- Auth guard redirects unauthenticated users to /login
- Deep linking supported with path parameters: /{resource}/:id
- Bottom navigation uses ShellRoute / nested navigators
```

**Extract as implementation (GoRouter example):**
```dart
final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isAuth = ref.read(authProvider).isAuthenticated;
    if (!isAuth && !state.matchedLocation.startsWith('/auth')) {
      return '/auth/login';
    }
    return null;
  },
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/{resource}',
          builder: (context, state) => const {Entity}ListPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return {Entity}DetailPage(id: id);
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
```

---

## 7. Forms & Validation

| What to check | Read example of |
|---|---|
| Form approach | Form + TextFormField, reactive_forms, flutter_form_builder |
| Validation | Built-in validators, custom validators, validator functions |
| Form state | How form state is managed (FormKey, reactive form group, BLoC) |
| Error display | How validation errors are shown (InputDecoration.errorText, snackbar) |
| Submit flow | Form validation -> BLoC event / repository call -> success/error handling |
| Complex forms | Multi-step forms, dynamic fields, dependent dropdowns |

**Extract as implementation (example):**
```dart
// Form with built-in validation
class Create{Entity}Form extends StatefulWidget {
  const Create{Entity}Form({super.key, required this.onSubmit});
  final ValueChanged<Create{Entity}Params> onSubmit;

  @override
  State<Create{Entity}Form> createState() => _Create{Entity}FormState();
}

class _Create{Entity}FormState extends State<Create{Entity}Form> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSubmit(Create{Entity}Params(name: _nameController.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (value) => (value?.isEmpty ?? true) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _submit, child: const Text('Create')),
        ],
      ),
    );
  }
}
```

---

## 8. Dependency Injection

| What to check | Read example of |
|---|---|
| DI library | get_it + injectable, Riverpod, GetX, manual |
| Registration | Lazy singletons, factories, named instances |
| Module organization | Single file vs modular (per-feature or per-layer) |
| Initialization | When DI runs (before runApp, in main.dart) |
| Scoping | Feature-scoped vs app-wide registrations |

**Extract as implementation (get_it + injectable example):**
```dart
// injection_container.dart
final sl = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async => sl.init();

// Module registration
@module
abstract class {Feature}Module {
  @lazySingleton
  {Entity}Repository get {entity}Repository =>
      {Entity}RepositoryImpl(remoteDataSource: sl(), networkInfo: sl());

  @injectable
  {Entity}Bloc get {entity}Bloc => {Entity}Bloc(get{Entities}: sl());
}
```

---

## 9. UI & Theming

| What to check | Read example of |
|---|---|
| Design system | Material, Cupertino, or custom |
| ThemeData | How themes are defined (light, dark, custom colors) |
| ColorScheme | Custom ColorScheme or Material defaults |
| TextTheme | Custom text styles, GoogleFonts, font families |
| Spacing | Consistent spacing constants or ad-hoc values |
| Responsive | LayoutBuilder, MediaQuery, responsive_framework, flutter_screenutil |
| Dark mode | ThemeMode toggle, system-responsive, persistent preference |
| Custom theme extensions | ThemeExtension<T> for custom tokens |

**Extract as implementation (example):**
```dart
// theme.dart
class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    textTheme: GoogleFonts.interTextTheme(),
    appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
  );
}
```

---

## 10. Testing

| What to check | Read example of |
|---|---|
| Test types | Unit, widget, integration, golden |
| File location | test/ mirrors lib/ structure, or flat? |
| Mocking | mockito (code gen) or mocktail (manual)? |
| BLoC testing | bloc_test package, `blocTest()` helper |
| Widget testing | WidgetTester, pumpWidget, finder patterns |
| Test data | Fixtures, factories, fake implementations |
| Setup | setUp/tearDown, custom helpers, dependency overrides |
| Coverage | What they prioritize: BLoC logic? Repositories? Widgets? |

**Extract as architectural:**
```
- Tests mirror lib/ directory structure
- BLoC tests use blocTest() for event -> state verification
- Repository tests mock data sources
- Widget tests use pumpWidget with dependency overrides
- Test data via factory functions or constant fixtures
```

**Extract as implementation (example):**
```dart
// BLoC test
blocTest<{Entity}Bloc, {Entity}State>(
  'emits [Loading, Loaded] when Load{Entities} succeeds',
  build: () {
    when(() => mockGet{Entities}())
        .thenAnswer((_) async => Right([test{Entity}]));
    return {Entity}Bloc(get{Entities}: mockGet{Entities});
  },
  act: (bloc) => bloc.add(Load{Entities}()),
  expect: () => [
    {Entity}Loading(),
    {Entity}Loaded([test{Entity}]),
  ],
);

// Widget test
testWidgets('{Entity}Card displays name', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: {Entity}Card({entity}: test{Entity}),
    ),
  );
  expect(find.text(test{Entity}.name), findsOneWidget);
});
```

---

## 11. Coding Style Fingerprint

This section captures the **personal coding style** of the team -- not WHAT they build but HOW they write Dart code. Read 5-6 diverse files to extract these signals.

| Signal | What to look for |
|---|---|
| `final` vs `var` vs explicit types | `final name = ...` or `String name = ...` or `var name = ...`? |
| Named vs positional parameters | `{required String name}` or `String name`? When each? |
| Trailing commas | Enforced everywhere (Flutter formatter-friendly) or omitted? |
| Cascade notation `..` | Used for builder-style object configuration? |
| Extension methods | Custom extensions on String, BuildContext, etc.? How many? |
| `const` constructors | Used on every widget? Only where necessary? |
| `typedef` vs `Function` type | `typedef Callback = void Function(String)` or inline `void Function(String)`? |
| Pattern matching (Dart 3+) | `switch` expressions, `if-case`, destructuring? |
| Records (Dart 3+) | `(String, int)` record types? |
| Sealed classes | Sealed class hierarchies for states/events? Or abstract + extends? |
| `part` / `part of` | Used for Freezed code gen only? Or also for file splitting? |
| Import organization | `dart:` -> `package:` -> relative? Sorted? Grouped with blank lines? |
| String interpolation | `'Hello $name'` or `'Hello ${name}'` (always braces)? |
| Null safety patterns | `?.` vs `!` vs `late` vs `required` -- which patterns dominate? |
| Doc comments `///` vs `//` | Public API documented with `///`? Or minimal comments? |
| Guard clauses | Early returns at top of methods or nested if/else? |
| File length | Short focused files (<100 lines) or large files (300+ lines)? |
| Enum style | Dart enhanced enums with methods? Or simple enums + switch? |

**Extract as a style profile:**
```
CODING STYLE PROFILE:
- Variables: final by default, explicit types for complex objects
- Parameters: named + required for widgets, positional for simple functions
- Trailing commas: enforced (flutter format friendly)
- Cascades: used for configuring Dio, Paint, etc.
- Extensions: heavy use on BuildContext, String, DateTime
- Const: all widget constructors are const
- Null safety: ?. everywhere, ! only in test code, late for controllers
- Imports: dart: -> package: -> relative, no blank line separators
- Comments: /// for public API, // TODO for incomplete work, minimal inline
- Files: short (<150 lines), one widget per file
- Sealed classes: for BLoC states and events (Dart 3+)
```

---

## 12. Inconsistencies & Anti-patterns

Look for places where the team does NOT follow their own patterns. These are critical to document so the generated skill avoids reproducing mistakes.

| What to look for | Why it matters |
|---|---|
| Screens with business logic (not in BLoC/provider) | Some files may bypass the state management layer |
| Direct HTTP calls in widgets | Should go through repository/data source |
| Models without fromJson/toJson | Inconsistent serialization |
| Mixed state management (BLoC in one feature, setState in another) | Migration in progress or inconsistency |
| Raw strings for routes (not using path constants) | Naming drift |
| Widgets not using const constructor | Performance and lint inconsistency |
| Inconsistent error handling (try/catch in some, Either in others) | No unified strategy |
| Generated files committed (.g.dart, .freezed.dart) vs gitignored | Build process inconsistency |

**Document as:**
```
INCONSISTENCIES FOUND:
- lib/features/legacy_dashboard/ -- calls Dio directly, bypasses repository
  -> AVOID: always use repository pattern
- lib/features/settings/ -- uses setState, rest of app uses BLoC
  -> AVOID: always use BLoC for state management
- 3 of 10 models lack Freezed annotations, use manual fromJson
  -> RULE: every model MUST use Freezed + json_serializable
- Some routes use string literals, others use constants
  -> RULE: always use route constants

DECISION: When inconsistency found, follow the MAJORITY pattern (the one used most).
```

---

## 13. Advanced (if present)

Only scan these if they exist in the project:

### Platform Channels
- MethodChannel / EventChannel usage
- Platform-specific implementations (android/, ios/)
- Pigeon for type-safe platform communication

### Firebase Integration
- Firebase initialization pattern
- Firestore data access patterns
- Auth flow with Firebase Auth
- Push notifications setup

### Animations
- Implicit animations (AnimatedContainer, AnimatedOpacity)
- Explicit animations (AnimationController, Tween)
- flutter_animate, Rive, Lottie usage
- Hero transitions, page transitions

### Code Generation
- build_runner workflow and configuration
- Freezed model patterns (union types, copyWith, when/map)
- Retrofit API interface definitions
- Injectable module registration
- Auto-generated route setup

### i18n / Localization
- ARB file structure
- Localization delegate setup
- How strings are accessed (context.l10n, S.of(context), tr())
- Pluralization and parameterized strings

### Performance
- const widget usage
- RepaintBoundary placement
- ListView.builder for long lists
- Image caching strategies
- Compute / Isolate for heavy work
- Deferred loading (deferred as)
