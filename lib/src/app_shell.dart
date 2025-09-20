// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth/auth_provider.dart';
import 'services/store_config.dart';
import 'services/theme_provider.dart';
import 'services/license/license_provider.dart';
import 'utils/strings.dart';
import 'utils/app_themes.dart';
import 'utils/dark_mode_utils.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/products/products_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/suppliers_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/sales_history_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/accounting_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/debts_screen.dart';
import 'screens/tests_screen.dart';
import 'screens/advanced_reports_screen.dart';
import 'screens/inventory_reports_screen.dart';
import 'screens/license_check_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // تهيئة مزود الترخيص عند بدء الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LicenseProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final store = context.watch<StoreConfig>();
    final themeProvider = context.watch<ThemeProvider>();
    final licenseProvider = context.watch<LicenseProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final gradients = theme.extension<AppGradients>();

    // Update theme provider with current system brightness
    WidgetsBinding.instance.addPostFrameCallback((_) {
      themeProvider.updateDarkModeStatus(isDark);
    });

    // فحص الترخيص أولاً
    if (!licenseProvider.isActivated) {
      return const LicenseCheckScreen();
    }

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    // Disabled forced password change screen on default login per request

    final pages = <Widget>[
      const DashboardScreen(),
      const SalesScreen(),
      const SalesHistoryScreen(),
      const ProductsScreen(),
      const CategoriesScreen(),
      const InventoryScreen(),
      const CustomersScreen(),
      const SuppliersScreen(),
      const AccountingScreen(),
      const DebtsScreen(),
      const ReportsScreen(),
      const AdvancedReportsScreen(),
      const InventoryReportsScreen(),
      const TestsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          store.appTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: _selectedIndex != 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedIndex = 0),
                tooltip: 'العودة للرئيسية',
              )
            : null,
        actions: [
          // Dark mode toggle button
          IconButton(
            tooltip: themeProvider.isDarkMode ? 'الوضع الفاتح' : 'الوضع المظلم',
            icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                auth.currentUser?['name']?.toString() ?? '',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          IconButton(
            tooltip: AppStrings.logout,
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
                  gradients?.sidebarStart ?? scheme.primary.withOpacity(0.08),
                  gradients?.sidebarMiddle ?? scheme.primary.withOpacity(0.12),
                  gradients?.sidebarEnd ?? scheme.primary.withOpacity(0.16),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: DarkModeUtils.getShadowColor(context),
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
                    color: isDark ? scheme.primaryContainer : scheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.1)
                            : Colors.white.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppStrings.mainMenu,
                              style: TextStyle(
                                color: isDark
                                    ? scheme.onPrimaryContainer
                                    : scheme.onPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              AppStrings.selectSection,
                              style: TextStyle(
                                color: (isDark
                                        ? scheme.onPrimaryContainer
                                        : scheme.onPrimary)
                                    .withOpacity(0.85),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.2,
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
                        label: AppStrings.dashboard,
                        index: 0,
                        isSelected: _selectedIndex == 0,
                      ),
                      _buildNavItem(
                        icon: Icons.point_of_sale,
                        label: AppStrings.sales,
                        index: 1,
                        isSelected: _selectedIndex == 1,
                      ),
                      _buildNavItem(
                        icon: Icons.history,
                        label: AppStrings.salesHistory,
                        index: 2,
                        isSelected: _selectedIndex == 2,
                      ),
                      _buildNavItem(
                        icon: Icons.inventory_2,
                        label: AppStrings.products,
                        index: 3,
                        isSelected: _selectedIndex == 3,
                      ),
                      _buildNavItem(
                        icon: Icons.category,
                        label: AppStrings.categories,
                        index: 4,
                        isSelected: _selectedIndex == 4,
                      ),
                      _buildNavItem(
                        icon: Icons.warehouse,
                        label: AppStrings.inventory,
                        index: 5,
                        isSelected: _selectedIndex == 5,
                      ),
                      _buildNavItem(
                        icon: Icons.people_alt,
                        label: AppStrings.customers,
                        index: 6,
                        isSelected: _selectedIndex == 6,
                      ),
                      _buildNavItem(
                        icon: Icons.local_shipping,
                        label: AppStrings.suppliers,
                        index: 7,
                        isSelected: _selectedIndex == 7,
                      ),
                      _buildNavItem(
                        icon: Icons.account_balance,
                        label: AppStrings.accounting,
                        index: 8,
                        isSelected: _selectedIndex == 8,
                      ),
                      _buildNavItem(
                        icon: Icons.payments,
                        label: AppStrings.debts,
                        index: 9,
                        isSelected: _selectedIndex == 9,
                      ),
                      _buildNavItem(
                        icon: Icons.bar_chart,
                        label: AppStrings.reports,
                        index: 10,
                        isSelected: _selectedIndex == 10,
                      ),
                      _buildNavItem(
                        icon: Icons.account_balance_wallet,
                        label: 'التقارير المالية',
                        index: 11,
                        isSelected: _selectedIndex == 11,
                      ),
                      _buildNavItem(
                        icon: Icons.inventory_2,
                        label: 'تقارير الجرد',
                        index: 12,
                        isSelected: _selectedIndex == 12,
                      ),
                      _buildNavItem(
                        icon: Icons.science,
                        label: 'الاختبارات',
                        index: 13,
                        isSelected: _selectedIndex == 13,
                      ),
                      _buildNavItem(
                        icon: Icons.settings,
                        label: AppStrings.settings,
                        index: 14,
                        isSelected: _selectedIndex == 14,
                      ),
                    ],
                  ),
                ),

                // Footer section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surface.withOpacity(0.06),
                    border: Border(
                      top: BorderSide(
                        color: DarkModeUtils.getBorderColor(context),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            scheme.primaryContainer.withOpacity(0.25),
                        child: Icon(
                          Icons.person,
                          color: scheme.onPrimaryContainer,
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
                                  AppStrings.user,
                              style: TextStyle(
                                color: DarkModeUtils.getTextColor(context),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              AppStrings.activeUser,
                              style: TextStyle(
                                color: DarkModeUtils.getSecondaryTextColor(
                                    context),
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
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: Container(
                key: ValueKey(_selectedIndex),
                child: pages[_selectedIndex],
              ),
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
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? DarkModeUtils.getCardColor(context).withOpacity(0.1)
                      : DarkModeUtils.getCardColor(context).withOpacity(0.9))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.2),
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
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                        : DarkModeUtils.getCardColor(context).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black)
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.blue
                              : Colors.white.withOpacity(0.9)),
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
                      color: Theme.of(context).colorScheme.primary,
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
