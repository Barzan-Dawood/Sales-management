import 'package:flutter/material.dart';

class AppUsageGuideScreen extends StatelessWidget {
  final bool showAppBar;

  const AppUsageGuideScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.purple.shade700,
            Colors.purple.shade50,
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
            _buildHeaderCard(),
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
• اذهب إلى الإعدادات
• أدخل اسم المتجر ورقم الهاتف والعنوان
• احفظ المعلومات

**الخطوة 2: إضافة المنتجات**
• اذهب إلى "المنتجات"
• اضغط "إضافة منتج جديد"
• أدخل اسم المنتج والسعر والكمية
• احفظ المنتج

**الخطوة 3: تسجيل أول عملية بيع**
• اذهب إلى "المبيعات"
• اختر المنتجات المطلوبة
• أدخل الكميات
• احفظ العملية
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
3. أدخل التفاصيل: الاسم، السعر، الكمية، الوصف
4. اختر الفئة المناسبة
5. اضغط "حفظ"

**تعديل منتج موجود:**
1. اذهب إلى "المنتجات"
2. اضغط على المنتج المطلوب
3. عدّل المعلومات
4. اضغط "حفظ التغييرات"

**إدارة المخزون:**
• راقب الكميات المتوفرة
• أضف كميات جديدة عند الحاجة
• احذف المنتجات غير المستخدمة
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
3. اختر المورد
4. أضف المنتجات والكميات
5. أدخل أسعار الشراء
6. اضغط "تأكيد الشراء"

**إدارة الموردين:**
• أضف معلومات الموردين
• احفظ بيانات الاتصال
• راقب تاريخ المشتريات

**تحديث المخزون:**
• يتم تحديث المخزون تلقائياً
• راجع الكميات الجديدة
• تأكد من صحة البيانات
''',
            ),
            const SizedBox(height: 20),

            // العملاء والموردين
            _buildGuideSection(
              icon: Icons.people,
              title: 'إدارة العملاء والموردين',
              content: '''
**إضافة عميل جديد:**
1. اذهب إلى "العملاء"
2. اضغط "إضافة عميل"
3. أدخل الاسم ورقم الهاتف
4. أضف العنوان (اختياري)
5. احفظ البيانات

**إضافة مورد جديد:**
1. اذهب إلى "الموردين"
2. اضغط "إضافة مورد"
3. أدخل معلومات المورد
4. احفظ البيانات

**إدارة الديون:**
• راقب ديون العملاء
• سجل المدفوعات
• أضف ديون جديدة عند الحاجة
''',
            ),
            const SizedBox(height: 20),

            // التقارير
            _buildGuideSection(
              icon: Icons.analytics,
              title: 'التقارير والإحصائيات',
              content: '''
**التقارير المتاحة:**
• تقرير المبيعات اليومية
• تقرير المبيعات الشهرية
• تقرير المخزون
• تقرير العملاء
• تقرير الموردين

**كيفية عرض التقارير:**
1. اذهب إلى "التقارير"
2. اختر نوع التقرير
3. حدد الفترة الزمنية
4. اضغط "عرض التقرير"

**تصدير التقارير:**
• يمكن طباعة التقارير
• أو حفظها كملفات
• مشاركتها مع المحاسب
''',
            ),
            const SizedBox(height: 20),

            // النسخ الاحتياطية
            _buildGuideSection(
              icon: Icons.backup,
              title: 'النسخ الاحتياطية',
              content: '''
**إنشاء نسخة احتياطية:**
1. اذهب إلى "الإعدادات"
2. اختر "إدارة البيانات"
3. اضغط "إنشاء نسخة احتياطية"
4. اختر مكان الحفظ
5. انتظر حتى اكتمال العملية

**استعادة البيانات:**
1. اذهب إلى "الإعدادات"
2. اختر "إدارة البيانات"
3. اضغط "استعادة البيانات"
4. اختر الملف المطلوب
5. تأكيد الاستعادة

**نصائح مهمة:**
• أنشئ نسخ احتياطية منتظمة
• احفظ النسخ في مكان آمن
• اختبر النسخ بين الحين والآخر
''',
            ),
            const SizedBox(height: 20),

            // نصائح مفيدة
            _buildGuideSection(
              icon: Icons.lightbulb,
              title: 'نصائح مفيدة',
              content: '''
**للاستخدام الأمثل:**
• استخدم التطبيق يومياً لتسجيل العمليات
• راجع التقارير بانتظام
• احتفظ بنسخ احتياطية حديثة
• نظم المنتجات في فئات واضحة

**لحل المشاكل:**
• تأكد من اتصال الإنترنت للنسخ الاحتياطية
• راجع الإعدادات إذا واجهت مشاكل
• استخدم "إعادة تعيين" بحذر
• تواصل مع الدعم الفني عند الحاجة

**للمحافظة على الأمان:**
• لا تشارك بيانات الدخول
• احتفظ بنسخ احتياطية آمنة
• راجع البيانات بانتظام
• استخدم كلمات مرور قوية
''',
            ),
            const SizedBox(height: 20),

            // معلومات الاتصال
            _buildContactCard(),
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
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text(
              'دليل الاستخدام',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            backgroundColor: Colors.purple.shade700,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
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

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade600, Colors.purple.shade800],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.2),
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
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              'assets/images/pos.png',
              width: 32,
              height: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'دليل استخدام التطبيق',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تعلم كيفية استخدام نظام إدارة المكتب',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.purple.shade100,
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
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.purple.shade600,
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
                    color: Colors.purple.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.blue.shade200,
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
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.contact_support,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'هل تحتاج مساعدة إضافية؟',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
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
              color: Colors.blue.shade700,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
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
              backgroundColor: Colors.purple.shade600,
              foregroundColor: Colors.white,
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
              foregroundColor: Colors.purple.shade600,
              side: BorderSide(color: Colors.purple.shade600),
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
