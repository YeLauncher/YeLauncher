import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yelauncher/data/services/secure_storage_service.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_profile_model.dart';

void main() {
  late SecureStorageService service;
  late FlutterSecureStorage storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = const FlutterSecureStorage();
    service = SecureStorageService();
  });

  group('SecureStorageService Basics', () {
    test('save writes value to storage', () async {
      final result = await service.save(key: 'key', value: 'value');
      expect(result, isTrue);
      
      final stored = await storage.read(key: 'key');
      expect(stored, 'value');
    });

    test('read returns value from storage', () async {
      await storage.write(key: 'key', value: 'value');
      final result = await service.read(key: 'key');
      expect(result, 'value');
    });

    test('remove deletes value from storage', () async {
      await storage.write(key: 'key', value: 'value');
      final result = await service.remove(key: 'key');
      expect(result, isTrue);
      
      final stored = await storage.read(key: 'key');
      expect(stored, isNull);
    });

    test('clear deletes all values', () async {
      await storage.write(key: 'key1', value: 'value1');
      await storage.write(key: 'key2', value: 'value2');
      
      final result = await service.clear();
      expect(result, isTrue);
      
      final stored1 = await storage.read(key: 'key1');
      final stored2 = await storage.read(key: 'key2');
      expect(stored1, isNull);
      expect(stored2, isNull);
    });

    test('contains returns true if value exists', () async {
      await storage.write(key: 'key', value: 'value');
      final result = await service.contains(key: 'key');
      expect(result, isTrue);
    });

    test('contains returns false if value does not exist', () async {
      final result = await service.contains(key: 'key');
      expect(result, isFalse);
    });
  });

  group('Minecraft Profiles', () {
    final testProfile = MinecraftProfileModel(
      uuid: '1234',
      nickname: 'Steve',
      accessToken: 'abc',
      userType: 'mojang',
    );

    test('saveProfiles stores JSON securely', () async {
      final result = await service.saveProfiles([testProfile]);
      expect(result, isTrue);

      final storedJson = await storage.read(key: 'minecraft_profiles');
      expect(storedJson, isNotNull);
      
      final decoded = jsonDecode(storedJson!);
      expect(decoded.length, 1);
      expect(decoded[0]['uuid'], '1234');
    });

    test('getProfiles retrieves and decodes JSON', () async {
      final json = jsonEncode([testProfile.toJson()]);
      await storage.write(key: 'minecraft_profiles', value: json);

      final result = await service.getProfiles();
      expect(result.length, 1);
      expect(result.first.uuid, '1234');
      expect(result.first.nickname, 'Steve');
    });

    test('getProfiles migrates legacy profile', () async {
      // Setup legacy profile
      final legacyJson = jsonEncode(testProfile.toJson());
      await storage.write(key: 'minecraft_profile', value: legacyJson);

      final result = await service.getProfiles();
      expect(result.length, 1);
      expect(result.first.uuid, '1234');

      // Verify migration artifacts
      final profilesJson = await storage.read(key: 'minecraft_profiles');
      expect(profilesJson, isNotNull);
      
      final selectedId = await storage.read(key: 'selected_minecraft_profile');
      expect(selectedId, '1234');
      
      final legacyStillExists = await storage.read(key: 'minecraft_profile');
      expect(legacyStillExists, isNull);
    });

    test('getProfiles returns empty if no profiles found', () async {
      final result = await service.getProfiles();
      expect(result, isEmpty);
    });

    test('getProfiles returns empty on decoding failure', () async {
      await storage.write(key: 'minecraft_profiles', value: 'Invalid JSON');
      final result = await service.getProfiles();
      expect(result, isEmpty);
    });

    test('saveSelectedProfileId stores UUID successfully', () async {
      final result = await service.saveSelectedProfileId('1234');
      expect(result, isTrue);
      
      final stored = await storage.read(key: 'selected_minecraft_profile');
      expect(stored, '1234');
    });

    test('getSelectedProfile returns the selected profile', () async {
      final json = jsonEncode([testProfile.toJson()]);
      await storage.write(key: 'minecraft_profiles', value: json);
      await storage.write(key: 'selected_minecraft_profile', value: '1234');

      final profile = await service.getSelectedProfile();
      expect(profile, isNotNull);
      expect(profile?.uuid, '1234');
    });

    test('getSelectedProfile falls back to first profile if selected UUID is not found', () async {
      final json = jsonEncode([testProfile.toJson()]);
      await storage.write(key: 'minecraft_profiles', value: json);
      await storage.write(key: 'selected_minecraft_profile', value: 'nonexistent');

      final profile = await service.getSelectedProfile();
      expect(profile, isNotNull);
      expect(profile?.uuid, '1234');
    });

    test('getSelectedProfile returns null if no profiles exist', () async {
      final profile = await service.getSelectedProfile();
      expect(profile, isNull);
    });

    test('hasProfile returns true if profiles exist', () async {
      final json = jsonEncode([testProfile.toJson()]);
      await storage.write(key: 'minecraft_profiles', value: json);
      expect(await service.hasProfile(), isTrue);
    });

    test('hasProfile returns false if no profiles exist', () async {
      expect(await service.hasProfile(), isFalse);
    });

    test('clearProfiles clears all keys', () async {
      await storage.write(key: 'minecraft_profiles', value: 'data');
      await storage.write(key: 'selected_minecraft_profile', value: 'data');
      await storage.write(key: 'minecraft_profile', value: 'data');
      
      final result = await service.clearProfiles();
      expect(result, isTrue);
      
      expect(await storage.read(key: 'minecraft_profiles'), isNull);
      expect(await storage.read(key: 'selected_minecraft_profile'), isNull);
      expect(await storage.read(key: 'minecraft_profile'), isNull);
    });
  });
}
