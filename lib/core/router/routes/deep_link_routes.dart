import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/router/app_routes.dart';

final deepLinkRoutes = [
  GoRoute(
    path: AppRoutes.deepLinkProduct,
    redirect: (final context, final state) {
      final productId = state.pathParameters[AppRoutes.paramProductId]!;
      final colorId = state.uri.queryParameters[AppRoutes.queryColor];
      return AppRoutes.personalShopProductPath(productId, colorId: colorId);
    },
  ),
  GoRoute(
    path: AppRoutes.deepLinkStore,
    redirect: (final context, final state) {
      final storeId = state.pathParameters[AppRoutes.paramStoreId]!;
      return AppRoutes.personalShopStorePath(storeId);
    },
  ),
];
