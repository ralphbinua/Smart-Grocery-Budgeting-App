import 'package:flutter/material.dart';
import '../models/grocery_input_item.dart';
import '../theme/app_theme.dart';

class GroceryItemInputTile extends StatefulWidget {
  final GroceryInputItem item;
  final VoidCallback onRemove;
  final void Function(String? name, int? qty, double? price) onUpdate;

  const GroceryItemInputTile({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  State<GroceryItemInputTile> createState() => _GroceryItemInputTileState();
}

class _GroceryItemInputTileState extends State<GroceryItemInputTile> {
  bool _isEditing = false;
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _priceController = TextEditingController(
        text: widget.item.estimatedPrice?.toStringAsFixed(2) ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _saveEdit() {
    final name =
        _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null;
    final price = double.tryParse(_priceController.text.trim());
    widget.onUpdate(name, null, price);
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _isEditing ? AppColors.bgCardAlt : AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isEditing
              ? AppColors.primary.withValues(alpha: 0.4)
              : const Color(0xFF1E293B),
        ),
      ),
      child: _isEditing ? _buildEditMode() : _buildViewMode(),
    );
  }

  Widget _buildViewMode() {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.shopping_basket_outlined,
            size: 18, color: AppColors.primary),
      ),
      title: Text(
        widget.item.name,
        style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600),
      ),
      subtitle: Row(
        children: [
          Text(
            'Qty: ${widget.item.quantity}',
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 11),
          ),
          if (widget.item.estimatedPrice != null) ...[
            const Text(' · ',
                style:
                    TextStyle(color: AppColors.textMuted, fontSize: 11)),
            Text(
              '₱${widget.item.estimatedPrice!.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quantity stepper
          _qtyButton(
            icon: Icons.remove,
            onTap: () {
              if (widget.item.quantity > 1) {
                widget.onUpdate(null, widget.item.quantity - 1, null);
              } else {
                widget.onRemove();
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${widget.item.quantity}',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700),
            ),
          ),
          _qtyButton(
            icon: Icons.add,
            onTap: () =>
                widget.onUpdate(null, widget.item.quantity + 1, null),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _isEditing = true),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.bgCardAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_rounded,
                  size: 14, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: widget.onRemove,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 14, color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Item name',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Estimated price (₱)',
                    prefixText: '₱ ',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveEdit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Save'),
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: () => setState(() => _isEditing = false),
                child: const Text('Cancel',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.bgCardAlt,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Icon(icon, size: 14, color: AppColors.textSecondary),
      ),
    );
  }
}
