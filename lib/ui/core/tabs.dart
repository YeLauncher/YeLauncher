import 'package:flutter/widgets.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';

class Tab {
  final String title;
  final IconData? icon;

  const Tab({required this.title, this.icon});
}

class Tabs extends StatelessWidget {
  final int currentTabIndex;
  final ValueChanged<int> onTabChanged;
  final List<Tab> tabs;
  final Color backgroundColor;
  final Color selectedTabColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;

  const Tabs({
    super.key,
    required this.tabs,
    required this.currentTabIndex,
    required this.onTabChanged,
    required this.backgroundColor,
    required this.selectedTabColor,
    required this.selectedTextColor,
    required this.unselectedTextColor,
  });

  Tabs.surface({
    super.key,
    required this.tabs,
    required this.currentTabIndex,
    required this.onTabChanged,
  }) : backgroundColor = AppColors.dark.surfaceContainerLowest,
       selectedTabColor = AppColors.dark.primary,
       selectedTextColor = AppColors.dark.onPrimary,
       unselectedTextColor = AppColors.dark.onSurfaceVariant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dark.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          return _buildTabItem(index, tab.title, tab.icon);
        }),
      ),
    );
  }

  Widget _buildTabItem(int index, String title, IconData? icon) {
    final isSelected = currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutQuart,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? selectedTabColor : const Color(0x00000000),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? selectedTextColor : unselectedTextColor,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.defaultTheme.labelLarge.copyWith(
                    color: isSelected ? selectedTextColor : unselectedTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
