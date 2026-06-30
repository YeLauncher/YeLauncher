import 'package:flutter/widgets.dart';
import 'package:yelauncher/ui/core/button.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'package:yelauncher/ui/settings/view_models/settings_viewmodel.dart';
import 'package:yelauncher/l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsViewModel viewModel;

  const SettingsScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Container(
          color: AppColors.dark.surface,
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settingsTabTitle,
                style: AppText.defaultTheme.title.copyWith(
                  color: AppColors.dark.onSurface,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.languageLabel,
                style: AppText.defaultTheme.titleSmall.copyWith(
                  color: AppColors.dark.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                spacing: 16,
                children: [
                  if (viewModel.currentLocale.languageCode == 'en')
                    Button.primary(
                      l10n.english,
                      onPressed: () {},
                    )
                  else
                    Button.surface(
                      l10n.english,
                      onPressed: () => viewModel.setLocale(const Locale('en')),
                    ),
                  if (viewModel.currentLocale.languageCode == 'uk')
                    Button.primary(
                      l10n.ukrainian,
                      onPressed: () {},
                    )
                  else
                    Button.surface(
                      l10n.ukrainian,
                      onPressed: () => viewModel.setLocale(const Locale('uk')),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
