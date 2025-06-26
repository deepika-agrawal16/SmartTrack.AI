import 'package:flutter/material.dart';

// Data model for a single category item
class Category {
  final String name;
  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;

  const Category({
    required this.name,
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
  });

  // Method to allow copying Category with changes (useful for immutability)
  Category copyWith({
    String? name,
    IconData? icon,
    Color? iconBackgroundColor,
    Color? iconColor,
  }) {
    return Category(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      iconBackgroundColor: iconBackgroundColor ?? this.iconBackgroundColor,
      iconColor: iconColor ?? this.iconColor,
    );
  }
}

// Data model for a group of categories
class CategoryGroup {
  final String title;
  final List<Category> categories;

  const CategoryGroup({
    required this.title,
    required this.categories,
  });

  // Method to allow copying CategoryGroup with changes (useful for immutability)
  CategoryGroup copyWith({
    String? title,
    List<Category>? categories,
  }) {
    return CategoryGroup(
      title: title ?? this.title,
      categories: categories ?? this.categories,
    );
  }
}
