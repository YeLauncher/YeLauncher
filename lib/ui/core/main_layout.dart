import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/navigation_button.dart';

class MainLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.dark.surface,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            color: AppColors.dark.surfaceContainerLow,
            child: Column(
              spacing: 8,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NavigationButton.primary(
                  iconData: Symbols.sports_esports_rounded,
                  isSelected: navigationShell.currentIndex == 0,
                  onPressed: () => navigationShell.goBranch(0),
                ),
                NavigationButton.primary(
                  iconData: Symbols.extension_rounded,
                  isSelected: navigationShell.currentIndex == 1,
                  onPressed: () => navigationShell.goBranch(1),
                ),
              ],
            ),
          ),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
