import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/cart_item.dart';
import '../theme/app_theme.dart';
import '../widgets/deal_card.dart';

class AIRecommendationsScreen extends StatefulWidget {
  const AIRecommendationsScreen({super.key});

  @override
  State<AIRecommendationsScreen> createState() => _AIRecommendationsScreenState();
}

class _AIRecommendationsScreenState extends State<AIRecommendationsScreen> {
  static const _baseUrl = 'https://smart-grocery-budgeting-app.onrender.com';
  List<Map<String, dynamic>> _dbPromos = [];
  bool _promosLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDbPromos();
  }

  Future<void> _fetchDbPromos() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/products/promos'));
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        if (mounted) {
          setState(() {
            _dbPromos = data.cast<Map<String, dynamic>>();
            _promosLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _promosLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _promosLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final itemsWithAlt = cart.items.where((i) => i.alternative != null).toList();
    final itemsWithDeals = cart.items.where((i) => i.coupons.isNotEmpty).toList();
    final totalSavings = _calcPotentialSavings(itemsWithAlt);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAIHeader(itemsWithAlt.length, itemsWithDeals.length, totalSavings),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Store Promos Section (always shown, DB-backed) ─────────
          SliverToBoxAdapter(child: _buildStorePromosSection()),

          // ── Empty State ────────────────────────────────────────────
          if (itemsWithAlt.isEmpty && itemsWithDeals.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _buildEmptyState(),
                    const SizedBox(height: 40),
                    _buildTipsCard(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            )
          else ...[
            // ── Cheaper Alternatives Section ───────────────────────
            if (itemsWithAlt.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.swap_horiz_rounded,
                              color: AppColors.success, size: 18),
                          SizedBox(width: 8),
                          Text('Cheaper Alternatives',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                          'AI-recommended products with equal or better quality',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _buildSwapCard(ctx, itemsWithAlt[i]),
                  childCount: itemsWithAlt.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],

            // ── Deals & Coupons Section ────────────────────────────
            if (itemsWithDeals.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Icon(Icons.local_offer_rounded,
                          color: AppColors.warning, size: 18),
                      SizedBox(width: 8),
                      Text('Active Deals & Coupons',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) =>
                      _buildDealsSection(ctx, itemsWithDeals[i]),
                  childCount: itemsWithDeals.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],

            // ── Tips ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTipsCard(),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
  // ─── Store Promos (DB-backed) ────────────────────────────────────────────────
  Widget _buildStorePromosSection() {
    if (_promosLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          height: 130,
          child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
        ),
      );
    }
    if (_dbPromos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_fire_department_rounded, color: Colors.black, size: 14),
                ),
                const SizedBox(width: 8),
                const Text('Store Promos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${_dbPromos.length} deals',
                      style: const TextStyle(fontSize: 10, color: Color(0xFFFFD700), fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() => _promosLoading = true);
                    _fetchDbPromos();
                  },
                  child: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 18),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 138,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16),
              itemCount: _dbPromos.length,
              itemBuilder: (ctx, i) => _buildPromoCard(_dbPromos[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(Map<String, dynamic> promo) {
    final name = (promo['name'] as String? ?? 'Product').split(' ').take(4).join(' ');
    final label = promo['promoLabel'] as String? ?? 'On Sale';
    final store = promo['promoStore'] as String? ?? '';
    final discount = (promo['promoDiscount'] as num?)?.toInt() ?? 0;
    final price = (promo['latestPrice'] as num?)?.toDouble() ?? 0.0;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1204), Color(0xFF0F1A10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (discount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF6B00)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$discount% OFF',
                      style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.w800)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('PROMO',
                      style: TextStyle(fontSize: 10, color: Color(0xFFFFD700), fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Color(0xFFFFD700), fontStyle: FontStyle.italic),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₱${price.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              if (store.isNotEmpty)
                Flexible(
                  child: Text(store.split(' ').first,
                      style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis),
                ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      snap: true,
      backgroundColor: AppColors.bg,
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: AppColors.accent, size: 22),
          SizedBox(width: 10),
          Text('Smart Deals',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  // ─── Summary Header ──────────────────────────────────────────────────────────
  Widget _buildAIHeader(int altCount, int dealCount, double potentialSavings) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1040), Color(0xFF0D1A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(colors: AppColors.purpleGradient),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    blurRadius: 20)
              ],
            ),
            child: const Icon(Icons.psychology_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Recommendation Engine',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  '$altCount swap${altCount == 1 ? '' : 's'} · $dealCount deal${dealCount == 1 ? '' : 's'} found',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                if (potentialSavings > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.trending_down_rounded,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Potential savings: ₱${potentialSavings.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.success,
                              fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Swap Card ──────────────────────────────────────────────────────────────
  Widget _buildSwapCard(BuildContext context, CartItem item) {
    final altName = item.alternative!['name'] as String;
    final altPrice =
        (item.alternative!['price'] as num).toDouble();
    final savings = item.price - altPrice;
    final pctOff =
        ((savings / item.price) * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Column(
          children: [
            // Original item
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove,
                      color: AppColors.danger, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.lineThrough),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(item.category,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Text('₱${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
              ],
            ),

            // Divider with AI SWAP badge
            Stack(
              alignment: Alignment.centerRight,
              children: [
                const Divider(color: Color(0xFF1E293B), height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: AppColors.purpleGradient),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('AI SWAP',
                      style: TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
                ),
              ],
            ),

            // Alternative item
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      color: AppColors.success, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(altName,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      if (item.note != null && item.note!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.verified_rounded,
                                size: 12, color: AppColors.info),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(item.note!,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.info,
                                      fontStyle: FontStyle.italic),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₱${altPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('$pctOff% off',
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.success,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Action Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.savings_rounded,
                            color: AppColors.success, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                              'Save ₱${savings.toStringAsFixed(2)} × ${item.quantity}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Provider.of<CartProvider>(context, listen: false)
                        .acceptSwap(item.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('✓ Swapped to $altName'),
                          backgroundColor: AppColors.success),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('Swap',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Deals Section ──────────────────────────────────────────────────────────
  Widget _buildDealsSection(BuildContext context, CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(item.name,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
          ),
          ...item.coupons.map(
            (deal) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: DealCard(dealText: deal, itemName: item.name),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tips Card ──────────────────────────────────────────────────────────────
  Widget _buildTipsCard() {
    final tips = [
      ('🥛', 'Store brands are 20–40% cheaper with similar nutritional value.'),
      ('🛒', 'Buying in bulk reduces cost per unit for pantry staples.'),
      ('📊', 'Accepting AI alternatives saves avg. ₱15–₱40 per item.'),
      ('🏷️',
          'Check SM, Robinsons, and Puregold weekly promos for better deals.'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_rounded,
                  color: AppColors.warning, size: 18),
              SizedBox(width: 8),
              Text('Smart Shopping Tips',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tip.$1,
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(tip.$2,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ─── Empty State ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: Color(0xFF161F2E),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome,
                size: 56, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          const Text('No recommendations yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text(
            'Add your grocery list and tap\n"Analyze List" to get AI-powered deals.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  double _calcPotentialSavings(List<CartItem> itemsWithAlt) {
    double total = 0;
    for (final item in itemsWithAlt) {
      if (item.alternative != null) {
        final altPrice =
            (item.alternative!['price'] as num).toDouble();
        final diff = item.price - altPrice;
        if (diff > 0) total += diff * item.quantity;
      }
    }
    return total;
  }
}
