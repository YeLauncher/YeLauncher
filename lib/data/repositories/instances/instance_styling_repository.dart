import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class InstanceStylingRepository {
  final List<String> availableIcons = [
    'inventory_2_rounded',
    'swords_rounded',
    'eco_rounded',
    'home_rounded',
    'star_rounded',
    'sports_esports_rounded',
    'public_rounded',
    'castle_rounded',
    'diamond_rounded',
    'landscape_rounded',
    'forest_rounded',
    'agriculture_rounded',
    'science_rounded',
    'explore_rounded',
  ];

  final List<String> availableColors = [
    '#3D5A80',
    '#EE6C4D',
    '#81B29A',
    '#9B5DE5',
    '#293241',
    '#E07A5F',
    '#F2CC8F',
    '#335C67',
    '#540B0E',
    '#8338EC',
  ];

  IconData getIconData(String? iconName) {
    switch (iconName) {
      case 'inventory_2_rounded':
        return Symbols.inventory_2_rounded;
      case 'swords_rounded':
        return Symbols.swords_rounded;
      case 'eco_rounded':
        return Symbols.eco_rounded;
      case 'home_rounded':
        return Symbols.home_rounded;
      case 'star_rounded':
        return Symbols.star_rounded;
      case 'sports_esports_rounded':
        return Symbols.sports_esports_rounded;
      case 'public_rounded':
        return Symbols.public_rounded;
      case 'castle_rounded':
        return Symbols.castle_rounded;
      case 'diamond_rounded':
        return Symbols.diamond_rounded;
      case 'landscape_rounded':
        return Symbols.landscape_rounded;
      case 'forest_rounded':
        return Symbols.forest_rounded;
      case 'agriculture_rounded':
        return Symbols.agriculture_rounded;
      case 'science_rounded':
        return Symbols.science_rounded;
      case 'explore_rounded':
        return Symbols.explore_rounded;
      default:
        return Symbols.inventory_2_rounded;
    }
  }

  Color getColor(String? colorHex, {required Color fallback}) {
    if (colorHex == null || colorHex.isEmpty) {
      return fallback;
    }
    try {
      return Color(int.parse(colorHex.replaceAll('#', '0xFF')));
    } catch (_) {
      return fallback;
    }
  }
}
