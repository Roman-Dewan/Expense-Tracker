import 'package:flutter/material.dart';

class Account {
  final String id;
  final String name;
  final String type; // 'cash', 'bank', 'credit_card', 'wallet'
  final double initialBalance;
  final IconData icon;
  final Color color;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    this.initialBalance = 0.0,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'initial_balance': initialBalance,
      'icon_code': icon.codePoint,
      'color_value': color.toARGB32(),
    };
  }

  static IconData getIcon(String id) {
    switch (id) {
      case 'acc_cash':
        return Icons.account_balance_wallet;
      case 'acc_bank':
        return Icons.account_balance;
      case 'acc_digital':
        return Icons.phone_android;
      default:
        return Icons.account_balance_wallet;
    }
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    final id = map['id'] as String;
    return Account(
      id: id,
      name: map['name'] as String,
      type: map['type'] as String,
      initialBalance: (map['initial_balance'] as num).toDouble(),
      icon: getIcon(id),
      color: Color(map['color_value'] as int),
    );
  }

  static List<Account> get defaultAccounts => [
        const Account(
          id: 'acc_cash',
          name: 'Cash in Wallet',
          type: 'cash',
          initialBalance: 0.0,
          icon: Icons.account_balance_wallet,
          color: Color(0xFF4CAF50),
        ),
        const Account(
          id: 'acc_bank',
          name: 'Primary Bank',
          type: 'bank',
          initialBalance: 0.0,
          icon: Icons.account_balance,
          color: Color(0xFF2196F3),
        ),
        const Account(
          id: 'acc_digital',
          name: 'Mobile / E-Wallet',
          type: 'wallet',
          initialBalance: 0.0,
          icon: Icons.phone_android,
          color: Color(0xFFFF9800),
        ),
      ];
}
