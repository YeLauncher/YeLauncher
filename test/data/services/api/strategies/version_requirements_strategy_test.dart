import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yelauncher/data/services/api/models/version_requirements_api_model.dart';
import 'package:yelauncher/data/services/api/strategies/version_21_requirements_strategy.dart';
import 'package:yelauncher/utilities/result.dart';

void main() {
  group('Version21RequirementsStrategy', () {
    late Version21RequirementsStrategy strategy;
    late Map<String, dynamic> testJson;

    setUp(() {
      strategy = Version21RequirementsStrategy();
      final file = File('assets/requirements_26.1.2_test.json');
      testJson = jsonDecode(file.readAsStringSync());
    });

    test('should parse VersionRequirementsApiModel successfully from JSON', () {
      final result = strategy.parseVersionPrerequisites(testJson);

      expect(result, isA<Success<VersionRequirementsApiModel>>());
      final value = (result as Success<VersionRequirementsApiModel>).value;

      // expect(value.id, '26.1.2');
      expect(value.mainClass, 'net.minecraft.client.main.Main');
      // expect(value.minimumLauncherVersion, 21);

      expect(value.libraries.length, 2);
      expect(value.libraries.first.name, 'at.yawk.lz4:lz4-java:1.10.1');
      expect(value.libraries.last.name, 'org.lwjgl:lwjgl-freetype:3.4.1:natives-windows');
      expect(value.arguments.length, 41);
    });
  });
}

