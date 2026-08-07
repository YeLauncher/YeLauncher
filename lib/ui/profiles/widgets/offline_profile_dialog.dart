import 'package:flutter/widgets.dart';
import 'package:yelauncher/l10n/app_localizations.dart';
import 'package:yelauncher/ui/core/button.dart';
import 'package:yelauncher/ui/core/text_field.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';

class OfflineProfileDialog extends StatefulWidget {
  final void Function(String) onCreate;

  const OfflineProfileDialog({super.key, required this.onCreate});

  @override
  State<OfflineProfileDialog> createState() => _OfflineProfileDialogState();
}

class _OfflineProfileDialogState extends State<OfflineProfileDialog> {
  final _nicknameController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 400,
        decoration: BoxDecoration(
            color: AppColors.dark.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.dark.onSurface.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.dark.scrim.withValues(alpha: 0.5),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.addOfflineAccountTitle,
                      style: AppText.defaultTheme.headlineLarge.copyWith(
                        color: AppColors.dark.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.addOfflineAccountSubtitle,
                      style: AppText.defaultTheme.bodyLarge.copyWith(
                        color: AppColors.dark.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      labelText: AppLocalizations.of(context)!.nicknameLabel,
                      controller: _nicknameController,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  color: AppColors.dark.surfaceContainer,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 12,
                  children: [
                    Button.surface(
                      AppLocalizations.of(context)!.cancel,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    ValueListenableBuilder(
                      valueListenable: _nicknameController,
                      builder: (context, value, _) {
                        return Button.primary(
                          AppLocalizations.of(context)!.createButton,
                          onPressed: value.text.trim().isNotEmpty
                              ? () {
                                  widget.onCreate(value.text.trim());
                                  Navigator.of(context).pop();
                                }
                              : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}
