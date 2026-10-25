import 'package:flutter/material.dart';

import '../models/category.dart';

/// Icon keys a user can choose from, mapped to their [IconData].
///
/// Stored as a string key on [Category] so the database stays icon-library
/// agnostic and the choice survives export/import.
const Map<String, IconData> categoryIcons = <String, IconData>{
  'home': Icons.home_outlined,
  'restaurant': Icons.restaurant_outlined,
  'directions_bus': Icons.directions_bus_outlined,
  'savings': Icons.savings_outlined,
  'celebration': Icons.celebration_outlined,
  'shopping_cart': Icons.shopping_cart_outlined,
  'health': Icons.favorite_outline,
  'bolt': Icons.bolt_outlined,
  'school': Icons.school_outlined,
  'pets': Icons.pets_outlined,
  'fitness': Icons.fitness_center_outlined,
  'flight': Icons.flight_outlined,
  'coffee': Icons.local_cafe_outlined,
  'phone': Icons.smartphone_outlined,
  'gift': Icons.card_giftcard_outlined,
  'work': Icons.work_outline,
  'child': Icons.child_care_outlined,
  'wifi': Icons.wifi_outlined,
  'car': Icons.directions_car_outlined,
  'wallet': Icons.account_balance_wallet_outlined,
};

/// Default palette offered in the category color picker (shadcn/Tailwind hues
/// matching the app's dark design).
const List<String> categoryColorPalette = <String>[
  '#22C55E',
  '#EC4899',
  '#6366F1',
  '#14B8A6',
  '#F59E0B',
  '#EF4444',
  '#A855F7',
  '#3B82F6',
  '#F97316',
  '#10B981',
  '#EAB308',
  '#8B5CF6',
];

/// Resolves the string `color`/`icon` stored on a [Category] into real Flutter
/// values, with sensible fallbacks so bad data never crashes the UI.
extension CategoryVisuals on Category {
  Color get displayColor {
    var hex = color.replaceFirst('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex'; // add opaque alpha
    final value = int.tryParse(hex, radix: 16);
    return value == null ? Colors.blueGrey : Color(value);
  }

  IconData get displayIcon => categoryIcons[icon] ?? Icons.label_outline;
}
