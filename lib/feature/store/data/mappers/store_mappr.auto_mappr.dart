// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AutoMapprGenerator
// **************************************************************************

// ignore_for_file: type=lint, unnecessary_cast, unused_local_variable

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_mappr_annotation/auto_mappr_annotation.dart' as _i1;
import 'package:tryzeon/core/shared/measurements/collections/measurements_collection.dart'
    as _i13;
import 'package:tryzeon/core/shared/measurements/data/models/measurements_model.dart'
    as _i11;
import 'package:tryzeon/core/shared/measurements/entities/measurements.dart'
    as _i12;
import 'package:tryzeon/feature/store/analytics/data/collections/product_analytics_collection.dart'
    as _i10;
import 'package:tryzeon/feature/store/analytics/data/models/product_analytics_summary_model.dart'
    as _i8;
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart'
    as _i9;
import 'package:tryzeon/feature/store/data/mappers/store_mappr.dart' as _i14;
import 'package:tryzeon/feature/store/products/data/collections/product_collection.dart'
    as _i4;
import 'package:tryzeon/feature/store/products/data/models/product_model.dart'
    as _i2;
import 'package:tryzeon/feature/store/products/domain/entities/product.dart'
    as _i3;
import 'package:tryzeon/feature/store/profile/data/collections/store_profile_collection.dart'
    as _i7;
import 'package:tryzeon/feature/store/profile/data/models/store_profile_model.dart'
    as _i5;
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart'
    as _i6;

/// {@template package:tryzeon/feature/store/data/mappers/store_mappr.dart}
/// Available mappings:
/// - `ProductSizeModel` → `ProductSize`.
/// - `ProductSize` → `ProductSizeModel`.
/// - `ProductSizeModel` → `ProductSizeCollection`.
/// - `ProductSizeCollection` → `ProductSizeModel`.
/// - `ProductModel` → `Product`.
/// - `Product` → `ProductModel`.
/// - `ProductModel` → `ProductCollection`.
/// - `ProductCollection` → `ProductModel`.
/// - `StoreProfileModel` → `StoreProfile`.
/// - `StoreProfile` → `StoreProfileModel`.
/// - `StoreProfileModel` → `StoreProfileCollection`.
/// - `StoreProfileCollection` → `StoreProfileModel`.
/// - `ProductAnalyticsSummaryModel` → `ProductAnalyticsSummary`.
/// - `ProductAnalyticsSummaryModel` → `ProductAnalyticsCollection`.
/// - `ProductAnalyticsCollection` → `ProductAnalyticsSummaryModel`.
/// - `MeasurementsModel` → `Measurements`.
/// - `Measurements` → `MeasurementsModel`.
/// - `MeasurementsModel` → `MeasurementsCollection`.
/// - `MeasurementsCollection` → `MeasurementsModel`.
/// {@endtemplate}
class $StoreMappr implements _i1.AutoMapprInterface {
  const $StoreMappr();

  Type _typeOf<T>() => T;

  List<_i1.AutoMapprInterface> get _delegates => const [];

