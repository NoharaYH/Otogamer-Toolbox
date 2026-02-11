import 'package:flutter/material.dart';

class GameProvider extends ChangeNotifier {
  int _currentIndex = 0;
  final PageController pageController = PageController();

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index.clamp(0, 1);
      notifyListeners();
    }
  }

  // Update index from PageView scroll
  void onPageChanged(int index) {
    setIndex(index);
  }

  // Programmatic navigation
  void animateToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
