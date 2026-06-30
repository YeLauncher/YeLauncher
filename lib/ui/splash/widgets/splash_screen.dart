import 'package:flutter/material.dart' hide CircularProgressIndicator;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/routing/routes.dart';
import 'package:yelauncher/ui/core/circular_progress_indicator.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'package:yelauncher/ui/splash/view_models/splash_viewmodel.dart';
import 'package:yelauncher/l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  final SplashViewModel viewModel;

  const SplashScreen({super.key, required this.viewModel});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    await Future.wait([
      widget.viewModel.initialize(),
      Future.delayed(const Duration(milliseconds: 1500)),
    ]);
    if (!mounted) return;

    final minecraftRepo = context.read<MinecraftRepository>();
    final isAuthenticated = await minecraftRepo.isAuthenticated();

    if (!mounted) return;

    if (isAuthenticated) {
      context.go(Routes.instances);
    } else {
      context.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.dark.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Using a simple icon/logo placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.dark.primaryContainer,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Center(
                child: Text(
                  'YL',
                  style: AppText.defaultTheme.titleLarge.copyWith(
                    color: AppColors.dark.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator.primary(),
            ),
            const SizedBox(height: 24),
            ListenableBuilder(
              listenable: widget.viewModel,
              builder: (context, _) {
                final l10n = AppLocalizations.of(context)!;
                String statusMessage;
                switch (widget.viewModel.status) {
                  case SplashStatus.checkingData:
                    statusMessage = l10n.splashCheckingData;
                  case SplashStatus.checkingUpdates:
                    statusMessage = l10n.splashCheckingUpdates;
                  case SplashStatus.downloadingUpdate:
                    statusMessage = l10n.splashDownloadingUpdate;
                  case SplashStatus.installingUpdate:
                    statusMessage = l10n.splashInstallingUpdate;
                  case SplashStatus.downloadError:
                    statusMessage = l10n.splashDownloadError;
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      statusMessage,
                      style: AppText.defaultTheme.titleSmall.copyWith(
                        color: AppColors.dark.onSurfaceVariant,
                      ),
                    ),
                    if (widget.viewModel.downloadProgress != null) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 240,
                        child: LinearProgressIndicator(
                          value: widget.viewModel.downloadProgress,
                          backgroundColor: AppColors.dark.surfaceContainerHighest,
                          color: AppColors.dark.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
