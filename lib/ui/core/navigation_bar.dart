import 'package:flutter/widgets.dart';
import 'package:yelauncher/ui/core/navigation_button.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';

class NavigationBar extends StatefulWidget {
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;
  final List<IconData> icons;

  const NavigationBar({
    super.key,
    required this.initialIndex,
    this.onIndexChanged,
    required this.icons,
  });

  @override
  State<StatefulWidget> createState() => _NavigationBarState();
}

class _NavigationBarState extends State<NavigationBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _handleTap(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
      widget.onIndexChanged?.call(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.dark.surfaceContainer,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        spacing: 4,
        mainAxisSize: MainAxisSize.max,
        children: [
          for (int i = 0; i < widget.icons.length; i++) ...[
            NavigationButton.primary(
              iconData: widget.icons[i],
              isSelected: _selectedIndex == i,
              onPressed: () => _handleTap(i),
            ),
          ],
        ],
      ),
    );
  }
}
