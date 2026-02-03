import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:tryzeon/core/config/app_constants.dart';

enum NotificationType { success, error, info, warning }

class TopNotification {
  static void show(
    final BuildContext context, {
    required final String message,
    final NotificationType type = NotificationType.info,
  }) {
    final duration = type == NotificationType.error
        ? AppConstants.errorToastDuration
        : AppConstants.toastDuration;

    toastification.showCustom(
      context: context,
      autoCloseDuration: duration,
      alignment: Alignment.topCenter,
      direction: TextDirection.ltr,
      animationDuration: AppConstants.defaultAnimationDuration,
      animationBuilder: (final context, final animation, final alignment, final child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
        );
      },
      builder: (final context, final holder) {
        final (iconColor, icon) = _getStyle(type);

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: Colors.transparent,
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 4, color: iconColor),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(icon, color: iconColor, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    message,
                                    style: TextStyle(
                                      color: Colors.grey[900],
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => toastification.dismiss(holder),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.grey[400],
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static (Color, IconData) _getStyle(final NotificationType type) {
    return switch (type) {
      NotificationType.success => (const Color(0xFF10B981), Icons.check_circle),
      NotificationType.error => (const Color(0xFFEF4444), Icons.cancel),
      NotificationType.warning => (const Color(0xFFF59E0B), Icons.warning),
      NotificationType.info => (const Color(0xFF3B82F6), Icons.info),
    };
  }
}
