import 'package:flutter/widgets.dart';

class BreadcrumbService extends ChangeNotifier {
  final Map<String, String> _titles = {};

  void registerTitle(String segment, String title) {
    if (_titles[segment] != title) {
      _titles[segment] = title;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  String? getTitle(String segment) {
    return _titles[segment];
  }
}
