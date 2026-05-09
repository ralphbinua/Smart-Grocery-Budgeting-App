import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';

class AIRecommendationsScreen extends StatelessWidget {
  const AIRecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final itemsWithAlt = cart.items.where((i) => i.alternative != null).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAIHeader(itemsWithAlt.length, cart.totalSavedByAI),
                  const SizedBox(height: 20),
                  _buildTipsCard(),
                  const SizedBox(height: 20),
                  const Text('Smart Swap Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  const Text('Based on your cart — cheaper alternatives available', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          if (itemsWithAlt.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildSwapCard(context, itemsWithAlt[index]),
                childCount: itemsWithAlt.length,
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildAlgorithmCard(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
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
          Text('AI Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildAIHeader(int count, double saved) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1040), Color(0xFF0D1A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.purpleGradient),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 20)],
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Cost Engine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('$count product swap${count == 1 ? '' : 's'} found', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.trending_down_rounded, color: AppColors.success, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('Potential savings: ₱${saved.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    final tips = [
      ('🥛', 'Store brands are 20–40% cheaper for dairy products.'),
      ('🛒', 'Bulk items reduce cost per unit significantly.'),
      ('📊', 'Buying alternatives saves avg. ₱15 per item.'),
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
              Icon(Icons.lightbulb_rounded, color: AppColors.warning, size: 18),
              SizedBox(width: 8),
              Text('Smart Shopping Tips', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip.$1, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(child: Text(tip.$2, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSwapCard(BuildContext context, item) {
    final altName = item.alternative!['name'] as String;
    final altPrice = (item.alternative!['price'] as num).toDouble();
    final savings = item.price - altPrice;
    final pctOff = ((savings / item.price) * 100).toStringAsFixed(0);

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
            // Current item
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.danger, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, decoration: TextDecoration.lineThrough)),
                      Text(item.category, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Text('₱${item.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary, decoration: TextDecoration.lineThrough)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Row(
                children: [
                  Container(width: 30, height: 1, color: const Color(0xFF1E293B)),
                  const SizedBox(width: 8),
                  const Icon(Icons.swap_vert_rounded, color: AppColors.accent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Container(height: 1, color: const Color(0xFF1E293B))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: AppColors.purpleGradient),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('AI SWAP', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ),
                ],
              ),
            ),
            // Alternative item
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(altName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const Text('Recommended alternative', style: TextStyle(fontSize: 11, color: AppColors.success)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₱${altPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.success)),
                    Text('$pctOff% off', style: const TextStyle(fontSize: 11, color: AppColors.success)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.success.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.savings_rounded, color: AppColors.success, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Save ₱${savings.toStringAsFixed(2)} per item', style: const TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Provider.of<CartProvider>(context, listen: false).acceptSwap(item.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Swapped to $altName!')),
                    );
                  },
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text('Swap'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlgorithmCard() {
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
              Icon(Icons.memory_rounded, color: AppColors.accent, size: 18),
              SizedBox(width: 8),
              Text('How the AI Engine Works', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          _algoStep('1', 'Barcode is scanned by IoT device', AppColors.info),
          _algoStep('2', 'Product data fetched from cloud database', AppColors.accent),
          _algoStep('3', 'AI analyzes category, brand & historical pricing', AppColors.warning),
          _algoStep('4', 'Cheaper alternatives matched in same category', AppColors.success),
          _algoStep('5', 'Recommendation displayed in real-time', AppColors.primary),
        ],
      ),
    );
  }

  Widget _algoStep(String num, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Center(child: Text(num, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
            child: const Icon(Icons.auto_awesome, size: 56, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          const Text('No recommendations yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Scan items to receive AI-powered\ncost optimization suggestions.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
