# Per-Product Analytics Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace store-level analytics with per-product analytics, lift the month filter to the home page, and display per-product metrics on each product card.

**Architecture:** New `analytics_product_monthly_summary` Supabase table replaces `analytics_monthly_summary`. A single provider fetches all product summaries for the store, shared by both the traffic dashboard (which sums them for store totals) and each product card. The month filter is extracted from `StoreTrafficDashboard` into a standalone widget at the home page level.

**Tech Stack:** Flutter, Riverpod (code-gen), Freezed, json_serializable, auto_mappr, Isar, Supabase (Postgres RPC)

---

## Task 1: Backend — Create `analytics_product_monthly_summary` table and update RPC

> This task is done in Supabase Dashboard / SQL Editor, not in Flutter code.

**Step 1: Create the new table**

Run in Supabase SQL Editor:

```sql
CREATE TABLE analytics_product_monthly_summary (
  store_id TEXT NOT NULL,
  product_id TEXT NOT NULL,
  year INT NOT NULL,
  month INT NOT NULL,
  view_count INT NOT NULL DEFAULT 0,
  tryon_count INT NOT NULL DEFAULT 0,
  purchase_click_count INT NOT NULL DEFAULT 0,
  PRIMARY KEY (store_id, product_id, year, month)
);

-- Index for querying all products by store + time
CREATE INDEX idx_apms_store_time
  ON analytics_product_monthly_summary (store_id, year, month);

-- RLS
ALTER TABLE analytics_product_monthly_summary ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Store owners can read their own product analytics"
  ON analytics_product_monthly_summary
  FOR SELECT
  USING (store_id IN (
    SELECT id FROM store_profiles WHERE user_id = auth.uid()
  ));
```

**Step 2: Update `update_analytics_summary` Trigger Function**

Modify the existing event logging trigger (or RPC) to upsert into `analytics_product_monthly_summary`. Since we are focusing on per-product analytics, you need to include `product_id` in the `INSERT` and `ON CONFLICT` clauses:

```sql
declare
  v_year int;
  v_month int;
begin
  -- Extract date parts
  v_year := extract(year from new.created_at);
  v_month := extract(month from new.created_at);

  -- Upsert (Insert or Update) into the per-product summary
  insert into analytics_product_monthly_summary (
    store_id, 
    product_id, 
    year, 
    month, 
    view_count, 
    tryon_count, 
    purchase_click_count
  )
  values (
    new.store_id, 
    new.product_id,
    v_year, 
    v_month, 
    case when new.event_type = 'view' then 1 else 0 end,
    case when new.event_type = 'try_on' then 1 else 0 end,
    case when new.event_type = 'purchase_click' then 1 else 0 end
  )
  on conflict (store_id, product_id, year, month)
  do update set 
    view_count = analytics_product_monthly_summary.view_count + excluded.view_count,
    tryon_count = analytics_product_monthly_summary.tryon_count + excluded.tryon_count,
    purchase_click_count = analytics_product_monthly_summary.purchase_click_count + excluded.purchase_click_count;

  return new;
end;
```

**Step 3: Backfill existing data**

Run a one-time migration to populate `analytics_product_monthly_summary` from `analytics_events`:

```sql
INSERT INTO analytics_product_monthly_summary (store_id, product_id, year, month, view_count, tryon_count, purchase_click_count)
SELECT
  store_id,
  product_id,
  EXTRACT(YEAR FROM created_at)::INT AS year,
  EXTRACT(MONTH FROM created_at)::INT AS month,
  COUNT(*) FILTER (WHERE event_type = 'view') AS view_count,
  COUNT(*) FILTER (WHERE event_type = 'try_on') AS tryon_count,
  COUNT(*) FILTER (WHERE event_type = 'purchase_click') AS purchase_click_count
FROM analytics_events
GROUP BY store_id, product_id, year, month
ON CONFLICT (store_id, product_id, year, month) DO UPDATE SET
  view_count = EXCLUDED.view_count,
  tryon_count = EXCLUDED.tryon_count,
  purchase_click_count = EXCLUDED.purchase_click_count;
```

