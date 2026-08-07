import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/data/services/download_service.dart';
import 'package:yelauncher/domain/models/content/content_file.dart';
import 'package:yelauncher/domain/models/content/content_item.dart';
import 'package:yelauncher/domain/models/content/content_version.dart';
import 'package:yelauncher/domain/models/download/cancellation_token.dart';
import 'package:yelauncher/domain/models/download/download_model.dart';
import 'package:yelauncher/domain/models/instance/installed_content_model.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';
import 'package:yelauncher/domain/models/notification/notification_model.dart';
import 'package:yelauncher/ui/core/toast/toast_service.dart';

class NotificationProvider extends ChangeNotifier {
  final List<NotificationModel> _notifications = [];

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);

  int get activeCount =>
      _notifications.where((n) => n.status == NotificationStatus.running).length;

  void dismiss(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void _updateNotification(
    String id, {
    String? title,
    String? description,
    double? progress,
    NotificationStatus? status,
  }) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(
        title: title,
        description: description,
        progress: progress,
        status: status,
      );
      notifyListeners();
    }
  }

  Future<void> startInstallation({
    required DownloadService downloadService,
    required InstanceRepository instanceRepo,
    required InstanceModel selectedInstance,
    required ContentItem mainItem,
    required ContentVersion mainVersion,
    required List<Map<String, dynamic>> dependenciesToInstall,
    required ToastService toastService,
  }) async {
    final notificationId = DateTime.now().millisecondsSinceEpoch.toString();
    final token = CancellationToken();

    _notifications.insert(
      0,
      NotificationModel(
        id: notificationId,
        title: 'Installing ${mainItem.title}',
        description: 'Preparing...',
        progress: 0.0,
        cancellationToken: token,
        onCancel: () {
          token.cancel();
          _updateNotification(
            notificationId,
            status: NotificationStatus.cancelled,
            description: 'Cancelled',
          );
        },
      ),
    );
    notifyListeners();

    toastService.show(
      title: 'Installation Started',
      description: 'Downloading ${mainItem.title}',
      type: ToastType.info,
    );

    try {
      final allInstances = await instanceRepo.getInstances();
      final currentInstance = allInstances.firstWhere(
        (i) => i.id == selectedInstance.id,
      );

      final newInstalledContent = List<InstalledContentModel>.from(
        currentInstance.installedContent,
      );

      Future<void> downloadAndInstall(ContentItem item, ContentVersion version) async {
        if (newInstalledContent.any(
          (c) => c.projectId == item.id && c.versionId == version.id,
        )) {
          return;
        }

        final type = item.projectType;
        ContentFile? file;

        if (type == 'mod') {
          final loader = selectedInstance.modLoader.toLowerCase();
          if (loader.isNotEmpty && loader != 'none' && loader != 'vanilla') {
            for (final f in version.files) {
              if (f.filename.toLowerCase().contains(loader)) {
                file = f;
                break;
              }
            }
          }
        }

        file ??= version.files.firstWhere(
          (f) => f.primary,
          orElse: () => version.files.first,
        );

        final url = file.url;
        final fileName = Uri.decodeFull(file.filename);

        final folderName = switch (type) {
          'resourcepack' => 'resourcepacks',
          'shader' => 'shaderpacks',
          _ => 'mods',
        };
        final relativePath = 'instances/${selectedInstance.id}/$folderName/$fileName';

        await downloadService.downloadIfMissing(
          DownloadModel(url: url, path: relativePath, sha1: ''),
          onProgress: (downloaded, total) {
            if (total != null && total > 0) {
              _updateNotification(
                notificationId,
                description: 'Downloading ${item.title}...',
                progress: (downloaded / total).clamp(0.0, 1.0),
              );
            }
          },
          cancellationToken: token,
        );

        // Remove existing installed content if present
        final existingIndex = newInstalledContent.indexWhere(
          (c) => c.projectId == item.id,
        );
        if (existingIndex != -1) {
          final oldContent = newInstalledContent[existingIndex];
          final appData = await getApplicationSupportDirectory();
          final oldFile = File(
            p.join(
              appData.path,
              'instances',
              selectedInstance.id,
              folderName,
              Uri.decodeFull(oldContent.filename),
            ),
          );

          if (await oldFile.exists()) {
            await oldFile.delete();
          }
          final disabledOldFile = File('${oldFile.path}.disabled');
          if (await disabledOldFile.exists()) {
            await disabledOldFile.delete();
          }
          newInstalledContent.removeAt(existingIndex);
        }

        final content = InstalledContentModel(
          projectId: item.id,
          versionId: version.id,
          filename: Uri.decodeFull(fileName),
          title: item.title,
          type: type,
          author: item.author ?? 'Unknown Author',
          version: version.versionNumber,
          iconUrl: item.iconUrl,
        );
        newInstalledContent.add(content);
      }

      await downloadAndInstall(mainItem, mainVersion);

      for (final dep in dependenciesToInstall) {
        final depItem = dep['item'] as ContentItem;
        final depVersion = dep['version'] as ContentVersion;
        await downloadAndInstall(depItem, depVersion);
      }

      final updatedInstance = currentInstance.copyWith(
        installedContent: newInstalledContent,
      );
      await instanceRepo.saveInstance(updatedInstance);

      if (!token.isCancelled) {
        _updateNotification(
          notificationId,
          status: NotificationStatus.completed,
          description: 'Completed',
          progress: 1.0,
        );

        toastService.show(
          title: 'Installation Complete',
          description: 'Successfully installed ${mainItem.title}',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (e is CancelledException) return;

      _updateNotification(
        notificationId,
        status: NotificationStatus.failed,
        description: e.toString(),
      );

      toastService.show(
        title: 'Installation Failed',
        description: 'Failed to install ${mainItem.title}',
        type: ToastType.error,
      );
    }
  }
}
