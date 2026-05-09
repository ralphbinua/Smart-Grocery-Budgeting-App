import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _aiSuggestionsEnabled = true;
  bool _iotAutoConnect = true;
  double _monthlyBudget = 5000.0;
  final String _userName = 'Juan Dela Cruz';
  final String _userEmail = 'juan.delacruz@smartcart.ph';

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

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
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 20),
                  _buildMonthlyStats(cart),
                  const SizedBox(height: 20),
                  _buildBudgetSection(context, cart),
                  const SizedBox(height: 20),
                  _buildPreferencesSection(),
                  const SizedBox(height: 20),
                  _buildIoTSection(),
                  const SizedBox(height: 20),
                  _buildAboutSection(),
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
          Icon(Icons.person_rounded, color: AppColors.primary, size: 22),
          SizedBox(width: 10),
          Text('Profile & Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2419), Color(0xFF0D1F35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.primaryGradient),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20)],
            ),
            child: Center(
              child: Text(
                _userName.split(' ').map((n) => n[0]).take(2).join(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(_userEmail, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, color: AppColors.primary, size: 13),
                      SizedBox(width: 4),
                      Text('Smart Shopper', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyStats(CartProvider cart) {
    final totalHistorySpent = cart.history.fold(0.0, (s, h) => s + h.totalSpent);
    final totalHistorySaved = cart.history.fold(0.0, (s, h) => s + h.totalSaved);

    return Row(
      children: [
        _statBox('Total Spent', '₱${totalHistorySpent.toStringAsFixed(0)}', AppColors.info, Icons.payments_rounded),
        const SizedBox(width: 10),
        _statBox('AI Saved', '₱${totalHistorySaved.toStringAsFixed(0)}', AppColors.success, Icons.savings_rounded),
        const SizedBox(width: 10),
        _statBox('Trips', '${cart.history.length}', AppColors.accentLight, Icons.shopping_bag_rounded),
      ],
    );
  }

  Widget _statBox(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSection(BuildContext context, CartProvider cart) {
    return _sectionCard(
      title: 'Budget Settings',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: AppColors.primary,
      children: [
        _settingRow(
          label: 'Shopping Budget',
          subtitle: 'Current trip limit',
          trailing: GestureDetector(
            onTap: () => _showBudgetEdit(context, cart),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Text(
                cart.budgetLimit > 0 ? '₱${cart.budgetLimit.toStringAsFixed(0)}' : 'Set →',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ),
        const Divider(color: Color(0xFF1E293B), height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Monthly Budget Goal', style: TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                  Text('₱${_monthlyBudget.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              Slider(
                value: _monthlyBudget,
                min: 500,
                max: 20000,
                divisions: 39,
                activeColor: AppColors.primary,
                inactiveColor: const Color(0xFF1E293B),
                onChanged: (v) => setState(() => _monthlyBudget = v),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('₱500', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  const Text('₱20,000', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return _sectionCard(
      title: 'Preferences',
      icon: Icons.settings_rounded,
      iconColor: AppColors.info,
      children: [
        _toggleRow(
          label: 'Budget Notifications',
          subtitle: 'Alert when near limit',
          value: _notificationsEnabled,
          onChanged: (v) => setState(() => _notificationsEnabled = v),
        ),
        const Divider(color: Color(0xFF1E293B), height: 1),
        _toggleRow(
          label: 'AI Suggestions',
          subtitle: 'Show cost alternatives',
          value: _aiSuggestionsEnabled,
          onChanged: (v) => setState(() => _aiSuggestionsEnabled = v),
        ),
      ],
    );
  }

  Widget _buildIoTSection() {
    return _sectionCard(
      title: 'IoT Cart Settings',
      icon: Icons.sensors_rounded,
      iconColor: AppColors.accent,
      children: [
        _toggleRow(
          label: 'Auto-connect IoT Cart',
          subtitle: 'Connect when nearby via Wi-Fi',
          value: _iotAutoConnect,
          onChanged: (v) => setState(() => _iotAutoConnect = v),
        ),
        const Divider(color: Color(0xFF1E293B), height: 1),
        _settingRow(
          label: 'Device Pairing',
          subtitle: 'ESP32 Cart #SG-001',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Paired', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w700)),
          ),
        ),
        const Divider(color: Color(0xFF1E293B), height: 1),
        _settingRow(
          label: 'Scanner Type',
          subtitle: 'Barcode + RFID',
          trailing: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.textMuted, size: 18),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _sectionCard(
      title: 'About',
      icon: Icons.info_rounded,
      iconColor: AppColors.textMuted,
      children: [
        _settingRow(label: 'App Version', subtitle: 'v1.0.0 (Capstone Build)', trailing: const SizedBox()),
        const Divider(color: Color(0xFF1E293B), height: 1),
        _settingRow(label: 'Research Title', subtitle: 'IoT-Enabled Smart Grocery Budgeting', trailing: const SizedBox()),
        const Divider(color: Color(0xFF1E293B), height: 1),
        _settingRow(label: 'School', subtitle: 'Capstone Project 2026', trailing: const SizedBox()),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
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
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _toggleRow({required String label, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: const Color(0xFF1E293B),
          ),
        ],
      ),
    );
  }

  Widget _settingRow({required String label, required String subtitle, required Widget trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  void _showBudgetEdit(BuildContext context, CartProvider cart) {
    final controller = TextEditingController(text: cart.budgetLimit > 0 ? cart.budgetLimit.toStringAsFixed(0) : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Set Shopping Budget', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: TextField(
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
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text) ?? 0;
              if (v > 0) {
                cart.setBudget(v);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
