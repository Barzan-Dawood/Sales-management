// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AppUsageGuideScreen extends StatelessWidget {
  final bool showAppBar;

  const AppUsageGuideScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget content = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.primary,
            scheme.surface,
          ],
          stops: const [0.0, 0.1],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(context),
            const SizedBox(height: 20),

            // مقدمة
            _buildGuideSection(
              icon: Icons.info_outline,
              title: 'مرحباً بك في نظام إدارة المكتب',
              content: '''
هذا الدليل سيساعدك على فهم كيفية استخدام نظام إدارة المكتب بكفاءة. التطبيق مصمم ليكون بسيط وسهل الاستخدام، مع واجهة عربية واضحة.

**المميزات الرئيسية:**
• إدارة المنتجات والمخزون
• تسجيل المبيعات والمشتريات
• إدارة العملاء والموردين
• تقارير مالية شاملة
• نسخ احتياطية آمنة
• واجهة عربية كاملة
''',
            ),
            const SizedBox(height: 20),

            // البدء السريع
            _buildGuideSection(
              icon: Icons.play_arrow,
              title: 'البدء السريع',
              content: '''
**الخطوة 1: إعداد المتجر**
• افتح "الإعدادات" > "معلومات المتجر"
• أدخل اسم المتجر (غير قابل للتعديل لاحقاً) ورقم الهاتف والعنوان
• احفظ المعلومات

**الخطوة 2: إضافة المنتجات**
• اذهب إلى "المنتجات"
• اضغط "إضافة منتج جديد"
• أدخل الاسم، السعر البيع، السعر الشراء (إن وجد)، الكمية، والوصف
• احفظ المنتج

**الخطوة 3: إضافة العملاء (اختياري)**
• اذهب إلى "العملاء" > "إضافة عميل"
• أدخل الاسم ورقم الهاتف والعنوان
• احفظ

**الخطوة 4: أول عملية بيع**
• اذهب إلى "المبيعات"
• اختر المنتجات والكميات
• اختر نوع البيع: نقد/دين/تقسيط
  - نقد: إتمام فوري
  - دين: يُسجل المتبقي على العميل
  - تقسيط: اختر الدفعة الأولى، وسيُحسب المتبقي تلقائياً
• احفظ العملية واطبع الفاتورة (اختياري)
''',
            ),
            const SizedBox(height: 20),

            // إدارة المنتجات
            _buildGuideSection(
              icon: Icons.inventory,
              title: 'إدارة المنتجات والمخزون',
              content: '''
**إضافة منتج جديد:**
1. اذهب إلى "المنتجات"
2. اضغط "إضافة منتج جديد"
3. أدخل: الاسم، السعر البيع، السعر الشراء (اختياري)، الكمية، الوصف، والفئة
4. احفظ

**تعديل منتج موجود:**
1. من "المنتجات" اختر المنتج
2. عدّل المعلومات المطلوبة
3. احفظ التغييرات

**إدارة المخزون:**
• راقب الكميات المتوفرة
• أضف كميات عند التوريد
• يحدث الرصيد تلقائياً بعد كل بيع/شراء
''',
            ),
            const SizedBox(height: 20),

            // المبيعات
            _buildGuideSection(
              icon: Icons.shopping_cart,
              title: 'تسجيل المبيعات',
              content: '''
**عملية بيع جديدة:**
1. اذهب إلى "المبيعات"
2. اضغط "بيع جديد"
3. اختر المنتجات من القائمة
4. أدخل الكمية لكل منتج
5. راجع المجموع الكلي
6. اضغط "تأكيد البيع"

**إدارة العملاء:**
• أضف معلومات العميل (اختياري)
• احفظ بيانات العملاء للاستخدام المستقبلي
• راقب تاريخ المشتريات

**طباعة الفاتورة:**
• بعد تأكيد البيع
• اضغط "طباعة" لطباعة الفاتورة
• أو "حفظ" لحفظ العملية فقط
''',
            ),
            const SizedBox(height: 20),

            // المشتريات
            _buildGuideSection(
              icon: Icons.shopping_bag,
              title: 'تسجيل المشتريات',
              content: '''
**عملية شراء جديدة:**
1. اذهب إلى "المشتريات"
2. اضغط "شراء جديد"
3. اختر المورد (أو أضفه أولاً من قسم الموردين)
4. أضف المنتجات والكميات وأسعار الشراء
5. احفظ العملية

**تحديث المخزون:**
• يتم تحديث المخزون تلقائياً بعد الشراء
''',
            ),
            const SizedBox(height: 20),

            // العملاء والموردين
            _buildGuideSection(
              icon: Icons.people,
              title: 'إدارة العملاء والموردين',
              content: '''
**العملاء:**
• إضافة عميل: الاسم، الهاتف، العنوان
• ربط عملية الدين/التقسيط بالعميل
• متابعة السداد من صفحة العميل

**الموردون:**
• إضافة مورد: الاسم، الهاتف، العنوان
• ربط المشتريات بالمورد
''',
            ),
            const SizedBox(height: 20),

            // التقارير
            _buildGuideSection(
              icon: Icons.analytics,
              title: 'التقارير والإحصائيات',
              content: '''
**التقارير المتاحة:**
• تقرير المبيعات اليومية/الشهرية حسب نوع البيع
• تقرير المخزون والكميات الناقصة
• تقارير العملاء والموردين

**العرض والتصدير:**
1. اذهب إلى "التقارير"
2. اختر نوع التقرير والفترة
3. اعرض/اطبع/احفظ التقرير
''',
            ),
            const SizedBox(height: 20),

            // النسخ الاحتياطية
            _buildGuideSection(
              icon: Icons.backup,
              title: 'النسخ الاحتياطية',
              content: '''
**إنشاء نسخة احتياطية:**
1. اذهب إلى "الإعدادات" > "إدارة البيانات"
2. اختر "إنشاء نسخة احتياطية" وحدد مكان الحفظ

**استعادة البيانات:**
1. من نفس المكان اختر "استعادة البيانات"
2. اختر ملف النسخة الاحتياطية
3. أكد العملية

**نصائح:**
• أنشئ نسخاً منتظمة وخارج الجهاز إن أمكن
• اختبر الاستعادة كل فترة
''',
            ),
            const SizedBox(height: 20),

            // نصائح مفيدة
            _buildGuideSection(
              icon: Icons.lightbulb,
              title: 'نصائح مفيدة',
              content: '''
• سجّل العمليات أولاً بأول لتفادي الأخطاء
• راجع التقارير دورياً لاتخاذ قرارات أفضل
• استخدم البحث والفلاتر لتسريع العمل
• حافظ على تحديث بيانات العملاء والموردين
• فعّل الوضع الليلي حسب تفضيلك من الإعدادات
''',
            ),
            const SizedBox(height: 20),

            // معلومات الاتصال
            _buildContactCard(context),
            const SizedBox(height: 20),

            // أزرار العمل
            _buildActionButtons(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (showAppBar) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: scheme.background,
          appBar: AppBar(
            title: const Text(
              'دليل الاستخدام',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: scheme.onPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: content,
        ),
      );
    } else {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: content,
      );
    }
  }

  Widget _buildHeaderCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primaryContainer],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.onPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              'assets/images/office.png',
              width: 32,
              height: 32,
              color: scheme.onPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'دليل استخدام التطبيق',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تعلم كيفية استخدام نظام إدارة المكتب',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Builder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                    Theme.of(context).brightness == Brightness.dark
                        ? 0.5
                        : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: scheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: scheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: scheme.onSurface,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: scheme.secondary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: scheme.secondary.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.contact_support,
                  color: scheme.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'هل تحتاج مساعدة إضافية؟',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: scheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'إذا كان لديك أي أسئلة أو تحتاج مساعدة إضافية، لا تتردد في التواصل معنا:\n\n📧 البريد الإلكتروني: barzan.dawood.dev@gmail.com\n📱 الواتساب: 07866744144\n📍 العنوان: نينوى - سنجار، العراق\n\nسنكون سعداء لمساعدتك في أي وقت!',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: scheme.secondary,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check),
            label: const Text('فهمت، شكراً'),
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close),
            label: const Text('إغلاق'),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.primary,
              side: BorderSide(color: scheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
