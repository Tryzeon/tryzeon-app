import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/subscription/data/collections/subscription_collection.dart';
import 'package:tryzeon/feature/personal/subscription/data/collections/subscription_plan_collection.dart';
import 'package:tryzeon/feature/personal/subscription/data/models/subscription_model.dart';
import 'package:tryzeon/feature/personal/subscription/data/models/subscription_plan_model.dart';

class SubscriptionLocalDataSource {
  SubscriptionLocalDataSource(this._isarService);

  final IsarService _isarService;
  static const _mappr = PersonalMappr();

  // --- Subscription ---
  Future<SubscriptionModel?> getSubscription(final String userId) async {
    final isar = await _isarService.db;
    final collection = await isar.subscriptionCollections.getByUserId(userId);
    if (collection == null) return null;

    if (collection.lastUpdated == null ||
        DateTime.now().difference(collection.lastUpdated!) >
            AppConstants.staleDurationSubscription) {
      return null;
    }

    final model = _mappr.convert<SubscriptionCollection, SubscriptionModel>(collection);
    return model;
  }

  Future<void> saveSubscription(final SubscriptionModel subscription) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final collection = _mappr.convert<SubscriptionModel, SubscriptionCollection>(
        subscription,
      );
      collection.lastUpdated = DateTime.now();
      await isar.subscriptionCollections.put(collection);
    });
  }

  // --- Subscription Plans ---
  Future<List<SubscriptionPlanModel>?> getSubscriptionPlans() async {
    final isar = await _isarService.db;
    final collections = await isar.subscriptionPlanCollections
        .where()
        .anySortOrder()
        .findAll();
    if (collections.isEmpty) return null;

    final firstItem = collections.first;
    if (firstItem.lastUpdated == null ||
        DateTime.now().difference(firstItem.lastUpdated!) >
            AppConstants.staleDurationSubscriptionPlans) {
      return null;
    }

    final models = collections.map((final c) =>
              _mappr.convert<SubscriptionPlanCollection, SubscriptionPlanModel>(c),
        ).toList()
        ..sort((final a, final b) => a.sortOrder.compareTo(b.sortOrder));
    return models;
  }

  Future<void> saveSubscriptionPlans(final List<SubscriptionPlanModel> plans) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.subscriptionPlanCollections.clear();
      for (final plan in plans) {
        final collection = _mappr
            .convert<SubscriptionPlanModel, SubscriptionPlanCollection>(plan);
        collection.lastUpdated = DateTime.now();
        await isar.subscriptionPlanCollections.put(collection);
      }
    });
  }
}
