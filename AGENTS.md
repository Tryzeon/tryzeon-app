# AGENTS.md

## Working notes

- Design/spec docs under `docs/superpowers/` are gitignored and intentionally NOT committed. Write them there for reference, but never `git add -f` or commit them.
- The user manages commits themselves.
- Always propose the best-practice, long-term solution. Do not compromise the design to minimize change scope or migration effort, and don't accept "do it this way for now, refactor later" — optimize for correctness and quality, not for avoiding churn.
- Dart/Flutter conventions (theme, state management, errors, logging) live in `lib/CLAUDE.md`.
- **No code comments by default:** write self-explanatory code instead. Only annotate a non-obvious trade-off or constraint a reader cannot infer from the code — never restate what a symbol already says.
- Jira tickets: use the `acli` CLI to fetch ticket details instead of asking the user to paste them.

## Engineering principles

- **No backward-compatibility cruft:** delete the obsolete path outright instead of stacking a compatibility layer on top of it. This includes removed routes and URLs: no redirect or fallback for old links (e.g. links already sent in LINE messages) — update every in-repo reference and drop the route.
- **Grow in layers:** build the smallest working end-to-end version first, then add layers on top. Never replace something that works with a half-finished version.
- **Don't reinvent:** check the docs of existing dependencies first; if none fits, prefer a mature library over hand-rolled code.

## Common Commands

```bash
dart run build_runner build --delete-conflicting-outputs   # codegen: riverpod, freezed, json, isar, auto_mappr, envied
```

Code generation is required after editing any annotated file (`@riverpod`, `@freezed`, `@JsonSerializable`, Isar `@collection`, `@AutoMappr`, `@Envied`).

`Env` (`lib/core/config/env.dart`) is generated from a `.env` file via `envied`. The `.env` file must define all four keys or codegen fails: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `REVENUE_CAT_API_KEY`, `R2_PUBLIC_IMAGES_BASE_URL`.

## Architecture

### Architecture rules

Every feature follows Clean Architecture. When adding code, these are hard rules, not suggestions:

- **Layering:** `data/` (datasources, dtos/, Isar collections, repository impls, mappers) → `domain/` (entities, repository interfaces, usecases) → `presentation/` (pages, widgets). Presentation NEVER imports `data/` or the Supabase client. All DI/wiring providers live in the feature's top-level `providers/` folder — never under `presentation/providers/` (state notifiers used only by the UI may stay in `presentation/`, but anything that constructs datasources/repositories goes in `providers/`).
- **SDK clients come from DI:** third-party SDK clients (`SupabaseClient`, `Dio`, …) are provided once in `core/di/core_providers.dart`, and every datasource/service provider gets them with `ref.watch(...)` (template: `supabaseClientProvider`). `Supabase.instance` and other global singletons are read only inside that core provider, never in a feature provider, datasource, or service, so tests can swap the client with a provider override.
- **Usecases:** presentation/providers call usecases, never repositories directly. Usecases expose `call()` returning `Result<T, Failure>`. Multi-field inputs use a freezed params object (e.g. `CreateProductParams`) — never long positional argument lists. Name usecases as verb phrases without a `UseCase` suffix (`CreateProduct`, not `CreateProductUseCase`).
- **DTO boundary:** Supabase/JSON rows are decoded into `*Dto` classes (`data/dtos/`) only inside `data/`. DTOs and Isar caches each convert only to and from domain entities via auto_mappr — never `Dto ↔ Cache`. Mapprs follow module boundaries: one mappr per module (a sub-feature or a `feature/common/*` module), named after the module and kept in its `data/mappers/` (template: `wardrobe_mappr.dart`, `ProductSizeMappr`). Never a hub shared across a feature group, and never one mappr per type. A mapping lives in the module that defines its DTO and cache types, even with a single consumer, and other modules pull it in through `includes:`. The `common/store` mappr is `CommonStoreMappr` so it is not mistaken for the store feature. auto_mappr flattens `includes` transitively at codegen, so never list a mappr that is already reached through another include; that is a duplicate-mapping build error. The one exception is a conversion that merges a second source rather than copying field by field: a `*Request` derived from a query (a sealed option split into several params, pagination passed alongside the entity) is built by a `to*Request` function in `data/mappers/` (template: `toListShopProductsRequest`), and an entity combining a response with fields only the request knows is constructed in the repository, still converting each nested DTO through the mappr (template: `TryonRepositoryImpl.tryon`). Remote datasources return DTOs; local datasources take and return entities. Cache key columns the entity does not carry (e.g. `storeId`/`year`/`month`) are passed to the local datasource as arguments. Domain entities never expose `fromJson`/`toJson`. Name the top-level payload a datasource sends `*Request` (write-only, `toJson` only, e.g. `CreateProductRequest`); everything decoded — table rows and edge-function responses — and fragments nested inside a request are `*Dto`. Decode edge-function responses with `decodeFunctionResponse` on a `@JsonSerializable(checked: true)` DTO, so a malformed body surfaces as `ServerFailure`.
- **Remote writes:** repositories are keyed by aggregate root, not by table. A domain repository interface exposes one write method per aggregate-level intent (`createProduct`, `updateProduct`, `deleteProduct`), takes and returns domain types only, and never names a table or child table. Which tables that intent touches is a `data/` detail: the repository impl fans the aggregate out across its rows (template: `ProductRepositoryImpl.createProduct` writes `products` then `product_sizes`), and a child-entity change set (template: `ProductSizeDiff`) is a domain value computed in `domain/`, not a row plan. Intent lives in usecases, which also own business rules (e.g. `isOnboarded: true`). Two payload patterns inside the impl:
  - *Patch* (default): the repository takes a domain patch object (null = unchanged) and maps it to a `*Request` with `includeIfNull: false` (template: `UserProfileUpdate`).
  - *Diff*: for edit flows that must be able to clear a field, the interface takes `original` and `target` entities and the impl sends `jsonDiff` of their mapped DTOs' `toJson()`; server-owned columns are excluded on the DTO with `@JsonKey(includeToJson: false)`, never stripped in the datasource (template: store profile, product).

  `Err` means nothing was written remotely: after a successful remote write, a cache save/refresh failure logs and invalidates the cache, and the call returns `Ok`.