---

> 🛑 **CHECKPOINT 1:** Backend setup complete. Please review the SQL changes and confirm table creation in Supabase before proceeding to the Flutter implementation.

---

## Task 2: Add `tableAnalyticsProductMonthlySummary` to AppConstants

**Files:**
- Modify: `lib/core/config/app_constants.dart`

**Step 1: Add the constant**

In `app_constants.dart`, after line 19 (`tableAnalyticsMonthlySummary`), add:

```dart
static const String tableAnalyticsProductMonthlySummary =
    'analytics_product_monthly_summary';
```

---

## Task 3: Create `ProductAnalyticsSummary` entity

**Files:**
- Create: `lib/feature/store/analytics/domain/entities/product_analytics_summary.dart`

**Step 1: Create the freezed entity**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_analytics_summary.freezed.dart';

@freezed
sealed class ProductAnalyticsSummary with _$ProductAnalyticsSummary {
  const factory ProductAnalyticsSummary({
    required final String productId,
    required final int viewCount,
    required final int tryonCount,
    required final int purchaseClickCount,
  }) = _ProductAnalyticsSummary;
}
```

**Step 2: Run build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs`

---

## Task 4: Create `ProductAnalyticsSummaryModel`

**Files:**
- Create: `lib/feature/store/analytics/data/models/product_analytics_summary_model.dart`

**Step 1: Create the JSON model**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'product_analytics_summary_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductAnalyticsSummaryModel {
  const ProductAnalyticsSummaryModel({
    required this.storeId,
    required this.productId,
    required this.year,
    required this.month,
    required this.viewCount,
    required this.tryonCount,
    required this.purchaseClickCount,
  });

  factory ProductAnalyticsSummaryModel.fromJson(
    final Map<String, dynamic> json,
  ) =>
      _$ProductAnalyticsSummaryModelFromJson(json);

  final String storeId;
  final String productId;
  final int year;
  final int month;
  final int viewCount;
  final int tryonCount;
  final int purchaseClickCount;

  Map<String, dynamic> toJson() =>
      _$ProductAnalyticsSummaryModelToJson(this);
}
```

**Step 2: Run build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs`

---

## Task 5: Create `ProductAnalyticsSummaryCollection` (Isar)

**Files:**
- Create: `lib/feature/store/analytics/data/collections/product_analytics_collection.dart`

**Step 1: Create the Isar collection**

```dart
import 'package:isar_community/isar.dart';

part 'product_analytics_collection.g.dart';

@collection
class ProductAnalyticsCollection {
  Id id = Isar.autoIncrement;

  @Index(
    composite: [
      CompositeIndex('productId'),
      CompositeIndex('year'),
      CompositeIndex('month'),
    ],
  )
  late String storeId;
  late String productId;
  late int year;
  late int month;
  late int viewCount;
  late int tryonCount;
  late int purchaseClickCount;
}
```

**Step 2: Run build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs`

---

## Task 6: Update `StoreMappr` — add product analytics mappings

**Files:**
- Modify: `lib/feature/store/data/mappers/store_mappr.dart`

**Step 1: Add imports**

Add these imports at the top:

```dart
import '../../analytics/data/collections/product_analytics_collection.dart';
import '../../analytics/data/models/product_analytics_summary_model.dart';
import '../../analytics/domain/entities/product_analytics_summary.dart';
```

**Step 2: Add mapping types**

Add these entries to the `@AutoMappr([...])` list, after the existing `StoreAnalyticsSummary` mappings:

```dart
// ProductAnalyticsSummary mappings
MapType<ProductAnalyticsSummaryModel, ProductAnalyticsSummary>(),
MapType<ProductAnalyticsSummaryModel, ProductAnalyticsCollection>(
  fields: [Field('productId', from: 'productId')],
),
MapType<ProductAnalyticsCollection, ProductAnalyticsSummaryModel>(
  fields: [Field('productId', from: 'productId')],
),
```

**Step 3: Run build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs`

---

> 🛑 **CHECKPOINT 2:** Data Models, Entity, Isar Collection, and StoreMappr setup complete. Please review the generated code (`.g.dart`, `.freezed.dart`, `store_mappr.auto_mappr.dart`) to ensure no build errors.

