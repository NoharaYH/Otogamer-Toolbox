import 'package:flutter/animation.dart';

class UiAnimations {
  // --- Durations ---
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration micro = Duration(milliseconds: 60);

  // --- Curves ---
  static const Curve curveOut = Curves.easeOutQuart;
  static const Curve curveIn = Curves.easeInQuart;
  static const Curve bounceCurve = Curves.easeOutCubic;

  // --- Scale Factors ---
  static const double activeScale = 0.95;
  static const double bounceScale = 0.9;
}