  /// {@macro AutoMapprInterface:canConvert}
  /// {@macro package:tryzeon/feature/store/data/mappers/store_mappr.dart}
  @override
  bool canConvert<SOURCE, TARGET>({bool recursive = true}) {
    final sourceTypeOf = _typeOf<SOURCE>();
    final targetTypeOf = _typeOf<TARGET>();
    if ((sourceTypeOf == _typeOf<_i2.ProductSizeModel>() ||
            sourceTypeOf == _typeOf<_i2.ProductSizeModel?>()) &&
        (targetTypeOf == _typeOf<_i3.ProductSize>() ||
            targetTypeOf == _typeOf<_i3.ProductSize?>())) {
      return true;
    }
    if ((sourceTypeOf == _typeOf<_i3.ProductSize>() ||
            sourceTypeOf == _typeOf<_i3.ProductSize?>()) &&
        (targetTypeOf == _typeOf<_i2.ProductSizeModel>() ||
            targetTypeOf == _typeOf<_i2.ProductSizeModel?>())) {
      return true;
    }
    if ((sourceTypeOf == _typeOf<_i2.ProductSizeModel>() ||
            sourceTypeOf == _typeOf<_i2.ProductSizeModel?>()) &&
        (targetTypeOf == _typeOf<_i4.ProductSizeCollection>() ||
            targetTypeOf == _typeOf<_i4.ProductSizeCollection?>())) {
      return true;
    }
    if ((sourceTypeOf == _typeOf<_i4.ProductSizeCollection>() ||
            sourceTypeOf == _typeOf<_i4.ProductSizeCollection?>()) &&
        (targetTypeOf == _typeOf<_i2.ProductSizeModel>() ||
            targetTypeOf == _typeOf<_i2.ProductSizeModel?>())) {
      return true;
    }
    if ((sourceTypeOf == _typeOf<_i2.ProductModel>() ||
            sourceTypeOf == _typeOf<_i2.ProductModel?>()) &&
        (targetTypeOf == _typeOf<_i3.Product>() ||
            targetTypeOf == _typeOf<_i3.Product?>())) {
      return true;
    }
    if ((sourceTypeOf == _typeOf<_i3.Product>() ||
            sourceTypeOf == _typeOf<_i3.Product?>()) &&
        (targetTypeOf == _typeOf<_i2.ProductModel>() ||
            targetTypeOf == _typeOf<_i2.ProductModel?>())) {
      return true;
    }
    if ((sourceTypeOf == _typeOf<_i2.ProductModel>() ||
            sourceTypeOf == _typeOf<_i2.ProductModel?>()) &&
        (targetTypeOf == _typeOf<_i4.ProductCollection>() ||
            targetTypeOf == _typeOf<_i4.ProductCollection?>())) {
      return true;
    }
    if ((sourceTypeOf == _typeOf<_i4.ProductCollection>() ||
            sourceTypeOf == _typeOf<_i4.ProductCollection?>()) &&
        (targetTypeOf == _typeOf<_i2.ProductModel>() ||
            targetTypeOf == _typeOf<_i2.ProductModel?>())) {
      return true;
    }
    if ((sourceTypeOf == _typeOf<_i5.StoreProfileModel>() ||
            sourceTypeOf == _typeOf<_i5.StoreProfileModel?>()) &&
        (targetTypeOf == _typeOf<_i6.StoreProfile>() ||
            targetTypeOf == _typeOf<_i6.StoreProfile?>())) {
      return true;
    }
    if ((sourceTypeOf == _typeOf<_i6.StoreProfile>() ||
            sourceTypeOf == _typeOf<_i6.StoreProfile?>()) &&
        (targetTypeOf == _typeOf<_i5.StoreProfileModel>() ||
            targetTypeOf == _typeOf<_i5.StoreProfileModel?>())) {
      return true;
    }
    if ((sourceTypeOf == _typeOf<_i5.StoreProfileModel>() ||
            sourceTypeOf == _typeOf<_i5.StoreProfileModel?>()) &&
        (targetTypeOf == _typeOf<_i7.StoreProfileCollection>() ||
            targetTypeOf == _typeOf<_i7.StoreProfileCollection?>())) {
      return true;
    }
    if ((sourceTypeOf == _typeOf<_i7.StoreProfileCollection>() ||
            sourceTypeOf == _typeOf<_i7.StoreProfileCollection?>()) &&
        (targetTypeOf == _typeOf<_i5.StoreProfileModel>() ||
            targetTypeOf == _typeOf<_i5.StoreProfileModel?>())) {
      return true;
    }
    if ((sourceTypeOf == _typeOf<_i8.ProductAnalyticsSummaryModel>() ||
            sourceTypeOf == _typeOf<_i8.ProductAnalyticsSummaryModel?>()) &&
        (targetTypeOf == _typeOf<_i9.ProductAnalyticsSummary>() ||
            targetTypeOf == _typeOf<_i9.ProductAnalyticsSummary?>())) {
      return true;
    }
    if ((sourceTypeOf == _typeOf<_i8.ProductAnalyticsSummaryModel>() ||
            sourceTypeOf == _typeOf<_i8.ProductAnalyticsSummaryModel?>()) &&
        (targetTypeOf == _typeOf<_i10.ProductAnalyticsCollection>() ||
            targetTypeOf == _typeOf<_i10.ProductAnalyticsCollection?>())) {
      return true;
    }
    if ((sourceTypeOf == _typeOf<_i10.ProductAnalyticsCollection>() ||
            sourceTypeOf == _typeOf<_i10.ProductAnalyticsCollection?>()) &&
        (targetTypeOf == _typeOf<_i8.ProductAnalyticsSummaryModel>() ||
            targetTypeOf == _typeOf<_i8.ProductAnalyticsSummaryModel?>())) {
      return true;
    }
    if ((sourceTypeOf == _typeOf<_i11.MeasurementsModel>() ||
            sourceTypeOf == _typeOf<_i11.MeasurementsModel?>()) &&
        (targetTypeOf == _typeOf<_i12.Measurements>() ||
            targetTypeOf == _typeOf<_i12.Measurements?>())) {
      return true;
    }
    if ((sourceTypeOf == _typeOf<_i12.Measurements>() ||
            sourceTypeOf == _typeOf<_i12.Measurements?>()) &&
        (targetTypeOf == _typeOf<_i11.MeasurementsModel>() ||
            targetTypeOf == _typeOf<_i11.MeasurementsModel?>())) {
      return true;
    }
    if ((sourceTypeOf == _typeOf<_i11.MeasurementsModel>() ||
            sourceTypeOf == _typeOf<_i11.MeasurementsModel?>()) &&
        (targetTypeOf == _typeOf<_i13.MeasurementsCollection>() ||
            targetTypeOf == _typeOf<_i13.MeasurementsCollection?>())) {
      return true;
    }
    if ((sourceTypeOf == _typeOf<_i13.MeasurementsCollection>() ||
            sourceTypeOf == _typeOf<_i13.MeasurementsCollection?>()) &&
        (targetTypeOf == _typeOf<_i11.MeasurementsModel>() ||
            targetTypeOf == _typeOf<_i11.MeasurementsModel?>())) {
      return true;
    }
    if (recursive) {
      for (final mappr in _delegates) {
        if (mappr.canConvert<SOURCE, TARGET>()) {
          return true;
        }
      }
    }
    return false;
  }

  /// {@macro AutoMapprInterface:convert}
  /// {@macro package:tryzeon/feature/store/data/mappers/store_mappr.dart}
  @override
  TARGET convert<SOURCE, TARGET>(SOURCE? model) {
    if (canConvert<SOURCE, TARGET>(recursive: false)) {
      return _convert(model)!;
    }
    for (final mappr in _delegates) {
      if (mappr.canConvert<SOURCE, TARGET>()) {
        return mappr.convert(model)!;
      }
    }

    throw Exception('No ${_typeOf<SOURCE>()} -> ${_typeOf<TARGET>()} mapping.');
  }

  /// {@macro AutoMapprInterface:tryConvert}
  /// {@macro package:tryzeon/feature/store/data/mappers/store_mappr.dart}
  @override
  TARGET? tryConvert<SOURCE, TARGET>(
    SOURCE? model, {
    void Function(Object error, StackTrace stackTrace, SOURCE? source)?
    onMappingError,
  }) {
    if (canConvert<SOURCE, TARGET>(recursive: false)) {
      return _safeConvert(model, onMappingError: onMappingError);
    }
    for (final mappr in _delegates) {
      if (mappr.canConvert<SOURCE, TARGET>()) {
        return mappr.tryConvert(model, onMappingError: onMappingError);
      }
    }

    return null;
  }

  /// {@macro AutoMapprInterface:convertIterable}
  /// {@macro package:tryzeon/feature/store/data/mappers/store_mappr.dart}
  @override
  Iterable<TARGET> convertIterable<SOURCE, TARGET>(Iterable<SOURCE?> model) {
    if (canConvert<SOURCE, TARGET>(recursive: false)) {
      return model.map<TARGET>((item) => _convert(item)!);
    }
    for (final mappr in _delegates) {
      if (mappr.canConvert<SOURCE, TARGET>()) {
        return mappr.convertIterable(model);
      }
    }

    throw Exception('No ${_typeOf<SOURCE>()} -> ${_typeOf<TARGET>()} mapping.');
  }

