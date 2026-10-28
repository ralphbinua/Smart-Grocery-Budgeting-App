import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ProductPriceEntryDialog extends StatefulWidget {
  final String name;
  final String? brand;
  final String? quantity;

  const ProductPriceEntryDialog({
    super.key,
    required this.name,
    this.brand,
    this.quantity,
  });

  @override
  State<ProductPriceEntryDialog> createState() =>
      _ProductPriceEntryDialogState();
}

class _ProductPriceEntryDialogState extends State<ProductPriceEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _priceFocusNode = FocusNode();

  @override
  void dispose() {
    _priceController.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  void _cancel() {
    _priceFocusNode.unfocus();
    Navigator.of(context).pop();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final price = double.parse(_priceController.text.trim());
    _priceFocusNode.unfocus();
    Navigator.of(context).pop(price);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgCard,
      title: const Text(
        'Enter product price',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [
                widget.name,
                if (widget.brand?.isNotEmpty ?? false) widget.brand!,
                if (widget.quantity?.isNotEmpty ?? false) widget.quantity!,
              ].join(' · '),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              focusNode: _priceFocusNode,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Price at the store',
                prefixText: '₱ ',
              ),
              validator: (value) {
                final price = double.tryParse(value?.trim() ?? '');
                if (price == null || price <= 0) {
                  return 'Enter a price greater than zero.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _cancel, child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Add to list')),
      ],
    );
  }
}
