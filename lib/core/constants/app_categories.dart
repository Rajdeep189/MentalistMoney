import 'package:flutter/material.dart';

/// A spending category with a circular geometric icon identity.
class AppCategory {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final Color color2;

  const AppCategory(this.key, this.label, this.icon, this.color, this.color2);
}

class Categories {
  Categories._();

  static const food = AppCategory('food', 'Food & Dining', Icons.restaurant_rounded, Color(0xFFFF8A3D), Color(0xFFFF5E62));
  static const transport = AppCategory('transport', 'Transport', Icons.directions_car_rounded, Color(0xFF4E9BFF), Color(0xFF2E6BF6));
  static const shopping = AppCategory('shopping', 'Shopping', Icons.shopping_bag_rounded, Color(0xFFFF5EA8), Color(0xFFD63384));
  static const groceries = AppCategory('groceries', 'Groceries', Icons.local_grocery_store_rounded, Color(0xFF34C77B), Color(0xFF1FA85C));
  static const bills = AppCategory('bills', 'Bills & Utilities', Icons.receipt_long_rounded, Color(0xFF22B8CF), Color(0xFF0E8FA8));
  static const entertainment = AppCategory('entertainment', 'Entertainment', Icons.movie_filter_rounded, Color(0xFF9B6BFF), Color(0xFF6C3DF4));
  static const health = AppCategory('health', 'Health', Icons.favorite_rounded, Color(0xFFFF5E62), Color(0xFFE5484D));
  static const salary = AppCategory('salary', 'Salary', Icons.account_balance_wallet_rounded, Color(0xFF2FBF71), Color(0xFF128A4C));
  static const freelance = AppCategory('freelance', 'Freelance', Icons.work_rounded, Color(0xFFFFB020), Color(0xFFFF8A00));
  static const transfer = AppCategory('transfer', 'Transfer', Icons.swap_horiz_rounded, Color(0xFF8A93A6), Color(0xFF5B6472));
  static const other = AppCategory('other', 'Other', Icons.category_rounded, Color(0xFFB8A98A), Color(0xFF8A7B5E));

  static const all = [food, transport, shopping, groceries, bills, entertainment, health, salary, freelance, transfer, other];
  static const expense = [food, transport, shopping, groceries, bills, entertainment, health, other];
  static const income = [salary, freelance, other];

  static AppCategory byKey(String key) {
    for (final c in all) {
      if (c.key == key) return c;
    }
    return other;
  }
}
