import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  double _budgetLimit = 0.0;
  double _totalSpent = 0.0;
  List<CartItem> _items = [];

  double get budgetLimit => _budgetLimit;
  double get totalSpent => _totalSpent;
  double get remaining => _budgetLimit - _totalSpent;
  List<CartItem> get items => _items;

  void setBudget(double limit) {
    _budgetLimit = limit;
    notifyListeners();
  }

  void addItemWithAI(String name, double price, Map<String, dynamic>? alternative) {
    _items.insert(0, CartItem(name: name, price: price, alternative: alternative));
    _totalSpent += price;
    notifyListeners();
  }
}