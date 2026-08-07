import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_profile_model.dart';

final _logger = Logger('SecureStorageService');

class SecureStorageService {
  static const _instance = FlutterSecureStorage();

  static const _profilesKey = 'minecraft_profiles';
  static const _selectedProfileKey = 'selected_minecraft_profile';
  static const _legacyProfileKey = 'minecraft_profile';

  /// Saves a value securely with the given [key].
  ///
  /// If a value already exists for this key, it will be overwritten.
  /// Returns `true` if the save operation was successful.
  Future<bool> save({
    required String key,
    required String value,
  }) async {
    try {
      await _instance.write(key: key, value: value);
      _logger.info('Successfully saved value for key: $key');
      return true;
    } catch (e) {
      _logger.warning('Failed to save value for key: $key', e);
      return false;
    }
  }

  /// Retrieves a securely stored value by [key].
  ///
  /// Returns the stored value if found, or `null` if the key does not exist.
  /// Returns `null` if an error occurs during retrieval.
  Future<String?> read({required String key}) async {
    try {
      final value = await _instance.read(key: key);
      if (value != null) {
        _logger.fine('Successfully retrieved value for key: $key');
      }
      return value;
    } catch (e) {
      _logger.warning('Failed to read value for key: $key', e);
      return null;
    }
  }

  /// Removes a securely stored value by [key].
  ///
  /// If the key does not exist, this operation completes without error.
  /// Returns `true` if the remove operation was successful.
  Future<bool> remove({required String key}) async {
    try {
      await _instance.delete(key: key);
      _logger.info('Successfully removed value for key: $key');
      return true;
    } catch (e) {
      _logger.warning('Failed to remove value for key: $key', e);
      return false;
    }
  }

  /// Removes all securely stored values.
  ///
  /// This clears the entire secure storage.
  /// Returns `true` if the clear operation was successful.
  Future<bool> clear() async {
    try {
      await _instance.deleteAll();
      _logger.info('Successfully cleared all secure storage');
      return true;
    } catch (e) {
      _logger.warning('Failed to clear secure storage', e);
      return false;
    }
  }

  /// Checks if a value exists for the given [key].
  ///
  /// Returns `true` if the key exists in secure storage, `false` otherwise.
  Future<bool> contains({required String key}) async {
    try {
      final value = await _instance.read(key: key);
      return value != null;
    } catch (e) {
      _logger.warning('Failed to check if key exists: $key', e);
      return false;
    }
  }

  /// Saves a list of [MinecraftProfileModel]s securely using JSON serialization.
  Future<bool> saveProfiles(List<MinecraftProfileModel> profiles) async {
    try {
      final json = jsonEncode(profiles.map((p) => p.toJson()).toList());
      await _instance.write(key: _profilesKey, value: json);
      _logger.info('Successfully saved ${profiles.length} profiles');
      return true;
    } catch (e) {
      _logger.warning('Failed to save profiles', e);
      return false;
    }
  }

  /// Retrieves securely stored [MinecraftProfileModel]s from JSON.
  Future<List<MinecraftProfileModel>> getProfiles() async {
    try {
      final json = await _instance.read(key: _profilesKey);
      if (json != null) {
        final List<dynamic> decoded = jsonDecode(json);
        return decoded.map((e) => MinecraftProfileModel.fromJson(e)).toList();
      }

      // Migration from legacy single profile
      final legacyJson = await _instance.read(key: _legacyProfileKey);
      if (legacyJson != null) {
        final decoded = jsonDecode(legacyJson) as Map<String, dynamic>;
        final profile = MinecraftProfileModel.fromJson(decoded);
        _logger.info('Migrating legacy profile: ${profile.nickname}');
        await saveProfiles([profile]);
        await saveSelectedProfileId(profile.uuid);
        await _instance.delete(key: _legacyProfileKey);
        return [profile];
      }

      return [];
    } catch (e) {
      _logger.warning('Failed to retrieve or deserialize profiles', e);
      return [];
    }
  }

  /// Saves the selected profile UUID.
  Future<bool> saveSelectedProfileId(String uuid) async {
    try {
      await _instance.write(key: _selectedProfileKey, value: uuid);
      _logger.info('Successfully saved selected profile ID: $uuid');
      return true;
    } catch (e) {
      _logger.warning('Failed to save selected profile ID', e);
      return false;
    }
  }

  /// Retrieves the selected profile UUID.
  Future<String?> getSelectedProfileId() async {
    try {
      return await _instance.read(key: _selectedProfileKey);
    } catch (e) {
      _logger.warning('Failed to retrieve selected profile ID', e);
      return null;
    }
  }

  /// Retrieves the currently selected [MinecraftProfileModel].
  Future<MinecraftProfileModel?> getSelectedProfile() async {
    final profiles = await getProfiles();
    final selectedId = await getSelectedProfileId();
    if (profiles.isNotEmpty) {
      if (selectedId != null) {
        try {
          return profiles.firstWhere((p) => p.uuid == selectedId);
        } catch (_) {
          return profiles.first; // Fallback to first if selected ID is invalid
        }
      }
      return profiles.first;
    }
    return null;
  }

  /// Checks if any profile exists in secure storage.
  Future<bool> hasProfile() async {
    final profiles = await getProfiles();
    return profiles.isNotEmpty;
  }

  /// Clears all stored profiles and the selected profile ID.
  Future<bool> clearProfiles() async {
    try {
      await _instance.delete(key: _profilesKey);
      await _instance.delete(key: _selectedProfileKey);
      await _instance.delete(key: _legacyProfileKey);
      _logger.info('Successfully cleared profiles from secure storage');
      return true;
    } catch (e) {
      _logger.warning('Failed to clear profiles', e);
      return false;
    }
  }
}