---

## Task 7: Create product analytics remote datasource

**Files:**
- Create: `lib/feature/store/analytics/data/datasources/product_analytics_remote_datasource.dart`

**Step 1: Create the datasource**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/store/analytics/data/models/product_analytics_summary_model.dart';

class ProductAnalyticsRemoteDataSource {
  ProductAnalyticsRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  /// Fetches per-product analytics for a specific month.
  Future<List<ProductAnalyticsSummaryModel>>
      getProductAnalyticsSummaries(
    final String storeId, {
    required final int year,
    required final int month,
  }) async {
    final response = await _supabaseClient
        .from(AppConstants.tableAnalyticsProductMonthlySummary)
        .select()
        .eq('store_id', storeId)
        .eq('year', year)
        .eq('month', month);

    return response
        .map(
          (final e) =>
              ProductAnalyticsSummaryModel.fromJson(
                Map<String, dynamic>.from(e),
              ),
        )
        .toList();
  }

  /// Fetches all per-product analytics for a store (all time).
  Future<List<ProductAnalyticsSummaryModel>>
      getAllProductAnalyticsSummaries(
    final String storeId,
  ) async {
    final response = await _supabaseClient
        .from(AppConstants.tableAnalyticsProductMonthlySummary)
        .select()
        .eq('store_id', storeId);

    return response
        .map(
          (final e) =>
              ProductAnalyticsSummaryModel.fromJson(
                Map<String, dynamic>.from(e),
              ),
        )
        .toList();
  }
}
```

---

## Task 8: Create product analytics local datasource

**Files:**
- Create: `lib/feature/store/analytics/data/datasources/product_analytics_local_datasource.dart`

**Step 1: Create the datasource**

```dart
import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/feature/store/analytics/data/collections/product_analytics_collection.dart';
import 'package:tryzeon/feature/store/analytics/data/models/product_analytics_summary_model.dart';
import 'package:tryzeon/feature/store/data/mappers/store_mappr.dart';

class ProductAnalyticsLocalDataSource {
  ProductAnalyticsLocalDataSource(this._isarService);

  final IsarService _isarService;
  static const _mappr = StoreMappr();

  Future<List<ProductAnalyticsSummaryModel>?>
      getProductAnalyticsSummaries(
    final String storeId,
    final int year,
    final int month,
  ) async {
    final isar = await _isarService.db;
    final collections = await isar.productAnalyticsCollections
        .filter()
        .storeIdEqualTo(storeId)
        .yearEqualTo(year)
        .monthEqualTo(month)
        .findAll();

    if (collections.isEmpty) return null;

    return collections
        .map(
          (final c) => _mappr.convert<
              ProductAnalyticsCollection,
              ProductAnalyticsSummaryModel>(c),
        )
        .toList();
  }

  Future<void> saveProductAnalyticsSummaries(
    final List<ProductAnalyticsSummaryModel> summaries,
  ) async {
    final isar = await _isarService.db;

    await isar.writeTxn(() async {
      for (final summary in summaries) {
        final collection = _mappr.convert<
            ProductAnalyticsSummaryModel,
            ProductAnalyticsCollection>(summary);

        final existing = await isar.productAnalyticsCollections
            .filter()
            .storeIdEqualTo(summary.storeId)
            .productIdEqualTo(summary.productId)
            .yearEqualTo(summary.year)
            .monthEqualTo(summary.month)
            .findFirst();

        if (existing != null) {
          collection.id = existing.id;
        }

        await isar.productAnalyticsCollections.put(collection);
      }
    });
  }
}
```

---

## Task 9: Create product analytics repository

**Files:**
- Create: `lib/feature/store/analytics/domain/repositories/product_analytics_repository.dart`
- Create: `lib/feature/store/analytics/data/repositories/product_analytics_repository_impl.dart`

**Step 1: Create the abstract repository**

```dart
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:typed_result/typed_result.dart';

