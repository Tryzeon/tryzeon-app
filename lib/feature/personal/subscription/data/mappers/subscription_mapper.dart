import 'package:tryzeon/feature/personal/subscription/data/collections/subscription_collection.dart';
import 'package:tryzeon/feature/personal/subscription/data/models/subscription_model.dart';

extension SubscriptionModelMapper on SubscriptionModel {
  SubscriptionCollection toCollection() {
    return SubscriptionCollection()
      ..userId = userId
      ..plan = plan;
  }
}

extension SubscriptionCollectionMapper on SubscriptionCollection {
  SubscriptionModel toModel() {
    return SubscriptionModel(userId: userId, plan: plan);
  }
}
