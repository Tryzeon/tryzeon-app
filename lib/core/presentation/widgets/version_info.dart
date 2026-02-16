import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:tryzeon/core/utils/app_logger.dart';

class VersionInfo extends ConsumerWidget {
  const VersionInfo({required this.versionProvider, super.key});

  final Future<String> Function(WidgetRef ref) versionProvider;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return FutureBuilder<String>(
      future: versionProvider(ref),
      builder: (final context, final snapshot) {
        return Center(
          child: GestureDetector(
            onLongPress: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (final context) => TalkerScreen(talker: AppLogger.talker),
                ),
              );
            },
            child: Text(
              'Version ${snapshot.data ?? '...'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      },
    );
  }
}
