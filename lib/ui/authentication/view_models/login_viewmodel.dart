import 'package:flutter/foundation.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_profile_model.dart';
import 'package:yelauncher/utilities/command.dart';
import 'package:yelauncher/utilities/result.dart';

class LoginViewModel extends ChangeNotifier {
  late final Command1<void, String> loginOffline;
  late final Command0<void> loginMicrosoft;
  final MinecraftRepository _minecraftRepository;

  LoginViewModel({required MinecraftRepository minecraftRepository}) : _minecraftRepository = minecraftRepository {
    loginMicrosoft = Command0(_loginMicrosoft);
    loginOffline = Command1(_loginOffline);

    // Keep view updated when commands change
    loginMicrosoft.addListener(_onCommandUpdated);
    loginOffline.addListener(_onCommandUpdated);
  }

  bool get isAuthenticating => loginMicrosoft.running || loginOffline.running;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    loginMicrosoft.removeListener(_onCommandUpdated);
    loginOffline.removeListener(_onCommandUpdated);
    super.dispose();
  }

  void _onCommandUpdated() {
    // Prefer reporting the latest failure between the two commands
    final lm = loginMicrosoft.result;
    final lo = loginOffline.result;

    if (lm is Failure) {
      _errorMessage = lm.error.toString();
    } else if (lo is Failure) {
      _errorMessage = lo.error.toString();
    } else {
      _errorMessage = null;
    }

    notifyListeners();
  }

  Future<Result<void>> _loginMicrosoft() async {
    final result = await _minecraftRepository.authenticate();
    return switch (result) {
      Success<MinecraftProfileModel>(value: _) => const Result.success(null),
      Failure<MinecraftProfileModel>(:final error) => Result.failure(error),
    };
  }

  Future<Result<void>> _loginOffline(String nickname) async {
    final result = await _minecraftRepository.authenticateOffline(nickname);
    return switch (result) {
      Success<MinecraftProfileModel>(value: _) => const Result.success(null),
      Failure<MinecraftProfileModel>(:final error) => Result.failure(error),
    };
  }
}
