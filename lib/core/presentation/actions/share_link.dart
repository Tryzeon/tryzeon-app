import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareLink(final BuildContext context, final String url) {
  final box = context.findRenderObject()! as RenderBox;
  return SharePlus.instance.share(
    ShareParams(
      text: url,
      sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}
