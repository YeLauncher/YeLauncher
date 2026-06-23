import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_profile_model.dart';

final _logger = Logger('SecureStorageService');

class SecureStorageService {
  static const _instance = FlutterSecureStorage();
  static const _profileKey = 'minecraft_profile';

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

  /// Saves a [MinecraftProfileModel] securely using JSON serialization.
  ///
  /// The profile is converted to JSON and stored under a fixed profile key.
  /// If a profile already exists, it will be overwritten.
  /// Returns `true` if the save operation was successful.
  Future<bool> saveProfile(MinecraftProfileModel profile) async {
    try {
      final json = jsonEncode(profile.toJson());
      await _instance.write(key: _profileKey, value: json);
      _logger.info('Successfully saved profile for: ${profile.nickname}');
      return true;
    } catch (e) {
      _logger.warning('Failed to save profile', e);
      return false;
    }
  }

  /// Retrieves a securely stored [MinecraftProfileModel] from JSON.
  ///
  /// Returns the deserialized profile if found, or `null` if:
  /// - The profile key does not exist
  /// - The stored JSON is invalid or cannot be deserialized
  /// - An error occurs during retrieval
  Future<MinecraftProfileModel?> getProfile() async {
    try {
      final json = await _instance.read(key: _profileKey);
      if (json == null) {
        _logger.fine('No profile found in secure storage');
        return null;
      }

      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final profile = MinecraftProfileModel.fromJson(decoded);
      _logger.info('Successfully retrieved profile for: ${profile.nickname}');
      return profile;
    } catch (e) {
      _logger.warning('Failed to retrieve or deserialize profile', e);
      return null;
    }
  }

  /// Checks if a profile exists in secure storage.
  ///
  /// Returns `true` if a profile is stored, `false` otherwise.
  Future<bool> hasProfile() async {
    try {
      final value = await _instance.read(key: _profileKey);
      return value != null;
    } catch (e) {
      _logger.warning('Failed to check if profile exists', e);
      return false;
    }
  }

  /// Clears the stored profile from secure storage.
  ///
  /// Returns `true` if the remove operation was successful.
  Future<bool> clearProfile() async {
    try {
      await _instance.delete(key: _profileKey);
      _logger.info('Successfully cleared profile from secure storage');
      return true;
    } catch (e) {
      _logger.warning('Failed to clear profile', e);
      return false;
    }
  }
}

