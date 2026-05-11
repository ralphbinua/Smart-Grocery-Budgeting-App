import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/budget_ring.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/category_chip.dart';
import '../widgets/scan_animation.dart';
import '../widgets/stat_card.dart';
import 'camera_scan_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, cart),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildBudgetCard(context, cart),
                  const SizedBox(height: 20),
                  _buildStatsRow(cart),
                  const SizedBox(height: 20),
                  _buildIoTStatusBar(context, cart),
                  const SizedBox(height: 20),
                  _buildCartHeader(context, cart),
                ],
              ),
            ),
          ),
          if (cart.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyCart(),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CartItemTile(item: cart.items[index]),
                ),
                childCount: cart.items.length,
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(height: cart.items.isNotEmpty ? 100 : 0),
          ),
        ],
      ),
      floatingActionButton: _buildScanFAB(context, cart),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, CartProvider cart) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      snap: true,
      pinned: false,
      backgroundColor: AppColors.bg,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.primaryGradient),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shopping_cart_rounded, size: 20, color: Colors.black),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SmartCart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text('${cart.totalItems} items in cart', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
      actions: [
        if (cart.items.isNotEmpty)
          IconButton(
            onPressed: () => _showClearConfirm(context),
            icon: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
            tooltip: 'Checkout',
          ),
        IconButton(
          onPressed: () => _showBudgetDialog(context),
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: const Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
          ),
          tooltip: 'Set Budget',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBudgetCard(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: cart.isOverBudget
              ? [const Color(0xFF2D1515), const Color(0xFF1A0A0A)]
              : cart.isNearLimit
                  ? [const Color(0xFF2D2500), const Color(0xFF1A1600)]
                  : [const Color(0xFF0D2419), const Color(0xFF091A11)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cart.isOverBudget
              ? AppColors.danger.withOpacity(0.4)
              : cart.isNearLimit
                  ? AppColors.warning.withOpacity(0.4)
                  : AppColors.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      cart.isOverBudget
                          ? Icons.warning_rounded
                          : cart.isNearLimit
                              ? Icons.notifications_active_rounded
                              : Icons.account_balance_wallet_rounded,
                      size: 16,
                      color: cart.isOverBudget
                          ? AppColors.danger
                          : cart.isNearLimit
                              ? AppColors.warning
                              : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cart.isOverBudget ? 'OVER BUDGET' : cart.isNearLimit ? 'NEAR LIMIT' : 'REMAINING BALANCE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: cart.isOverBudget ? AppColors.danger : cart.isNearLimit ? AppColors.warning : AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: cart.remaining),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  builder: (context, value, _) => Text(
                    '₱${value.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: cart.isOverBudget ? AppColors.danger : cart.isNearLimit ? AppColors.warning : AppColors.textPrimary,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: cart.progressPercent),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: const Color(0xFF1E293B),
                      valueColor: AlwaysStoppedAnimation(
                        cart.isOverBudget ? AppColors.danger : cart.isNearLimit ? AppColors.warning : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _infoChip('Limit', '₱${cart.budgetLimit.toStringAsFixed(0)}', AppColors.textSecondary, CrossAxisAlignment.start)),
                    Expanded(child: _infoChip('Spent', '₱${cart.totalSpent.toStringAsFixed(2)}', AppColors.info, CrossAxisAlignment.center)),
                    Expanded(child: _infoChip('Saved', '₱${cart.totalSavedByAI.toStringAsFixed(2)}', AppColors.success, CrossAxisAlignment.end)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          BudgetRing(
            progress: cart.progressPercent,
            isOver: cart.isOverBudget,
            isNear: cart.isNearLimit,
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value, Color color, CrossAxisAlignment alignment) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildStatsRow(CartProvider cart) {
    return Row(
      children: [
        Expanded(child: StatCard(icon: Icons.shopping_bag_rounded, label: 'Items', value: '${cart.totalItems}', color: AppColors.info)),
        const SizedBox(width: 10),
        Expanded(child: StatCard(icon: Icons.savings_rounded, label: 'AI Saved', value: '₱${cart.totalSavedByAI.toStringAsFixed(0)}', color: AppColors.success)),
        const SizedBox(width: 10),
        Expanded(child: StatCard(icon: Icons.pie_chart_rounded, label: 'Used', value: '${(cart.progressPercent * 100).toStringAsFixed(0)}%', color: AppColors.warning)),
      ],
    );
  }

  Widget _buildIoTStatusBar(BuildContext context, CartProvider cart) {
    return GestureDetector(
      onTap: () {
        Provider.of<CartProvider>(context, listen: false).setIoTConnected(!cart.isConnected);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cart.isConnected ? const Color(0xFF0D2419) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cart.isConnected ? AppColors.primary.withOpacity(0.4) : const Color(0xFF1E293B),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: cart.isConnected ? AppColors.primary : AppColors.textMuted,
                shape: BoxShape.circle,
                boxShadow: cart.isConnected
                    ? [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 6)]
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.wifi_rounded, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                cart.isConnected ? 'IoT Cart Connected • ESP32 Active' : 'IoT Cart Disconnected — Tap to connect',
                style: TextStyle(
                  fontSize: 12,
                  color: cart.isConnected ? AppColors.primary : AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              cart.isConnected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              size: 16,
              color: cart.isConnected ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartHeader(BuildContext context, CartProvider cart) {
    return Row(
      children: [
        const Text('Live Cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(width: 8),
        if (cart.items.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${cart.items.length}', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        const SizedBox(width: 10),
        if (cart.items.isNotEmpty)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: cart.spendingByCategory.keys
                    .take(3)
                    .map((cat) => Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: CategoryChip(label: cat),
                        ))
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: const Icon(Icons.qr_code_scanner_rounded, size: 56, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          const Text('No items scanned yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Tap the scan button or use your\nIoT cart to start adding items', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          const ScanAnimation(),
        ],
      ),
    );
  }

  Widget _buildScanFAB(BuildContext context, CartProvider cart) {
    return cart.isScanning
        ? Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.primaryGradient),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
              ),
            ),
          )
        : FloatingActionButton.extended(
            onPressed: () => _showScannerChoice(context),
            backgroundColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            label: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.primaryGradient),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: const Row(
                children: [
                  Icon(Icons.qr_code_scanner_rounded, color: Colors.black, size: 20),
                  SizedBox(width: 8),
                  Text('Scan Item', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14)),
                ],
              ),
            ),
          );
  }

  void _showScannerChoice(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose Scanner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            ListTile(
              onTap: () async {
                Navigator.pop(ctx);
                final barcode = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (_) => const CameraScanScreen()),
                );
                if (barcode != null && context.mounted) {
                  Provider.of<CartProvider>(context, listen: false).processBarcode(barcode);
                }
              },
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              ),
              title: const Text('Phone Camera', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: const Text('Use your device camera to scan barcodes', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ),
            const SizedBox(height: 8),
            ListTile(
              onTap: () {
                Navigator.pop(ctx);
                // Simulate an IoT scan triggering
                Provider.of<CartProvider>(context, listen: false).simulateScan();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Waiting for IoT scanner...'), duration: Duration(seconds: 1)),
                );
              },
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.info.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.memory_rounded, color: AppColors.info),
              ),
              title: const Text('IoT Scanner', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: const Text('Use the scanner on your Smart Cart', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _showBudgetDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Text('Set Budget', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your shopping budget for this trip.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                hintText: '0.00',
                prefixText: '₱ ',
                prefixStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 22),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final budget = double.tryParse(controller.text) ?? 0;
              if (budget > 0) {
                Provider.of<CartProvider>(context, listen: false).setBudget(budget);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Budget set to ₱${budget.toStringAsFixed(2)}'),
                    backgroundColor: AppColors.bgCardAlt,
                  ),
                );
              }
            },
            child: const Text('Save Budget'),
          ),
        ],
      ),
    );
  }

  void _showClearConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Text('Checkout & Save', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text('This will save your current cart to purchase history and clear the cart. Continue?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<CartProvider>(context, listen: false).clearCart();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cart saved to purchase history!')),
              );
            },
            child: const Text('Checkout'),
          ),
        ],
      ),
    );
  }
}