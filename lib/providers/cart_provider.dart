import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../models/cart_item.dart';
import '../models/grocery_input_item.dart';
import '../models/purchase_history.dart';
import '../services/openai_service.dart';
import '../theme/app_theme.dart';

class CartProvider with ChangeNotifier {
  static const String _baseUrl = 'https://smart-grocery-budgeting-app.onrender.com';
  double _budgetLimit = 0.0;

  // ─── Grocery Input List (user's raw typed list, pre-analysis) ───────────────
  final List<GroceryInputItem> _groceryList = [];

  // ─── Analyzed Cart Items (populated after AI analysis) ──────────────────────
  List<CartItem> _items = [];

  bool _isAnalyzing = false;
  final List<PurchaseHistory> _history = [];

  // ─── Alert tracking (each fires only once per session) ──────────────────────
  bool _alert50Shown = false;
  bool _alert80Shown = false;
  bool _alert100Shown = false;

  CartProvider() {
    _loadPreferences();
  }

  // ─── Getters ─────────────────────────────────────────────────────────────────
  double get budgetLimit => _budgetLimit;
  double get totalSpent => _items.fold(0.0, (sum, i) => sum + i.total);
  double get remaining => _budgetLimit - totalSpent;
  double get progressPercent =>
      _budgetLimit > 0 ? (totalSpent / _budgetLimit).clamp(0.0, 1.0) : 0.0;
  List<CartItem> get items => List.unmodifiable(_items);
  List<GroceryInputItem> get groceryList => List.unmodifiable(_groceryList);
  bool get isAnalyzing => _isAnalyzing;
  bool get isOverBudget => remaining < 0;
  bool get isNearLimit =>
      _budgetLimit > 0 && progressPercent >= 0.8 && !isOverBudget;
  int get totalItems => _items.fold(0, (sum, i) => sum + i.quantity);
  List<PurchaseHistory> get history => List.unmodifiable(_history);
  bool get hasGroceryItems => _groceryList.isNotEmpty;
  bool get hasAnalyzedItems => _items.isNotEmpty;

  int get couponCount =>
      _items.where((i) => i.coupons.isNotEmpty).length;

  int get alternativeCount =>
      _items.where((i) => i.alternative != null).length;

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