  /// For iterable items, converts from SOURCE to TARGET if such mapping is configured, into Iterable.
  ///
  /// When an item in the source iterable is null, uses `whenSourceIsNull` if defined or null
  ///
  /// {@macro package:tryzeon/feature/store/data/mappers/store_mappr.dart}
  @override
  Iterable<TARGET?> tryConvertIterable<SOURCE, TARGET>(
    Iterable<SOURCE?> model, {
    void Function(Object error, StackTrace stackTrace, SOURCE? source)?
    onMappingError,
  }) {
    if (canConvert<SOURCE, TARGET>(recursive: false)) {
      return model.map<TARGET?>(
        (item) => _safeConvert(item, onMappingError: onMappingError),
      );
    }
    for (final mappr in _delegates) {
      if (mappr.canConvert<SOURCE, TARGET>()) {
        return mappr.tryConvertIterable(model, onMappingError: onMappingError);
      }
    }

    throw Exception('No ${_typeOf<SOURCE>()} -> ${_typeOf<TARGET>()} mapping.');
  }

  /// {@macro AutoMapprInterface:convertList}
  /// {@macro package:tryzeon/feature/store/data/mappers/store_mappr.dart}
  @override
  List<TARGET> convertList<SOURCE, TARGET>(Iterable<SOURCE?> model) {
    if (canConvert<SOURCE, TARGET>(recursive: false)) {
      return convertIterable<SOURCE, TARGET>(model).toList();
    }
    for (final mappr in _delegates) {
      if (mappr.canConvert<SOURCE, TARGET>()) {
        return mappr.convertList(model);
      }
    }

    throw Exception('No ${_typeOf<SOURCE>()} -> ${_typeOf<TARGET>()} mapping.');
  }

  /// For iterable items, converts from SOURCE to TARGET if such mapping is configured, into List.
  ///
  /// When an item in the source iterable is null, uses `whenSourceIsNull` if defined or null
  ///
  /// {@macro package:tryzeon/feature/store/data/mappers/store_mappr.dart}
  @override
  List<TARGET?> tryConvertList<SOURCE, TARGET>(
    Iterable<SOURCE?> model, {
    void Function(Object error, StackTrace stackTrace, SOURCE? source)?
    onMappingError,
  }) {
    if (canConvert<SOURCE, TARGET>(recursive: false)) {
      return tryConvertIterable<SOURCE, TARGET>(
        model,
        onMappingError: onMappingError,
      ).toList();
    }
    for (final mappr in _delegates) {
      if (mappr.canConvert<SOURCE, TARGET>()) {
        return mappr.tryConvertList(model, onMappingError: onMappingError);
      }
    }

    throw Exception('No ${_typeOf<SOURCE>()} -> ${_typeOf<TARGET>()} mapping.');
  }

  /// {@macro AutoMapprInterface:convertSet}
  /// {@macro package:tryzeon/feature/store/data/mappers/store_mappr.dart}
  @override
  Set<TARGET> convertSet<SOURCE, TARGET>(Iterable<SOURCE?> model) {
    if (canConvert<SOURCE, TARGET>(recursive: false)) {
      return convertIterable<SOURCE, TARGET>(model).toSet();
    }
    for (final mappr in _delegates) {
      if (mappr.canConvert<SOURCE, TARGET>()) {
        return mappr.convertSet(model);
      }
    }

    throw Exception('No ${_typeOf<SOURCE>()} -> ${_typeOf<TARGET>()} mapping.');
  }

  /// For iterable items, converts from SOURCE to TARGET if such mapping is configured, into Set.
  ///
  /// When an item in the source iterable is null, uses `whenSourceIsNull` if defined or null
  ///
  /// {@macro package:tryzeon/feature/store/data/mappers/store_mappr.dart}
  @override
  Set<TARGET?> tryConvertSet<SOURCE, TARGET>(
    Iterable<SOURCE?> model, {
    void Function(Object error, StackTrace stackTrace, SOURCE? source)?
    onMappingError,
  }) {
    if (canConvert<SOURCE, TARGET>(recursive: false)) {
      return tryConvertIterable<SOURCE, TARGET>(
        model,
        onMappingError: onMappingError,
      ).toSet();
    }
    for (final mappr in _delegates) {
      if (mappr.canConvert<SOURCE, TARGET>()) {
        return mappr.tryConvertSet(model, onMappingError: onMappingError);
      }
    }

    throw Exception('No ${_typeOf<SOURCE>()} -> ${_typeOf<TARGET>()} mapping.');
  }

