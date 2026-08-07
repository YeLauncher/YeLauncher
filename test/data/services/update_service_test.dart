import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:yelauncher/data/services/update_service.dart';

import 'update_service_test.mocks.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String path;

  MockPathProviderPlatform(this.path);

  @override
  Future<String?> getTemporaryPath() async => path;
}

@GenerateNiceMocks([MockSpec<http.Client>()])
void main() {
  late MockClient mockClient;
  late UpdateService updateService;

  setUp(() {
    mockClient = MockClient();
    updateService = UpdateService(client: mockClient);
    
    // Set a baseline version for testing
    PackageInfo.setMockInitialValues(
      appName: 'YeLauncher',
      packageName: 'com.yelauncher.app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  group('checkForUpdate', () {
    test('returns correct asset URL when a newer version is available', () async {
      final mockResponse = http.Response(
        '''
        {
          "tag_name": "v1.1.0",
          "assets": [
            {
              "name": "yelauncher-windows-installer.exe",
              "browser_download_url": "https://example.com/yelauncher-windows-installer.exe"
            },
            {
              "name": "YeLauncher-linux-x86_64.AppImage",
              "browser_download_url": "https://example.com/YeLauncher.AppImage"
            },
            {
              "name": "YeLauncher-macos.dmg",
              "browser_download_url": "https://example.com/YeLauncher.dmg"
            }
          ]
        }
        ''',
        200,
      );

      when(mockClient.get(any)).thenAnswer((_) async => mockResponse);

      final result = await updateService.checkForUpdate();
      
      // The result depends on what platform the test runner executes on.
      // We just assert that it matched one of the available assets and returned a valid string.
      expect(result, isNotNull);
      expect(result, startsWith('https://example.com/'));
    });

    test('returns null if no newer version is available', () async {
      final mockResponse = http.Response(
        '''
        {
          "tag_name": "v1.0.0",
          "assets": [
            {
              "name": "yelauncher-windows-installer.exe",
              "browser_download_url": "https://example.com/update.exe"
            }
          ]
        }
        ''',
        200,
      );

      when(mockClient.get(any)).thenAnswer((_) async => mockResponse);

      final result = await updateService.checkForUpdate();
      expect(result, isNull);
    });

    test('returns null on network error', () async {
      when(mockClient.get(any)).thenThrow(Exception('Network error'));

      final result = await updateService.checkForUpdate();
      expect(result, isNull);
    });
  });

  group('downloadUpdate', () {
    test('downloads file and reports progress', () async {
      final tempDir = await Directory.systemTemp.createTemp('update_service_test_');
      PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
      
      final mockResponse = http.StreamedResponse(
        Stream.fromIterable([
          [1, 2, 3],
          [4, 5, 6],
        ]),
        200,
        contentLength: 10,
      );

      when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

      final progressUpdates = <double>[];
      final file = await updateService.downloadUpdate(
        'https://example.com/update.exe',
        (progress) => progressUpdates.add(progress),
      );

      expect(file, isNotNull);
      expect(await file!.length(), 6); // Total 6 bytes downloaded
      expect(progressUpdates, isNotEmpty);
      
      await tempDir.delete(recursive: true);
    });

    test('returns null on download failure', () async {
      final tempDir = await Directory.systemTemp.createTemp('update_service_test_');
      PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
      
      final mockResponse = http.StreamedResponse(
        Stream.empty(),
        404,
      );

      when(mockClient.send(any)).thenAnswer((_) async => mockResponse);

      final file = await updateService.downloadUpdate('https://example.com/update.exe', (progress) {});
      expect(file, isNull);
      
      await tempDir.delete(recursive: true);
    });
  });
}
