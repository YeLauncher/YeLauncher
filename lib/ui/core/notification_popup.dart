import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';
import 'package:provider/provider.dart';
import 'package:yelauncher/ui/core/notification_provider.dart';
import 'package:yelauncher/domain/models/notification/notification_model.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'package:yelauncher/l10n/app_localizations.dart';
import 'package:yelauncher/ui/core/notification_item.dart';

class NotificationPopup extends StatelessWidget {
  const NotificationPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;
    final loc = AppLocalizations.of(context)!;

    return Container(
      width: 360,
      constraints: const BoxConstraints(maxHeight: 480),
      decoration: BoxDecoration(
        color: AppColors.dark.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dark.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x00000000).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.notificationsTitle,
                  style: AppText.defaultTheme.titleMedium.copyWith(
                    color: AppColors.dark.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (notifications.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      for (final n in notifications) {
                        if (n.status != NotificationStatus.running) {
                          provider.dismiss(n.id);
                        }
                      }
                    },
                    child: Text(
                      'Clear',
                      style: AppText.defaultTheme.labelMedium.copyWith(
                        color: AppColors.dark.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: AppColors.dark.outlineVariant.withValues(alpha: 0.5),
          ),
          if (notifications.isEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: 32.0,
                right: 32.0,
                bottom: 32.0,
                top: 16.0,
              ),
              child: Center(
                child: Text(
                  loc.noNotifications, // Add this to arb
                  style: AppText.defaultTheme.bodyMedium.copyWith(
                    color: AppColors.dark.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                itemCount: notifications.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return NotificationItem(
                    notification: notification,
                    onDismiss: () => provider.dismiss(notification.id),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _MockNotificationProvider extends NotificationProvider {
  @override
  List<NotificationModel> get notifications => [
    const NotificationModel(
      id: '1',
      title: 'Downloading Fabric Loader',
      description: '45% - 2.1 MB / 4.5 MB',
      progress: 0.45,
      status: NotificationStatus.running,
    ),
    const NotificationModel(
      id: '2',
      title: 'Installation Complete',
      description: 'Successfully installed Minecraft 1.20.1',
      status: NotificationStatus.completed,
    ),
    const NotificationModel(
      id: '3',
      title: 'Installation Failed',
      description: 'Network connection lost',
      status: NotificationStatus.failed,
    ),
    const NotificationModel(
      id: '4',
      title: 'Download Cancelled',
      description: 'Cancelled by user',
      status: NotificationStatus.cancelled,
    ),
  ];
}

class _EmptyNotificationProvider extends NotificationProvider {
  @override
  List<NotificationModel> get notifications => [];
}

@Preview(name: 'Populated Notifications', group: 'Notification Popup')
Widget populatedNotificationPopupPreview() {
  return WidgetsApp(
    color: AppColors.dark.primary,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) {
      return ChangeNotifierProvider<NotificationProvider>(
        create: (_) => _MockNotificationProvider(),
        child: const Center(child: NotificationPopup()),
      );
    },
  );
}

@Preview(name: 'Empty Notifications', group: 'Notification Popup')
Widget emptyNotificationPopupPreview() {
  return WidgetsApp(
    color: AppColors.dark.primary,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) {
      return ChangeNotifierProvider<NotificationProvider>(
        create: (_) => _EmptyNotificationProvider(),
        child: const Center(child: NotificationPopup()),
      );
    },
  );
}
