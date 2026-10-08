import 'package:flutter/widgets.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:typed_result/typed_result.dart';

extension RefreshFeedback on Iterable<Future<Result<void, Failure>>> {
  Future<void> showFirstFailure(final BuildContext context) async {
    final results = await Future.wait(this);
    final failure = results
        .map((final result) => result.getError())
        .nonNulls
        .firstOrNull;
    if (failure == null || !context.mounted) return;
    TopNotification.show(context, message: failure.displayMessage());
  }
}
