import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/material.dart';
import 'package:aifinanceapp/features/transactions/data/models/category_model.dart';

part 'category_providers.g.dart';

@Riverpod(keepAlive: true)
class CategoryNotifier extends _$CategoryNotifier {
  @override
  List<CategoryGroup> build() {
    return [
      CategoryGroup(
        title: "Health & Fitness",
        categories: [
          Category(name: "Run", icon: Icons.directions_run, iconBackgroundColor: const Color(0xFFEEEBFF), iconColor: const Color(0xFF7B61FF)),
          Category(name: "Doctor", icon: Icons.medical_services, iconBackgroundColor: const Color(0xFFFFE0E0), iconColor: const Color(0xFFEF5350)),
          Category(name: "Medicine", icon: Icons.medication, iconBackgroundColor: const Color(0xFFE0F2F7), iconColor: const Color(0xFF2196F3)),
          Category(name: "Exercise", icon: Icons.fitness_center, iconBackgroundColor: const Color(0xFFE0F7FA), iconColor: const Color(0xFF00BCD4)),
          Category(name: "Cycling", icon: Icons.directions_bike, iconBackgroundColor: const Color(0xFFE8F5E9), iconColor: const Color(0xFF4CAF50)),
          Category(name: "Swim", icon: Icons.pool, iconBackgroundColor: const Color(0xFFFFF3E0), iconColor: const Color(0xFFFF9800)),
        ],
      ),
      CategoryGroup(
        title: "Food & Shopping",
        categories: [
          Category(name: "Grocery", icon: Icons.local_grocery_store, iconBackgroundColor: const Color(0xFFE8F5E9), iconColor: const Color(0xFF4CAF50)),
          Category(name: "Tea & Coffees", icon: Icons.coffee, iconBackgroundColor: const Color(0xFFFBE9E7), iconColor: const Color(0xFFE65100)),
          Category(name: "Drinks", icon: Icons.local_bar, iconBackgroundColor: const Color(0xFFE0F7FA), iconColor: const Color(0xFF00BCD4)),
          Category(name: "Restaurants", icon: Icons.restaurant, iconBackgroundColor: const Color(0xFFFFF3E0), iconColor: const Color(0xFFFF9800)),
        ],
      ),
      CategoryGroup(
        title: "Bills & Utilities",
        categories: [
          Category(name: "Phone Bill", icon: Icons.phone_android, iconBackgroundColor: const Color(0xFFFFE0E0), iconColor: const Color(0xFFEF5350)),
          Category(name: "Water Bill", icon: Icons.water_drop, iconBackgroundColor: const Color(0xFFE0F2F7), iconColor: const Color(0xFF2196F3)),
          Category(name: "Gas Bill", icon: Icons.local_fire_department, iconBackgroundColor: const Color(0xFFFFF3E0), iconColor: const Color(0xFFFF9800)),
          Category(name: "Internet Bill", icon: Icons.wifi, iconBackgroundColor: const Color(0xFFE0F7FA), iconColor: const Color(0xFF00BCD4)),
          Category(name: "Rentals", icon: Icons.home_work, iconBackgroundColor: const Color(0xFFE8F5E9), iconColor: const Color(0xFF4CAF50)),
          Category(name: "TV Bill", icon: Icons.tv, iconBackgroundColor: const Color(0xFFE0F2F7), iconColor: const Color(0xFF00BCD4)),
          Category(name: "Electricity Bill", icon: Icons.flash_on, iconBackgroundColor: const Color(0xFFEEEBFF), iconColor: const Color(0xFF7B61FF)),
        ],
      ),
      CategoryGroup(
        title: "Family",
        categories: [
          Category(name: "Pets", icon: Icons.pets, iconBackgroundColor: const Color(0xFFEEEBFF), iconColor: const Color(0xFF7B61FF)),
          Category(name: "House", icon: Icons.house, iconBackgroundColor: const Color(0xFFFFF3E0), iconColor: const Color(0xFFFF9800)),
          Category(name: "Children", icon: Icons.child_care, iconBackgroundColor: const Color(0xFFE0F7FA), iconColor: const Color(0xFF00BCD4)),
          Category(name: "Gifts", icon: Icons.card_giftcard, iconBackgroundColor: const Color(0xFFFFE0E0), iconColor: const Color(0xFFEF5350)),
        ],
      ),
      CategoryGroup(
        title: "Gift & Donations",
        categories: [
          Category(name: "Marriage", icon: Icons.people_alt, iconBackgroundColor: const Color(0xFFFFEBF2), iconColor: const Color(0xFFF06292)),
          Category(name: "Funeral", icon: Icons.group_off, iconBackgroundColor: const Color(0xFFE0F2F7), iconColor: const Color(0xFF2196F3)),
          Category(name: "Charity", icon: Icons.volunteer_activism, iconBackgroundColor: const Color(0xFFFFF3E0), iconColor: const Color(0xFFFF9800)),
        ],
      ),
      CategoryGroup(
        title: "Shoppings",
        categories: [
          Category(name: "Clothings", icon: Icons.checkroom, iconBackgroundColor: const Color(0xFFFFEBF2), iconColor: const Color(0xFFF06292)),
          Category(name: "Footwear", icon: Icons.roller_skating, iconBackgroundColor: const Color(0xFFE0F7FA), iconColor: const Color(0xFF00BCD4)),
          Category(name: "Gadgets", icon: Icons.devices, iconBackgroundColor: const Color(0xFFE8F5E9), iconColor: const Color(0xFF4CAF50)),
          Category(name: "Electronics", icon: Icons.electrical_services, iconBackgroundColor: const Color(0xFFE0F2F7), iconColor: const Color(0xFF2196F3)),
          Category(name: "Furniture", icon: Icons.single_bed, iconBackgroundColor: const Color(0xFFDCEDC8), iconColor: const Color(0xFF689F38)),
          Category(name: "Vehicles", icon: Icons.directions_car, iconBackgroundColor: const Color(0xFFEEEBFF), iconColor: const Color(0xFF7B61FF)),
          Category(name: "Accessories", icon: Icons.headset, iconBackgroundColor: const Color(0xFFFFF3E0), iconColor: const Color(0xFFFF9800)),
        ],
      ),
    ];
  }

  void addCategory(String groupTitle, Category newCategory) {
    state = [
      for (final group in state)
        if (group.title == groupTitle)
          group.copyWith(categories: [...group.categories, newCategory])
        else
          group,
    ];
  }
}
