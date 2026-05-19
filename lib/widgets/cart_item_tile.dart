import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;

  const CartItemTile({super.key, required this.item});

  Color _categoryColor(String cat) {
    const colors = {
      'Dairy': AppColors.info,
      'Bakery': AppColors.warning,
      'Beverages': AppColors.accentLight,
      'Snacks': AppColors.accent,
      'Meat': AppColors.danger,
      'Canned Goods': Color(0xFF10B981),
      'Instant Food': Color(0xFFF97316),
      'General': AppColors.textMuted,
    };
    return colors[cat] ?? AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final catColor = _categoryColor(item.category);
    final hasAlt = item.alternative != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Category indicator
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(_categoryIcon(item.category), color: catColor, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(item.category, style: TextStyle(fontSize: 10, color: catColor, fontWeight: FontWeight.w600)),
                            ),
                            Text('₱${item.price.toStringAsFixed(2)} each', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₱${item.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      _QuantityControl(item: item, cart: cart),
                    ],
                  ),
                ],
              ),
            ),
            if (hasAlt) _buildAltSuggestion(context, item),
          ],
        ),
      ),
    );
  }

  Widget _buildAltSuggestion(BuildContext context, CartItem item) {
    final altName = item.alternative!['name'] as String;
    final altPrice = (item.alternative!['price'] as num).toDouble();
    final savings = item.price - altPrice;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent.withOpacity(0.08), AppColors.primary.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI: Swap to $altName',
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Save ₱${savings.toStringAsFixed(2)} • ₱${altPrice.toStringAsFixed(2)} ea',
                  style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Provider.of<CartProvider>(context, listen: false).acceptSwap(item.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Swapped to $altName!')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 4)],
              ),
              child: const Text('SWAP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    const icons = {
      'Dairy': Icons.egg_alt_rounded,
      'Bakery': Icons.breakfast_dining_rounded,
      'Beverages': Icons.local_drink_rounded,
      'Snacks': Icons.cookie_rounded,
      'Meat': Icons.set_meal_rounded,
      'Canned Goods': Icons.inventory_2_rounded,
      'Instant Food': Icons.ramen_dining_rounded,
      'General': Icons.shopping_basket_rounded,
    };
    return icons[cat] ?? Icons.shopping_basket_rounded;
  }
}

class _QuantityControl extends StatefulWidget {
  final CartItem item;
  final CartProvider cart;

  const _QuantityControl({required this.item, required this.cart});

  @override
  State<_QuantityControl> createState() => _QuantityControlState();
}

class _QuantityControlState extends State<_QuantityControl> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.item.quantity}');
  }

  @override
  void didUpdateWidget(covariant _QuantityControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.quantity != widget.item.quantity) {
      _controller.text = '${widget.item.quantity}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final val = int.tryParse(_controller.text.trim());
    if (val == null || val <= 0) {
      widget.cart.updateQuantity(widget.item.id, 0); // removes item
    } else {
      widget.cart.updateQuantity(widget.item.id, val);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Delete button
        GestureDetector(
          onTap: () => widget.cart.updateQuantity(widget.item.id, 0),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.delete_rounded, size: 14, color: AppColors.danger),
          ),
        ),
        const SizedBox(width: 6),
        // Qty text input
        SizedBox(
          width: 42,
          height: 28,
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.zero,
              filled: true,
              fillColor: AppColors.bgCardAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: BorderSide.none,
              ),
              hintText: '0',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            onSubmitted: (_) => _submit(),
            onTapOutside: (_) => _submit(),
          ),
        ),
      ],
    );
  }
}
