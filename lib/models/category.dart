import 'package:flutter/material.dart';
import 'transaction.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final TransactionType type;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_code': icon.codePoint,
      'color_value': color.toARGB32(),
      'type': type.index,
    };
  }

  static IconData getIcon(String id) {
    switch (id) {
      case 'cat_food':
        return Icons.restaurant;
      case 'cat_groceries':
        return Icons.local_grocery_store;
      case 'cat_transport':
        return Icons.directions_bus;
      case 'cat_shopping':
        return Icons.shopping_bag;
      case 'cat_bills':
        return Icons.receipt_long;
      case 'cat_entertainment':
        return Icons.movie;
      case 'cat_health':
        return Icons.medical_services;
      case 'cat_education':
        return Icons.school;
      case 'cat_personal':
        return Icons.face;
      case 'cat_other_exp':
        return Icons.more_horiz;
      case 'cat_salary':
        return Icons.payments;
      case 'cat_business':
        return Icons.business_center;
      case 'cat_freelance':
        return Icons.laptop_mac;
      case 'cat_investment':
        return Icons.trending_up;
      case 'cat_gifts':
        return Icons.card_giftcard;
      case 'cat_other_inc':
        return Icons.savings;
      default:
        return Icons.category;
    }
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    final id = map['id'] as String;
    return Category(
      id: id,
      name: map['name'] as String,
      icon: getIcon(id),
      color: Color(map['color_value'] as int),
      type: TransactionType.values[map['type'] as int],
    );
  }

  static List<Category> get defaultCategories => [
        // Expense Categories
        const Category(
          id: 'cat_groceries',
          name: 'Groceries',
          icon: Icons.local_grocery_store,
          color: Color(0xFFFFA726),
          type: TransactionType.expense,
        ),
        const Category(
          id: 'cat_transport',
          name: 'Transport',
          icon: Icons.directions_bus,
          color: Color(0xFF42A5F5),
          type: TransactionType.expense,
        ),
        const Category(
          id: 'cat_shopping',
          name: 'Shopping',
          icon: Icons.shopping_bag,
          color: Color(0xFFAB47BC),
          type: TransactionType.expense,
        ),
        const Category(
          id: 'cat_bills',
          name: 'Bills & Utilities',
          icon: Icons.receipt_long,
          color: Color(0xFFEF5350),
          type: TransactionType.expense,
        ),
        const Category(
          id: 'cat_food',
          name: 'Food & Dining',
          icon: Icons.restaurant,
          color: Color(0xFFFF7043),
          type: TransactionType.expense,
        ),
        const Category(
          id: 'cat_entertainment',
          name: 'Entertainment',
          icon: Icons.movie,
          color: Color(0xFFEC407A),
          type: TransactionType.expense,
        ),
        const Category(
          id: 'cat_health',
          name: 'Health & Medical',
          icon: Icons.medical_services,
          color: Color(0xFF26A69A),
          type: TransactionType.expense,
        ),
        const Category(
          id: 'cat_education',
          name: 'Education',
          icon: Icons.school,
          color: Color(0xFF5C6BC0),
          type: TransactionType.expense,
        ),
        const Category(
          id: 'cat_personal',
          name: 'Personal Care',
          icon: Icons.face,
          color: Color(0xFF7E57C2),
          type: TransactionType.expense,
        ),
        const Category(
          id: 'cat_other_exp',
          name: 'Other Expense',
          icon: Icons.more_horiz,
          color: Color(0xFF78909C),
          type: TransactionType.expense,
        ),

        // Income Categories
        const Category(
          id: 'cat_salary',
          name: 'Salary',
          icon: Icons.payments,
          color: Color(0xFF66BB6A),
          type: TransactionType.income,
        ),
        const Category(
          id: 'cat_business',
          name: 'Business',
          icon: Icons.business_center,
          color: Color(0xFF2E7D32),
          type: TransactionType.income,
        ),
        const Category(
          id: 'cat_freelance',
          name: 'Freelance',
          icon: Icons.laptop_mac,
          color: Color(0xFF26C6DA),
          type: TransactionType.income,
        ),
        const Category(
          id: 'cat_investment',
          name: 'Investments',
          icon: Icons.trending_up,
          color: Color(0xFF9CCC65),
          type: TransactionType.income,
        ),
        const Category(
          id: 'cat_gifts',
          name: 'Gifts & Rewards',
          icon: Icons.card_giftcard,
          color: Color(0xFFFFCA28),
          type: TransactionType.income,
        ),
        const Category(
          id: 'cat_other_inc',
          name: 'Other Income',
          icon: Icons.savings,
          color: Color(0xFF80CBC4),
          type: TransactionType.income,
        ),
      ];
}
