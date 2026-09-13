import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class StoreAddProductFab extends StatelessWidget {
  const StoreAddProductFab({super.key});

  @override
  Widget build(final BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: AppSpacing.bottomNavBarOverlap),
    child: FloatingActionButton(
      heroTag: null,
      onPressed: () => context.push(AppRoutes.dashboardProductAdd),
      tooltip: '新增商品',
      child: const Icon(Icons.add_rounded),
    ),
  );
}
