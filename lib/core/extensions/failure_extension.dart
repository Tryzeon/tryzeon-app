import 'package:tryzeon/core/error/failures.dart';

extension FailureMessage on Failure {
  String displayMessage() => message ?? defaultMessage;
}

extension ErrorDisplayMessage on Object? {
  String displayMessage() {
    final error = this;

    if (error is Failure) {
      return error.displayMessage();
    }

    if (error is String && error.isNotEmpty) {
      return error;
    }

    return const UnknownFailure().displayMessage();
  }
}
