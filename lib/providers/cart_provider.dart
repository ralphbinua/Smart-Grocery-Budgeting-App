import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
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
      saved += item.savedAmount * item.quantity;
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
  void addItemWithAI(String name, double price, Map<String, dynamic>? alternative, {String category = 'General', String barcode = '', int initialQuantity = 1}) {
    final previouslyOver = isOverBudget;
    final previouslyNear = isNearLimit;

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
        quantity: initialQuantity,
      ));
    }
    notifyListeners();

    if (isOverBudget && !previouslyOver) {
      _showOverBudgetAlert();
    } else if (isNearLimit && !previouslyNear) {
      _showNearLimitAlert();
    }
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
      final previouslyOver = isOverBudget;
      final previouslyNear = isNearLimit;

      _items[idx] = _items[idx].copyWith(quantity: quantity);
      notifyListeners();

      if (isOverBudget && !previouslyOver) {
        _showOverBudgetAlert();
      } else if (isNearLimit && !previouslyNear) {
        _showNearLimitAlert();
      }
    }
  }

  void acceptSwap(String id) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx >= 0 && _items[idx].alternative != null) {
      final original = _items[idx];
      final alt = original.alternative!;
      final altPrice = (alt['price'] as num).toDouble();
      
      _items[idx] = CartItem(
        id: original.id,
        name: alt['name'] as String,
        price: altPrice,
        category: original.category,
        barcode: original.barcode,
        alternative: null,
        savedAmount: (original.price - altPrice > 0) ? (original.price - altPrice) : 0.0,
        quantity: original.quantity,
        scannedAt: original.scannedAt,
      );
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    if (_items.isEmpty) return;
    final now = DateTime.now();
    
    final newHistoryItem = PurchaseHistory(
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
    );
    
    _history.insert(0, newHistoryItem);
    
    // Save to MongoDB Cloud Database via our Node.js Backend
    try {
      // Automatically updated to your computer's exact WiFi IP address for Android compatibility!
      final url = Uri.parse('https://smart-grocery-budgeting-app.onrender.com/api/trips'); 
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'totalSpent': totalSpent,
          'totalSaved': totalSavedByAI,
          'items': _items.map((i) => {
            'barcode': i.barcode,
            'name': i.name,
            'price': i.price,
            'quantity': i.quantity,
            'isAiSwapped': i.savedAmount > 0
          }).toList()
        }),
      );
      debugPrint('[MongoDB] Checkout Trip successfully saved to Cloud!');
    } catch (e) {
      debugPrint('[MongoDB] Error saving trip: $e');
    }

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
    double price = 0.0;
    bool foundInDb = false;

    // 1. Check our Custom MongoDB Cloud Database First!
    try {
      final dbUrl = Uri.parse('https://smart-grocery-budgeting-app.onrender.com/api/products/$barcode');
      final dbResponse = await http.get(dbUrl).timeout(const Duration(seconds: 3));
      
      if (dbResponse.statusCode == 200) {
        final data = json.decode(dbResponse.body);
        name = data['name'];
        category = data['category'] ?? 'General';
        price = (data['latestPrice'] as num).toDouble();
        foundInDb = true;
        debugPrint('[MongoDB] Product found locally! $name at P$price');
      }
    } catch (e) {
      debugPrint('[MongoDB] Product not in local DB, checking internet...');
    }

    // 2. If not in DB, fallback to OpenFoodFacts (Crowdsource Mode)
    if (!foundInDb) {
      bool foundInApi = false;
      
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
            
            // Temporary fallback price for API products until user edits it manually
            price = 10.0 + (barcode.hashCode.abs() % 290); 
            foundInApi = true;
          }
        }
      } catch (e) {
        debugPrint('Barcode API Error: $e');
      }

      if (!foundInApi) {
        _isScanning = false;
        notifyListeners();

        final manualData = await _requestManualInput(barcode);
        if (manualData == null) {
          return; // User cancelled
        }
        
        name = manualData['name'];
        price = manualData['price'];
        category = 'General';
        
        _isScanning = true;
        notifyListeners();
      }

      // 3. Save this new item to MongoDB so it's there next time!
      try {
        final dbPostUrl = Uri.parse('https://smart-grocery-budgeting-app.onrender.com/api/products');
        await http.post(
          dbPostUrl,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'barcode': barcode,
            'name': name,
            'category': category,
            'latestPrice': price
          }),
        );
        debugPrint('[MongoDB] New product saved to Cloud for future scans!');
      } catch (e) {
        debugPrint('[MongoDB] Error saving new product: $e');
      }
    }

    // 4. Ask user for quantity
    final qty = await _requestQuantityInput(name, price);
    if (qty == null) {
      // User cancelled — abort
      _isScanning = false;
      notifyListeners();
      return;
    }

    // 5. Get AI recommendation
    final aiAlternative = await AIService.getAlternative(name, price, category);

    addItemWithAI(name, price, aiAlternative, category: category, barcode: barcode, initialQuantity: qty);

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

  Future<int?> _requestQuantityInput(String name, double price) async {
    final context = navigatorKey.currentContext;
    if (context == null) return null;

    final controller = TextEditingController(text: '1');

    return await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shopping_cart_rounded, color: Color(0xFF10B981), size: 22),
            SizedBox(width: 10),
            Text('Add to Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('₱${price.toStringAsFixed(2)} each', style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 20),
            const Text('Quantity', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                hintText: '1',
                hintStyle: const TextStyle(color: Colors.white38),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                Navigator.pop(ctx, val);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _requestManualInput(String barcode) async {
    final context = navigatorKey.currentContext;
    if (context == null) return null;

    final nameController = TextEditingController();
    final priceController = TextEditingController();

    return await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Unknown Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This barcode was not found in our database. Please enter the details manually.', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Product Name',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Price (₱)',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceController.text);
              if (nameController.text.isNotEmpty && price != null && price > 0) {
                Navigator.pop(ctx, {'name': nameController.text.trim(), 'price': price});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save Product', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  String _randomBarcode() {
    final r = Random();
    return List.generate(13, (_) => r.nextInt(10)).join();
  }

  String _monthName(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }

  void _showOverBudgetAlert() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFEF4444),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Budget Limit Exceeded!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'This item puts you over your shopping budget limit by ₱${(totalSpent - budgetLimit).toStringAsFixed(2)}.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF334155)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Acknowledge',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showBudgetDialogFromAlert(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Adjust Budget',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showNearLimitAlert() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Approaching Budget Limit', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                    Text('You have used over 85% of your trip budget. Remaining: ₱${remaining.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  void _showBudgetDialogFromAlert(BuildContext context) {
    final controller = TextEditingController(text: budgetLimit > 0 ? budgetLimit.toStringAsFixed(0) : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF10B981), size: 22),
            SizedBox(width: 10),
            Text('Adjust Budget', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set a new shopping budget for this trip.', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: '0.00',
                prefixText: '₱ ',
                prefixStyle: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 22),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF10B981))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final budget = double.tryParse(controller.text) ?? 0;
              if (budget > 0) {
                setBudget(budget);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Budget updated to ₱${budget.toStringAsFixed(2)}'),
                    backgroundColor: const Color(0xFF1E293B),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save Budget', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}