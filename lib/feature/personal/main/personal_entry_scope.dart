import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../home/domain/entities/tryon_mode.dart';
import '../home/presentation/pages/home_page.dart';

class PersonalEntryScope extends InheritedWidget {
  const PersonalEntryScope({
    super.key,
    required this.tryOnFromStorage,
    required this.homePageController,
    required super.child,
  });

  final Future<void> Function(String clothesPath, {TryOnMode mode}) tryOnFromStorage;
  final HomePageController homePageController;

  static PersonalEntryScope? of(final BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PersonalEntryScope>();
  }

  @override
  bool updateShouldNotify(final PersonalEntryScope oldWidget) {
    return oldWidget.tryOnFromStorage != tryOnFromStorage;
  }
}
