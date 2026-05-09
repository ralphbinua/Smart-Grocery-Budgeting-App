import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/ai_recommendations_screen.dart';
import 'screens/profile_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.bgCard,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(
    ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: const SmartGroceryApp(),
    ),
  );
}

class SmartGroceryApp extends StatelessWidget {
  const SmartGroceryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartCart – IoT Grocery Budget',
      theme: AppTheme.dark,
      home: const _RootNavigation(),
    );
  }
}

class _RootNavigation extends StatefulWidget {
  const _RootNavigation();

  @override
  State<_RootNavigation> createState() => _RootNavigationState();
}

class _RootNavigationState extends State<_RootNavigation> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final AnimationController _notifController;

  final List<Widget> _screens = const [
    DashboardScreen(),
    AIRecommendationsScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _notifController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _notifController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(cart),
    );
  }

  Widget _buildBottomNav(CartProvider cart) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              _navItem(0, Icons.shopping_cart_rounded, Icons.shopping_cart_outlined, 'Cart', badge: cart.totalItems > 0 ? '${cart.totalItems}' : null),
              _navItem(1, Icons.auto_awesome, Icons.auto_awesome_outlined, 'AI', badge: cart.items.where((i) => i.alternative != null).length > 0
                  ? '${cart.items.where((i) => i.alternative != null).length}'
                  : null),
              _navItem(2, Icons.history_rounded, Icons.history_rounded, 'History'),
              _navItem(3, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData selectedIcon, IconData unselectedIcon, String label, {String? badge}) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.textMuted;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      isSelected ? selectedIcon : unselectedIcon,
                      key: ValueKey(isSelected),
                      color: color,
                      size: 24,
                    ),
                  ),
                  if (badge != null)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: AppColors.primaryGradient),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(badge, style: const TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.w800)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