- **Module boundaries:** a feature may depend on another feature's `domain/` (entities, usecases, repository interfaces) or on `feature/common/*` — never on another feature's `data/` internals. If two features need the same DTO, promote the concept to `common/` or expose it through a domain contract. A feature may publish one public-API barrel `<feature>.dart` exporting its domain entities and decoders for its own wire rows (e.g. `decodeShopProductRow`); other features import that barrel, never `data/**` directly.
- **`feature/common/*` layout:** same nested layout as features (`domain/entities/`, not a flat `entities/` folder).
- **`core/modules/*` use the service pattern, not repository + usecase** (template: `location`). These are infrastructure (location, analytics, auth_identity, revenue_cat), not business features — abstract the capability behind an interface in `domain/services/`, put the implementation in `data/services/`, and keep domain types in `domain/entities/`. Consumers (providers, pages) depend on the interface, never the concrete impl or a raw datasource. Do NOT add a usecase layer here.
- **Wire names stay with their owner:** a table, storage bucket, edge-function, RPC or foreign-key name is a `static const` on the one datasource/service in `data/` that talks to it — never in `core` and never shared across features. If two features genuinely query the same table, the name lives in the `feature/common/*` module that owns that concept (template: `ProductSizeTable`); otherwise each datasource declares its own copy, since the server schema is the single source of truth. Error codes shared by every edge function (`supabase/functions/_shared/errors.ts`) are in `ApiErrorCode`. Route segments stay in `AppRoutes`. No raw strings at call sites.
- **Exception mapping:** extend `mapExceptionToFailure` with typed `is` checks when introducing a new error source. Never match on `toString()` contents, and never swallow errors with a bare `catch (_)` — at minimum log via `AppLogger`. Catch in the data layer (repository / service impl) and return `Result`; service interfaces return `Result` too. Usecases never catch — they compose `Result`s.
- **Isar cache invalidation:** a cached enum string that no longer decodes throws `CacheDecodeException` and the repository refetches that row, so renaming an enum value needs no bump. Bump `AppConstants.cacheSchemaVersion` in the same commit only for what strict decoding cannot see: adding or renaming an `@collection` field, or teaching the client an enum value the server already returns (old rows hold a tolerated fallback that still decodes cleanly). The bump wipes every collection, so it is not free.
- **Widgets stay thin:** no business logic (network calls, encoding, orchestration) inside `build()` or inline page callbacks — put it in a notifier/controller or usecase that returns `Result`.

### Analytics

Analytics pipeline (event batching → RPC → trigger → monthly summary) is documented in README.md §Analytics System.

