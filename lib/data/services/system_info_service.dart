import 'dart:io';
import 'package:logging/logging.dart';

/// Service to query system hardware information such as total physical RAM.
class SystemInfoService {
  static final _logger = Logger('SystemInfoService');

  /// Fallback value if we cannot detect the system's physical RAM.
  static const int _defaultMemoryMB = 8192;

  /// Gets the total physical memory of the system in megabytes.
  ///
  /// Falls back to [_defaultMemoryMB] (8 GB) if detection fails.
  Future<int> getTotalPhysicalMemoryMB() async {
    try {
      if (Platform.isWindows) {
        return await _getWindowsMemory();
      } else if (Platform.isMacOS) {
        return await _getMacOSMemory();
      } else if (Platform.isLinux) {
        return await _getLinuxMemory();
      }
    } catch (e, stack) {
      _logger.warning(
        'Failed to fetch physical memory, falling back to ${_defaultMemoryMB}MB.',
        e,
        stack,
      );
    }
    return _defaultMemoryMB;
  }

  Future<int> _getWindowsMemory() async {
    final result = await Process.run('powershell', [
      '-command',
      '(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory',
    ]);
    if (result.exitCode == 0) {
      final bytes = int.tryParse(result.stdout.toString().trim());
      if (bytes != null) {
        return bytes ~/ (1024 * 1024);
      }
    }
    return _defaultMemoryMB;
  }

  Future<int> _getMacOSMemory() async {
    final result = await Process.run('sysctl', ['-n', 'hw.memsize']);
    if (result.exitCode == 0) {
      final bytes = int.tryParse(result.stdout.toString().trim());
      if (bytes != null) {
        return bytes ~/ (1024 * 1024);
      }
    }
    return _defaultMemoryMB;
  }

  Future<int> _getLinuxMemory() async {
    final file = File('/proc/meminfo');
    if (await file.exists()) {
      final contents = await file.readAsString();
      final match = RegExp(r'MemTotal:\s+(\d+)\s+kB').firstMatch(contents);
      if (match != null) {
        final kb = int.tryParse(match.group(1)!);
        if (kb != null) {
          return kb ~/ 1024;
        }
      }
    }
    return _defaultMemoryMB;
  }
}
