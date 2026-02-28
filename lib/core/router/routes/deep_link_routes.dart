import 'package:go_router/go_router.dart';

final deepLinkRoutes = [
  GoRoute(
    path: '/product/:productId',
    redirect: (final context, final state) {
      final productId = state.pathParameters['productId']!;
      return '/personal/shop/product/$productId';
    },
  ),
  GoRoute(
    path: '/shop/:storeId',
    redirect: (final context, final state) {
      final storeId = state.pathParameters['storeId']!;
      return '/personal/shop/store/$storeId';
    },
  ),
];
