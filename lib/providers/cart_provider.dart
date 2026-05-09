import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/purchase_history.dart';
import 'dart:math';

class CartProvider with ChangeNotifier {
  double _budgetLimit = 0.0;
  List<CartItem> _items = [];
  bool _isConnected = false;
  bool _isScanning = false;
  final List<PurchaseHistory> _history = _generateMockHistory();

  // Getters
  double get budgetLimit => _budgetLimit;
  double get totalSpent => _items.fold(0.0, (sum, item) => sum + item.total);
  double get remaining => _budgetLimit - totalSpent;
  double get progressPercent => _budgetLimit > 0 ? (totalSpent / _budgetLimit).clamp(0.0, 1.0) : 0.0;
  List<CartItem> get items => List.unmodifiable(_items);
  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  List<PurchaseHistory> get history => List.unmodifiable(_history);
  bool get isOverBudget => remaining < 0;
  bool get isNearLimit => _budgetLimit > 0 && remaining / _budgetLimit < 0.15 && !isOverBudget;
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalSavedByAI {
    double saved = 0;
    for (final item in _items) {
      if (item.alternative != null) {
        final altPrice = (item.alternative!['price'] as num).toDouble();
        if (altPrice < item.price) {
          saved += (item.price - altPrice) * item.quantity;
        }
      }
    }
    return saved;
  }

  Map<String, double> get spendingByCategory {
    final map = <String, double>{};
    for (final item in _items) {
      map[item.category] = (map[item.category] ?? 0) + item.total;
    }
    return map;
  }

  void setBudget(double limit) {
    _budgetLimit = limit;
    notifyListeners();
  }

  void setIoTConnected(bool connected) {
    _isConnected = connected;
    notifyListeners();
  }

  void addItemWithAI(String name, double price, Map<String, dynamic>? alternative, {String category = 'General', String barcode = ''}) {
    final existingIndex = _items.indexWhere((i) => i.name == name);
    if (existingIndex >= 0) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + 1,
      );
    } else {
      _items.insert(0, CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        price: price,
        category: category,
        barcode: barcode.isNotEmpty ? barcode : _randomBarcode(),
        alternative: alternative,
      ));
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void updateQuantity(String id, int quantity) {
    if (quantity <= 0) {
      removeItem(id);
      return;
    }
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  void acceptSwap(String id) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx >= 0 && _items[idx].alternative != null) {
      final original = _items[idx];
      final alt = original.alternative!;
      
      _items[idx] = CartItem(
        id: original.id,
        name: alt['name'] as String,
        price: (alt['price'] as num).toDouble(),
        category: original.category,
        barcode: original.barcode,
        alternative: null, // clear the alternative since it's swapped
        quantity: original.quantity,
        scannedAt: original.scannedAt,
      );
      notifyListeners();
    }
  }

  void clearCart() {
    if (_items.isEmpty) return;
    final now = DateTime.now();
    _history.insert(0, PurchaseHistory(
      id: now.millisecondsSinceEpoch.toString(),
      date: '${_monthName(now.month)} ${now.day}, ${now.year}',
      items: _items.map((i) => HistoryItem(
        name: i.name,
        price: i.price,
        quantity: i.quantity,
        category: i.category,
      )).toList(),
      totalSpent: totalSpent,
      budgetLimit: _budgetLimit,
      totalSaved: totalSavedByAI,
    ));
    _items = [];
    notifyListeners();
  }

  void simulateScan() async {
    _isScanning = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1200));

    final mockItems = [
      {'name': 'Nestle Milk 1L', 'price': 98.0, 'category': 'Dairy', 'alt': {'name': 'Magnolia Milk 1L', 'price': 79.0}},
      {'name': 'Gardenia Bread', 'price': 68.0, 'category': 'Bakery', 'alt': {'name': 'SunMaid Bread', 'price': 55.0}},
      {'name': 'Lucky Me Noodles', 'price': 15.0, 'category': 'Instant Food', 'alt': null},
      {'name': 'C2 Green Tea 500ml', 'price': 25.0, 'category': 'Beverages', 'alt': {'name': 'Wilkins Water 500ml', 'price': 12.0}},
      {'name': 'Oishi Prawn Crackers', 'price': 35.0, 'category': 'Snacks', 'alt': {'name': 'Nova Chips', 'price': 28.0}},
      {'name': 'Purefoods Hotdog 500g', 'price': 145.0, 'category': 'Meat', 'alt': {'name': 'CDO Hotdog 500g', 'price': 118.0}},
      {'name': 'San Miguel Beer 330ml', 'price': 55.0, 'category': 'Beverages', 'alt': null},
      {'name': 'Century Tuna 155g', 'price': 42.0, 'category': 'Canned Goods', 'alt': {'name': 'Sunshine Tuna 155g', 'price': 35.0}},
    ];

    final random = Random();
    final pick = mockItems[random.nextInt(mockItems.length)];
    final rawAlt = pick['alt'];
    addItemWithAI(
      pick['name'] as String,
      pick['price'] as double,
      rawAlt != null ? Map<String, dynamic>.from(rawAlt as Map) : null,
      category: pick['category'] as String,
    );

    _isScanning = false;
    notifyListeners();
  }

  String _randomBarcode() {
    final r = Random();
    return List.generate(13, (_) => r.nextInt(10)).join();
  }

  String _monthName(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }

  static List<PurchaseHistory> _generateMockHistory() {
    return [
      PurchaseHistory(
        id: '1',
        date: 'May 05, 2026',
        storeName: 'SM Supermarket',
        items: [
          HistoryItem(name: 'Nestle Milk 1L', price: 98.0, quantity: 2, category: 'Dairy'),
          HistoryItem(name: 'Gardenia Bread', price: 68.0, quantity: 1, category: 'Bakery'),
          HistoryItem(name: 'Lucky Me Noodles', price: 15.0, quantity: 5, category: 'Instant Food'),
          HistoryItem(name: 'Purefoods Hotdog 500g', price: 145.0, quantity: 1, category: 'Meat'),
        ],
        totalSpent: 437.0,
        budgetLimit: 500.0,
        totalSaved: 62.0,
      ),
      PurchaseHistory(
        id: '2',
        date: 'April 28, 2026',
        storeName: 'Robinsons Supermarket',
        items: [
          HistoryItem(name: 'Century Tuna 155g', price: 42.0, quantity: 3, category: 'Canned Goods'),
          HistoryItem(name: 'C2 Green Tea 500ml', price: 25.0, quantity: 4, category: 'Beverages'),
          HistoryItem(name: 'Oishi Prawn Crackers', price: 35.0, quantity: 2, category: 'Snacks'),
        ],
        totalSpent: 296.0,
        budgetLimit: 350.0,
        totalSaved: 24.0,
      ),
      PurchaseHistory(
        id: '3',
        date: 'April 20, 2026',
        storeName: 'Puregold',
        items: [
          HistoryItem(name: 'Nestle Milk 1L', price: 98.0, quantity: 1, category: 'Dairy'),
          HistoryItem(name: 'Lucky Me Noodles', price: 15.0, quantity: 10, category: 'Instant Food'),
          HistoryItem(name: 'San Miguel Beer 330ml', price: 55.0, quantity: 6, category: 'Beverages'),
        ],
        totalSpent: 548.0,
        budgetLimit: 600.0,
        totalSaved: 38.0,
      ),
    ];
  }
}