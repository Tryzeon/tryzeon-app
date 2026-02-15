import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/feature/personal/subscription/data/collections/subscription_collection.dart';
import 'package:tryzeon/feature/personal/subscription/data/mappers/subscription_mapper.dart';
import 'package:tryzeon/feature/personal/subscription/data/models/subscription_model.dart';

class SubscriptionLocalDataSource {
  SubscriptionLocalDataSource(this._isarService);

  final IsarService _isarService;

  Future<SubscriptionModel?> getSubscription(final String userId) async {
    final isar = await _isarService.db;
    final collection = await isar.subscriptionCollections.getByUserId(userId);
    if (collection == null) return null;

    if (collection.lastUpdated == null ||
        DateTime.now().difference(collection.lastUpdated!) >
            AppConstants.staleDurationSubscription) {
      return null;
    }

    return collection.toModel();
  }

  Future<void> saveSubscription(final SubscriptionModel subscription) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final collection = subscription.toCollection();
      collection.lastUpdated = DateTime.now();
      await isar.subscriptionCollections.put(collection);
    });
  }
}
