import 'package:flutter/material.dart';
import 'package:tryzeon/core/presentation/dialogs/upgrade_dialog.dart';

Future<void> showWardrobeFullDialog(final BuildContext context) => UpgradeDialog.show(
  context,
  title: '衣櫃已達上限',
  content: '您的衣櫃容量已達上限\n升級至更高方案以獲得更多儲存空間！',
);
