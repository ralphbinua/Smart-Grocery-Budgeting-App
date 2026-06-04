import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/budget_ring.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/category_chip.dart';
import '../widgets/grocery_item_input_tile.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final FocusNode _itemFocus = FocusNode();
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _itemController.dispose();
    _priceController.dispose();
    _itemFocus.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _addItem(CartProvider cart) {
    final name = _itemController.text.trim();
    if (name.isEmpty) return;
    final price = double.tryParse(_priceController.text.trim());
    cart.addGroceryItem(name, estimatedPrice: price);
    _itemController.clear();
    _priceController.clear();
    _itemFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, cart),
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
                  _buildInputSection(cart),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // ── Grocery Input List ─────────────────────────────────────
          if (cart.groceryList.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    const Text(
                      'My Grocery List',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${cart.groceryList.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.info,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _showClearListConfirm(context, cart),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Clear all',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GroceryItemInputTile(
                    item: cart.groceryList[index],
                    onRemove: () =>
                        cart.removeGroceryItem(cart.groceryList[index].id),
                    onUpdate: (name, qty, price) => cart.updateGroceryItem(
                      cart.groceryList[index].id,
                      name: name,
                      quantity: qty,
                      estimatedPrice: price,
                    ),
                  ),
                ),
                childCount: cart.groceryList.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
          ],

          // ── Analyzed Cart Items ────────────────────────────────────
          if (cart.hasAnalyzedItems) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    const Text(
                      'Analyzed Items',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (cart.items.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${cart.items.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    if (cart.items.isNotEmpty)
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: cart.spendingByCategory.keys
                                .take(3)
                                .map(
                                  (cat) => Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: CategoryChip(label: cat),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    if (cart.items.isNotEmpty)
                      IconButton(
                        onPressed: () => _showCheckoutConfirm(context),
                        icon: const Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        tooltip: 'Checkout',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CartItemTile(item: cart.items[index]),
                ),
                childCount: cart.items.length,
              ),
            ),
          ],

          // ── Empty State ────────────────────────────────────────────
          if (cart.groceryList.isEmpty && !cart.hasAnalyzedItems)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: _buildFAB(cart),
    );
  }

  // ─── App Bar ────────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context, CartProvider cart) {
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
            child: const Icon(
              Icons.shopping_cart_rounded,
              size: 20,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SmartCart',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                cart.hasAnalyzedItems
                    ? '${cart.totalItems} items · ₱${cart.totalSpent.toStringAsFixed(0)} spent'
                    : '${cart.groceryList.length} item${cart.groceryList.length == 1 ? '' : 's'} in list',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _showBudgetDialog(context),
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: const Icon(
              Icons.tune_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          tooltip: 'Set Budget',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ─── Budget Card ─────────────────────────────────────────────────────────────
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
              ? AppColors.danger.withValues(alpha: 0.4)
              : cart.isNearLimit
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.primary.withValues(alpha: 0.3),
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
                        cart.isOverBudget
                            ? 'OVER BUDGET'
                            : cart.isNearLimit
                            ? 'NEAR LIMIT'
                            : 'REMAINING BALANCE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: cart.isOverBudget
                              ? AppColors.danger
                              : cart.isNearLimit
                              ? AppColors.warning
                              : AppColors.primary,
                        ),
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
                      color: cart.isOverBudget
                          ? AppColors.danger
                          : cart.isNearLimit
                          ? AppColors.warning
                          : AppColors.textPrimary,
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
                        cart.isOverBudget
                            ? AppColors.danger
                            : cart.isNearLimit
                            ? AppColors.warning
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Threshold markers
                Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          const SizedBox(height: 16),
                          _thresholdMarker('50%', 0.5, cart.progressPercent),
                          _thresholdMarker('80%', 0.8, cart.progressPercent),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _infoChip(
                        'Limit',
                        '₱${cart.budgetLimit.toStringAsFixed(0)}',
                        AppColors.textSecondary,
                        CrossAxisAlignment.start,
                      ),
                    ),
                    Expanded(
                      child: _infoChip(
                        'Spent',
                        '₱${cart.totalSpent.toStringAsFixed(2)}',
                        AppColors.info,
                        CrossAxisAlignment.center,
                      ),
                    ),
                    Expanded(
                      child: _infoChip(
                        'Saved',
                        '₱${cart.totalSavedByAI.toStringAsFixed(2)}',
                        AppColors.success,
                        CrossAxisAlignment.end,
                      ),
                    ),
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

  Widget _thresholdMarker(String label, double threshold, double current) {
    final passed = current >= threshold;
    return Positioned(
      left: threshold * (MediaQuery.of(context).size.width - 160),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: passed ? AppColors.warning : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _infoChip(
    String label,
    String value,
    Color color,
    CrossAxisAlignment alignment,
  ) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Stats Row ───────────────────────────────────────────────────────────────
  Widget _buildStatsRow(CartProvider cart) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.shopping_bag_rounded,
            label: 'Items',
            value: '${cart.totalItems}',
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            icon: Icons.savings_rounded,
            label: 'AI Saved',
            value: '₱${cart.totalSavedByAI.toStringAsFixed(0)}',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            icon: Icons.local_offer_rounded,
            label: 'Deals',
            value: '${cart.couponCount}',
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  // ─── Input Section ───────────────────────────────────────────────────────────
  Widget _buildInputSection(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _itemController,
                  focusNode: _itemFocus,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Item name (e.g. Nestle Milk)',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.shopping_basket_outlined,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    filled: true,
                    fillColor: AppColors.bgCardAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _addItem(cart),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _priceController,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: '₱ Price',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    filled: true,
                    fillColor: AppColors.bgCardAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _addItem(cart),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _addItem(cart),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.primaryGradient,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Quick-add chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  size: 12,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                ...[
                  'Rice 5kg',
                  'Eggs (12)',
                  'Cooking Oil',
                  'Chicken',
                  'Milk',
                  'Bread',
                  'Shampoo',
                  'Detergent',
                ].map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: GestureDetector(
                      onTap: () => cart.addGroceryItem(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgCardAlt,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty State ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Layered icon
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.format_list_bulleted_add,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              'Your grocery list is empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add items above and let AI find\ncheaper alternatives for you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildFeatureChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChips() {
    final features = [
      (Icons.swap_horiz_rounded, AppColors.success, 'Cheaper Alternatives'),
      (Icons.verified_rounded, AppColors.info, 'Quality Verified'),
      (Icons.local_offer_rounded, AppColors.warning, 'Coupons & Deals'),
      (Icons.calculate_rounded, AppColors.primary, 'Live Budget'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: features.map((f) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: f.$2.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: f.$2.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(f.$1, size: 13, color: f.$2),
              const SizedBox(width: 6),
              Text(
                f.$3,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: f.$2,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── FAB ─────────────────────────────────────────────────────────────────────
  Widget _buildFAB(CartProvider cart) {
    if (cart.isAnalyzing) {
      return ScaleTransition(
        scale: _pulseAnimation,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.purpleGradient),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Analyzing...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!cart.hasGroceryItems) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: () => cart.analyzeList(),
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      label: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.primaryGradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.black, size: 20),
            SizedBox(width: 8),
            Text(
              'Analyze List',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────────
  void _showBudgetDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            SizedBox(width: 10),
            Text(
              'Set Budget',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your shopping budget for this trip.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                hintText: '0.00',
                prefixText: '₱ ',
                prefixStyle: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final budget = double.tryParse(controller.text) ?? 0;
              if (budget > 0) {
                Provider.of<CartProvider>(
                  context,
                  listen: false,
                ).setBudget(budget);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Budget set to ₱${budget.toStringAsFixed(2)}',
                    ),
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

  void _showClearListConfirm(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Clear Grocery List',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'This will remove all items from your grocery list.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              cart.clearGroceryList();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showCheckoutConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            SizedBox(width: 10),
            Text(
              'Checkout & Save',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: const Text(
          'This will save your current cart to purchase history and start a new session. Continue?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<CartProvider>(context, listen: false).clearCart();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cart saved to purchase history!'),
                ),
              );
            },
            child: const Text('Checkout'),
          ),
        ],
      ),
    );
  }
}
