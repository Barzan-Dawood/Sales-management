// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'enhanced_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return const EnhancedSettingsScreen();
  }
}
