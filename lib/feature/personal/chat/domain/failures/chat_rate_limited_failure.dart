import 'package:tryzeon/core/error/failures.dart';

class ChatRateLimitedFailure extends RateLimitFailure {
  const ChatRateLimitedFailure([super.message]);

  @override
  String get defaultMessage => '今天聊得比較多了，休息一下再來找我';
}
