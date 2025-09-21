import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/store_info.dart';
import '../services/store_info_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/app_design_system.dart';

/// شاشة تعديل معلومات المتجر (مبسطة)
class StoreInfoScreen extends StatefulWidget {
  const StoreInfoScreen({super.key});

  @override
  State<StoreInfoScreen> createState() => _StoreInfoScreenState();
}

class _StoreInfoScreenState extends State<StoreInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  StoreInfo? _currentStoreInfo;

  @override
  void initState() {
    super.initState();
    _loadStoreInfo();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// تحميل معلومات المتجر
  Future<void> _loadStoreInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storeInfo = await StoreInfoService.getStoreInfo();
      if (storeInfo != null) {
        _currentStoreInfo = storeInfo;
        _fillFormFields(storeInfo);
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في تحميل معلومات المتجر: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// ملء حقول النموذج
  void _fillFormFields(StoreInfo storeInfo) {
    _storeNameController.text = storeInfo.storeName;
    _addressController.text = storeInfo.address;
    _phoneController.text = storeInfo.phone;
    _descriptionController.text = storeInfo.description;
  }

  /// حفظ معلومات المتجر
  Future<void> _saveStoreInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final storeInfo = StoreInfo(
        id: _currentStoreInfo?.id,
        storeName: _storeNameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        description: _descriptionController.text.trim(),
        createdAt: _currentStoreInfo?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await StoreInfoService.saveStoreInfo(storeInfo);

      if (success) {
        _currentStoreInfo = storeInfo;
        _showSuccessSnackBar('تم حفظ معلومات المتجر بنجاح');
        // إغلاق النافذة بعد الحفظ بنجاح
        Navigator.pop(context);
      } else {
        _showErrorSnackBar('فشل في حفظ معلومات المتجر');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في حفظ معلومات المتجر: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  /// حذف معلومات المتجر
  Future<void> _deleteStoreInfo() async {
    final confirmed = await _showDeleteConfirmationDialog();
    if (!confirmed) return;

    try {
      final success = await StoreInfoService.deleteStoreInfo();
      if (success) {
        _currentStoreInfo = null;
        _clearFormFields();
        _showSuccessSnackBar('تم حذف معلومات المتجر');
      } else {
        _showErrorSnackBar('فشل في حذف معلومات المتجر');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في حذف معلومات المتجر: $e');
    }
  }

  /// مسح حقول النموذج
  void _clearFormFields() {
    _storeNameController.clear();
    _addressController.clear();
    _phoneController.clear();
    _descriptionController.clear();
  }

  /// عرض رسالة نجاح
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// عرض رسالة خطأ
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// عرض حوار تأكيد الحذف
  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: const Text('هل أنت متأكد من حذف معلومات المتجر؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.errorRed,
                ),
                child: const Text('حذف'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معلومات المحل'),
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          if (_currentStoreInfo != null)
            IconButton(
              onPressed: _deleteStoreInfo,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'حذف معلومات المتجر',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  /// بناء النموذج
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات المحل
            _buildSectionHeader('معلومات المحل'),
            const SizedBox(height: 16),

            // اسم المحل
            _buildTextField(
              controller: _storeNameController,
              label: 'اسم المحل *',
              hint: 'أدخل اسم المحل',
              icon: Icons.store,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'اسم المحل مطلوب';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // العنوان
            _buildTextField(
              controller: _addressController,
              label: 'العنوان *',
              hint: 'أدخل عنوان المحل',
              icon: Icons.location_on,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'العنوان مطلوب';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // رقم الهاتف
            _buildTextField(
              controller: _phoneController,
              label: 'رقم الهاتف *',
              hint: 'أدخل رقم الهاتف',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'رقم الهاتف مطلوب';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // الوصف
            _buildTextField(
              controller: _descriptionController,
              label: 'وصف المحل *',
              hint: 'أدخل وصف مختصر للمحل',
              icon: Icons.info,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'وصف المحل مطلوب';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // أزرار التحكم
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  /// بناء رأس القسم
  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primaryBlue,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyles.heading6.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء حقل النص
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: AppDesignSystem.createInputDecoration(
        hintText: hint,
        labelText: label,
        prefixIcon: icon,
        borderColor: AppColors.borderLight,
        focusColor: AppColors.borderFocus,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: AppTextStyles.body2,
    );
  }

  /// بناء أزرار التحكم
  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveStoreInfo,
        icon: _isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ التغييرات'),
        style: AppDesignSystem.createButtonStyle(
          backgroundColor: AppColors.successGreen,
          foregroundColor: AppColors.white,
        ),
      ),
    );
  }
}
