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
      const ProductsScreen(),
      const SalesScreen(),
      const CustomersScreen(),
      const SuppliersScreen(),
      const CategoriesScreen(),
      const InventoryScreen(),
      const AccountingScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    final destinations = <NavigationDestination>[
      const NavigationDestination(
          icon: Icon(Icons.space_dashboard), label: 'لوحة التحكم'),
      const NavigationDestination(
          icon: Icon(Icons.inventory_2), label: 'المنتجات'),
      const NavigationDestination(
          icon: Icon(Icons.point_of_sale), label: 'المبيعات'),
      const NavigationDestination(
          icon: Icon(Icons.people_alt), label: 'العملاء'),
      const NavigationDestination(
          icon: Icon(Icons.local_shipping), label: 'الموردون'),
      const NavigationDestination(icon: Icon(Icons.category), label: 'الأقسام'),
      const NavigationDestination(
          icon: Icon(Icons.warehouse), label: 'المخزون'),
      const NavigationDestination(
          icon: Icon(Icons.account_balance), label: 'الحسابات'),
      const NavigationDestination(
          icon: Icon(Icons.bar_chart), label: 'التقارير'),
      const NavigationDestination(
          icon: Icon(Icons.settings), label: 'الإعدادات'),
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
          NavigationRail(
            selectedIndex: _selectedIndex,
            labelType: NavigationRailLabelType.selected,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            destinations: const [
              NavigationRailDestination(
                  icon: Icon(Icons.space_dashboard),
                  label: Text('لوحة التحكم')),
              NavigationRailDestination(
                  icon: Icon(Icons.inventory_2), label: Text('المنتجات')),
              NavigationRailDestination(
                  icon: Icon(Icons.point_of_sale), label: Text('المبيعات')),
              NavigationRailDestination(
                  icon: Icon(Icons.people_alt), label: Text('العملاء')),
              NavigationRailDestination(
                  icon: Icon(Icons.local_shipping), label: Text('الموردون')),
              NavigationRailDestination(
                  icon: Icon(Icons.category), label: Text('الأقسام')),
              NavigationRailDestination(
                  icon: Icon(Icons.warehouse), label: Text('المخزون')),
              NavigationRailDestination(
                  icon: Icon(Icons.account_balance), label: Text('الحسابات')),
              NavigationRailDestination(
                  icon: Icon(Icons.bar_chart), label: Text('التقارير')),
              NavigationRailDestination(
                  icon: Icon(Icons.settings), label: Text('الإعدادات')),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
              child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: pages[_selectedIndex])),
        ],
      ),
      bottomNavigationBar: null,
    );
  }
}
