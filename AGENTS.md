# AGENTS.md

## Project Snapshot

Tryzeon is a Flutter application for AI virtual try-on, wardrobe management, and store-facing product operations.

This repository contains:
- A Flutter client app under `lib/`
- Supabase Edge Functions under `supabase/functions/`
- Firebase integration for analytics and crash reporting
- RevenueCat integration for subscription billing

The codebase is organized primarily by feature, with shared infrastructure in `lib/core`.

## Tech Stack

- Flutter
- Riverpod (`hooks_riverpod`, code generation via `riverpod_annotation`)
- GoRouter
- Supabase
- Firebase Analytics + Crashlytics
- RevenueCat
- Isar
- Freezed / JSON Serializable / AutoMappr / Envied code generation

## First Files To Read

When starting work, read these first:

1. `lib/main.dart`
2. `lib/core/router/app_router.dart`
3. The feature entry file relevant to the task
4. `pubspec.yaml`
5. `README.md`

If the task touches store flows, also inspect:

- `lib/feature/store/main/store_entry.dart`
- `lib/feature/store/profile/providers/store_profile_providers.dart`

If the task touches personal flows, also inspect:

- `lib/feature/personal/main/`
- `lib/feature/personal/profile/providers/personal_profile_providers.dart`

If the task touches backend behavior, inspect:

- `supabase/functions/_shared/`
- The specific function under `supabase/functions/<name>/`

## Runtime Entry Points

- App bootstrap: `lib/main.dart`
- Router: `lib/core/router/app_router.dart`
- Route definitions: `lib/core/router/routes/`
- Shell routes: `lib/core/router/shells/`
- Store app entry area: `lib/feature/store/main/`
- Personal app entry area: `lib/feature/personal/main/`

Important bootstrap behavior in `lib/main.dart`:

- Initializes Firebase before app start
- Enables Crashlytics and Analytics outside debug mode
- Initializes Supabase using generated env values
- Initializes RevenueCat and links current logged-in user when available
- Wraps app with `ProviderScope`

## Directory Map

### `lib/core`

Cross-feature infrastructure and shared app-level code.

- `config/`: env, app constants
- `di/`: global providers and dependency wiring
- `error/`: failures and exceptions
- `extensions/`: shared extension methods
- `modules/`: cross-cutting integrations such as analytics, location, RevenueCat
- `presentation/`: shared dialogs and widgets
- `router/`: navigation and redirect logic
- `shared/`: reusable domain concepts shared across features
- `theme/`: app theme
- `utils/`: helpers such as logging, validation, image helpers

Do not put feature-specific UI or business logic in `core` unless it is truly reused across multiple features.

### `lib/feature`

Feature-oriented code. Current major areas include:

- `auth/`
- `common/product_categories/`
- `personal/`
- `store/`
- `debug/`

Prefer adding code to the closest existing feature instead of creating new top-level shared folders.

### `lib/feature/personal`

User-facing flows such as:

- onboarding
- profile
- wardrobe
- shop
- chat
- subscription
- settings

### `lib/feature/store`

Store-owner-facing flows such as:

- onboarding
- home dashboard
- products
- analytics
- profile
- settings

### `supabase/functions`

Server-side Edge Functions. Current functions include:

- `tryon/`
- `chat/`
- `update-subscription/`
- `delete-account/`
- `cleanup-orphan-images/`

Shared backend helpers live in `supabase/functions/_shared/`.

## Common Layering Pattern

Most non-trivial features follow a layered structure similar to:

- `data/`
- `domain/`
- `presentation/`
- `providers/`

Common roles:

- `domain/entities`: core business objects
- `domain/usecases`: app actions and orchestration
- `domain/repositories`: abstractions
- `data/datasources`: remote/local data access
- `data/repositories`: repository implementations
- `data/models`: serialization and transport models
- `presentation/`: pages, widgets, dialogs, hooks, controllers
- `providers/`: Riverpod provider entry points

When changing data shape, check all impacted layers, not just the UI.

## Routing Rules

Navigation is not trivial. Before changing routes, read `lib/core/router/app_router.dart`.

Current router behavior includes:

- Auth gating
- Home redirection based on last login type
- Store onboarding interception
- Personal onboarding interception
- Deep-link exceptions for store paths

If you change:

- auth state behavior
- onboarding completion logic
- store profile loading
- personal profile loading
- deep-link paths

then re-check redirect behavior carefully. Router regressions are high risk.

## State Management Rules

- Riverpod is the default state management mechanism
- Prefer feature-scoped providers over global state
- Reuse existing provider patterns before introducing new abstractions
- If a feature already exposes use cases through providers, follow that pattern

Before adding a new provider, search the feature for an existing provider entry point.

## Backend Integration Rules

- Supabase is the main backend integration point
- Edge Functions live under `supabase/functions/`
- Shared server logic belongs in `supabase/functions/_shared/`
- Keep client-side assumptions aligned with server payloads

If you change an Edge Function contract, inspect:

- Flutter models
- mappers
- remote datasources
- repository implementations
- any calling UI state

## Generated Code

This repo uses code generation. After changing annotated files, generated files may need to be refreshed.

Common triggers:

- Riverpod annotations
- Freezed models
- JSON serializable models
- AutoMappr mappings
- Envied config
- Isar collections

Regenerate with:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Commands

Install dependencies:

```bash
flutter pub get
```

Run code generation:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Run the app:

```bash
flutter run
```

Run on a specific device:

```bash
flutter devices
flutter run -d <device-id>
```

Lint / normalize:

```bash
dart fix --apply
dart format .
```

Build Android APK:

```bash
flutter build apk
```

## Change Playbooks

### UI-only change

1. Find the page/widget under the relevant feature `presentation/` folder
2. Check related providers before changing behavior
3. Verify route entry points if navigation is affected
4. Run `dart format .`

### New field in a feature model

1. Update entity/value object
2. Update model and serialization
3. Update mapper
4. Update datasource and repository logic
5. Update use case if needed
6. Update provider/UI consumers
7. Run code generation if annotations are involved

### Route or onboarding change

1. Inspect `lib/core/router/app_router.dart`
2. Inspect the relevant profile providers
3. Validate both logged-in and logged-out flows
4. Validate onboarding-complete and onboarding-incomplete flows
5. Validate deep-link exceptions if store routes are involved

### Supabase function change

1. Update the target function
2. Reuse helpers from `_shared/` when possible
3. Confirm request/response shape
4. Update Flutter-side callers if contract changes

## Guardrails

- Prefer the existing feature-first structure
- Keep `core/` for truly cross-feature code
- Avoid introducing duplicate abstractions when a feature already has a repository/usecase/provider flow
- Do not bypass router redirect rules casually
- Do not assume store and personal flows behave the same
- Do not change backend contracts without checking the Flutter client
- Keep edits focused; avoid broad refactors unless the task requires them

## High-Risk Areas

- `lib/core/router/app_router.dart`
- Auth-related providers and login type resolution
- Store onboarding and personal onboarding gating
- Supabase function request/response contracts
- Analytics event flow and batching behavior
- Subscription behavior involving RevenueCat identity linkage
- Generated-code-backed models and providers

## Definition Of Done

Before considering work complete:

1. Relevant files compile logically and imports are clean
2. Formatting has been applied
3. Code generation has been run if required
4. Router impacts have been checked if navigation/auth/onboarding changed
5. Client/server contracts are aligned if backend changes were made
6. The smallest reasonable validation command has been run

If you are unsure where a change belongs, prefer the relevant feature folder first, then escalate to `core` only if the code is genuinely cross-cutting.
