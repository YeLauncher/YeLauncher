import 'package:flutter/foundation.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_profile_model.dart';
import 'package:yelauncher/utilities/command.dart';
import 'package:yelauncher/utilities/result.dart';
import 'package:yelauncher/routing/router.dart';
import 'package:yelauncher/l10n/app_localizations.dart';
import 'package:yelauncher/ui/core/notification_service.dart';

class ProfilesViewModel extends ChangeNotifier {
  final MinecraftRepository _minecraftRepository;

  List<MinecraftProfileModel> profiles = [];
  MinecraftProfileModel? selectedProfile;

  late final Command0 loadProfiles;
  late final Command0 authenticate;
  late final Command1<void, String> selectProfile;
  late final Command1<void, String> removeProfile;
  late final Command1<void, String> addOfflineProfile;

  ProfilesViewModel({required MinecraftRepository minecraftRepository})
      : _minecraftRepository = minecraftRepository {
    loadProfiles = Command0(_loadProfiles);
    authenticate = Command0(_authenticate);
    selectProfile = Command1<void, String>(_selectProfile);
    removeProfile = Command1<void, String>(_removeProfile);
    addOfflineProfile = Command1<void, String>(_addOfflineProfile);
  }

  Future<Result<void>> _loadProfiles() async {
    final profilesResult = await _minecraftRepository.getProfiles();
    if (profilesResult case Success<List<MinecraftProfileModel>>(value: final list)) {
      profiles = list;
    }

    final selectedResult = await _minecraftRepository.getSelectedProfile();
    if (selectedResult case Success<MinecraftProfileModel?>(value: final profile)) {
      selectedProfile = profile;
    }

    notifyListeners();
    return const Result.success(null);
  }

  Future<Result<void>> _authenticate() async {
    final result = await _minecraftRepository.authenticate();
    if (result is Success<MinecraftProfileModel>) {
      await _loadProfiles();
    } else if (result is Failure<MinecraftProfileModel>) {
      if (result.error.toString().contains('Minecraft account')) {
        final context = rootNavigatorKey.currentContext;
        if (context != null && context.mounted) {
          final l10n = AppLocalizations.of(context);
          NotificationService.showNotification(
            l10n?.minecraftAccountNotExists ?? 'Minecraft account does not exist',
            isError: true,
          );
        }
      }
    }
    return result;
  }

  Future<Result<void>> _selectProfile(String uuid) async {
    final result = await _minecraftRepository.selectProfile(uuid);
    if (result is Success<void>) {
      await _loadProfiles();
    }
    return result;
  }

  Future<Result<void>> _removeProfile(String uuid) async {
    final result = await _minecraftRepository.removeProfile(uuid);
    if (result is Success<void>) {
      await _loadProfiles();
    }
    return result;
  }

  Future<Result<void>> _addOfflineProfile(String nickname) async {
    final result = await _minecraftRepository.addOfflineProfile(nickname);
    if (result is Success<void>) {
      await _loadProfiles();
    }
    return result;
  }

  void cancelAuthentication() {
    _minecraftRepository.cancelAuthentication();
  }
}
