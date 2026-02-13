import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class VersionInfo extends ConsumerWidget {
  const VersionInfo({required this.versionProvider, super.key});

  final Future<String> Function(WidgetRef ref) versionProvider;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return FutureBuilder<String>(
      future: versionProvider(ref),
      builder: (final context, final snapshot) {
        return Center(
          child: Text(
            'Version ${snapshot.data ?? '...'}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
        );
      },
    );
  }
}
