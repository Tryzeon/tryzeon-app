import 'package:talker_flutter/talker_flutter.dart';

class AppLogger {
  static final Talker talker = TalkerFlutter.init(
    logger: TalkerLogger(settings: TalkerLoggerSettings(enableColors: false)),
  );

  static StackTrace? _cropStackTrace(final StackTrace? stackTrace) {
    if (stackTrace == null) return null;

    final lines = stackTrace.toString().split('\n');

    if (lines.length <= 15) return stackTrace;

    final croppedString = '${lines.take(15).join('\n')}\n... (truncated)';

    return StackTrace.fromString(croppedString);
  }

  static void debug(
    final dynamic message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) {
    talker.debug(message, error, _cropStackTrace(stackTrace));
  }

  static void info(
    final dynamic message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) {
    talker.info(message, error, _cropStackTrace(stackTrace));
  }

  static void warning(
    final dynamic message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) {
    talker.warning(message, error, _cropStackTrace(stackTrace));
  }

  static void error(
    final dynamic message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) {
    talker.error(message, error, _cropStackTrace(stackTrace));
  }

  static void fatal(
    final dynamic message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) {
    talker.critical(message, error, _cropStackTrace(stackTrace));
  }
}
