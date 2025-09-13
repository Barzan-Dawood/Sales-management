import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text(
              'سياسة الخصوصية',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade700,
                  Colors.blue.shade50,
                ],
                stops: const [0.0, 0.1],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // مقدمة
                  _buildSection(
                    title: 'مقدمة',
                    content: '''
نحن في نظام إدارة المكتب نحترم خصوصيتك ونلتزم بحماية معلوماتك. هذا التطبيق يستخدم قاعدة بيانات محلية تماماً ولا نجمع أي معلومات شخصية عن المستخدمين.

**مهم جداً:** جميع بياناتك محفوظة محلياً على جهازك فقط ولا يتم إرسالها إلى أي خادم خارجي.

آخر تحديث: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}
              ''',
                  ),

                  // المعلومات التي نجمعها
                  _buildSection(
                    title: 'المعلومات التي نجمعها',
                    content: '''
**لا نجمع أي معلومات شخصية عن المستخدمين!**

هذا التطبيق يعمل بالكامل محلياً:

1. **البيانات المحلية فقط:**
   - بيانات العملاء والموردين (محفوظة على جهازك)
   - معلومات المنتجات والمخزون (محفوظة على جهازك)
   - سجلات المبيعات والمشتريات (محفوظة على جهازك)
   - البيانات المالية والمحاسبية (محفوظة على جهازك)

2. **لا نجمع:**
   - معلومات شخصية عن المستخدم
   - عنوان IP أو معلومات الشبكة
   - معلومات الجهاز أو التطبيق
   - أي بيانات استخدام أو تحليلات

3. **الخصوصية الكاملة:**
   - جميع البيانات محفوظة محلياً فقط
   - لا توجد اتصالات خارجية
   - لا توجد تتبع أو مراقبة
              ''',
                  ),

                  // كيفية استخدام المعلومات
                  _buildSection(
                    title: 'كيفية استخدام المعلومات',
                    content: '''
**لا نستخدم أي معلومات شخصية لأننا لا نجمعها!**

التطبيق يعمل بالكامل محلياً:

1. **البيانات المحلية:**
   - جميع البيانات محفوظة على جهازك فقط
   - لا يتم إرسال أي شيء إلى خوادم خارجية
   - أنت تتحكم بالكامل في بياناتك

2. **لا توجد استخدامات خارجية:**
   - لا توجد تحليلات أو إحصائيات
   - لا توجد تتبع أو مراقبة
   - لا توجد مشاركة مع أطراف ثالثة

3. **الخصوصية المطلقة:**
   - بياناتك تبقى على جهازك فقط
   - لا يمكن لأحد الوصول إليها
   - أنت المالك الوحيد لبياناتك
              ''',
                  ),

                  // مشاركة المعلومات
                  _buildSection(
                    title: 'مشاركة المعلومات',
                    content: '''
**لا نشارك أي معلومات لأننا لا نجمعها أصلاً!**

هذا التطبيق محلي بالكامل:

1. **لا توجد مشاركة:**
   - لا نشارك أي معلومات شخصية
   - لا نبيع أو نؤجر البيانات
   - لا توجد خدمات خارجية

2. **البيانات محلية فقط:**
   - جميع البيانات على جهازك فقط
   - لا توجد نسخ احتياطية سحابية
   - لا توجد اتصالات خارجية

3. **الخصوصية الكاملة:**
   - بياناتك تبقى خاصة بك
   - لا يمكن لأحد الوصول إليها
   - أنت تتحكم بالكامل في بياناتك
              ''',
                  ),

                  // حماية البيانات
                  _buildSection(
                    title: 'حماية البيانات',
                    content: '''
**حماية البيانات محلية بالكامل:**

1. **التخزين المحلي:**
   - جميع البيانات محفوظة على جهازك فقط
   - لا توجد اتصالات خارجية
   - لا توجد مخاطر أمنية خارجية

2. **النسخ الاحتياطية المحلية:**
   - يمكنك إنشاء نسخ احتياطية محلية
   - تخزين آمن على جهازك
   - إمكانية الاستعادة المحلية

3. **التحكم الكامل:**
   - أنت تتحكم في جميع بياناتك
   - لا يمكن لأحد الوصول إليها
   - الخصوصية مضمونة 100%
              ''',
                  ),

                  // حقوقك
                  _buildSection(
                    title: 'حقوقك',
                    content: '''
لديك الحق في:

1. **الوصول:**
   - طلب نسخة من بياناتك
   - معرفة كيفية استخدامها
   - مراجعة المعلومات المحفوظة

2. **التصحيح:**
   - تصحيح البيانات الخاطئة
   - تحديث المعلومات
   - إكمال البيانات الناقصة

3. **الحذف:**
   - طلب حذف بياناتك
   - إلغاء الحساب
   - إزالة المعلومات الشخصية

4. **النقل:**
   - تصدير بياناتك
   - نقلها إلى نظام آخر
   - تنسيق قابل للقراءة
              ''',
                  ),

                  // ملفات تعريف الارتباط
                  _buildSection(
                    title: 'ملفات تعريف الارتباط والتقنيات المماثلة',
                    content: '''
نستخدم تقنيات مماثلة لملفات تعريف الارتباط:

1. **التخزين المحلي:**
   - حفظ الإعدادات
   - تحسين الأداء
   - تذكر التفضيلات

2. **التحليلات:**
   - فهم كيفية الاستخدام
   - تحسين التطبيق
   - إصلاح المشاكل

يمكنك إدارة هذه الإعدادات من خلال إعدادات التطبيق.
              ''',
                  ),

                  // الاحتفاظ بالبيانات
                  _buildSection(
                    title: 'الاحتفاظ بالبيانات',
                    content: '''
نحتفظ ببياناتك طالما:

1. **حسابك نشط:**
   - طالما تستخدم التطبيق
   - للوصول للخدمات
   - لتحسين التجربة

2. **المتطلبات القانونية:**
   - حسب القوانين المحلية
   - للضرائب والمحاسبة
   - لحل النزاعات

3. **النسخ الاحتياطية:**
   - لفترة محدودة
   - للأمان والاستعادة
   - ثم الحذف التلقائي
              ''',
                  ),

                  // التحديثات
                  _buildSection(
                    title: 'تحديثات سياسة الخصوصية',
                    content: '''
قد نحدث هذه السياسة من وقت لآخر:

1. **الإشعار:**
   - سنخبرك بالتغييرات المهمة
   - عبر التطبيق أو البريد الإلكتروني
   - قبل تطبيق التغييرات

2. **المراجعة:**
   - ننصح بمراجعة السياسة دورياً
   - تاريخ آخر تحديث في الأعلى
   - نسخة محدثة متاحة دائماً

3. **الموافقة:**
   - الاستمرار في الاستخدام يعني الموافقة
   - يمكنك إلغاء الحساب إذا لم توافق
   - نحترم اختيارك دائماً
              ''',
                  ),

                  // التواصل معنا
                  _buildSection(
                    title: 'التواصل معنا',
                    content: '''
لأي أسئلة حول سياسة الخصوصية:

📧 البريد الإلكتروني: barzan.dawood.dev@gmail.com
📞 الهاتف: +964 786 674 4144
🌐 الموقع: www.office-management.com
📍 العنوان: جمهورية العراق

نحن ملتزمون بالرد على استفساراتك في أقرب وقت ممكن.
              ''',
                  ),

                  const SizedBox(height: 20),

                  // تأكيد الطبيعة المحلية
                  Card(
                    elevation: 3,
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.security,
                                  color: Colors.green.shade600),
                              const SizedBox(width: 8),
                              Text(
                                'تأكيد الخصوصية الكاملة',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '✅ جميع بياناتك محفوظة محلياً على جهازك فقط\n'
                            '✅ لا توجد اتصالات خارجية أو خوادم\n'
                            '✅ لا نجمع أي معلومات شخصية عنك\n'
                            '✅ لا توجد تتبع أو مراقبة\n'
                            '✅ الخصوصية مضمونة 100%\n'
                            '✅ أنت المالك الوحيد لبياناتك',
                            style: TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // معلومات إضافية
                  Card(
                    elevation: 2,
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue.shade600),
                              const SizedBox(width: 8),
                              Text(
                                'معلومات مهمة',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• هذه السياسة تنطبق على جميع مستخدمي التطبيق\n'
                            '• نحن ملتزمون بحماية خصوصيتك\n'
                            '• يمكنك مراجعة هذه السياسة في أي وقت\n'
                            '• للأسئلة العاجلة، تواصل معنا مباشرة',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // أزرار العمل
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TermsConditionsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.description),
                          label: const Text('شروط الاستخدام'),
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
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildSection({required String title, required String content}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// شاشة شروط الاستخدام
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شروط الاستخدام'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // مقدمة
            _buildSection(
              title: 'مقدمة',
              content: '''
مرحباً بك في نظام إدارة المكتب. باستخدامك لهذا التطبيق، فإنك توافق على الالتزام بشروط الاستخدام هذه.

**مهم:** هذا التطبيق يعمل محلياً بالكامل ولا يتطلب اتصال بالإنترنت.

آخر تحديث: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}
              ''',
            ),

            // قبول الشروط
            _buildSection(
              title: 'قبول الشروط',
              content: '''
باستخدام التطبيق، فإنك:

1. **توافق على:**
   - جميع شروط الاستخدام
   - سياسة الخصوصية
   - أي تحديثات مستقبلية

2. **تؤكد أنك:**
   - لديك الصلاحية للاتفاق
   - تفهم الشروط والأحكام
   - ستلتزم بها

3. **إذا لم توافق:**
   - لا تستخدم التطبيق
   - أوقف الحساب فوراً
   - احذف التطبيق
              ''',
            ),

            // استخدام التطبيق
            _buildSection(
              title: 'استخدام التطبيق',
              content: '''
يمكنك استخدام التطبيق لـ:

1. **الأغراض المسموحة:**
   - إدارة أعمالك التجارية
   - تنظيم البيانات المالية
   - إنشاء التقارير

2. **الأغراض المحظورة:**
   - الأنشطة غير القانونية
   - انتهاك حقوق الآخرين
   - إلحاق الضرر بالخدمة

3. **الالتزامات:**
   - استخدام صحيح ومسؤول
   - حماية كلمة المرور
   - عدم مشاركة الحساب
              ''',
            ),

            // الحساب والمسؤولية
            _buildSection(
              title: 'الحساب والمسؤولية',
              content: '''
أنت مسؤول عن:

1. **حسابك:**
   - صحة المعلومات المدخلة
   - حماية كلمة المرور
   - جميع الأنشطة من حسابك

2. **البيانات:**
   - دقة البيانات المدخلة
   - النسخ الاحتياطية
   - حماية المعلومات الحساسة

3. **الاستخدام:**
   - الاستخدام القانوني فقط
   - عدم إساءة الاستخدام
   - احترام حقوق الآخرين
              ''',
            ),

            // الملكية الفكرية
            _buildSection(
              title: 'الملكية الفكرية',
              content: '''
جميع الحقوق محفوظة:

1. **التطبيق:**
   - مملوك لنا بالكامل
   - محمي بحقوق الطبع والنشر
   - لا يجوز نسخه أو توزيعه

2. **المحتوى:**
   - البرمجيات والكود
   - التصميم والواجهة
   - الوثائق والمساعدة

3. **العلامات التجارية:**
   - أسماء المنتجات
   - الشعارات والرموز
   - العلامات التجارية
              ''',
            ),

            // الخدمة والدعم
            _buildSection(
              title: 'الخدمة والدعم',
              content: '''
نحن نقدم:

1. **الخدمة:**
   - "كما هي" بدون ضمانات
   - قد تكون هناك انقطاعات
   - نعمل على التحسين المستمر

2. **الدعم:**
   - خلال ساعات العمل
   - عبر القنوات المحددة
   - حسب الإمكانيات المتاحة

3. **التحديثات:**
   - تحسينات دورية
   - إصلاح الأخطاء
   - ميزات جديدة
              ''',
            ),

            // الإلغاء والإنهاء
            _buildSection(
              title: 'الإلغاء والإنهاء',
              content: '''
يمكن إنهاء الخدمة:

1. **من جانبك:**
   - في أي وقت
   - عبر إعدادات التطبيق
   - أو التواصل معنا

2. **من جانبنا:**
   - في حالة انتهاك الشروط
   - لأسباب فنية
   - مع إشعار مسبق

3. **الآثار:**
   - توقف الوصول للخدمة
   - إمكانية تصدير البيانات
   - حذف الحساب نهائياً
              ''',
            ),

            // المسؤولية القانونية
            _buildSection(
              title: 'المسؤولية القانونية',
              content: '''
نحن غير مسؤولين عن:

1. **الخسائر:**
   - خسائر مالية أو تجارية
   - فقدان البيانات
   - انقطاع الخدمة

2. **الضرر:**
   - ضرر مباشر أو غير مباشر
   - خسائر عرضية
   - أضرار خاصة

3. **الحدود:**
   - المسؤولية محدودة
   - حسب القانون المحلي
   - في حدود الإمكانيات
              ''',
            ),

            // القانون الحاكم
            _buildSection(
              title: 'القانون الحاكم',
              content: '''
تخضع هذه الشروط لـ:

1. **القانون العراقي:**
   - حسب قوانين جمهورية العراق
   - المحاكم العراقية
   - الدستور العراقي

2. **حل النزاعات:**
   - التفاوض أولاً
   - التحكيم إذا لزم الأمر
   - المحاكم العراقية المختصة

3. **اللغة:**
   - النسخة العربية هي الأساس
   - أي ترجمات للتوضيح فقط
   - في حالة التعارض، العربية أولاً
              ''',
            ),

            const SizedBox(height: 20),

            // أزرار العمل
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.privacy_tip),
                    label: const Text('سياسة الخصوصية'),
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
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
