import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:yelauncher/data/repositories/settings/settings_repository.dart';
import 'package:yelauncher/data/services/system_info_service.dart';
import 'package:yelauncher/ui/core/button.dart';
import 'package:yelauncher/ui/core/slider.dart';
import 'package:yelauncher/ui/core/text_field.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'package:yelauncher/ui/settings/view_models/settings_viewmodel.dart';
import 'package:yelauncher/l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsViewModel viewModel;

  const SettingsScreen({super.key, required this.viewModel});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  bool _isSaving = false;

  double _memoryValue = SettingsRepository.defaultJavaMemory.toDouble();
  int _maxMemoryMB = 16384; // will be updated from SystemInfoService

  @override
  void initState() {
    super.initState();
    _memoryValue = widget.viewModel.javaMemory.toDouble();
    _widthController = TextEditingController(
      text: widget.viewModel.windowWidth.toString(),
    );
    _heightController = TextEditingController(
      text: widget.viewModel.windowHeight.toString(),
    );
    _fetchSystemMemory();
  }

  Future<void> _fetchSystemMemory() async {
    final systemInfo = SystemInfoService();
    final totalMB = await systemInfo.getTotalPhysicalMemoryMB();
    if (mounted) {
      setState(() {
        _maxMemoryMB = totalMB;
        // Clamp current value if it exceeds actual RAM
        if (_memoryValue > _maxMemoryMB) {
          _memoryValue = _maxMemoryMB.toDouble();
        }
      });
    }
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      // Enforce non-empty values by falling back to defaults
      final width = int.tryParse(_widthController.text.trim()) ??
          SettingsRepository.defaultWindowWidth;
      final height = int.tryParse(_heightController.text.trim()) ??
          SettingsRepository.defaultWindowHeight;

      // Update text controllers to reflect enforced values
      _widthController.text = width.toString();
      _heightController.text = height.toString();

      await widget.viewModel.saveMinecraftSettings(
        javaMemory: _memoryValue.toInt(),
        windowWidth: width,
        windowHeight: height,
        customJavaPath: widget.viewModel.customJavaPath,
        jvmArguments: widget.viewModel.jvmArguments,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildSettingsRow({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.defaultTheme.labelLarge.copyWith(
                  color: AppColors.dark.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppText.defaultTheme.bodySmall.copyWith(
                  color: AppColors.dark.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
        Expanded(flex: 3, child: child),
      ],
    );
  }

  Widget _buildFormSection({
    required String title,
    required IconData iconData,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dark.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dark.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                Icon(iconData, color: AppColors.dark.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppText.defaultTheme.titleSmall.copyWith(
                    color: AppColors.dark.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: AppColors.dark.outlineVariant.withValues(alpha: 0.5),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 32,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Calculate slider divisions (steps of 512MB)
    final maxSliderMB = (_maxMemoryMB / 512).floor() * 512;
    final divisions = maxSliderMB ~/ 512;

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return Container(
          color: AppColors.dark.surface,
          child: SingleChildScrollView(
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
                    if (widget.viewModel.currentLocale.languageCode == 'en')
                      Button.primary(
                        l10n.english,
                        onPressed: () {},
                      )
                    else
                      Button.surface(
                        l10n.english,
                        onPressed: () => widget.viewModel.setLocale(const Locale('en')),
                      ),
                    if (widget.viewModel.currentLocale.languageCode == 'uk')
                      Button.primary(
                        l10n.ukrainian,
                        onPressed: () {},
                      )
                    else
                      Button.surface(
                        l10n.ukrainian,
                        onPressed: () => widget.viewModel.setLocale(const Locale('uk')),
                      ),
                  ],
                ),
                const SizedBox(height: 32),

                Text(
                  l10n.settingsMinecraftTitle,
                  style: AppText.defaultTheme.titleSmall.copyWith(
                    color: AppColors.dark.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFormSection(
                  title: l10n.settingsMinecraftTitle,
                  iconData: Symbols.desktop_windows_rounded,
                  children: [
                    _buildSettingsRow(
                      title: l10n.settingsWindowResolution,
                      description: l10n.settingsWindowResolutionDesc,
                      child: Row(
                        spacing: 16,
                        children: [
                          Expanded(
                            child: TextField(
                              labelText: l10n.settingsWidth,
                              controller: _widthController,
                              width: double.infinity,
                            ),
                          ),
                          Text(
                            'x',
                            style: AppText.defaultTheme.titleSmall.copyWith(
                              color: AppColors.dark.onSurfaceVariant,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              labelText: l10n.settingsHeight,
                              controller: _heightController,
                              width: double.infinity,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildFormSection(
                  title: l10n.settingsJavaEnvironment,
                  iconData: Symbols.memory_rounded,
                  children: [
                    _buildSettingsRow(
                      title: l10n.settingsMaxMemory,
                      description: l10n.settingsMaxMemoryDesc,
                      child: AppSlider(
                        min: 512,
                        max: maxSliderMB.toDouble(),
                        value: _memoryValue.clamp(512, maxSliderMB.toDouble()),
                        divisions: divisions > 0 ? divisions : 1,
                        valueLabelBuilder: (v) => '${v.toInt()} ${l10n.settingsMB}',
                        onChanged: (v) {
                          setState(() => _memoryValue = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Button.primary(
                      l10n.saveChangesButton,
                      onPressed: _isSaving ? () {} : _saveSettings,
                      iconData: Symbols.save_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