abstract class ProductAnalyticsRepository {
  Future<Result<List<ProductAnalyticsSummary>, Failure>>
      getProductAnalyticsSummaries(
    final String storeId, {
    final int? year,
    final int? month,
  });
}
```

**Step 2: Create the repository implementation**

```dart
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/product_analytics_local_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/product_analytics_remote_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/models/product_analytics_summary_model.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/domain/repositories/product_analytics_repository.dart';
import 'package:tryzeon/feature/store/data/mappers/store_mappr.dart';
import 'package:typed_result/typed_result.dart';

class ProductAnalyticsRepositoryImpl
    implements ProductAnalyticsRepository {
  ProductAnalyticsRepositoryImpl({
    required final ProductAnalyticsRemoteDataSource remoteDataSource,
    required final ProductAnalyticsLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final ProductAnalyticsRemoteDataSource _remoteDataSource;
  final ProductAnalyticsLocalDataSource _localDataSource;
  static const _mappr = StoreMappr();

  @override
  Future<Result<List<ProductAnalyticsSummary>, Failure>>
      getProductAnalyticsSummaries(
    final String storeId, {
    final int? year,
    final int? month,
  }) async {
    try {
      final now = DateTime.now();
      final isAllTime = year == null || month == null;

      if (isAllTime) {
        final models = await _remoteDataSource
            .getAllProductAnalyticsSummaries(storeId);
        return Ok(_aggregateByProduct(models));
      }

      final isPastMonth =
          year < now.year || (year == now.year && month < now.month);

      if (isPastMonth) {
        final cached = await _localDataSource
            .getProductAnalyticsSummaries(storeId, year, month);
        if (cached != null) {
          return Ok(
            cached
                .map(
                  (final m) => _mappr.convert<
                      ProductAnalyticsSummaryModel,
                      ProductAnalyticsSummary>(m),
                )
                .toList(),
          );
        }
      }

      final remoteModels = await _remoteDataSource
          .getProductAnalyticsSummaries(
        storeId,
        year: year,
        month: month,
      );

      if (isPastMonth) {
        await _localDataSource
            .saveProductAnalyticsSummaries(remoteModels);
      }

      return Ok(
        remoteModels
            .map(
              (final m) => _mappr.convert<
                  ProductAnalyticsSummaryModel,
                  ProductAnalyticsSummary>(m),
            )
            .toList(),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to get product analytics summaries',
        e,
        stackTrace,
      );
      return Err(mapExceptionToFailure(e));
    }
  }

  /// For all-time: aggregate multiple monthly rows per product
  /// into a single summary per product.
  List<ProductAnalyticsSummary> _aggregateByProduct(
    final List<ProductAnalyticsSummaryModel> models,
  ) {
    final Map<String, ProductAnalyticsSummary> map = {};
    for (final m in models) {
      final existing = map[m.productId];
      if (existing != null) {
        map[m.productId] = ProductAnalyticsSummary(
          productId: m.productId,
          viewCount: existing.viewCount + m.viewCount,
          tryonCount: existing.tryonCount + m.tryonCount,
          purchaseClickCount:
              existing.purchaseClickCount + m.purchaseClickCount,
        );
      } else {
        map[m.productId] = ProductAnalyticsSummary(
          productId: m.productId,
          viewCount: m.viewCount,
          tryonCount: m.tryonCount,
          purchaseClickCount: m.purchaseClickCount,
        );
      }
    }
    return map.values.toList();
  }
}
```

---

## Task 10: Create `GetProductAnalyticsSummaries` use case

**Files:**
- Create: `lib/feature/store/analytics/domain/usecases/get_product_analytics_summaries.dart`

**Step 1: Create the use case**

```dart
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/domain/repositories/product_analytics_repository.dart';
import 'package:tryzeon/feature/store/profile/domain/repositories/store_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetProductAnalyticsSummaries {
  GetProductAnalyticsSummaries(
    this._analyticsRepository,
    this._profileRepository,
  );

  final ProductAnalyticsRepository _analyticsRepository;
  final StoreProfileRepository _profileRepository;

  Future<Result<List<ProductAnalyticsSummary>, Failure>> call({
    final int? year,
    final int? month,
  }) async {
    final profileResult =
        await _profileRepository.getStoreProfile();
    if (profileResult.isFailure) {
      return Err(profileResult.getError()!);
    }

    final profile = profileResult.get()!;

    return _analyticsRepository.getProductAnalyticsSummaries(
      profile.id,
      year: year,
      month: month,
    );
  }
}
```

---

## Task 11: Rewrite `store_analytics_providers.dart`

**Files:**
- Modify: `lib/feature/store/analytics/providers/store_analytics_providers.dart`

**Step 1: Replace the full file contents**

```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/product_analytics_local_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/product_analytics_remote_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/repositories/product_analytics_repository_impl.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/domain/repositories/product_analytics_repository.dart';
import 'package:tryzeon/feature/store/analytics/domain/usecases/get_product_analytics_summaries.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'store_analytics_providers.g.dart';

// --- Filter Provider (shared by dashboard + product cards) ---
@riverpod
class StoreAnalyticsFilter extends _$StoreAnalyticsFilter {
  @override
  ({int year, int month})? build() {
    final now = DateTime.now();
    return (year: now.year, month: now.month);
  }

  ({int year, int month})? get filter => state;

  set filter(final ({int year, int month})? filter) {
    state = filter;
  }
}

// --- Data Sources ---
@riverpod
ProductAnalyticsRemoteDataSource productAnalyticsRemoteDataSource(
  final Ref ref,
) {
  return ProductAnalyticsRemoteDataSource(Supabase.instance.client);
}

@riverpod
ProductAnalyticsLocalDataSource productAnalyticsLocalDataSource(
  final Ref ref,
) {
  return ProductAnalyticsLocalDataSource(IsarService());
}

// --- Repository ---
@riverpod
ProductAnalyticsRepository productAnalyticsRepository(
  final Ref ref,
) {
  return ProductAnalyticsRepositoryImpl(
    remoteDataSource:
        ref.watch(productAnalyticsRemoteDataSourceProvider),
    localDataSource:
        ref.watch(productAnalyticsLocalDataSourceProvider),
  );
}

// --- Use Case ---
@riverpod
GetProductAnalyticsSummaries getProductAnalyticsSummaries(
  final Ref ref,
) {
  return GetProductAnalyticsSummaries(
    ref.watch(productAnalyticsRepositoryProvider),
    ref.watch(storeProfileRepositoryProvider),
  );
}

// --- Feature Provider: per-product summaries ---
@riverpod
Future<List<ProductAnalyticsSummary>> productAnalyticsSummaries(
  final Ref ref,
) async {
  final filter = ref.watch(storeAnalyticsFilterProvider);
  final useCase = ref.watch(getProductAnalyticsSummariesProvider);
  final result = await useCase(
    year: filter?.year,
    month: filter?.month,
  );

  if (result.isFailure) {
    throw result.getError()!;
  }

  return result.get()!;
}

/// Convenience provider: Map<productId, summary> for O(1) lookup
@riverpod
Map<String, ProductAnalyticsSummary> productAnalyticsMap(
  final Ref ref,
) {
  final summariesAsync = ref.watch(productAnalyticsSummariesProvider);
  return summariesAsync.maybeWhen(
    data: (final summaries) => {
      for (final s in summaries) s.productId: s,
    },
    orElse: () => {},
  );
}

/// Force refresh analytics data
Future<void> refreshAnalytics(final WidgetRef ref) async {
  try {
    final _ =
        await ref.refresh(productAnalyticsSummariesProvider.future);
  } catch (_) {
    // Let UI show ErrorView or stale data
  }
}
```

**Step 2: Run build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs`

---

> 🛑 **CHECKPOINT 3:** Data Layer (Datasources, Repository, UseCase) and Providers setup complete. Please review business logic and state management before proceeding to the UI updates.

---

## Task 12: Extract month filter into standalone widget

**Files:**
- Create: `lib/feature/store/home/presentation/widgets/month_filter_widget.dart`

**Step 1: Create the widget**

Extract the month filter UI from `StoreTrafficDashboard` into its own widget:

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';

class MonthFilterWidget extends HookConsumerWidget {
  const MonthFilterWidget({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final filter = ref.watch(storeAnalyticsFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.chevron_left_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
              tooltip: '上一個月',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              onPressed: () => _onPreviousMonth(ref, filter),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    filter == null
                        ? '全部時間'
                        : '${filter.year}年 ${filter.month}月',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.chevron_right_rounded,
                color: _canGoNextMonth(filter)
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.3),
                size: 20,
              ),
              tooltip: '下一個月',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              onPressed: _canGoNextMonth(filter)
                  ? () => _onNextMonth(ref, filter)
                  : null,
            ),
            Container(
              width: 1,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              color: colorScheme.outlineVariant
                  .withValues(alpha: 0.5),
            ),
            IconButton(
              icon: Icon(
                Icons.all_inclusive_rounded,
                color: filter == null
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 16,
              ),
              tooltip: '全部時間',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              onPressed: () => _onAllTime(ref),
            ),
          ],
        ),
      ),
    );
  }

  void _onPreviousMonth(
    final WidgetRef ref,
    final ({int year, int month})? filter,
  ) {
    final now = DateTime.now();
    if (filter == null) {
      ref.read(storeAnalyticsFilterProvider.notifier).filter = (
        year: now.year,
        month: now.month,
      );
    } else {
      var newYear = filter.year;
      var newMonth = filter.month - 1;
      if (newMonth < 1) {
        newYear -= 1;
        newMonth = 12;
      }
      ref.read(storeAnalyticsFilterProvider.notifier).filter = (
        year: newYear,
        month: newMonth,
      );
    }
  }

  void _onNextMonth(
    final WidgetRef ref,
    final ({int year, int month})? filter,
  ) {
    final now = DateTime.now();
    if (filter == null) {
      ref.read(storeAnalyticsFilterProvider.notifier).filter = (
        year: now.year,
        month: now.month,
      );
    } else {
      var newYear = filter.year;
      var newMonth = filter.month + 1;
      if (newMonth > 12) {
        newYear += 1;
        newMonth = 1;
      }
      ref.read(storeAnalyticsFilterProvider.notifier).filter = (
        year: newYear,
        month: newMonth,
      );
    }
  }

  void _onAllTime(final WidgetRef ref) {
    ref.read(storeAnalyticsFilterProvider.notifier).filter = null;
  }

  bool _canGoNextMonth(
    final ({int year, int month})? filter,
  ) {
    if (filter == null) return true;
    final now = DateTime.now();
    return !(filter.year == now.year && filter.month == now.month);
  }
}
```

---

## Task 13: Rewrite `StoreTrafficDashboard` — display only, no filter

**Files:**
- Modify: `lib/feature/store/home/presentation/widgets/store_traffic_dashboard.dart`

**Step 1: Replace the full file contents**

Remove the month filter UI and compute totals from per-product summaries:

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';

class StoreTrafficDashboard extends HookConsumerWidget {
  const StoreTrafficDashboard({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final analyticsAsync =
        ref.watch(productAnalyticsSummariesProvider);

    final colorScheme = Theme.of(context).colorScheme;

    int totalView = 0;
    int totalTryOn = 0;
    int totalPurchaseClicks = 0;
    bool hasError = false;

    if (analyticsAsync.hasValue && analyticsAsync.value != null) {
      for (final s in analyticsAsync.value!) {
        totalView += s.viewCount;
        totalTryOn += s.tryonCount;
        totalPurchaseClicks += s.purchaseClickCount;
      }
    } else if (analyticsAsync.hasError) {
      hasError = true;
    }

    final isLoading = analyticsAsync.isLoading;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color:
              colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '總流量概況',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (hasError) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: '資料載入失敗，請下拉刷新',
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: colorScheme.error,
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _StatItem(
                label: '瀏覽次數',
                value: isLoading ? 8888 : totalView,
                icon: Icons.visibility_rounded,
                isLoading: isLoading,
                hasError: hasError,
              ),
              Container(
                width: 1,
                height: 40,
                margin:
                    const EdgeInsets.symmetric(horizontal: 16),
                color: colorScheme.outlineVariant
                    .withValues(alpha: 0.5),
              ),
              _StatItem(
                label: '虛擬試穿',
                value: isLoading ? 8888 : totalTryOn,
                icon: Icons.checkroom_rounded,
                isLoading: isLoading,
                hasError: hasError,
              ),
              Container(
                width: 1,
                height: 40,
                margin:
                    const EdgeInsets.symmetric(horizontal: 16),
                color: colorScheme.outlineVariant
                    .withValues(alpha: 0.5),
              ),
              _StatItem(
                label: '購買點擊',
                value: isLoading ? 8888 : totalPurchaseClicks,
                icon: Icons.ads_click_rounded,
                isLoading: isLoading,
                hasError: hasError,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.isLoading,
    required this.hasError,
  });

  final String label;
  final int value;
  final IconData icon;
  final bool isLoading;
  final bool hasError;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: colorScheme.onSurfaceVariant,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Skeletonizer(
            enabled: isLoading,
            child: Text(
              hasError ? '--' : value.toString(),
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(
                    color: hasError
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.primary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Task 14: Update `StoreProductCard` — show per-product analytics

**Files:**
- Modify: `lib/feature/store/products/presentation/widgets/product_card.dart`

**Step 1: Replace the full file contents**

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/common/product_categories/providers/product_categories_providers.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';

class StoreProductCard extends HookConsumerWidget {
  const StoreProductCard({super.key, required this.product});
  final Product product;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final categoriesAsync =
        ref.watch(productCategoriesProvider);
    final categoryNames = categoriesAsync.maybeWhen(
      data: (final categories) {
        final Map<String, String> idToName = {
          for (final cat in categories) cat.id: cat.name,
        };
        return product.categories
            .map((final id) => idToName[id] ?? id)
            .where((final name) => name.isNotEmpty)
            .join(', ');
      },
      orElse: () => '',
    );

    final analyticsMap = ref.watch(productAnalyticsMapProvider);
    final analytics = analyticsMap[product.id];

    return GestureDetector(
      onTap: () {
        context.push(
          '/store/products/${product.id}',
          extra: product,
        );
      },
      child: Card(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    cacheKey: product.imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder:
                        (final context, final url) =>
                            const Center(
                              child:
                                  CircularProgressIndicator(),
                            ),
                    errorWidget:
                        (final context, final url,
                            final error) =>
                        const Center(
                          child: Icon(Icons.error_outline),
                        ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    categoryNames,
                    style: textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price}',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Per-product analytics
                  Row(
                    children: [
                      _AnalyticsBadge(
                        icon: Icons.visibility_rounded,
                        count: analytics?.viewCount ?? 0,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),
                      const SizedBox(width: 8),
                      _AnalyticsBadge(
                        icon: Icons.checkroom_rounded,
                        count: analytics?.tryonCount ?? 0,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),
                      const SizedBox(width: 8),
                      _AnalyticsBadge(
                        icon: Icons.ads_click_rounded,
                        count:
                            analytics?.purchaseClickCount ?? 0,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsBadge extends StatelessWidget {
  const _AnalyticsBadge({
    required this.icon,
    required this.count,
    required this.colorScheme,
    required this.textTheme,
  });

  final IconData icon;
  final int count;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(final BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 2),
        Text(
          count.toString(),
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
```

