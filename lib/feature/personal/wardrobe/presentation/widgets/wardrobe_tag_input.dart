import 'package:flutter/material.dart';

class WardrobeTagInput extends StatelessWidget {
  const WardrobeTagInput({
    super.key,
    required this.controller,
    required this.onAdd,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final VoidCallback onAdd;
  final bool autofocus;

  @override
  Widget build(final BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      textInputAction: TextInputAction.done,
      style: Theme.of(context).textTheme.bodyLarge,
      onSubmitted: (final _) => onAdd(),
      decoration: InputDecoration(
        hintText: '新增標籤...',
        suffixIcon: IconButton(
          tooltip: '新增標籤',
          icon: const Icon(Icons.add_rounded),
          onPressed: onAdd,
        ),
      ),
    );
  }
}
