import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _aiSuggestionsEnabled = true;
  double _monthlyBudget = 5000.0;
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
                  _buildSessionSection(),
                  const SizedBox(height: 20),
                  _buildBudgetSection(context, cart),
                  const SizedBox(height: 20),
                  _buildPreferencesSection(),
                  const SizedBox(height: 20),
                  _buildAISection(),
                  const SizedBox(height: 20),
                  _buildAboutSection(),
                  const SizedBox(height: 20),
                  _buildAdminSection(context),
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
          Icon(Icons.settings_rounded, color: AppColors.primary, size: 22),
          SizedBox(width: 10),
          Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildSessionSection() {
    return _sectionCard(
      title: 'Session',
      icon: Icons.account_circle_rounded,
      iconColor: AppColors.primary,
      children: [
        _settingRow(
          label: 'Guest Mode',
          subtitle: 'Data is saved locally on device',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, color: AppColors.primary, size: 13),
                SizedBox(width: 4),
                Text('Local', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
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
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
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
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('₱500', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  Text('₱20,000', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
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
      icon: Icons.tune_rounded,
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

  Widget _buildAISection() {
    return _sectionCard(
      title: 'AI & Recommendations',
      icon: Icons.auto_awesome,
      iconColor: AppColors.accent,
      children: [
        _toggleRow(
          label: 'AI Suggestions',
          subtitle: 'Show cheaper product alternatives',
          value: _aiSuggestionsEnabled,
          onChanged: (v) => setState(() => _aiSuggestionsEnabled = v),
        ),
        const Divider(color: Color(0xFF1E293B), height: 1),
        _settingRow(
          label: 'AI Engine',
          subtitle: 'Groq LLaMA 3.1 (Fast & Free)',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Active', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w700)),
          ),
        ),
        const Divider(color: Color(0xFF1E293B), height: 1),
        _settingRow(
          label: 'Budget Alerts',
          subtitle: 'Notified at 50%, 80%, and 100%',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('3 tiers', style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w700)),
          ),
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
        _settingRow(label: 'Research Title', subtitle: 'AI-Powered Smart Grocery Budgeting System', trailing: const SizedBox()),
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
            activeThumbColor: AppColors.primary,
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

  Widget _actionRow({required String label, required IconData icon, Color? iconColor, Color? textColor, Widget? trailing, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 14, color: textColor ?? AppColors.textPrimary, fontWeight: FontWeight.w500)),
            ),
            trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  // Scanner type picker removed — no longer needed in the new AI-input flow.



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

  Widget _buildAdminSection(BuildContext context) {
    return _sectionCard(
      title: 'Developer',
      icon: Icons.developer_mode_rounded,
      iconColor: AppColors.warning,
      children: [
        _actionRow(
          label: 'Admin Dashboard',
          icon: Icons.admin_panel_settings_rounded,
          iconColor: AppColors.textSecondary,
          onTap: () => _showAdminLogin(context),
        ),
      ],
    );
  }

  void _showAdminLogin(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Admin Login', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Password',
            labelStyle: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              if (controller.text == 'admin123') { // Simple hardcoded password for now
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
              } else {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid password')));
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}
