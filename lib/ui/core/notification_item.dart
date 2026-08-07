import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';
import 'package:yelauncher/domain/models/notification/notification_model.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:yelauncher/ui/core/icon_button.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRunning = notification.status == NotificationStatus.running;
    final bool hasProgress = notification.progress != null;

    IconData statusIcon;
    Color statusColor;

    switch (notification.status) {
      case NotificationStatus.running:
        statusIcon = Symbols.downloading_rounded;
        statusColor = AppColors.dark.primary;
        break;
      case NotificationStatus.completed:
        statusIcon = Symbols.check_circle_rounded;
        statusColor = const Color(0xFF4CAF50); // Success green
        break;
      case NotificationStatus.failed:
        statusIcon = Symbols.error_rounded;
        statusColor = AppColors.dark.error;
        break;
      case NotificationStatus.cancelled:
        statusIcon = Symbols.cancel_rounded;
        statusColor = AppColors.dark.onSurfaceVariant;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  notification.title,
                  style: AppText.defaultTheme.labelLarge.copyWith(
                    color: AppColors.dark.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isRunning)
                IconButton.surface(
                  iconData: Symbols.close_rounded,
                  onPressed: notification.onCancel ?? () {},
                )
              else
                IconButton.surface(
                  iconData: Symbols.close_rounded,
                  onPressed: onDismiss,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 28),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.description,
                      style: AppText.defaultTheme.bodyMedium.copyWith(
                        color: AppColors.dark.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isRunning && hasProgress) ...[
                      const SizedBox(height: 12),
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.dark.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: notification.progress ?? 0),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, value, child) {
                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Previews
// -----------------------------------------------------------------------------

@Preview(name: 'Running', group: 'Notification Item')
Widget runningNotificationPreview() {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Container(
      color: AppColors.dark.surfaceContainerHigh,
      width: 360,
      child: NotificationItem(
        notification: const NotificationModel(
          id: '1',
          title: 'Downloading Fabric Loader',
          description: '45% - 2.1 MB / 4.5 MB',
          progress: 0.45,
          status: NotificationStatus.running,
        ),
        onDismiss: () {},
      ),
    ),
  );
}

@Preview(name: 'Completed', group: 'Notification Item')
Widget completedNotificationPreview() {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Container(
      color: AppColors.dark.surfaceContainerHigh,
      width: 360,
      child: NotificationItem(
        notification: const NotificationModel(
          id: '2',
          title: 'Installation Complete',
          description: 'Successfully installed Minecraft 1.20.1',
          status: NotificationStatus.completed,
        ),
        onDismiss: () {},
      ),
    ),
  );
}

@Preview(name: 'Failed', group: 'Notification Item')
Widget failedNotificationPreview() {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Container(
      color: AppColors.dark.surfaceContainerHigh,
      width: 360,
      child: NotificationItem(
        notification: const NotificationModel(
          id: '3',
          title: 'Installation Failed',
          description: 'Network connection lost',
          status: NotificationStatus.failed,
        ),
        onDismiss: () {},
      ),
    ),
  );
}

@Preview(name: 'Cancelled', group: 'Notification Item')
Widget cancelledNotificationPreview() {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Container(
      color: AppColors.dark.surfaceContainerHigh,
      width: 360,
      child: NotificationItem(
        notification: const NotificationModel(
          id: '4',
          title: 'Download Cancelled',
          description: 'Cancelled by user',
          status: NotificationStatus.cancelled,
        ),
        onDismiss: () {},
      ),
    ),
  );
}
