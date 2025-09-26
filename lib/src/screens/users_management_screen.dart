import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth/auth_provider.dart';
import '../services/db/database_service.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';
import '../utils/dark_mode_utils.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  int _credsVersion = 0;
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final db = context.read<DatabaseService>();

    // التحقق من الصلاحية
    if (!authProvider.hasPermission(UserPermission.manageUsers)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المستخدمين'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                'ليس لديك صلاحية للوصول إلى هذه الصفحة',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      backgroundColor: DarkModeUtils.getBackgroundColor(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات المستخدم الحالي
            Card(
              color: DarkModeUtils.getCardColor(context),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'المستخدم الحالي',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('الاسم', authProvider.currentUserName),
                    _buildInfoRow('الرمز', authProvider.currentEmployeeCode),
                    _buildInfoRow('الدور', authProvider.currentUserRole),
                    _buildInfoRow('الصلاحيات',
                        authProvider.currentUser?.permissionsDescription ?? ''),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // إدارة أسماء المستخدمين وكلمات المرور (للمدير)
            Card(
              color: DarkModeUtils.getCardColor(context),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _UserCredsEditor(key: ValueKey(_credsVersion), db: db),
                    const SizedBox(height: 16),
                    // زر إعادة ضبط كلمات المرور (للمدير فقط)
                    if (authProvider.currentUserRole == 'مدير')
                      _buildResetPasswordsButton(
                        context,
                        db,
                        () {
                          setState(() {
                            _credsVersion++;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // شرح الصلاحيات
            Card(
              color: DarkModeUtils.getCardColor(context),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.security,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'شرح الصلاحيات',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPermissionInfo(
                        'مدير', UserRole.manager.permissionsDescription),
                    _buildPermissionInfo(
                        'مشرف', UserRole.supervisor.permissionsDescription),
                    _buildPermissionInfo(
                        'موظف', UserRole.employee.permissionsDescription),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  // تم الاستغناء عن عرض بيانات المستخدمين الافتراضية لصالح محرر الاعتمادات

  Widget _buildPermissionInfo(String role, String permissions) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DarkModeUtils.getBackgroundColor(context).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            permissions,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _UserCredsEditor extends StatefulWidget {
  const _UserCredsEditor({super.key, required this.db});
  final DatabaseService db;

  @override
  State<_UserCredsEditor> createState() => _UserCredsEditorState();
}

class _UserCredsEditorState extends State<_UserCredsEditor> {
  final TextEditingController _supervisorUsername = TextEditingController();
  final TextEditingController _employeeUsername = TextEditingController();
  final TextEditingController _supervisorPassword = TextEditingController();
  final TextEditingController _employeePassword = TextEditingController();
  bool _showSupervisorPassword = false;
  bool _showEmployeePassword = false;
  bool _savingSupervisor = false;
  bool _savingEmployee = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sup = (await widget.db.database.query('users',
            where: 'role = ?', whereArgs: ['supervisor'], limit: 1))
        .firstOrNull;
    final emp = (await widget.db.database.query('users',
            where: 'role = ?', whereArgs: ['employee'], limit: 1))
        .firstOrNull;
    setState(() {
      _supervisorUsername.text = (sup?['username']?.toString() ?? 'supervisor');
      _employeeUsername.text = (emp?['username']?.toString() ?? 'cashier');
    });
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  void dispose() {
    _supervisorUsername.dispose();
    _employeeUsername.dispose();
    _supervisorPassword.dispose();
    _employeePassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with description
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.manage_accounts,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'إدارة بيانات المستخدمين',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'يمكنك تعديل اسم المستخدم وكلمة المرور لكل دور. سيتم حفظ التغييرات فوراً عند الضغط على زر الحفظ.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.8),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // User editor cards - responsive layout
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildEditorCard(
                  title: 'المشرف',
                  icon: Icons.supervisor_account,
                  color: Colors.orange,
                  usernameController: _supervisorUsername,
                  passwordController: _supervisorPassword,
                  showPassword: _showSupervisorPassword,
                  isSaving: _savingSupervisor,
                  onToggleObscure: () => setState(() {
                    _showSupervisorPassword = !_showSupervisorPassword;
                  }),
                  onSave: () async {
                    if (_savingSupervisor) return;
                    setState(() => _savingSupervisor = true);
                    try {
                      await _saveSupervisor();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('فشل الحفظ: $e'),
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _savingSupervisor = false);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEditorCard(
                  title: 'الموظف',
                  icon: Icons.person,
                  color: Colors.blue,
                  usernameController: _employeeUsername,
                  passwordController: _employeePassword,
                  showPassword: _showEmployeePassword,
                  isSaving: _savingEmployee,
                  onToggleObscure: () => setState(() {
                    _showEmployeePassword = !_showEmployeePassword;
                  }),
                  onSave: () async {
                    if (_savingEmployee) return;
                    setState(() => _savingEmployee = true);
                    try {
                      await _saveEmployee();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('فشل الحفظ: $e'),
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _savingEmployee = false);
                    }
                  },
                ),
              ),
            ],
          )
        else ...[
          _buildEditorCard(
            title: 'المشرف',
            icon: Icons.supervisor_account,
            color: Colors.orange,
            usernameController: _supervisorUsername,
            passwordController: _supervisorPassword,
            showPassword: _showSupervisorPassword,
            isSaving: _savingSupervisor,
            onToggleObscure: () => setState(() {
              _showSupervisorPassword = !_showSupervisorPassword;
            }),
            onSave: () async {
              if (_savingSupervisor) return;
              setState(() => _savingSupervisor = true);
              try {
                await _saveSupervisor();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل الحفظ: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _savingSupervisor = false);
              }
            },
          ),
          const SizedBox(height: 16),
          _buildEditorCard(
            title: 'الموظف',
            icon: Icons.person,
            color: Colors.blue,
            usernameController: _employeeUsername,
            passwordController: _employeePassword,
            showPassword: _showEmployeePassword,
            isSaving: _savingEmployee,
            onToggleObscure: () => setState(() {
              _showEmployeePassword = !_showEmployeePassword;
            }),
            onSave: () async {
              if (_savingEmployee) return;
              setState(() => _savingEmployee = true);
              try {
                await _saveEmployee();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل الحفظ: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _savingEmployee = false);
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildEditorCard({
    required String title,
    required IconData icon,
    required Color color,
    required TextEditingController usernameController,
    required TextEditingController passwordController,
    required bool showPassword,
    required bool isSaving,
    required VoidCallback onToggleObscure,
    required Future<void> Function() onSave,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DarkModeUtils.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Username field
          TextField(
            controller: usernameController,
            decoration: InputDecoration(
              labelText: 'اسم المستخدم',
              hintText: 'أدخل اسم المستخدم الجديد',
              prefixIcon: Icon(Icons.person, color: color),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color, width: 2),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // Password field
          TextField(
            controller: passwordController,
            obscureText: !showPassword,
            decoration: InputDecoration(
              labelText: 'كلمة المرور الجديدة',
              hintText: 'اتركها فارغة للحفاظ على الكلمة الحالية',
              prefixIcon: Icon(Icons.lock, color: color),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color, width: 2),
              ),
              isDense: true,
              suffixIcon: IconButton(
                tooltip:
                    showPassword ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور',
                icon: Icon(
                  showPassword ? Icons.visibility_off : Icons.visibility,
                  color: color,
                ),
                onPressed: onToggleObscure,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isSaving ? null : () => onSave(),
              icon: isSaving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : const Icon(Icons.save, size: 18),
              label: Text(isSaving ? 'جارٍ الحفظ...' : 'حفظ $title'),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSupervisor() async {
    final nowIso = DateTime.now().toIso8601String();
    final newName = _supervisorUsername.text.trim();
    if (newName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('اسم المستخدم لا يمكن أن يكون فارغاً'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
      return;
    }

    // الحصول على بيانات المشرف الحالي
    final currentSupervisor = (await widget.db.database.query('users',
            where: 'role = ?', whereArgs: ['supervisor'], limit: 1))
        .firstOrNull;

    if (currentSupervisor == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('لم يتم العثور على حساب المشرف'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
      return;
    }

    final currentUsername = currentSupervisor['username']?.toString() ?? '';
    final supervisorId = currentSupervisor['id'];

    // التحقق من التضارب فقط إذا كان اسم المستخدم مختلف
    if (currentUsername != newName) {
      final conflict = await widget.db.database.query('users',
          where: 'username = ? AND id != ?',
          whereArgs: [newName, supervisorId],
          limit: 1);
      if (conflict.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('الاسم "$newName" مستخدم من حساب آخر'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ));
        }
        return;
      }

      // تحديث اسم المستخدم
      await widget.db.database.update(
          'users', {'username': newName, 'updated_at': nowIso},
          where: 'id = ?', whereArgs: [supervisorId]);
    }

    // تحديث كلمة المرور إذا تم إدخالها
    if (_supervisorPassword.text.isNotEmpty) {
      await widget.db.database.update(
        'users',
        {'password': _sha256(_supervisorPassword.text), 'updated_at': nowIso},
        where: 'id = ?',
        whereArgs: [supervisorId],
      );
      _supervisorPassword.clear();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('تم حفظ المشرف'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ));
    }
  }

  Future<void> _saveEmployee() async {
    final nowIso = DateTime.now().toIso8601String();
    final newName = _employeeUsername.text.trim();
    if (newName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('اسم المستخدم لا يمكن أن يكون فارغاً'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
      return;
    }

    // الحصول على بيانات الموظف الحالي
    final currentEmployee = (await widget.db.database.query('users',
            where: 'role = ?', whereArgs: ['employee'], limit: 1))
        .firstOrNull;

    if (currentEmployee == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('لم يتم العثور على حساب الموظف'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
      return;
    }

    final currentUsername = currentEmployee['username']?.toString() ?? '';
    final employeeId = currentEmployee['id'];

    // التحقق من التضارب فقط إذا كان اسم المستخدم مختلف
    if (currentUsername != newName) {
      final conflict = await widget.db.database.query('users',
          where: 'username = ? AND id != ?',
          whereArgs: [newName, employeeId],
          limit: 1);
      if (conflict.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('الاسم "$newName" مستخدم من حساب آخر'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ));
        }
        return;
      }

      // تحديث اسم المستخدم
      await widget.db.database.update(
          'users', {'username': newName, 'updated_at': nowIso},
          where: 'id = ?', whereArgs: [employeeId]);
    }

    // تحديث كلمة المرور إذا تم إدخالها
    if (_employeePassword.text.isNotEmpty) {
      await widget.db.database.update(
        'users',
        {'password': _sha256(_employeePassword.text), 'updated_at': nowIso},
        where: 'id = ?',
        whereArgs: [employeeId],
      );
      _employeePassword.clear();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('تم حفظ الموظف'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ));
    }
  }
}

// زر إعادة ضبط كلمات المرور (للمدير فقط)
Widget _buildResetPasswordsButton(
    BuildContext context, DatabaseService db, VoidCallback onAfterReset) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      border: Border.all(
        color: Colors.orange,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: ElevatedButton.icon(
      onPressed: () => _showResetPasswordsDialog(context, db, onAfterReset),
      icon: const Icon(Icons.refresh, color: Colors.white),
      label: const Text(
        'إعادة ضبط أسماء المستخدمين وكلمات المرور',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}

// حوار تأكيد إعادة ضبط كلمات المرور
Future<void> _showResetPasswordsDialog(
    BuildContext context, DatabaseService db, VoidCallback onAfterReset) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('تأكيد إعادة الضبط'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من إعادة ضبط أسماء المستخدمين وكلمات المرور لجميع المستخدمين إلى القيم الافتراضية؟\n\n'
          'سيتم إعادة تعيين إلى:\n'
          '• المدير: admin / Admin@2025\n'
          '• المشرف: supervisor / Supervisor@2025\n'
          '• الموظف: employee / Employee@2025',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _resetAllPasswords(context, db, onAfterReset);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد الإعادة'),
          ),
        ],
      );
    },
  );
}

// دالة إعادة ضبط كلمات المرور
Future<void> _resetAllPasswords(
    BuildContext context, DatabaseService db, VoidCallback onAfterReset) async {
  try {
    debugPrint('بدء إعادة ضبط كلمات المرور...');

    // إظهار مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final nowIso = DateTime.now().toIso8601String();
    debugPrint('وقت التحديث: $nowIso');

    // إعادة ضبط المدير (اسم المستخدم + كلمة المرور)
    final managerId = await _getUserIdByRole(db, 'manager');
    debugPrint('معرف المدير: $managerId');
    if (managerId != null) {
      // فض أي تعارض على اسم admin
      final conflict = await db.database.query(
        'users',
        columns: ['id'],
        where: 'username = ? AND id != ?',
        whereArgs: ['admin', managerId],
        limit: 1,
      );
      if (conflict.isNotEmpty) {
        final otherId = conflict.first['id'];
        await db.database.update(
          'users',
          {
            'username': 'admin_conflict_$otherId',
            'updated_at': nowIso,
          },
          where: 'id = ?',
          whereArgs: [otherId],
        );
      }
      final result = await db.database.update(
        'users',
        {
          'username': 'admin',
          'password': _sha256('Admin@2025'),
          'updated_at': nowIso,
        },
        where: 'id = ?',
        whereArgs: [managerId],
      );
      debugPrint('نتيجة تحديث المدير: $result');
    } else {
      debugPrint('لم يتم العثور على المدير');
    }

    // إعادة ضبط المشرف (اسم المستخدم + كلمة المرور)
    final supervisorId = await _getUserIdByRole(db, 'supervisor');
    debugPrint('معرف المشرف: $supervisorId');
    if (supervisorId != null) {
      try {
        // فض أي تعارض على اسم supervisor
        final conflict = await db.database.query(
          'users',
          columns: ['id'],
          where: 'username = ? AND id != ?',
          whereArgs: ['supervisor', supervisorId],
          limit: 1,
        );
        if (conflict.isNotEmpty) {
          final otherId = conflict.first['id'];
          await db.database.update(
            'users',
            {
              'username': 'supervisor_conflict_$otherId',
              'updated_at': nowIso,
            },
            where: 'id = ?',
            whereArgs: [otherId],
          );
        }
        final result = await db.database.update(
          'users',
          {
            'username': 'supervisor',
            'password': _sha256('Supervisor@2025'),
            'updated_at': nowIso,
          },
          where: 'id = ?',
          whereArgs: [supervisorId],
        );
        debugPrint('نتيجة تحديث المشرف: $result');
      } catch (e) {
        debugPrint('خطأ في تحديث المشرف: $e');
        // محاولة تحديث كلمة المرور فقط
        try {
          final result = await db.database.update(
            'users',
            {
              'password': _sha256('Supervisor@2025'),
              'updated_at': nowIso,
            },
            where: 'id = ?',
            whereArgs: [supervisorId],
          );
          debugPrint('تم تحديث كلمة مرور المشرف فقط: $result');
        } catch (e2) {
          debugPrint('خطأ في تحديث كلمة مرور المشرف: $e2');
        }
      }
    } else {
      debugPrint('لم يتم العثور على المشرف');
    }

    // إعادة ضبط الموظف (اسم المستخدم + كلمة المرور)
    final employeeId = await _getUserIdByRole(db, 'employee');
    debugPrint('معرف الموظف: $employeeId');
    if (employeeId != null) {
      try {
        // فض أي تعارض على اسم employee
        final conflict = await db.database.query(
          'users',
          columns: ['id'],
          where: 'username = ? AND id != ?',
          whereArgs: ['employee', employeeId],
          limit: 1,
        );
        if (conflict.isNotEmpty) {
          final otherId = conflict.first['id'];
          await db.database.update(
            'users',
            {
              'username': 'employee_conflict_$otherId',
              'updated_at': nowIso,
            },
            where: 'id = ?',
            whereArgs: [otherId],
          );
        }
        final result = await db.database.update(
          'users',
          {
            'username': 'employee',
            'password': _sha256('Employee@2025'),
            'updated_at': nowIso,
          },
          where: 'id = ?',
          whereArgs: [employeeId],
        );
        debugPrint('نتيجة تحديث الموظف: $result');
      } catch (e) {
        debugPrint('خطأ في تحديث الموظف: $e');
        // محاولة تحديث كلمة المرور فقط
        try {
          final result = await db.database.update(
            'users',
            {
              'password': _sha256('Employee@2025'),
              'updated_at': nowIso,
            },
            where: 'id = ?',
            whereArgs: [employeeId],
          );
          debugPrint('تم تحديث كلمة مرور الموظف فقط: $result');
        } catch (e2) {
          debugPrint('خطأ في تحديث كلمة مرور الموظف: $e2');
        }
      }
    } else {
      debugPrint('لم يتم العثور على الموظف');
    }

    // إغلاق مؤشر التحميل
    if (context.mounted) Navigator.of(context).pop();

    // إظهار رسالة نجاح
    if (context.mounted) {
      debugPrint('تم إعادة ضبط جميع البيانات بنجاح!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'تم إعادة ضبط أسماء المستخدمين وكلمات المرور بنجاح!\n'
            'المدير: admin / Admin@2025\n'
            'المشرف: supervisor / Supervisor@2025\n'
            'الموظف: employee / Employee@2025',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    }
    onAfterReset();
  } catch (e) {
    // إغلاق مؤشر التحميل
    if (context.mounted) Navigator.of(context).pop();

    // إظهار رسالة خطأ
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في إعادة ضبط أسماء المستخدمين وكلمات المرور: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

// دالة تشفير كلمة المرور
String _sha256(String input) {
  var bytes = utf8.encode(input);
  var digest = sha256.convert(bytes);
  return digest.toString();
}

// دالة مساعدة للحصول على معرف المستخدم حسب الدور
Future<int?> _getUserIdByRole(DatabaseService db, String role) async {
  try {
    final result = await db.database.query(
      'users',
      columns: ['id'],
      where: 'role = ?',
      whereArgs: [role],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int?;
    }
    return null;
  } catch (e) {
    debugPrint('خطأ في جلب معرف المستخدم للدور $role: $e');
    return null;
  }
}
