import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pub_semver/pub_semver.dart';

class UpdateService {
  final _log = Logger('UpdateService');
  final String _owner = 'YeLauncher';
  final String _repo = 'YeLauncher';

  /// Checks if an update is available. Returns the download URL if available, null otherwise.
  Future<String?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(packageInfo.version);

      final url = Uri.parse('https://api.github.com/repos/$_owner/$_repo/releases/latest');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tagName = data['tag_name'] as String;
        // Handle tags like 'v1.0.0'
        final versionString = tagName.startsWith('v') ? tagName.substring(1) : tagName;
        final latestVersion = Version.parse(versionString);

        if (latestVersion > currentVersion) {
          final assets = data['assets'] as List;
          return _getAssetUrl(assets);
        }
      } else {
        _log.warning('Failed to fetch latest release: ${response.statusCode}');
      }
    } catch (e, st) {
      _log.severe('Error checking for updates', e, st);
    }
    return null;
  }

  String? _getAssetUrl(List assets) {
    String suffix = '';
    if (Platform.isWindows) {
      suffix = '.msix';
    } else if (Platform.isLinux) {
      suffix = '.AppImage';
    } else if (Platform.isMacOS) {
      suffix = '.dmg';
    }

    for (var asset in assets) {
      final name = asset['name'] as String;
      if (name.endsWith(suffix)) {
        return asset['browser_download_url'] as String;
      }
    }
    return null;
  }

  /// Downloads the update to a temporary file and returns its path.
  Future<File?> downloadUpdate(String url, void Function(double) onProgress) async {
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        _log.warning('Failed to download update: ${response.statusCode}');
        return null;
      }

      final contentLength = response.contentLength;
      var receivedBytes = 0;

      final tempDir = await getTemporaryDirectory();
      // Use the filename from the URL
      final fileName = Uri.parse(url).pathSegments.last;
      final file = File(p.join(tempDir.path, fileName));
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (contentLength != null) {
          onProgress(receivedBytes / contentLength);
        }
      }
      await sink.close();
      return file;
    } catch (e, st) {
      _log.severe('Error downloading update', e, st);
      return null;
    }
  }

  /// Installs the update by launching the downloaded file.
  Future<void> installUpdate(File file) async {
    try {
      if (Platform.isWindows) {
        // Open the file with the default associated program (App Installer for .msix)
        await Process.run('explorer.exe', [file.path]);
        exit(0);
      } else if (Platform.isLinux) {
        // Make executable and run
        await Process.run('chmod', ['+x', file.path]);
        await Process.start(file.path, []);
        exit(0);
      } else if (Platform.isMacOS) {
        await Process.run('open', [file.path]);
        exit(0);
      }
    } catch (e, st) {
      _log.severe('Error installing update', e, st);
    }
  }
}
