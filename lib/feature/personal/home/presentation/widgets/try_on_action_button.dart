import 'package:flutter/material.dart';

class TryOnActionButton extends StatelessWidget {
  const TryOnActionButton({super.key, required this.onTap, this.isDisabled = false});

  final VoidCallback? onTap;
  final bool isDisabled;

  @override
  Widget build(final BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isDisabled ? null : onTap,
      icon: const Icon(Icons.auto_awesome_rounded),
      label: const Text('虛擬試穿'),
    );
  }
}
