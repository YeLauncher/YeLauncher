import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:yelauncher/ui/core/button.dart';
import 'package:yelauncher/ui/core/icon_button.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/l10n/app_localizations.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'package:yelauncher/ui/profiles/view_models/profiles_viewmodel.dart';
import 'package:yelauncher/ui/core/circular_progress_indicator.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key, required this.viewModel});
  final ProfilesViewModel viewModel;

  @override
  State<StatefulWidget> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadProfiles.execute();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.viewModel,
      child: Container(
        alignment: Alignment.topCenter,
        constraints: BoxConstraints.expand(),
        color: AppColors.dark.surface,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  spacing: 8,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      spacing: 16,
                      children: [
                        Icon(
                          Symbols.manage_accounts_rounded,
                          size: 40,
                          weight: 700,
                          color: AppColors.dark.primary,
                        ),
                        Text(
                          AppLocalizations.of(context)!.profilesTabTitle,
                          style: AppText.defaultTheme.titleLarge.copyWith(
                            color: AppColors.dark.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      AppLocalizations.of(context)!.manageAccountsSubtitle,
                      style: AppText.defaultTheme.body.copyWith(
                        color: AppColors.dark.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                ListenableBuilder(
                  listenable: widget.viewModel.authenticate,
                  builder: (context, child) {
                    if (widget.viewModel.authenticate.running) {
                      return Row(
                        spacing: 16,
                        children: [
                          CircularProgressIndicator.primary(),
                          Button.error(
                            AppLocalizations.of(context)!.cancel,
                            onPressed: () {
                              widget.viewModel.cancelAuthentication();
                            },
                          )
                        ],
                      );
                    }
                    return Button.primary(
                      AppLocalizations.of(context)!.addAccountButton,
                      iconData: Symbols.person_add_rounded,
                      onPressed: widget.viewModel.authenticate.execute,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListenableBuilder(
                listenable: widget.viewModel,
                builder: (context, _) {
                  if (widget.viewModel.profiles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 8,
                        children: [
                          Icon(
                            Symbols.person_off_rounded,
                            size: 80,
                            weight: 800,
                            color: AppColors.dark.onSurface,
                          ),
                          Column(
                            spacing: 4,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.noAccountsTitle,
                                style: AppText.defaultTheme.titleSmall.copyWith(
                                  color: AppColors.dark.onSurface,
                                ),
                              ),
                              Text(
                                AppLocalizations.of(context)!.noAccountsSubtitle,
                                style: AppText.defaultTheme.bodySmall.copyWith(
                                  color: AppColors.dark.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: widget.viewModel.profiles.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final profile = widget.viewModel.profiles[index];
                      final isSelected = profile.uuid == widget.viewModel.selectedProfile?.uuid;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.dark.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected ? Border.all(color: AppColors.dark.primary, width: 2) : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              spacing: 16,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.dark.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Symbols.person_rounded,
                                    color: AppColors.dark.primary,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 4,
                                  children: [
                                    Row(
                                      spacing: 8,
                                      children: [
                                        Text(
                                          profile.nickname,
                                          style: AppText.defaultTheme.titleSmall.copyWith(
                                            color: AppColors.dark.onSurface,
                                          ),
                                        ),
                                        if (isSelected)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.dark.primary,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              AppLocalizations.of(context)!.activeBadge,
                                              style: AppText.defaultTheme.label.copyWith(
                                                color: AppColors.dark.onPrimary,
                                              ),
                                            ),
                                          )
                                      ],
                                    ),
                                    Text(
                                      profile.uuid,
                                      style: AppText.defaultTheme.bodySmall.copyWith(
                                        color: AppColors.dark.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 8,
                              children: [
                                if (!isSelected)
                                  Button.secondary(
                                    AppLocalizations.of(context)!.selectButton,
                                    onPressed: () {
                                      widget.viewModel.selectProfile.execute(profile.uuid);
                                    },
                                  ),
                                IconButton.surface(
                                  iconData: Symbols.delete_rounded,
                                  onPressed: () {
                                    widget.viewModel.removeProfile.execute(profile.uuid);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
