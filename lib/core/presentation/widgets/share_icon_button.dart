import 'package:flutter/material.dart';
import 'package:tryzeon/core/presentation/actions/share_link.dart';

class ShareIconButton extends StatelessWidget {
  const ShareIconButton({super.key, required this.url});

  final String url;

  @override
  Widget build(final BuildContext context) {
    return IconButton(
      onPressed: () => shareLink(context, url),
      icon: Icon(Icons.adaptive.share),
    );
  }
}