---

## Task 15: Update `home_page.dart` — add shared month filter

**Files:**
- Modify: `lib/feature/store/home/presentation/pages/home_page.dart`

**Step 1: Replace the full file contents**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/home/presentation/widgets/month_filter_widget.dart';
import 'package:tryzeon/feature/store/home/presentation/widgets/store_home_header.dart';
import 'package:tryzeon/feature/store/home/presentation/widgets/store_traffic_dashboard.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_list_section.dart';
import 'package:tryzeon/feature/store/products/providers/store_products_providers.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';

class StoreHomePage extends HookConsumerWidget {
  const StoreHomePage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final profileAsync = ref.watch(storeProfileProvider);
    final profile = profileAsync.maybeWhen(
      data: (final profile) => profile,
      orElse: () => null,
    );

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: colorScheme.surface),
        child: SafeArea(
          child: Column(
            children: [
              StoreHomeHeader(profile: profile),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait([
                      refreshAnalytics(ref),
                      refreshProducts(ref),
                    ]);
                  },
                  color: colorScheme.primary,
                  child: const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [MonthFilterWidget()],
                        ),
                        SizedBox(height: 16),
                        StoreTrafficDashboard(),
                        ProductListSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color:
                  colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () {
              context.push('/store/products/add');
            },
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 65,
              height: 65,
              child: Icon(
                Icons.add_rounded,
                color: colorScheme.onPrimary,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

> 🛑 **CHECKPOINT 4:** UI refactoring complete. Month filter, Dashboard, Product Card, and Home Page should now reflect the new Analytics implementation. Please run the app and review the UI before cleaning up legacy code.

---

## Task 16: Cleanup — remove old store-level analytics code

**Files:**
- Delete: `lib/feature/store/analytics/data/models/store_analytics_summary_model.dart`
- Delete: `lib/feature/store/analytics/data/models/store_analytics_summary_model.g.dart`
- Delete: `lib/feature/store/analytics/data/collections/store_analytics_collection.dart`
- Delete: `lib/feature/store/analytics/data/collections/store_analytics_collection.g.dart`
- Delete: `lib/feature/store/analytics/data/datasources/store_analytics_remote_datasource.dart`
- Delete: `lib/feature/store/analytics/data/datasources/store_analytics_local_datasource.dart`
- Delete: `lib/feature/store/analytics/data/repositories/store_analytics_repository_impl.dart`
- Delete: `lib/feature/store/analytics/domain/entities/store_analytics_summary.dart`
- Delete: `lib/feature/store/analytics/domain/entities/store_analytics_summary.freezed.dart`
- Delete: `lib/feature/store/analytics/domain/repositories/store_analytics_repository.dart`
- Delete: `lib/feature/store/analytics/domain/usecases/get_store_analytics_summary.dart`
- Modify: `lib/feature/store/data/mappers/store_mappr.dart` — remove old `StoreAnalyticsSummary` mapping entries and their imports
- Modify: `lib/core/config/app_constants.dart` — remove `tableAnalyticsMonthlySummary`

**Step 1: Delete old files**

Delete all the files listed above.

**Step 2: Update `store_mappr.dart`**

Remove these imports:
```dart
import '../../analytics/data/collections/store_analytics_collection.dart';
import '../../analytics/data/models/store_analytics_summary_model.dart';
import '../../analytics/domain/entities/store_analytics_summary.dart';
```

Remove these mapping entries from `@AutoMappr`:
```dart
MapType<StoreAnalyticsSummaryModel, StoreAnalyticsSummary>(),
MapType<StoreAnalyticsCollection, StoreAnalyticsSummaryModel>(),
MapType<StoreAnalyticsSummaryModel, StoreAnalyticsCollection>(),
```

**Step 3: Remove `tableAnalyticsMonthlySummary` from `app_constants.dart`**

Remove line:
```dart
static const String tableAnalyticsMonthlySummary = 'analytics_monthly_summary';
```

**Step 4: Run build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs`

**Step 5: Run analysis**

Run: `dart analyze`
Run: `dart fix --apply && dart format .`

Fix any remaining import errors or references to deleted code.

---

## Task 17: Register Isar collection

**Files:**
- Modify: wherever Isar schemas are registered (likely `lib/core/data/services/isar_service.dart` or similar)

**Step 1: Find and update Isar schema registration**

Add `ProductAnalyticsCollectionSchema` to the list of schemas passed to `Isar.open()`. Remove `StoreAnalyticsCollectionSchema`.

---

## Task 18: Final verification

**Step 1:** Run `dart run build_runner build --delete-conflicting-outputs`
**Step 2:** Run `dart analyze` — expect 0 errors
**Step 3:** Run `dart fix --apply && dart format .`
**Step 4:** Run `flutter run` — verify the store home page shows the month filter at the top, traffic dashboard below, and each product card shows analytics badges
