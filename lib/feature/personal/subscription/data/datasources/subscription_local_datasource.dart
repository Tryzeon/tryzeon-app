import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/subscription/data/collections/subscription_collection.dart';
import 'package:tryzeon/feature/personal/subscription/data/models/subscription_model.dart';

class SubscriptionLocalDataSource {
  SubscriptionLocalDataSource(this._isarService);

  final IsarService _isarService;
  static const _mappr = PersonalMappr();

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
}
