import 'package:flutter/material.dart';

/// Radius constants for Rally's premium surface treatment.
class AppRadius {
  AppRadius._();

  static const double sm = 10.0;
  static const double md = 14.0;
  static const double lg = 20.0;
  static const double xl = 28.0;
  static const double pill = 999.0;

  static BorderRadius get small => BorderRadius.circular(sm);
  static BorderRadius get medium => BorderRadius.circular(md);
  static BorderRadius get large => BorderRadius.circular(lg);
  static BorderRadius get xLarge => BorderRadius.circular(xl);
  static BorderRadius get pillRadius => BorderRadius.circular(pill);
}