  TARGET? _convert<SOURCE, TARGET>(
    SOURCE? model, {
    bool canReturnNull = false,
  }) {
    final sourceTypeOf = _typeOf<SOURCE>();
    final targetTypeOf = _typeOf<TARGET>();
    if ((sourceTypeOf == _typeOf<_i2.ProductSizeModel>() ||
            sourceTypeOf == _typeOf<_i2.ProductSizeModel?>()) &&
        (targetTypeOf == _typeOf<_i3.ProductSize>() ||
            targetTypeOf == _typeOf<_i3.ProductSize?>())) {
      if (canReturnNull && model == null) {
        return null;
      }
      return (_map__i2$ProductSizeModel_To__i3$ProductSize(
            (model as _i2.ProductSizeModel?),
          )
          as TARGET);
    }
    if ((sourceTypeOf == _typeOf<_i3.ProductSize>() ||
            sourceTypeOf == _typeOf<_i3.ProductSize?>()) &&
        (targetTypeOf == _typeOf<_i2.ProductSizeModel>() ||
            targetTypeOf == _typeOf<_i2.ProductSizeModel?>())) {
      if (canReturnNull && model == null) {
        return null;
      }
      return (_map__i3$ProductSize_To__i2$ProductSizeModel(
            (model as _i3.ProductSize?),
          )
          as TARGET);
    }
    if ((sourceTypeOf == _typeOf<_i2.ProductSizeModel>() ||
            sourceTypeOf == _typeOf<_i2.ProductSizeModel?>()) &&
        (targetTypeOf == _typeOf<_i4.ProductSizeCollection>() ||
            targetTypeOf == _typeOf<_i4.ProductSizeCollection?>())) {
      if (canReturnNull && model == null) {
        return null;
      }
      return (_map__i2$ProductSizeModel_To__i4$ProductSizeCollection(
            (model as _i2.ProductSizeModel?),
          )
          as TARGET);
    }
    if ((sourceTypeOf == _typeOf<_i4.ProductSizeCollection>() ||
            sourceTypeOf == _typeOf<_i4.ProductSizeCollection?>()) &&
        (targetTypeOf == _typeOf<_i2.ProductSizeModel>() ||
            targetTypeOf == _typeOf<_i2.ProductSizeModel?>())) {
      if (canReturnNull && model == null) {
        return null;
      }
      return (_map__i4$ProductSizeCollection_To__i2$ProductSizeModel(
            (model as _i4.ProductSizeCollection?),
          )
          as TARGET);
    }
    if ((sourceTypeOf == _typeOf<_i2.ProductModel>() ||
            sourceTypeOf == _typeOf<_i2.ProductModel?>()) &&
        (targetTypeOf == _typeOf<_i3.Product>() ||
            targetTypeOf == _typeOf<_i3.Product?>())) {
      if (canReturnNull && model == null) {
        return null;
      }
      return (_map__i2$ProductModel_To__i3$Product((model as _i2.ProductModel?))
          as TARGET);
    }
    if ((sourceTypeOf == _typeOf<_i3.Product>() ||
            sourceTypeOf == _typeOf<_i3.Product?>()) &&
        (targetTypeOf == _typeOf<_i2.ProductModel>() ||
            targetTypeOf == _typeOf<_i2.ProductModel?>())) {
      if (canReturnNull && model == null) {
        return null;
      }
      return (_map__i3$Product_To__i2$ProductModel((model as _i3.Product?))
          as TARGET);
    }
    if ((sourceTypeOf == _typeOf<_i2.ProductModel>() ||
            sourceTypeOf == _typeOf<_i2.ProductModel?>()) &&
        (targetTypeOf == _typeOf<_i4.ProductCollection>() ||
            targetTypeOf == _typeOf<_i4.ProductCollection?>())) {
      if (canReturnNull && model == null) {
        return null;
      }
      return (_map__i2$ProductModel_To__i4$ProductCollection(
            (model as _i2.ProductModel?),
          )
          as TARGET);
    }
    if ((sourceTypeOf == _typeOf<_i4.ProductCollection>() ||
            sourceTypeOf == _typeOf<_i4.ProductCollection?>()) &&
        (targetTypeOf == _typeOf<_i2.ProductModel>() ||
            targetTypeOf == _typeOf<_i2.ProductModel?>())) {
      if (canReturnNull && model == null) {
        return null;
      }
      return (_map__i4$ProductCollection_To__i2$ProductModel(
            (model as _i4.ProductCollection?),
          )
          as TARGET);
    }
    if ((sourceTypeOf == _typeOf<_i5.StoreProfileModel>() ||
            sourceTypeOf == _typeOf<_i5.StoreProfileModel?>()) &&
        (targetTypeOf == _typeOf<_i6.StoreProfile>() ||
            targetTypeOf == _typeOf<_i6.StoreProfile?>())) {
      if (canReturnNull && model == null) {
        return null;
      }
      return (_map__i5$StoreProfileModel_To__i6$StoreProfile(
            (model as _i5.StoreProfileModel?),
          )
          as TARGET);
    }
    if ((sourceTypeOf == _typeOf<_i6.StoreProfile>() ||
            sourceTypeOf == _typeOf<_i6.StoreProfile?>()) &&
        (targetTypeOf == _typeOf<_i5.StoreProfileModel>() ||
            targetTypeOf == _typeOf<_i5.StoreProfileModel?>())) {
      if (canReturnNull && model == null) {
        return null;
      }
      return (_map__i6$StoreProfile_To__i5$StoreProfileModel(
            (model as _i6.StoreProfile?),
          )
          as TARGET);
    }
    if ((sourceTypeOf == _typeOf<_i5.StoreProfileModel>() ||
            sourceTypeOf == _typeOf<_i5.StoreProfileModel?>()) &&
        (targetTypeOf == _typeOf<_i7.StoreProfileCollection>() ||
            targetTypeOf == _typeOf<_i7.StoreProfileCollection?>())) {
      if (canReturnNull && model == null) {
        return null;
      }
      return (_map__i5$StoreProfileModel_To__i7$StoreProfileCollection(
            (model as _i5.StoreProfileModel?),
          )
          as TARGET);
    }
    if ((sourceTypeOf == _typeOf<_i7.StoreProfileCollection>() ||
            sourceTypeOf == _typeOf<_i7.StoreProfileCollection?>()) &&
        (targetTypeOf == _typeOf<_i5.StoreProfileModel>() ||
            targetTypeOf == _typeOf<_i5.StoreProfileModel?>())) {
      if (canReturnNull && model == null) {
        return null;
      }
      return (_map__i7$StoreProfileCollection_To__i5$StoreProfileModel(
            (model as _i7.StoreProfileCollection?),
          )
          as TARGET);
    }
    if ((sourceTypeOf == _typeOf<_i8.ProductAnalyticsSummaryModel>() ||
            sourceTypeOf == _typeOf<_i8.ProductAnalyticsSummaryModel?>()) &&
        (targetTypeOf == _typeOf<_i9.ProductAnalyticsSummary>() ||
            targetTypeOf == _typeOf<_i9.ProductAnalyticsSummary?>())) {
      if (canReturnNull && model == null) {
        return null;
      }
      return (_map__i8$ProductAnalyticsSummaryModel_To__i9$ProductAnalyticsSummary(
            (model as _i8.ProductAnalyticsSummaryModel?),
          )
          as TARGET);
    }
    if ((sourceTypeOf == _typeOf<_i8.ProductAnalyticsSummaryModel>() ||
            sourceTypeOf == _typeOf<_i8.ProductAnalyticsSummaryModel?>()) &&
        (targetTypeOf == _typeOf<_i10.ProductAnalyticsCollection>() ||
            targetTypeOf == _typeOf<_i10.ProductAnalyticsCollection?>())) {
      if (canReturnNull && model == null) {
        return null;
      }
      return (_map__i8$ProductAnalyticsSummaryModel_To__i10$ProductAnalyticsCollection(
            (model as _i8.ProductAnalyticsSummaryModel?),
          )
          as TARGET);
    }
    if ((sourceTypeOf == _typeOf<_i10.ProductAnalyticsCollection>() ||
            sourceTypeOf == _typeOf<_i10.ProductAnalyticsCollection?>()) &&
        (targetTypeOf == _typeOf<_i8.ProductAnalyticsSummaryModel>() ||
            targetTypeOf == _typeOf<_i8.ProductAnalyticsSummaryModel?>())) {
      if (canReturnNull && model == null) {
        return null;
      }
      return (_map__i10$ProductAnalyticsCollection_To__i8$ProductAnalyticsSummaryModel(
            (model as _i10.ProductAnalyticsCollection?),
          )
          as TARGET);
    }
    if ((sourceTypeOf == _typeOf<_i11.MeasurementsModel>() ||
            sourceTypeOf == _typeOf<_i11.MeasurementsModel?>()) &&
        (targetTypeOf == _typeOf<_i12.Measurements>() ||
            targetTypeOf == _typeOf<_i12.Measurements?>())) {
      if (canReturnNull && model == null) {
        return null;
      }
      return (_map__i11$MeasurementsModel_To__i12$Measurements(
            (model as _i11.MeasurementsModel?),
          )
          as TARGET);
    }
    if ((sourceTypeOf == _typeOf<_i12.Measurements>() ||
            sourceTypeOf == _typeOf<_i12.Measurements?>()) &&
        (targetTypeOf == _typeOf<_i11.MeasurementsModel>() ||
            targetTypeOf == _typeOf<_i11.MeasurementsModel?>())) {
      if (canReturnNull && model == null) {
        return null;
      }
      return (_map__i12$Measurements_To__i11$MeasurementsModel(
            (model as _i12.Measurements?),
          )
          as TARGET);
    }
    if ((sourceTypeOf == _typeOf<_i11.MeasurementsModel>() ||
            sourceTypeOf == _typeOf<_i11.MeasurementsModel?>()) &&
        (targetTypeOf == _typeOf<_i13.MeasurementsCollection>() ||
            targetTypeOf == _typeOf<_i13.MeasurementsCollection?>())) {
      if (canReturnNull && model == null) {
        return null;
      }
      return (_map__i11$MeasurementsModel_To__i13$MeasurementsCollection(
            (model as _i11.MeasurementsModel?),
          )
          as TARGET);
    }
    if ((sourceTypeOf == _typeOf<_i13.MeasurementsCollection>() ||
            sourceTypeOf == _typeOf<_i13.MeasurementsCollection?>()) &&
        (targetTypeOf == _typeOf<_i11.MeasurementsModel>() ||
            targetTypeOf == _typeOf<_i11.MeasurementsModel?>())) {
      if (canReturnNull && model == null) {
        return null;
      }
      return (_map__i13$MeasurementsCollection_To__i11$MeasurementsModel(
            (model as _i13.MeasurementsCollection?),
          )
          as TARGET);
    }
    throw Exception('No ${model.runtimeType} -> $targetTypeOf mapping.');
  }