  // ─── Persistence ──────────────────────────────────────────────────────────────
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _budgetLimit = prefs.getDouble('budget_limit') ?? 0.0;
    notifyListeners();
  }

  void setBudget(double limit) async {
    _budgetLimit = limit;
    // Reset alert flags when budget is changed
    _alert50Shown = false;
    _alert80Shown = false;
    _alert100Shown = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('budget_limit', limit);
    notifyListeners();
  }

  // ─── Grocery Input List Operations ───────────────────────────────────────────
  void addGroceryItem(String name, {int quantity = 1, double? estimatedPrice}) {
    if (name.trim().isEmpty) return;
    // Check for duplicates (case-insensitive)
    final exists = _groceryList.any(
        (i) => i.name.toLowerCase() == name.trim().toLowerCase());
    if (exists) return;

    _groceryList.add(GroceryInputItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      quantity: quantity,
      estimatedPrice: estimatedPrice,
    ));
    notifyListeners();
  }

  void removeGroceryItem(String id) {
    _groceryList.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  void updateGroceryItem(String id,
      {String? name, int? quantity, double? estimatedPrice}) {
    final idx = _groceryList.indexWhere((i) => i.id == id);
    if (idx < 0) return;
    final item = _groceryList[idx];
    if (name != null) item.name = name;
    if (quantity != null) item.quantity = quantity;
    if (estimatedPrice != null) item.estimatedPrice = estimatedPrice;
    notifyListeners();
  }

  void clearGroceryList() {
    _groceryList.clear();
    notifyListeners();
  }

  // ─── AI Batch Analysis ────────────────────────────────────────────────────────
  Future<void> analyzeList() async {
    if (_groceryList.isEmpty || _isAnalyzing) return;

    _isAnalyzing = true;
    notifyListeners();

    Map<String, Map<String, dynamic>>? dbGroundingData;
    try {
      final namesToSearch = _groceryList.map((item) => item.name).toList();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/products/search-batch'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'names': namesToSearch}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> rawMap = json.decode(response.body);
        dbGroundingData = {};
        rawMap.forEach((key, value) {
          if (value != null) {
            dbGroundingData![key.toLowerCase().trim()] = Map<String, dynamic>.from(value);
          }
        });
        debugPrint('[Grounding] Successfully matched ${dbGroundingData.length} items from database.');
      } else {
        debugPrint('[Grounding] Failed to load grounding data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[Grounding] Network/DB search error, proceeding with AI-only: $e');
    }

    try {
      final results = await AIService.analyzeGroceryList(
        _groceryList,
        dbGroundingData: dbGroundingData,
      );

      _items = [];

      for (int i = 0; i < results.length && i < _groceryList.length; i++) {
        final r = results[i];
        final input = _groceryList[i];

        final double price =
            (r['price'] as num?)?.toDouble() ?? input.estimatedPrice ?? 50.0;
        final String category = r['category'] as String? ?? 'General';
        final Map<String, dynamic>? alt =
            r['alternative'] as Map<String, dynamic>?;
        final String note = r['note'] as String? ?? '';
        final List<String> coupons = List<String>.from(
            (r['coupons'] as List?)?.cast<String>() ?? []);

        // If DB indicates a promo is active, build a rich coupon string
        // from the real DB promo fields and ensure it is in our coupons list.
        final dbEntry = dbGroundingData?[input.name.toLowerCase().trim()];
        final isDbPromo = dbEntry?['isPromo'] == true;
        if (isDbPromo) {
          final label   = (dbEntry?['promoLabel']  as String?)?.trim() ?? '';
          final store   = (dbEntry?['promoStore']   as String?)?.trim() ?? '';
          final discount = dbEntry?['promoDiscount'] ?? 0;
          String promoText = label.isNotEmpty ? label : 'Special Promo';
          if (discount is num && discount > 0) promoText += ' – ${discount.toInt()}% OFF';
          if (store.isNotEmpty) promoText += ' @ $store';
          if (!coupons.contains(promoText)) {
            coupons.insert(0, promoText);
          }
        }

        _items.insert(
          0,
          CartItem(
            id: '${DateTime.now().millisecondsSinceEpoch}_$i',
            name: r['name'] as String? ?? input.name,
            price: price,
            category: category,
            alternative: alt,
            note: note.isNotEmpty ? note : null,
            coupons: coupons,
            quantity: input.quantity,
          ),
        );
      }

      _checkBudgetAlerts();
    } catch (e) {
      debugPrint('CartProvider.analyzeList error: $e');
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  // ─── Cart Item Operations ─────────────────────────────────────────────────────
  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
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
      _checkBudgetAlerts();
      notifyListeners();
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
        alternative: null,
        savedAmount:
            (original.price - altPrice > 0) ? (original.price - altPrice) : 0.0,
        note: null,
        coupons: original.coupons,
        quantity: original.quantity,
        addedAt: original.addedAt,
      );
      notifyListeners();
    }
  }

  // ─── Checkout ──────────────────────────────────────────────────────────────────
  Future<void> clearCart() async {
    if (_items.isEmpty) return;
    final now = DateTime.now();

    final newHistoryItem = PurchaseHistory(
      id: now.millisecondsSinceEpoch.toString(),
      date: '${_monthName(now.month)} ${now.day}, ${now.year}',
      items: _items
          .map((i) => HistoryItem(
                name: i.name,
                price: i.price,
                quantity: i.quantity,
                category: i.category,
              ))
          .toList(),
      totalSpent: totalSpent,
      budgetLimit: _budgetLimit,
      totalSaved: totalSavedByAI,
    );

    _history.insert(0, newHistoryItem);

    // Save to MongoDB Cloud Database via Node.js backend
    try {
      final url =
          Uri.parse('$_baseUrl/api/trips');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'totalSpent': totalSpent,
          'totalSaved': totalSavedByAI,
          'items': _items
              .map((i) => {
                    'name': i.name,
                    'price': i.price,
                    'quantity': i.quantity,
                    'isAiSwapped': i.savedAmount > 0,
                  })
              .toList()
        }),
      );
      debugPrint('[MongoDB] Checkout Trip successfully saved to Cloud!');
    } catch (e) {
      debugPrint('[MongoDB] Error saving trip: $e');
    }

    _items = [];
    _groceryList.clear();
    // Reset alerts for new session
    _alert50Shown = false;
    _alert80Shown = false;
    _alert100Shown = false;
    notifyListeners();
  }

  // ─── Budget Alert System ─────────────────────────────────────────────────────
  void _checkBudgetAlerts() {
    if (_budgetLimit <= 0) return;

    final pct = progressPercent;

    if (pct >= 1.0 && !_alert100Shown) {
      _alert100Shown = true;
      _showOverBudgetAlert();
    } else if (pct >= 0.8 && !_alert80Shown) {
      _alert80Shown = true;
      _showThresholdSnackbar(
        '⚠️ 80% of budget used',
        'Only ₱${remaining.toStringAsFixed(2)} remaining.',
        const Color(0xFFF59E0B),
      );
    } else if (pct >= 0.5 && !_alert50Shown) {
      _alert50Shown = true;
      _showThresholdSnackbar(
        '💡 Halfway through your budget',
        '₱${remaining.toStringAsFixed(2)} remaining. Consider alternatives!',
        AppColors.info,
      );
    }
  }

  void _showThresholdSnackbar(
      String title, String subtitle, Color color) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.notifications_active_rounded,
                  color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 13)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    });
  }

  void _showOverBudgetAlert() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
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
                'Budget Limit Reached!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Your cart is over budget by ₱${(totalSpent - budgetLimit).toStringAsFixed(2)}. Consider swapping to cheaper alternatives.',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 14),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Got it',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600)),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Adjust Budget',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
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

  void _showBudgetDialogFromAlert(BuildContext context) {
    final controller = TextEditingController(
        text: budgetLimit > 0 ? budgetLimit.toStringAsFixed(0) : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded,
                color: Color(0xFF10B981), size: 22),
            SizedBox(width: 10),
            Text('Adjust Budget',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set a new shopping budget for this trip.',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: '0.00',
                prefixText: '₱ ',
                prefixStyle: TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 22),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF10B981))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final budget = double.tryParse(controller.text) ?? 0;
              if (budget > 0) {
                setBudget(budget);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save Budget',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────
  String _monthName(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }

  String randomId() {
    final r = Random();
    return List.generate(8, (_) => r.nextInt(10)).join();
  }
}