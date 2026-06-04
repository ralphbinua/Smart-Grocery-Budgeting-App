import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('https://smart-grocery-budgeting-app.onrender.com/api/products'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _products = data;
          _filteredProducts = data;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        final barcode = (p['barcode'] ?? '').toString().toLowerCase();
        return name.contains(query) || barcode.contains(query);
      }).toList();
    });
  }

  Future<void> _deleteProduct(String barcode) async {
    try {
      final response = await http.delete(Uri.parse('https://smart-grocery-budgeting-app.onrender.com/api/products/$barcode'));
      if (response.statusCode == 200 || response.statusCode == 204) {
        _fetchProducts();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted successfully')));
      } else {
        throw Exception('Failed to delete');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showProductDialog({Map<String, dynamic>? product}) {
    final isEdit = product != null;
    final barcodeController = TextEditingController(text: product?['barcode']?.toString() ?? '');
    final nameController = TextEditingController(text: product?['name']?.toString() ?? '');
    final categoryController = TextEditingController(text: product?['category']?.toString() ?? 'General');
    final priceController = TextEditingController(text: product?['latestPrice']?.toString() ?? '');
    final promoLabelController = TextEditingController(text: product?['promoLabel']?.toString() ?? '');
    final promoDiscountController = TextEditingController(text: (product?['promoDiscount'] ?? 0).toString());
    final promoStoreController = TextEditingController(text: product?['promoStore']?.toString() ?? '');
    bool isPromo = product?['isPromo'] == true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEdit ? 'Edit Product' : 'Add Product', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: barcodeController,
                  enabled: !isEdit,
                  decoration: const InputDecoration(labelText: 'Barcode', labelStyle: TextStyle(color: AppColors.textSecondary)),
                  style: const TextStyle(color: AppColors.textPrimary)
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: AppColors.textSecondary)),
                  style: const TextStyle(color: AppColors.textPrimary)
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category', labelStyle: TextStyle(color: AppColors.textSecondary)),
                  style: const TextStyle(color: AppColors.textPrimary)
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price (₱)', labelStyle: TextStyle(color: AppColors.textSecondary)),
                  style: const TextStyle(color: AppColors.textPrimary)
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.textSecondary, thickness: 0.3),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('🏷️  Active Promo', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                     Switch(
                       value: isPromo,
                       activeThumbColor: AppColors.primary,
                       onChanged: (v) => setDialogState(() => isPromo = v),
                     ),
                  ],
                ),
                if (isPromo) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: promoLabelController,
                    decoration: const InputDecoration(
                      labelText: 'Promo Label (e.g. Buy 2 Get 1)',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary)
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: promoDiscountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Discount % (e.g. 20)',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary)
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: promoStoreController,
                    decoration: const InputDecoration(
                      labelText: 'Store (e.g. SM Supermarket)',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary)
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final barcode = barcodeController.text;
                final name = nameController.text;
                final category = categoryController.text;
                final price = double.tryParse(priceController.text) ?? 0.0;

                if (barcode.isEmpty || name.isEmpty) return;

                try {
                  final url = isEdit
                    ? Uri.parse('https://smart-grocery-budgeting-app.onrender.com/api/products/$barcode')
                    : Uri.parse('https://smart-grocery-budgeting-app.onrender.com/api/products');

                  final requestBody = json.encode({
                    'barcode': barcode,
                    'name': name,
                    'category': category,
                    'latestPrice': price,
                    'isPromo': isPromo,
                    'promoLabel': promoLabelController.text.trim(),
                    'promoDiscount': double.tryParse(promoDiscountController.text) ?? 0,
                    'promoStore': promoStoreController.text.trim(),
                  });

                  final response = isEdit
                    ? await http.put(url, headers: {'Content-Type': 'application/json'}, body: requestBody)
                    : await http.post(url, headers: {'Content-Type': 'application/json'}, body: requestBody);

                  if (response.statusCode == 200 || response.statusCode == 201) {
                    _fetchProducts();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product saved successfully')));
                  } else {
                    throw Exception('Failed to save product');
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        title: const Text('Admin Dashboard', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showProductDialog(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by name or barcode...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.bgCardAlt,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _filteredProducts.isEmpty
                  ? const Center(child: Text('No products found', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.builder(
                      itemCount: _filteredProducts.length,
                      itemBuilder: (ctx, i) {
                        final p = _filteredProducts[i];
                        final hasPromo = p['isPromo'] == true;
                        final promoLabel = p['promoLabel']?.toString() ?? '';
                        final promoStore = p['promoStore']?.toString() ?? '';
                        final discount = p['promoDiscount'] ?? 0;
                        return Card(
                          color: hasPromo ? AppColors.bgCard.withAlpha(255) : AppColors.bgCard,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: hasPromo
                              ? const BorderSide(color: AppColors.primary, width: 1.2)
                              : BorderSide.none,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Expanded(child: Text(p['name'] ?? 'Unknown', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold))),
                                  if (hasPromo)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        discount > 0 ? '${discount.toInt()}% OFF' : 'PROMO',
                                        style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Barcode: ${p['barcode']}  •  ₱${p['latestPrice']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  if (hasPromo && promoLabel.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        '${promoLabel.isNotEmpty ? promoLabel : "On Sale"}${promoStore.isNotEmpty ? " @ $promoStore" : ""}',
                                        style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit, color: AppColors.primary), onPressed: () => _showProductDialog(product: p)),
                                  IconButton(icon: const Icon(Icons.delete, color: AppColors.danger), onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        backgroundColor: AppColors.bgCard,
                                        title: const Text('Confirm Delete', style: TextStyle(color: AppColors.textPrimary)),
                                        content: const Text('Are you sure you want to delete this product?', style: TextStyle(color: AppColors.textSecondary)),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                            onPressed: () {
                                              Navigator.pop(c);
                                              _deleteProduct(p['barcode'].toString());
                                            },
                                            child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
