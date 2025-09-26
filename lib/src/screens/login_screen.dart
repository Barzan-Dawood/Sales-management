// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rojsoft_manager/src/screens/enhanced_privacy_policy_screen.dart';
import '../services/auth/auth_provider.dart';
import '../services/db/database_service.dart';
import '../utils/dark_mode_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String _selectedUserType = 'manager'; // القيمة الافتراضية

  // بيانات المستخدمين الحقيقية من قاعدة البيانات
  final Map<String, String> _realUsernames = {
    'manager': 'admin',
    'supervisor': 'supervisor',
    'employee': 'employee',
  };

  @override
  void initState() {
    super.initState();
    _loadLastUsername();
    _loadRealUsernames();
  }

  @override
  void didUpdateWidget(LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // إعادة تحميل أسماء المستخدمين عند تحديث الصفحة
    _loadRealUsernames();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // إعادة تحميل أسماء المستخدمين عند العودة من صفحات أخرى
    _loadRealUsernames();
    // إعادة تحميل آخر اسم مستخدم لتحديث المؤشر والحقل بعد تسجيل الخروج
    _loadLastUsername();
    // تأكيد الاتساق عند العودة
    _reconcileUserTypeAndUsername();
  }

  Future<void> _loadLastUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUsername = prefs.getString('last_username');
      if (lastUsername != null && lastUsername.isNotEmpty) {
        _usernameController.text = lastUsername;
        _autoSelectRoleFor(lastUsername);
        _passwordController.clear();
      }
    } catch (_) {}
    // Ensure consistency after loading
    if (mounted) _reconcileUserTypeAndUsername();
  }

  Future<void> _loadRealUsernames() async {
    try {
      final db = context.read<DatabaseService>();

      // جلب اسم المستخدم للمدير
      final manager = (await db.database.query('users',
              where: 'role = ?', whereArgs: ['manager'], limit: 1))
          .firstOrNull;
      if (manager != null) {
        _realUsernames['manager'] = manager['username']?.toString() ?? 'admin';
      }

      // جلب اسم المستخدم للمشرف
      final supervisor = (await db.database.query('users',
              where: 'role = ?', whereArgs: ['supervisor'], limit: 1))
          .firstOrNull;
      if (supervisor != null) {
        _realUsernames['supervisor'] =
            supervisor['username']?.toString() ?? 'supervisor';
      }

      // جلب اسم المستخدم للموظف
      final employee = (await db.database.query('users',
              where: 'role = ?', whereArgs: ['employee'], limit: 1))
          .firstOrNull;
      if (employee != null) {
        _realUsernames['employee'] =
            employee['username']?.toString() ?? 'employee';
      }

      if (mounted) {
        setState(() {});
        _reconcileUserTypeAndUsername();
      }
    } catch (e) {
      debugPrint('خطأ في جلب أسماء المستخدمين: $e');
    }
  }

  void _autoSelectRoleFor(String username) {
    final u = username.toLowerCase();

    // التحقق من الأسماء الحقيقية أولاً
    if (_realUsernames['manager']?.toLowerCase() == u) {
      _selectedUserType = 'manager';
    } else if (_realUsernames['supervisor']?.toLowerCase() == u) {
      _selectedUserType = 'supervisor';
    } else if (_realUsernames['employee']?.toLowerCase() == u) {
      _selectedUserType = 'employee';
    } else {
      // التحقق من الأسماء الافتراضية كبديل
      if (u == 'admin') {
        _selectedUserType = 'manager';
      } else if (u == 'supervisor') {
        _selectedUserType = 'supervisor';
      } else if (u == 'employee') {
        _selectedUserType = 'employee';
      }
    }
    setState(() {});
  }

  Future<void> _attemptLogin(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final ok = await context.read<AuthProvider>().login(
          _usernameController.text.trim(),
          _passwordController.text,
        );
    setState(() => _loading = false);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'بيانات الدخول غير صحيحة - تأكد من اسم المستخدم وكلمة المرور'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    // Save last username
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_username', _usernameController.text.trim());
    } catch (_) {}
    final authProvider = context.read<AuthProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'مرحباً ${authProvider.currentUserName} - ${authProvider.currentUserRole}'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<String> _fetchUsernameForRole(
      BuildContext context, String role) async {
    try {
      final db = context.read<DatabaseService>();
      final result = await db.database.query(
        'users',
        columns: ['username'],
        where: 'role = ?',
        whereArgs: [role],
        limit: 1,
      );
      if (result.isNotEmpty) {
        final value = result.first['username']?.toString();
        if (value != null && value.isNotEmpty) return value;
      }
    } catch (e) {
      debugPrint('fetchUsernameForRole error for role=$role: $e');
    }
    // Fallbacks
    switch (role) {
      case 'manager':
        return 'admin';
      case 'supervisor':
        return 'supervisor';
      case 'employee':
      default:
        return 'employee';
    }
  }

  void _showLoginSuccessSnack(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'مرحباً ${authProvider.currentUserName} - ${authProvider.currentUserRole}'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _selectUserType(String userType) async {
    final username = await _fetchUsernameForRole(context, userType);
    if (!mounted) return;
    setState(() {
      _selectedUserType = userType;
      _realUsernames[userType] = username; // keep cache in sync
      _usernameController.text = username;
      _passwordController.clear();
    });
  }

  void _reconcileUserTypeAndUsername() {
    final currentText = _usernameController.text.trim();
    if (currentText.isNotEmpty) {
      // اجعل المؤشر يطابق النص الحالي
      _autoSelectRoleFor(currentText);
    } else {
      // اجعل النص يطابق المؤشر الحالي باستخدام القيم الحقيقية من قاعدة البيانات
      // ignore: discarded_futures
      _selectUserType(_selectedUserType);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkModeUtils.getBackgroundColor(context),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 8,
              color: DarkModeUtils.getCardColor(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // عنوان الترحيب
                      Container(
                        margin: const EdgeInsets.only(bottom: 32),
                        child: Column(
                          children: [
                            Text(
                              'RojSoft Manager',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: 100,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Icon(
                                      Icons.point_of_sale,
                                      size: 32,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // اختيار نوع المستخدم
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'اختر نوع المستخدم',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildUserTypeSelector(),
                          ],
                        ),
                      ),

                      // حقول تسجيل الدخول
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _usernameController,
                              textInputAction: TextInputAction.next,
                              decoration: DarkModeUtils.createInputDecoration(
                                context,
                                hintText: 'اسم المستخدم',
                                prefixIcon: Icons.person,
                              ).copyWith(
                                filled: true,
                                fillColor:
                                    DarkModeUtils.getBackgroundColor(context)
                                        .withOpacity(0.5),
                              ),
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'مطلوب' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              textInputAction: TextInputAction.done,
                              decoration: DarkModeUtils.createInputDecoration(
                                context,
                                hintText: 'كلمة المرور',
                                prefixIcon: Icons.lock,
                                suffixIcon: IconButton(
                                  tooltip: _obscure ? 'إظهار' : 'إخفاء',
                                  icon: Icon(_obscure
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                                  onPressed: () => setState(() {
                                    _obscure = !_obscure;
                                  }),
                                ),
                              ).copyWith(
                                filled: true,
                                fillColor:
                                    DarkModeUtils.getBackgroundColor(context)
                                        .withOpacity(0.5),
                              ),
                              obscureText: _obscure,
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'مطلوب' : null,
                              onFieldSubmitted: (_) =>
                                  _loading ? null : _attemptLogin(context),
                            ),
                          ],
                        ),
                      ),

                      // زر تسجيل الدخول
                      Container(
                        width: double.infinity,
                        height: 56,
                        margin: const EdgeInsets.only(bottom: 24),
                        child: FilledButton(
                          onPressed: _loading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate())
                                    return;
                                  setState(() => _loading = true);

                                  // منع طباعة بيانات حساسة

                                  final ok =
                                      await context.read<AuthProvider>().login(
                                            _usernameController.text.trim(),
                                            _passwordController.text,
                                          );

                                  debugPrint('نتيجة تسجيل الدخول: $ok');
                                  setState(() => _loading = false);
                                  if (!ok && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                            'بيانات الدخول غير صحيحة - تأكد من اسم المستخدم وكلمة المرور'),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } else if (ok && mounted) {
                                    final authProvider =
                                        context.read<AuthProvider>();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'مرحباً ${authProvider.currentUserName} - ${authProvider.currentUserRole}',
                                        ),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.login, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'تسجيل الدخول',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      // روابط سياسة الخصوصية
                      Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EnhancedPrivacyPolicyScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'سياسة الخصوصية',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            const Text(' • ', style: TextStyle(fontSize: 12)),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EnhancedTermsConditionsScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'شروط الاستخدام',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// بناء منتقي نوع المستخدم
  Widget _buildUserTypeSelector() {
    final options = const [
      (
        'manager',
        'مدير',
        Icons.admin_panel_settings,
      ),
      (
        'supervisor',
        'مشرف',
        Icons.supervisor_account,
      ),
      (
        'employee',
        'موظف',
        Icons.person,
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(o.$3, size: 16),
                const SizedBox(width: 6),
                Text(o.$2),
              ],
            ),
            selected: _selectedUserType == o.$1,
            onSelected: (_) async {
              await _selectUserType(o.$1);
            },
            selectedColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.15),
            labelStyle: Theme.of(context).textTheme.bodySmall,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: StadiumBorder(
              side: BorderSide(
                color: _selectedUserType == o.$1
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.4),
              ),
            ),
          ),
      ],
    );
  }

  /// بناء بطاقة نوع المستخدم
  // تم الاستغناء عن البطاقات الكبيرة لصالح شرائح اختيار مدمجة
}
