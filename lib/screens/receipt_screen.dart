import 'package:flutter/material.dart';
import '../models/purchase_history.dart';
import '../theme/app_theme.dart';

class ReceiptScreen extends StatelessWidget {
  final PurchaseHistory history;
  const ReceiptScreen({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Receipt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing receipt...')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildReceiptHeader(),
            const SizedBox(height: 16),
            _buildReceiptBody(context),
            const SizedBox(height: 16),
            _buildReceiptFooter(context),
            const SizedBox(height: 24),
            _buildPrintButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptHeader() {
    final pct = history.budgetUsedPercent;
    final color = pct > 100 ? AppColors.danger : pct > 85 ? AppColors.warning : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2419), Color(0xFF091A11)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.primaryGradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shopping_cart_rounded, color: Colors.black, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SmartCart Receipt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  Text(history.storeName, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('PAID', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFF1E293B)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _receiptInfoItem('Date', history.date, alignment: CrossAxisAlignment.start)),
              Expanded(child: _receiptInfoItem('Items', '${history.items.length}')),
              Expanded(child: _receiptInfoItem('Budget', '₱${history.budgetLimit.toStringAsFixed(0)}')),
              Expanded(child: _receiptInfoItem('Used', '${pct.toStringAsFixed(0)}%', color: color, alignment: CrossAxisAlignment.end)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _receiptInfoItem(String label, String value, {Color? color, CrossAxisAlignment alignment = CrossAxisAlignment.center}) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color ?? AppColors.textPrimary)),
        ),
      ],
    );
  }

  Widget _buildReceiptBody(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: const [
                Expanded(flex: 4, child: Text('Item', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
                Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('Price', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600), textAlign: TextAlign.end)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1E293B)),
          ...history.items.map((item) => _buildItemRow(item)),
        ],
      ),
    );
  }

  Widget _buildItemRow(HistoryItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1E293B)))),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(item.category, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.bgCardAlt,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('x${item.quantity}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('₱${item.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary), textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        children: [
          _footerRow('Subtotal', '₱${history.totalSpent.toStringAsFixed(2)}', AppColors.textSecondary),
          const SizedBox(height: 10),
          _footerRow('AI Savings', '- ₱${history.totalSaved.toStringAsFixed(2)}', AppColors.success),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF1E293B)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Spent', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text('₱${history.totalSpent.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.success.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.success, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You saved ₱${history.totalSaved.toStringAsFixed(2)} with AI cost optimization on this trip!',
                    style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildPrintButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Generating digital receipt PDF...')),
          );
        },
        icon: const Icon(Icons.print_rounded, size: 18),
        label: const Text('Generate Digital Receipt'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
