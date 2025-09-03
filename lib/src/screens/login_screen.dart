import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: 'admin');
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FlutterLogo(size: 64),
                    const SizedBox(height: 16),
                    Text('أهلاً بك',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _usernameController,
                      decoration:
                          const InputDecoration(labelText: 'اسم المستخدم'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration:
                          const InputDecoration(labelText: 'كلمة المرور'),
                      obscureText: true,
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
