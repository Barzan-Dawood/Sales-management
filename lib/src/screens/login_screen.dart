// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:office_mangment_system/src/screens/enhanced_privacy_policy_screen.dart';
import 'package:office_mangment_system/src/services/store_config.dart';
import 'package:provider/provider.dart';
import '../services/auth/auth_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkModeUtils.getBackgroundColor(context),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 3,
            color: DarkModeUtils.getCardColor(context),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(StoreConfig().appTitle,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    Text('أهلاً بك',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _usernameController,
                      decoration: DarkModeUtils.createInputDecoration(
                        context,
                        hintText: 'اسم المستخدم',
                        prefixIcon: Icons.person,
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
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
                      ),
                      obscureText: _obscure,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _loading
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                setState(() => _loading = true);
                                final ok =
                                    await context.read<AuthProvider>().login(
                                          _usernameController.text.trim(),
                                          _passwordController.text,
                                        );
                                setState(() => _loading = false);
                                if (!ok && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('بيانات الدخول غير صحيحة')),
                                  );
                                }
                              },
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('تسجيل الدخول'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // رابط سياسة الخصوصية
                    Row(
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