  TARGET? _safeConvert<SOURCE, TARGET>(
    SOURCE? model, {
    void Function(Object error, StackTrace stackTrace, SOURCE? source)?
    onMappingError,
  }) {
    if (!useSafeMapping<SOURCE, TARGET>()) {
      return _convert(model, canReturnNull: true);
    }
    try {
      return _convert(model, canReturnNull: true);
    } catch (e, s) {
      onMappingError?.call(e, s, model);
      return null;
    }
  }

  /// {@macro AutoMapprInterface:useSafeMapping}
  /// {@macro package:tryzeon/feature/store/data/mappers/store_mappr.dart}
  @override
  bool useSafeMapping<SOURCE, TARGET>() {
    return false;
  }

  _i3.ProductSize _map__i2$ProductSizeModel_To__i3$ProductSize(
    _i2.ProductSizeModel? input,
  ) {
    final model = input;
    if (model == null) {
      throw Exception(
        r'Mapping ProductSizeModel → ProductSize failed because ProductSizeModel was null, and no default value was provided. '
        r'Consider setting the whenSourceIsNull parameter on the MapType<ProductSizeModel, ProductSize> to handle null values during mapping.',
      );
    }
    return _i3.ProductSize(
      id: model.id,
      productId: model.productId,
      name: model.name,
      measurements: _map__i11$MeasurementsModel_To__i12$Measurements_Nullable(
        model.measurements,
      ),
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  _i2.ProductSizeModel _map__i3$ProductSize_To__i2$ProductSizeModel(
    _i3.ProductSize? input,
  ) {
    final model = input;
    if (model == null) {
      throw Exception(
        r'Mapping ProductSize → ProductSizeModel failed because ProductSize was null, and no default value was provided. '
        r'Consider setting the whenSourceIsNull parameter on the MapType<ProductSize, ProductSizeModel> to handle null values during mapping.',
      );
    }
    return _i2.ProductSizeModel(
      id: model.id,
      productId: model.productId,
      name: model.name,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      measurements: _map__i12$Measurements_To__i11$MeasurementsModel_Nullable(
        model.measurements,
      ),
    );
  }

  _i4.ProductSizeCollection
  _map__i2$ProductSizeModel_To__i4$ProductSizeCollection(
    _i2.ProductSizeModel? input,
  ) {
    final model = input;
    if (model == null) {
      throw Exception(
        r'Mapping ProductSizeModel → ProductSizeCollection failed because ProductSizeModel was null, and no default value was provided. '
        r'Consider setting the whenSourceIsNull parameter on the MapType<ProductSizeModel, ProductSizeCollection> to handle null values during mapping.',
      );
    }
    return _i4.ProductSizeCollection()
      ..id = model.id
      ..productId = model.productId
      ..name = model.name
      ..measurements =
          _map__i11$MeasurementsModel_To__i13$MeasurementsCollection_Nullable(
            model.measurements,
          )
      ..createdAt = model.createdAt
      ..updatedAt = model.updatedAt;
  }

  _i2.ProductSizeModel _map__i4$ProductSizeCollection_To__i2$ProductSizeModel(
    _i4.ProductSizeCollection? input,
  ) {
    final model = input;
    if (model == null) {
      throw Exception(
        r'Mapping ProductSizeCollection → ProductSizeModel failed because ProductSizeCollection was null, and no default value was provided. '
        r'Consider setting the whenSourceIsNull parameter on the MapType<ProductSizeCollection, ProductSizeModel> to handle null values during mapping.',
      );
    }
    return _i2.ProductSizeModel(
      id: model.id,
      productId: model.productId,
      name: model.name,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      measurements:
          _map__i13$MeasurementsCollection_To__i11$MeasurementsModel_Nullable(
            model.measurements,
          ),
    );
  }

  _i3.Product _map__i2$ProductModel_To__i3$Product(_i2.ProductModel? input) {
    final model = input;
    if (model == null) {
      throw Exception(
        r'Mapping ProductModel → Product failed because ProductModel was null, and no default value was provided. '
        r'Consider setting the whenSourceIsNull parameter on the MapType<ProductModel, Product> to handle null values during mapping.',
      );
    }
    return _i3.Product(
      storeId: model.storeId,
      name: model.name,
      categoryIds: model.categoryIds,
      price: model.price,
      imagePaths: model.imagePaths,
      imageUrls: model.imageUrls,
      id: model.id,
      purchaseLink: model.purchaseLink,
      material: model.material,
      elasticity: _i14.StoreMapprHelper.stringToElasticity(model),
      fit: _i14.StoreMapprHelper.stringToFit(model),
      thickness: _i14.StoreMapprHelper.stringToThickness(model),
      styles: _i14.StoreMapprHelper.stringsToStyles(model),
      sizes: model.sizes
          ?.map<_i3.ProductSize>(
            (value) => _map__i2$ProductSizeModel_To__i3$ProductSize(value),
          )
          .toList(),
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  _i2.ProductModel _map__i3$Product_To__i2$ProductModel(_i3.Product? input) {
    final model = input;
    if (model == null) {
      throw Exception(
        r'Mapping Product → ProductModel failed because Product was null, and no default value was provided. '
        r'Consider setting the whenSourceIsNull parameter on the MapType<Product, ProductModel> to handle null values during mapping.',
      );
    }
    return _i2.ProductModel(
      storeId: model.storeId,
      name: model.name,
      categoryIds: model.categoryIds,
      price: model.price,
      imagePaths: model.imagePaths,
      imageUrls: model.imageUrls,
      id: model.id,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      purchaseLink: model.purchaseLink,
      material: model.material,
      elasticity: _i14.StoreMapprHelper.elasticityToString(model),
      fit: _i14.StoreMapprHelper.fitToString(model),
      thickness: _i14.StoreMapprHelper.thicknessToString(model),
      styles: _i14.StoreMapprHelper.stylesToStrings(model),
      sizes: model.sizes
          ?.map<_i2.ProductSizeModel>(
            (value) => _map__i3$ProductSize_To__i2$ProductSizeModel(value),
          )
          .toList(),
    );
  }

  _i4.ProductCollection _map__i2$ProductModel_To__i4$ProductCollection(
    _i2.ProductModel? input,
  ) {
    final model = input;
    if (model == null) {
      throw Exception(
        r'Mapping ProductModel → ProductCollection failed because ProductModel was null, and no default value was provided. '
        r'Consider setting the whenSourceIsNull parameter on the MapType<ProductModel, ProductCollection> to handle null values during mapping.',
      );
    }
    return _i4.ProductCollection()
      ..storeId = model.storeId
      ..name = model.name
      ..categoryIds = model.categoryIds
      ..price = model.price
      ..imagePaths = model.imagePaths
      ..imageUrls = model.imageUrls
      ..productId = model.id
      ..purchaseLink = model.purchaseLink
      ..material = model.material
      ..elasticity = model.elasticity
      ..fit = model.fit
      ..thickness = model.thickness
      ..styles = model.styles
      ..sizes = model.sizes
          ?.map<_i4.ProductSizeCollection>(
            (value) =>
                _map__i2$ProductSizeModel_To__i4$ProductSizeCollection(value),
          )
          .toList()
      ..createdAt = model.createdAt
      ..updatedAt = model.updatedAt;
  }

  _i2.ProductModel _map__i4$ProductCollection_To__i2$ProductModel(
    _i4.ProductCollection? input,
  ) {
    final model = input;
    if (model == null) {
      throw Exception(
        r'Mapping ProductCollection → ProductModel failed because ProductCollection was null, and no default value was provided. '
        r'Consider setting the whenSourceIsNull parameter on the MapType<ProductCollection, ProductModel> to handle null values during mapping.',
      );
    }
    return _i2.ProductModel(
      storeId: model.storeId,
      name: model.name,
      categoryIds: model.categoryIds,
      price: model.price,
      imagePaths: model.imagePaths,
      imageUrls: model.imageUrls,
      id: model.productId,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      purchaseLink: model.purchaseLink,
      material: model.material,
      elasticity: model.elasticity,
      fit: model.fit,
      thickness: model.thickness,
      styles: model.styles,
      sizes: model.sizes
          ?.map<_i2.ProductSizeModel>(
            (value) =>
                _map__i4$ProductSizeCollection_To__i2$ProductSizeModel(value),
          )
          .toList(),
    );
  }

  _i6.StoreProfile _map__i5$StoreProfileModel_To__i6$StoreProfile(
    _i5.StoreProfileModel? input,
  ) {
    final model = input;
    if (model == null) {
      throw Exception(
        r'Mapping StoreProfileModel → StoreProfile failed because StoreProfileModel was null, and no default value was provided. '
        r'Consider setting the whenSourceIsNull parameter on the MapType<StoreProfileModel, StoreProfile> to handle null values during mapping.',
      );
    }
    return _i6.StoreProfile(
      id: model.id,
      ownerId: model.ownerId,
      name: model.name,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      address: model.address,
      logoPath: model.logoPath,
      logoUrl: model.logoUrl,
    );
  }

  _i5.StoreProfileModel _map__i6$StoreProfile_To__i5$StoreProfileModel(
    _i6.StoreProfile? input,
  ) {
    final model = input;
    if (model == null) {
      throw Exception(
        r'Mapping StoreProfile → StoreProfileModel failed because StoreProfile was null, and no default value was provided. '
        r'Consider setting the whenSourceIsNull parameter on the MapType<StoreProfile, StoreProfileModel> to handle null values during mapping.',
      );
    }
    return _i5.StoreProfileModel(
      id: model.id,
      ownerId: model.ownerId,
      name: model.name,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      address: model.address,
      logoPath: model.logoPath,
      logoUrl: model.logoUrl,
    );
  }

  _i7.StoreProfileCollection
  _map__i5$StoreProfileModel_To__i7$StoreProfileCollection(
    _i5.StoreProfileModel? input,
  ) {
    final model = input;
    if (model == null) {
      throw Exception(
        r'Mapping StoreProfileModel → StoreProfileCollection failed because StoreProfileModel was null, and no default value was provided. '
        r'Consider setting the whenSourceIsNull parameter on the MapType<StoreProfileModel, StoreProfileCollection> to handle null values during mapping.',
      );
    }
    return _i7.StoreProfileCollection()
      ..storeId = model.id
      ..ownerId = model.ownerId
      ..name = model.name
      ..createdAt = model.createdAt
      ..updatedAt = model.updatedAt
      ..address = model.address
      ..logoPath = model.logoPath
      ..logoUrl = model.logoUrl;
  }

  _i5.StoreProfileModel
  _map__i7$StoreProfileCollection_To__i5$StoreProfileModel(
    _i7.StoreProfileCollection? input,
  ) {
    final model = input;
    if (model == null) {
      throw Exception(
        r'Mapping StoreProfileCollection → StoreProfileModel failed because StoreProfileCollection was null, and no default value was provided. '
        r'Consider setting the whenSourceIsNull parameter on the MapType<StoreProfileCollection, StoreProfileModel> to handle null values during mapping.',
      );
    }
    return _i5.StoreProfileModel(
      id: model.storeId,
      ownerId: model.ownerId,
      name: model.name,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      address: model.address,
      logoPath: model.logoPath,
      logoUrl: model.logoUrl,
    );
  }

  _i9.ProductAnalyticsSummary
  _map__i8$ProductAnalyticsSummaryModel_To__i9$ProductAnalyticsSummary(
    _i8.ProductAnalyticsSummaryModel? input,
  ) {
    final model = input;
    if (model == null) {
      throw Exception(
        r'Mapping ProductAnalyticsSummaryModel → ProductAnalyticsSummary failed because ProductAnalyticsSummaryModel was null, and no default value was provided. '
        r'Consider setting the whenSourceIsNull parameter on the MapType<ProductAnalyticsSummaryModel, ProductAnalyticsSummary> to handle null values during mapping.',
      );
    }
    return _i9.ProductAnalyticsSummary(
      productId: model.productId,
      viewCount: model.viewCount,
      tryonCount: model.tryonCount,
      purchaseClickCount: model.purchaseClickCount,
    );
  }

  _i10.ProductAnalyticsCollection
  _map__i8$ProductAnalyticsSummaryModel_To__i10$ProductAnalyticsCollection(
    _i8.ProductAnalyticsSummaryModel? input,
  ) {
    final model = input;
    if (model == null) {
      throw Exception(
        r'Mapping ProductAnalyticsSummaryModel → ProductAnalyticsCollection failed because ProductAnalyticsSummaryModel was null, and no default value was provided. '
        r'Consider setting the whenSourceIsNull parameter on the MapType<ProductAnalyticsSummaryModel, ProductAnalyticsCollection> to handle null values during mapping.',
      );
    }
    return _i10.ProductAnalyticsCollection()
      ..storeId = model.storeId
      ..productId = model.productId
      ..year = model.year
      ..month = model.month
      ..viewCount = model.viewCount
      ..tryonCount = model.tryonCount
      ..purchaseClickCount = model.purchaseClickCount;
  }

  _i8.ProductAnalyticsSummaryModel
  _map__i10$ProductAnalyticsCollection_To__i8$ProductAnalyticsSummaryModel(
    _i10.ProductAnalyticsCollection? input,
  ) {
    final model = input;
    if (model == null) {
      throw Exception(
        r'Mapping ProductAnalyticsCollection → ProductAnalyticsSummaryModel failed because ProductAnalyticsCollection was null, and no default value was provided. '
        r'Consider setting the whenSourceIsNull parameter on the MapType<ProductAnalyticsCollection, ProductAnalyticsSummaryModel> to handle null values during mapping.',
      );
    }
    return _i8.ProductAnalyticsSummaryModel(
      storeId: model.storeId,
      productId: model.productId,
      year: model.year,
      month: model.month,
      viewCount: model.viewCount,
      tryonCount: model.tryonCount,
      purchaseClickCount: model.purchaseClickCount,
    );
  }

  _i12.Measurements _map__i11$MeasurementsModel_To__i12$Measurements(
    _i11.MeasurementsModel? input,
  ) {
    final model = input;
    if (model == null) {
      throw Exception(
        r'Mapping MeasurementsModel → Measurements failed because MeasurementsModel was null, and no default value was provided. '
        r'Consider setting the whenSourceIsNull parameter on the MapType<MeasurementsModel, Measurements> to handle null values during mapping.',
      );
    }
    return _i12.Measurements(
      height: model.height,
      chest: model.chest,
      waist: model.waist,
      hips: model.hips,
      shoulder: model.shoulder,
      sleeve: model.sleeve,
      heightOffset: model.heightOffset,
      chestOffset: model.chestOffset,
      waistOffset: model.waistOffset,
      hipsOffset: model.hipsOffset,
      shoulderOffset: model.shoulderOffset,
      sleeveOffset: model.sleeveOffset,
    );
  }

  _i11.MeasurementsModel _map__i12$Measurements_To__i11$MeasurementsModel(
    _i12.Measurements? input,
  ) {
    final model = input;
    if (model == null) {
      throw Exception(
        r'Mapping Measurements → MeasurementsModel failed because Measurements was null, and no default value was provided. '
        r'Consider setting the whenSourceIsNull parameter on the MapType<Measurements, MeasurementsModel> to handle null values during mapping.',
      );
    }
    return _i11.MeasurementsModel(
      height: model.height,
      chest: model.chest,
      waist: model.waist,
      hips: model.hips,
      shoulder: model.shoulder,
      sleeve: model.sleeve,
      heightOffset: model.heightOffset,
      chestOffset: model.chestOffset,
      waistOffset: model.waistOffset,
      hipsOffset: model.hipsOffset,
      shoulderOffset: model.shoulderOffset,
      sleeveOffset: model.sleeveOffset,
    );
  }

  _i13.MeasurementsCollection
  _map__i11$MeasurementsModel_To__i13$MeasurementsCollection(
    _i11.MeasurementsModel? input,
  ) {
    final model = input;
    if (model == null) {
      throw Exception(
        r'Mapping MeasurementsModel → MeasurementsCollection failed because MeasurementsModel was null, and no default value was provided. '
        r'Consider setting the whenSourceIsNull parameter on the MapType<MeasurementsModel, MeasurementsCollection> to handle null values during mapping.',
      );
    }
    return _i13.MeasurementsCollection()
      ..height = model.height
      ..chest = model.chest
      ..waist = model.waist
      ..hips = model.hips
      ..shoulder = model.shoulder
      ..sleeve = model.sleeve
      ..heightOffset = model.heightOffset
      ..chestOffset = model.chestOffset
      ..waistOffset = model.waistOffset
      ..hipsOffset = model.hipsOffset
      ..shoulderOffset = model.shoulderOffset
      ..sleeveOffset = model.sleeveOffset;
  }

  _i11.MeasurementsModel
  _map__i13$MeasurementsCollection_To__i11$MeasurementsModel(
    _i13.MeasurementsCollection? input,
  ) {
    final model = input;
    if (model == null) {
      throw Exception(
        r'Mapping MeasurementsCollection → MeasurementsModel failed because MeasurementsCollection was null, and no default value was provided. '
        r'Consider setting the whenSourceIsNull parameter on the MapType<MeasurementsCollection, MeasurementsModel> to handle null values during mapping.',
      );
    }
    return _i11.MeasurementsModel(
      height: model.height,
      chest: model.chest,
      waist: model.waist,
      hips: model.hips,
      shoulder: model.shoulder,
      sleeve: model.sleeve,
      heightOffset: model.heightOffset,
      chestOffset: model.chestOffset,
      waistOffset: model.waistOffset,
      hipsOffset: model.hipsOffset,
      shoulderOffset: model.shoulderOffset,
      sleeveOffset: model.sleeveOffset,
    );
  }

  _i12.Measurements? _map__i11$MeasurementsModel_To__i12$Measurements_Nullable(
    _i11.MeasurementsModel? input,
  ) {
    final model = input;
    if (model == null) {
      return null;
    }
    return _i12.Measurements(
      height: model.height,
      chest: model.chest,
      waist: model.waist,
      hips: model.hips,
      shoulder: model.shoulder,
      sleeve: model.sleeve,
      heightOffset: model.heightOffset,
      chestOffset: model.chestOffset,
      waistOffset: model.waistOffset,
      hipsOffset: model.hipsOffset,
      shoulderOffset: model.shoulderOffset,
      sleeveOffset: model.sleeveOffset,
    );
  }

  _i11.MeasurementsModel?
  _map__i12$Measurements_To__i11$MeasurementsModel_Nullable(
    _i12.Measurements? input,
  ) {
    final model = input;
    if (model == null) {
      return null;
    }
    return _i11.MeasurementsModel(
      height: model.height,
      chest: model.chest,
      waist: model.waist,
      hips: model.hips,
      shoulder: model.shoulder,
      sleeve: model.sleeve,
      heightOffset: model.heightOffset,
      chestOffset: model.chestOffset,
      waistOffset: model.waistOffset,
      hipsOffset: model.hipsOffset,
      shoulderOffset: model.shoulderOffset,
      sleeveOffset: model.sleeveOffset,
    );
  }

  _i13.MeasurementsCollection?
  _map__i11$MeasurementsModel_To__i13$MeasurementsCollection_Nullable(
    _i11.MeasurementsModel? input,
  ) {
    final model = input;
    if (model == null) {
      return null;
    }
    return _i13.MeasurementsCollection()
      ..height = model.height
      ..chest = model.chest
      ..waist = model.waist
      ..hips = model.hips
      ..shoulder = model.shoulder
      ..sleeve = model.sleeve
      ..heightOffset = model.heightOffset
      ..chestOffset = model.chestOffset
      ..waistOffset = model.waistOffset
      ..hipsOffset = model.hipsOffset
      ..shoulderOffset = model.shoulderOffset
      ..sleeveOffset = model.sleeveOffset;
  }

  _i11.MeasurementsModel?
  _map__i13$MeasurementsCollection_To__i11$MeasurementsModel_Nullable(
    _i13.MeasurementsCollection? input,
  ) {
    final model = input;
    if (model == null) {
      return null;
    }
    return _i11.MeasurementsModel(
      height: model.height,
      chest: model.chest,
      waist: model.waist,
      hips: model.hips,
      shoulder: model.shoulder,
      sleeve: model.sleeve,
      heightOffset: model.heightOffset,
      chestOffset: model.chestOffset,
      waistOffset: model.waistOffset,
      hipsOffset: model.hipsOffset,
      shoulderOffset: model.shoulderOffset,
      sleeveOffset: model.sleeveOffset,
    );
  }
}
