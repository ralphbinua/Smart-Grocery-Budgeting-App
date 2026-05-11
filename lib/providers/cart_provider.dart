import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item.dart';
import '../models/purchase_history.dart';
import '../services/openai_service.dart';
import '../services/socket_service.dart';

class CartProvider with ChangeNotifier {
  // Constants for demo/mocking
  static const List<Map<String, dynamic>> _mockItems = [
    {'name': 'Nestle Milk 1L', 'price': 98.0, 'category': 'Dairy'},
    {'name': 'Gardenia Bread', 'price': 68.0, 'category': 'Bakery'},
    {'name': 'Lucky Me Noodles', 'price': 15.0, 'category': 'Instant Food'},
    {'name': 'C2 Green Tea 500ml', 'price': 25.0, 'category': 'Beverages'},
    {'name': 'Oishi Prawn Crackers', 'price': 35.0, 'category': 'Snacks'},
    {'name': 'Purefoods Hotdog 500g', 'price': 145.0, 'category': 'Meat'},
    {'name': 'San Miguel Beer 330ml', 'price': 55.0, 'category': 'Beverages'},
    {'name': 'Century Tuna 155g', 'price': 42.0, 'category': 'Canned Goods'},
  ];

  double _budgetLimit = 0.0;
  List<CartItem> _items = [];
  bool _isConnected = false;
  bool _isScanning = false;
  String? _scannerType; // 'phone' or 'iot'
  final List<PurchaseHistory> _history = [];
  final SocketService _socketService = SocketService();

  CartProvider() {
    _loadPreferences();
    _initSocket();
  }

  // --- Getters ---
  double get budgetLimit => _budgetLimit;
  double get totalSpent => _items.fold(0.0, (sum, item) => sum + item.total);
  double get remaining => _budgetLimit - totalSpent;
  double get progressPercent => _budgetLimit > 0 ? (totalSpent / _budgetLimit).clamp(0.0, 1.0) : 0.0;
  List<CartItem> get items => List.unmodifiable(_items);
  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  String? get scannerType => _scannerType;
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

  // --- Persistence & Initialization ---
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _budgetLimit = prefs.getDouble('budget_limit') ?? 0.0;
    _scannerType = prefs.getString('scanner_type');
    notifyListeners();
  }

  void _initSocket() {
    _socketService.connectToServer((data) {
      if (data != null && data['barcode'] != null) {
        processBarcode(data['barcode'].toString());
        setIoTConnected(true);
      }
    });
  }

  // --- State Modifiers ---
  void setBudget(double limit) async {
    _budgetLimit = limit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('budget_limit', limit);
    notifyListeners();
  }

  Future<void> setScannerType(String? type) async {
    _scannerType = type;
    final prefs = await SharedPreferences.getInstance();
    if (type == null) {
      await prefs.remove('scanner_type');
    } else {
      await prefs.setString('scanner_type', type);
    }
    notifyListeners();
  }

  void setIoTConnected(bool connected) {
    _isConnected = connected;
    notifyListeners();
  }

  // --- Cart Operations ---
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
        alternative: null,
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

  // --- Scanning Logic ---
  void simulateScan() async {
    _isScanning = true;
    notifyListeners();

    final random = Random();
    final pick = _mockItems[random.nextInt(_mockItems.length)];
    
    final String name = pick['name'] as String;
    final double price = pick['price'] as double;
    final String category = pick['category'] as String;

    final aiAlternative = await AIService.getAlternative(name, price, category);

    addItemWithAI(name, price, aiAlternative, category: category);

    _isScanning = false;
    notifyListeners();
  }

  Future<void> processBarcode(String barcode) async {
    _isScanning = true;
    notifyListeners();

    String name = 'Unknown Product';
    String category = 'General';
    // Generate a deterministic fake price between 10 and 300
    final double price = 10.0 + (barcode.hashCode.abs() % 290);

    try {
      final url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'];
          
          final prodName = product['product_name'] ?? product['product_name_en'] ?? product['generic_name'] ?? 'Unknown Product';
          final brands = product['brands'] ?? '';
          name = brands.isNotEmpty ? '$brands - $prodName' : prodName;
          
          category = _parseCategory(product);
        }
      }
    } catch (e) {
      debugPrint('Barcode API Error: $e');
    }

    final aiAlternative = await AIService.getAlternative(name, price, category);

    addItemWithAI(name, price, aiAlternative, category: category, barcode: barcode);

    _isScanning = false;
    notifyListeners();
  }

  String _parseCategory(Map<String, dynamic> product) {
    if (product['categories_tags'] != null && (product['categories_tags'] as List).isNotEmpty) {
      final tag = (product['categories_tags'] as List).first.toString();
      return tag.contains(':') ? tag.split(':').last.replaceAll('-', ' ').toUpperCase() : tag;
    } else if (product['categories'] != null && product['categories'].toString().isNotEmpty) {
      return product['categories'].toString().split(',').first.trim();
    }
    return 'General';
  }

  String _randomBarcode() {
    final r = Random();
    return List.generate(13, (_) => r.nextInt(10)).join();
  }

  String _monthName(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }
}