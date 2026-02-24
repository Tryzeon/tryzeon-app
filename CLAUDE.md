# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Run code generation (freezed, riverpod, auto_mappr, json_serializable, isar)
dart run build_runner build --delete-conflicting-outputs

# Run on simulator/emulator
flutter run

# Static analysis
dart analyze

# Auto-fix and format (formatter page_width is 90, set in analysis_options.yaml)
dart fix --apply && dart format .

# Build APK
flutter build apk
```

Run `dart analyze` and `dart fix --apply && dart format .` before finishing any task. Fix all errors and warnings.

## Architecture

### Clean Architecture + Vertical Slice Architecture

```
lib/
├── core/                        # Shared infrastructure
│   ├── config/                  # AppConfig (.env), AppConstants (all magic strings/numbers)
│   ├── di/                      # core_providers.dart (Riverpod wiring for core services)
│   ├── error/                   # sealed Failure hierarchy + mapExceptionToFailure()
│   ├── extensions/
│   ├── modules/                 # Cross-cutting modules (analytics, location)
│   ├── presentation/widgets/    # Shared presentational widgets (ErrorView, LoadingOverlay, etc.)
│   ├── shared/                  # Shared domain concepts (measurements)
│   ├── theme/                   # AppTheme (Material 3, GoogleFonts.notoSansTc)
│   └── data/services/           # CacheService, IsarService
├── feature/
│   ├── auth/                    # Authentication (shared by both user types)
│   ├── common/                  # Shared feature code (product_categories)
│   ├── personal/                # Consumer-facing features
│   │   ├── home, wardrobe, shop, chat, profile, settings, subscription
│   │   └── data/mappers/        # PersonalMappr (shared mapper for personal features)
│   └── store/                   # Store-owner features
│       ├── home, products, profile, settings, onboarding, analytics
│       └── data/mappers/        # StoreMappr (shared mapper for store features)
└── main.dart                    # Entry point: AppConfig.load() → Supabase.initialize() → ProviderScope
```

### Feature Slice Internal Layout

Each feature follows this structure:

```
feature/<user_type>/<feature>/
├── providers/          # Riverpod wiring: datasource → repository → usecase providers
├── data/
│   ├── datasources/    # Raw I/O (remote = Supabase, local = Isar)
│   ├── repositories/   # Implements domain repository interface
│   ├── models/         # Supabase JSON models (with .g.dart)
│   ├── collections/    # Isar local DB schemas
│   └── mappers/        # auto_mappr definitions (Model ↔ Entity ↔ Collection)
├── domain/
│   ├── entities/       # Freezed pure domain objects
│   ├── repositories/   # Abstract interfaces
│   └── usecases/       # One class per use case
└── presentation/
    ├── pages/
    └── widgets/
```

### Two User Types

The app has two entry points based on `UserType`: `PersonalEntry` (consumer) and `StoreEntry` (store owner). Auth determines which is shown.

## Key Patterns

### Error Handling — `typed_result`

All repository methods and use cases return `Future<Result<T, Failure>>`. No exceptions leak across the domain boundary.

- Repository impl: `try { return Ok(value); } catch (e, st) { return Err(mapExceptionToFailure(e)); }`
- UI consumption: pattern match with `case Ok(:final value)` / `case Err(:final error)`
- Failure types: `NetworkFailure`, `ServerFailure`, `AuthFailure`, `ValidationFailure`, `UnknownFailure` (sealed class in `core/error/failures.dart`)

### Entities — `freezed`

```dart
@freezed
sealed class MyEntity with _$MyEntity {
  const factory MyEntity({required final String id, final String? name}) = _MyEntity;
  const MyEntity._(); // only when custom methods are needed
}
```

All fields use `final`. Required fields first, then nullable/optional.

### Object Mapping — `auto_mappr`

Each feature has a `*_mappr.dart` file mapping between three types: `Model` (Supabase JSON), `Collection` (Isar DB), and `Entity` (domain). Mappers cover both directions.

```dart
@AutoMappr([
  MapType<MyModel, MyEntity>(),
  MapType<MyEntity, MyModel>(),
  MapType<MyModel, MyCollection>(fields: [Field('collectionField', from: 'modelField')]),
])
class MyMappr extends $MyMappr { const MyMappr(); }
```

### Riverpod Providers — Code Generation

All providers use `@riverpod` annotation with generated `.g.dart` files. Provider graph follows strict layering:

```
DataSource providers → Repository provider → UseCase providers (one per use case)
```

Core services (`isarServiceProvider`, `cacheServiceProvider`, `analyticsEventQueueServiceProvider`) come from `core/di/core_providers.dart`.

### Constants

**ALL** magic strings and numbers must go in `core/config/app_constants.dart` — Supabase table/bucket names, edge function names, asset paths, durations, business logic numbers, SharedPreferences keys.

### Theming

Material 3 with `ColorScheme.fromSeed`. Always use `Theme.of(context).colorScheme.*` and `Theme.of(context).textTheme.*` — never hardcode colors or font styles.

### Backend

- **Supabase**: Postgres DB, Storage buckets, Auth (PKCE flow), Edge Functions (Deno/TypeScript in `supabase/functions/`)
- **Local cache**: Isar DB with `CacheService` abstraction
- **Edge Functions**: `chat/`, `tryon/`, `delete-account/`, `cleanup-orphan-images/`

## Design Principles

- **UseCase doesn't trust UI**: Never rely on data directly passed from UI without validation
- **UseCase fetches its own data**: UseCases retrieve all data they need independently
- **UI passes intent, not results**: UI communicates user intentions, not pre-computed results

## Framework Usage

- Use **context7** MCP tools to query latest usage and best practices for frameworks (Flutter, Supabase, Riverpod, etc.)
- Ensure up-to-date, deprecation-free APIs

## Version Control

- **STRICTLY FORBIDDEN**: Do not use `git add`, `git commit`, or `git push`
- User will review and commit manually
