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
import 'screens/users_management_screen.dart';
import 'models/user_model.dart';

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

    // فحص الترخيص أولاً (يسمح بالتجربة المجانية)
    if (!licenseProvider.isActivated && !licenseProvider.isTrialActive) {
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
      const UsersManagementScreen(), // إدارة المستخدمين
    ];

    bool canAccessIndex(int index) {
      switch (index) {
        case 0:
          return true; // Dashboard متاح للجميع بعد تسجيل الدخول
        case 1:
          return auth.hasPermission(UserPermission.manageSales);
        case 2:
          return auth.hasPermission(UserPermission.viewReports);
        case 3:
          return auth.hasPermission(UserPermission.manageProducts);
        case 4:
          return auth.hasPermission(UserPermission.manageCategories);
        case 5:
          return auth.hasPermission(UserPermission.manageInventory);
        case 6:
          return auth.hasPermission(UserPermission.manageCustomers);
        case 7:
          return auth.hasPermission(UserPermission.manageSuppliers);
        case 8:
          return auth.hasPermission(UserPermission.viewReports);
        case 9:
          return auth.hasPermission(UserPermission.viewReports);
        case 10:
          return auth.hasPermission(UserPermission.viewReports);
        case 11:
          return auth.hasPermission(UserPermission.viewProfitCosts);
        case 12:
          return auth.hasPermission(UserPermission.viewReports);
        case 13:
          return true; // شاشة الاختبارات لأغراض التطوير فقط
        case 14:
          return auth.hasPermission(UserPermission.systemSettings);
        case 15:
          return auth.hasPermission(UserPermission.manageUsers);
        default:
          return false;
      }
    }

    // منع الوصول غير المصرّح به عند تغيير المستخدم أو الصلاحيات
    if (!canAccessIndex(_selectedIndex)) {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              store.appTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
                auth.currentUserName.isNotEmpty
                    ? auth.currentUserName
                    : 'المستخدم',
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
        bottom: licenseProvider.isTrialActive
            ? PreferredSize(
                preferredSize: const Size.fromHeight(36),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.blue.withOpacity(0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_bottom,
                          size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'نسخة تجريبية: متبقّي ${context.read<LicenseProvider>().trialDaysLeft} يوم',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LicenseCheckScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.key, size: 16),
                        label: const Text('تفعيل الآن'),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
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
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary,
                        scheme.primary.withOpacity(0.8),
                        scheme.primaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.6, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.2)
                            : Colors.white.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/soft.png',
                          height: 50,
                          width: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppStrings.mainMenu,
                              style: TextStyle(
                                color: scheme.onPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              AppStrings.selectSection,
                              style: TextStyle(
                                color: scheme.onPrimary.withOpacity(0.9),
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
                      if (canAccessIndex(1))
                        _buildNavItem(
                          icon: Icons.point_of_sale,
                          label: AppStrings.sales,
                          index: 1,
                          isSelected: _selectedIndex == 1,
                        ),
                      if (canAccessIndex(2))
                        _buildNavItem(
                          icon: Icons.history,
                          label: AppStrings.salesHistory,
                          index: 2,
                          isSelected: _selectedIndex == 2,
                        ),
                      if (canAccessIndex(3))
                        _buildNavItem(
                          icon: Icons.inventory_2,
                          label: AppStrings.products,
                          index: 3,
                          isSelected: _selectedIndex == 3,
                        ),
                      if (canAccessIndex(4))
                        _buildNavItem(
                          icon: Icons.category,
                          label: AppStrings.categories,
                          index: 4,
                          isSelected: _selectedIndex == 4,
                        ),
                      if (canAccessIndex(5))
                        _buildNavItem(
                          icon: Icons.warehouse,
                          label: AppStrings.inventory,
                          index: 5,
                          isSelected: _selectedIndex == 5,
                        ),
                      if (canAccessIndex(6))
                        _buildNavItem(
                          icon: Icons.people_alt,
                          label: AppStrings.customers,
                          index: 6,
                          isSelected: _selectedIndex == 6,
                        ),
                      if (canAccessIndex(7))
                        _buildNavItem(
                          icon: Icons.local_shipping,
                          label: AppStrings.suppliers,
                          index: 7,
                          isSelected: _selectedIndex == 7,
                        ),
                      if (canAccessIndex(8))
                        _buildNavItem(
                          icon: Icons.account_balance,
                          label: AppStrings.accounting,
                          index: 8,
                          isSelected: _selectedIndex == 8,
                        ),
                      if (canAccessIndex(9))
                        _buildNavItem(
                          icon: Icons.payments,
                          label: AppStrings.debts,
                          index: 9,
                          isSelected: _selectedIndex == 9,
                        ),
                      if (canAccessIndex(10))
                        _buildNavItem(
                          icon: Icons.bar_chart,
                          label: AppStrings.reports,
                          index: 10,
                          isSelected: _selectedIndex == 10,
                        ),
                      if (canAccessIndex(11))
                        _buildNavItem(
                          icon: Icons.account_balance_wallet,
                          label: 'التقارير المالية',
                          index: 11,
                          isSelected: _selectedIndex == 11,
                        ),
                      if (canAccessIndex(12))
                        _buildNavItem(
                          icon: Icons.inventory_2,
                          label: 'تقارير الجرد',
                          index: 12,
                          isSelected: _selectedIndex == 12,
                        ),
                      if (canAccessIndex(13))
                        _buildNavItem(
                          icon: Icons.science,
                          label: 'الاختبارات',
                          index: 13,
                          isSelected: _selectedIndex == 13,
                        ),
                      // إدارة المستخدمين - للمديرين فقط
                      if (canAccessIndex(15))
                        _buildNavItem(
                          icon: Icons.people,
                          label: 'إدارة المستخدمين',
                          index: 15,
                          isSelected: _selectedIndex == 15,
                        ),
                      if (canAccessIndex(14))
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
                              auth.currentUserName.isNotEmpty
                                  ? auth.currentUserName
                                  : AppStrings.user,
                              style: TextStyle(
                                color: DarkModeUtils.getTextColor(context),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              auth.currentUserRole.isNotEmpty
                                  ? auth.currentUserRole
                                  : AppStrings.activeUser,
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
                child: canAccessIndex(_selectedIndex)
                    ? pages[_selectedIndex]
                    : const Center(
                        child: Text('صلاحيات غير كافية للوصول إلى هذه الصفحة'),
                      ),
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
