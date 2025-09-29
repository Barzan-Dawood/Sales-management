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
import 'utils/responsive_utils.dart';
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

    // Get screen dimensions for responsive design
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);
    final isMediumScreen = ResponsiveUtils.isMediumScreen(context);
    final isLargeScreen = ResponsiveUtils.isLargeScreen(context);

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
      appBar: isSmallScreen
          ? null
          : AppBar(
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
                  tooltip: themeProvider.isDarkMode
                      ? 'الوضع الفاتح'
                      : 'الوضع المظلم',
                  icon: Icon(themeProvider.isDarkMode
                      ? Icons.light_mode
                      : Icons.dark_mode),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
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
                                    color:
                                        Theme.of(context).colorScheme.primary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const LicenseCheckScreen(),
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
      body: isSmallScreen
          ? _buildMobileLayout(context, pages, canAccessIndex, auth, store,
              themeProvider, licenseProvider, scheme, isDark, gradients)
          : _buildDesktopLayout(
              context,
              pages,
              canAccessIndex,
              auth,
              store,
              themeProvider,
              licenseProvider,
              scheme,
              isDark,
              gradients,
              isSmallScreen,
              isMediumScreen,
              isLargeScreen),
      bottomNavigationBar: isSmallScreen
          ? _buildBottomNavigation(context, canAccessIndex)
          : null,
    );
  }

  Widget _buildMobileLayout(
      BuildContext context,
      List<Widget> pages,
      bool Function(int) canAccessIndex,
      AuthProvider auth,
      StoreConfig store,
      ThemeProvider themeProvider,
      LicenseProvider licenseProvider,
      ColorScheme scheme,
      bool isDark,
      AppGradients? gradients) {
    return Column(
      children: [
        // Mobile header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                gradients?.sidebarStart ?? scheme.primary.withOpacity(0.08),
                gradients?.sidebarMiddle ?? scheme.primary.withOpacity(0.12),
                gradients?.sidebarEnd ?? scheme.primary.withOpacity(0.16),
              ],
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => _showMobileMenu(context, canAccessIndex),
                    icon: const Icon(Icons.menu),
                    tooltip: 'القائمة',
                  ),
                  Expanded(
                    child: Text(
                      store.appTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    tooltip: themeProvider.isDarkMode
                        ? 'الوضع الفاتح'
                        : 'الوضع المظلم',
                    icon: Icon(themeProvider.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode),
                    onPressed: () => themeProvider.toggleTheme(),
                  ),
                  IconButton(
                    tooltip: AppStrings.logout,
                    icon: const Icon(Icons.logout),
                    onPressed: () => context.read<AuthProvider>().logout(),
                  ),
                ],
              ),
              if (licenseProvider.isTrialActive)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_bottom,
                          size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'نسخة تجريبية: متبقّي ${licenseProvider.trialDaysLeft} يوم',
                          style: TextStyle(color: scheme.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Main content
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
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
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context,
      List<Widget> pages,
      bool Function(int) canAccessIndex,
      AuthProvider auth,
      StoreConfig store,
      ThemeProvider themeProvider,
      LicenseProvider licenseProvider,
      ColorScheme scheme,
      bool isDark,
      AppGradients? gradients,
      bool isSmallScreen,
      bool isMediumScreen,
      bool isLargeScreen) {
    return Row(
      children: [
        // Enhanced Sidebar with better design
        Container(
          width: ResponsiveUtils.getResponsiveSidebarWidth(context),
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
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
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
                              color:
                                  DarkModeUtils.getSecondaryTextColor(context),
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
    );
  }

  Widget _buildBottomNavigation(
      BuildContext context, bool Function(int) canAccessIndex) {
    // Create a list of accessible indices for mobile navigation
    final accessibleIndices = <int>[];
    if (canAccessIndex(0)) accessibleIndices.add(0);
    if (canAccessIndex(1)) accessibleIndices.add(1);
    if (canAccessIndex(3)) accessibleIndices.add(3);
    if (canAccessIndex(6)) accessibleIndices.add(6);
    if (canAccessIndex(14)) accessibleIndices.add(14);

    // Ensure we always have at least the dashboard (index 0)
    if (accessibleIndices.isEmpty) {
      accessibleIndices.add(0);
    }

    // Find the current index in the accessible indices
    int currentBottomNavIndex = 0;
    if (accessibleIndices.contains(_selectedIndex)) {
      currentBottomNavIndex = accessibleIndices.indexOf(_selectedIndex);
    } else {
      // If current _selectedIndex is not accessible, default to first accessible index
      currentBottomNavIndex = 0;
      _selectedIndex = accessibleIndices[0];
    }

    // Ensure currentBottomNavIndex is within bounds
    currentBottomNavIndex =
        currentBottomNavIndex.clamp(0, accessibleIndices.length - 1);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentBottomNavIndex,
      onTap: (index) {
        if (index < accessibleIndices.length) {
          setState(() => _selectedIndex = accessibleIndices[index]);
        }
      },
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor:
          Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      items: accessibleIndices.map((index) {
        switch (index) {
          case 0:
            return const BottomNavigationBarItem(
              icon: Icon(Icons.space_dashboard),
              label: 'الرئيسية',
            );
          case 1:
            return const BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale),
              label: 'المبيعات',
            );
          case 3:
            return const BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2),
              label: 'المنتجات',
            );
          case 6:
            return const BottomNavigationBarItem(
              icon: Icon(Icons.people_alt),
              label: 'العملاء',
            );
          case 14:
            return const BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'الإعدادات',
            );
          default:
            return const BottomNavigationBarItem(
              icon: Icon(Icons.space_dashboard),
              label: 'الرئيسية',
            );
        }
      }).toList(),
    );
  }

  void _showMobileMenu(
      BuildContext context, bool Function(int) canAccessIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.menu,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'القائمة الرئيسية',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildMobileNavItem(
                    icon: Icons.space_dashboard,
                    label: 'الرئيسية',
                    index: 0,
                    isSelected: _selectedIndex == 0,
                    canAccess: canAccessIndex(0),
                  ),
                  if (canAccessIndex(1))
                    _buildMobileNavItem(
                      icon: Icons.point_of_sale,
                      label: 'المبيعات',
                      index: 1,
                      isSelected: _selectedIndex == 1,
                      canAccess: true,
                    ),
                  if (canAccessIndex(2))
                    _buildMobileNavItem(
                      icon: Icons.history,
                      label: 'تاريخ المبيعات',
                      index: 2,
                      isSelected: _selectedIndex == 2,
                      canAccess: true,
                    ),
                  if (canAccessIndex(3))
                    _buildMobileNavItem(
                      icon: Icons.inventory_2,
                      label: 'المنتجات',
                      index: 3,
                      isSelected: _selectedIndex == 3,
                      canAccess: true,
                    ),
                  if (canAccessIndex(4))
                    _buildMobileNavItem(
                      icon: Icons.category,
                      label: 'الأقسام',
                      index: 4,
                      isSelected: _selectedIndex == 4,
                      canAccess: true,
                    ),
                  if (canAccessIndex(5))
                    _buildMobileNavItem(
                      icon: Icons.warehouse,
                      label: 'المخزون',
                      index: 5,
                      isSelected: _selectedIndex == 5,
                      canAccess: true,
                    ),
                  if (canAccessIndex(6))
                    _buildMobileNavItem(
                      icon: Icons.people_alt,
                      label: 'العملاء',
                      index: 6,
                      isSelected: _selectedIndex == 6,
                      canAccess: true,
                    ),
                  if (canAccessIndex(7))
                    _buildMobileNavItem(
                      icon: Icons.local_shipping,
                      label: 'الموردين',
                      index: 7,
                      isSelected: _selectedIndex == 7,
                      canAccess: true,
                    ),
                  if (canAccessIndex(8))
                    _buildMobileNavItem(
                      icon: Icons.account_balance,
                      label: 'المحاسبة',
                      index: 8,
                      isSelected: _selectedIndex == 8,
                      canAccess: true,
                    ),
                  if (canAccessIndex(9))
                    _buildMobileNavItem(
                      icon: Icons.payments,
                      label: 'الديون',
                      index: 9,
                      isSelected: _selectedIndex == 9,
                      canAccess: true,
                    ),
                  if (canAccessIndex(10))
                    _buildMobileNavItem(
                      icon: Icons.bar_chart,
                      label: 'التقارير',
                      index: 10,
                      isSelected: _selectedIndex == 10,
                      canAccess: true,
                    ),
                  if (canAccessIndex(11))
                    _buildMobileNavItem(
                      icon: Icons.account_balance_wallet,
                      label: 'التقارير المالية',
                      index: 11,
                      isSelected: _selectedIndex == 11,
                      canAccess: true,
                    ),
                  if (canAccessIndex(12))
                    _buildMobileNavItem(
                      icon: Icons.inventory_2,
                      label: 'تقارير الجرد',
                      index: 12,
                      isSelected: _selectedIndex == 12,
                      canAccess: true,
                    ),
                  if (canAccessIndex(13))
                    _buildMobileNavItem(
                      icon: Icons.science,
                      label: 'الاختبارات',
                      index: 13,
                      isSelected: _selectedIndex == 13,
                      canAccess: true,
                    ),
                  if (canAccessIndex(14))
                    _buildMobileNavItem(
                      icon: Icons.settings,
                      label: 'الإعدادات',
                      index: 14,
                      isSelected: _selectedIndex == 14,
                      canAccess: true,
                    ),
                  if (canAccessIndex(15))
                    _buildMobileNavItem(
                      icon: Icons.people,
                      label: 'إدارة المستخدمين',
                      index: 15,
                      isSelected: _selectedIndex == 15,
                      canAccess: true,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
    required bool canAccess,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: canAccess
              ? () {
                  setState(() => _selectedIndex = index);
                  Navigator.pop(context);
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                        : Theme.of(context)
                            .colorScheme
                            .surface
                            .withOpacity(0.3),
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
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
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
