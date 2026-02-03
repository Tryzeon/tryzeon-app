import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';

import '../home/presentation/pages/home_page.dart';
import '../onboarding/presentation/pages/store_onboarding_page.dart';

/// 店家入口 - 負責判斷是否需要 onboarding
class StoreEntry extends HookConsumerWidget {
  const StoreEntry({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    ref.listen(storeProfileProvider, (final previous, final next) {
      if (next is AsyncError) {
        TopNotification.show(
          context,
          message: (next.error! as Failure).displayMessage(context),
          type: NotificationType.error,
        );
      }
    });

    final profileAsync = ref.watch(storeProfileProvider);

    if (profileAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (profileAsync.valueOrNull != null) {
      return const StoreHomePage();
    }

    return const PopScope(canPop: false, child: StoreOnboardingPage());
  }
}
