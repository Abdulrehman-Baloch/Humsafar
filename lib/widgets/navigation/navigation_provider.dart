import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _selectedIndex = -1;

  int get selectedIndex => _selectedIndex;

  void updateSelectedIndex(int index) {
    // Toggle selection - if the same index is tapped again, deselect it
    _selectedIndex = _selectedIndex == index ? -1 : index;
    notifyListeners();
  }
}
