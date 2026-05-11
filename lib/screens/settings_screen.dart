import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _aiSuggestionsEnabled = true;
  bool _iotAutoConnect = true;
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
                  _buildIoTSection(cart),
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
              color: AppColors.primary.withOpacity(0.15),
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

  Widget _buildIoTSection(CartProvider cart) {
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
        _actionRow(
          label: 'Scanner Type',
          icon: cart.scannerType == 'phone' ? Icons.camera_alt_rounded : Icons.qr_code_scanner_rounded,
          iconColor: AppColors.textMuted,
          onTap: () => _showScannerTypePicker(context, cart),
          trailing: Text(
            cart.scannerType == 'phone' ? 'Phone Camera' : cart.scannerType == 'iot' ? 'IoT Scanner' : 'Not Set',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
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

  void _showScannerTypePicker(BuildContext context, CartProvider cart) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Default Scanner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            _pickerOption(
              context,
              'Phone Camera',
              Icons.camera_alt_rounded,
              'Use your device camera',
              cart.scannerType == 'phone',
              () => cart.setScannerType('phone'),
            ),
            const SizedBox(height: 12),
            _pickerOption(
              context,
              'IoT Scanner',
              Icons.memory_rounded,
              'Use the scanner on your Smart Cart',
              cart.scannerType == 'iot',
              () => cart.setScannerType('iot'),
            ),
            const SizedBox(height: 12),
            _pickerOption(
              context,
              'Always Ask',
              Icons.question_mark_rounded,
              'Choose every time you scan',
              cart.scannerType == null,
              () => cart.setScannerType(null),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _pickerOption(BuildContext context, String title, IconData icon, String subtitle, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        onTap();
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary.withOpacity(0.3) : const Color(0xFF1E293B)),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: AppColors.textPrimary, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ],
        ),
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
