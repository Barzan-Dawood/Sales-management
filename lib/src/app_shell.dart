import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/auth/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/products/products_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/suppliers_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/accounting_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/categories_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    final pages = <Widget>[
      const DashboardScreen(),
      const SalesScreen(),
      const ProductsScreen(),
      const CategoriesScreen(),
      const InventoryScreen(),
      const CustomersScreen(),
      const SuppliersScreen(),
      const AccountingScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام نقاط البيع - إدارة المحل'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(auth.currentUser?['name']?.toString() ?? ''),
            ),
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Row(
        children: [
          // Enhanced Sidebar with better design
          Container(
            width: 240,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade100,
                  Colors.blue.shade200,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade600,
                        Colors.blue.shade700,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.store,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'القائمة الرئيسية',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'اختر القسم المطلوب',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Navigation items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      _buildNavItem(
                        icon: Icons.space_dashboard,
                        label: 'لوحة التحكم',
                        index: 0,
                        isSelected: _selectedIndex == 0,
                      ),
                      _buildNavItem(
                        icon: Icons.point_of_sale,
                        label: 'المبيعات',
                        index: 1,
                        isSelected: _selectedIndex == 1,
                      ),
                      _buildNavItem(
                        icon: Icons.inventory_2,
                        label: 'المنتجات',
                        index: 2,
                        isSelected: _selectedIndex == 2,
                      ),
                      _buildNavItem(
                        icon: Icons.category,
                        label: 'الأقسام',
                        index: 3,
                        isSelected: _selectedIndex == 3,
                      ),
                      _buildNavItem(
                        icon: Icons.warehouse,
                        label: 'المخزون',
                        index: 4,
                        isSelected: _selectedIndex == 4,
                      ),
                      _buildNavItem(
                        icon: Icons.people_alt,
                        label: 'العملاء',
                        index: 5,
                        isSelected: _selectedIndex == 5,
                      ),
                      _buildNavItem(
                        icon: Icons.local_shipping,
                        label: 'الموردون',
                        index: 6,
                        isSelected: _selectedIndex == 6,
                      ),
                      _buildNavItem(
                        icon: Icons.account_balance,
                        label: 'الحسابات',
                        index: 7,
                        isSelected: _selectedIndex == 7,
                      ),
                      _buildNavItem(
                        icon: Icons.bar_chart,
                        label: 'التقارير',
                        index: 8,
                        isSelected: _selectedIndex == 8,
                      ),
                      _buildNavItem(
                        icon: Icons.settings,
                        label: 'الإعدادات',
                        index: 9,
                        isSelected: _selectedIndex == 9,
                      ),
                    ],
                  ),
                ),

                // Footer section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.currentUser?['name']?.toString() ??
                                  'المستخدم',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'مستخدم نشط',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const VerticalDivider(width: 1),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: pages[_selectedIndex],
            ),
          ),
        ],
      ),
      bottomNavigationBar: null,
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedIndex = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.9)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: Colors.blue.shade400,
                      width: 2,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.shade100
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? Colors.blue.shade700
                        : Colors.blue.shade800,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.blue.shade800
                          : Colors.blue.shade900,
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
