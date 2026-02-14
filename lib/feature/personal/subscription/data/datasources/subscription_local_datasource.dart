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
    return collection?.toModel();
  }

  Future<void> saveSubscription(final SubscriptionModel subscription) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.subscriptionCollections.put(subscription.toCollection());
    });
  }
}
