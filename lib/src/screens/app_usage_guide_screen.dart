// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AppUsageGuideScreen extends StatefulWidget {
  final bool showAppBar;

  const AppUsageGuideScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<AppUsageGuideScreen> createState() => _AppUsageGuideScreenState();
}

class _AppUsageGuideScreenState extends State<AppUsageGuideScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, GlobalKey> _sectionKeys = {};
  late List<_GuideSectionData> _allSections;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _allSections = [
      _GuideSectionData(
        icon: Icons.info_outline,
        title: 'مرحباً بك في نظام إدارة المكتب',
        content:
            'هذا الدليل سيساعدك على فهم كيفية استخدام نظام إدارة المكتب بكفاءة. التطبيق مصمم ليكون بسيط وسهل الاستخدام، مع واجهة عربية واضحة.\n\nالمميزات الرئيسية:\n• إدارة المنتجات والمخزون\n• تسجيل المبيعات والمشتريات\n• إدارة العملاء والموردين\n• تقارير مالية شاملة\n• نسخ احتياطية آمنة\n• واجهة عربية كاملة',
      ),
      _GuideSectionData(
        icon: Icons.play_arrow,
        title: 'البدء السريع',
        content:
            'الخطوة 1: إعداد المتجر\n• افتح "الإعدادات" > "معلومات المتجر"\n• أدخل اسم المتجر (غير قابل للتعديل لاحقاً) ورقم الهاتف والعنوان\n• احفظ المعلومات\n\nالخطوة 2: إضافة المنتجات\n• اذهب إلى "المنتجات"\n• اضغط "إضافة منتج جديد"\n• أدخل الاسم، سعر البيع، سعر الشراء (إن وجد)، الكمية، والوصف\n• احفظ المنتج\n\nالخطوة 3: إضافة العملاء (اختياري)\n• اذهب إلى "العملاء" > "إضافة عميل"\n• أدخل الاسم ورقم الهاتف والعنوان\n• احفظ\n\nالخطوة 4: أول عملية بيع\n• اذهب إلى "المبيعات"\n• اختر المنتجات والكميات\n• اختر نوع البيع: نقد / دين / تقسيط\n  - نقد: إتمام فوري\n  - دين: يُسجل المتبقي على العميل\n  - تقسيط: اختر الدفعة الأولى، وسيُحسب المتبقي تلقائياً\n• احفظ العملية واطبع الفاتورة (اختياري)',
      ),
      _GuideSectionData(
        icon: Icons.inventory,
        title: 'إدارة المنتجات والمخزون',
        content:
            'إضافة منتج جديد:\n1. اذهب إلى "المنتجات"\n2. اضغط "إضافة منتج جديد"\n3. أدخل: الاسم، سعر البيع، سعر الشراء (اختياري)، الكمية، الوصف، والفئة\n4. احفظ\n\nتعديل منتج موجود:\n1. من "المنتجات" اختر المنتج\n2. عدّل المعلومات المطلوبة\n3. احفظ التغييرات\n\nإدارة المخزون:\n• راقب الكميات المتوفرة\n• أضف كميات عند التوريد\n• يحدث الرصيد تلقائياً بعد كل بيع/شراء',
      ),
      _GuideSectionData(
        icon: Icons.shopping_cart,
        title: 'تسجيل المبيعات',
        content:
            'عملية بيع جديدة:\n1. اذهب إلى "المبيعات"\n2. اضغط "بيع جديد"\n3. اختر المنتجات من القائمة\n4. أدخل الكمية لكل منتج\n5. راجع المجموع الكلي\n6. اضغط "تأكيد البيع"\n\nإدارة العملاء:\n• أضف معلومات العميل (اختياري)\n• احفظ بيانات العملاء للاستخدام المستقبلي\n• راقب تاريخ المشتريات\n\nطباعة الفاتورة:\n• بعد تأكيد البيع\n• اضغط "طباعة" لطباعة الفاتورة\n• أو "حفظ" لحفظ العملية فقط',
      ),
      _GuideSectionData(
        icon: Icons.shopping_bag,
        title: 'تسجيل المشتريات',
        content:
            'عملية شراء جديدة:\n1. اذهب إلى "المشتريات"\n2. اضغط "شراء جديد"\n3. اختر المورد (أو أضفه أولاً من قسم الموردين)\n4. أضف المنتجات والكميات وأسعار الشراء\n5. احفظ العملية\n\nتحديث المخزون:\n• يتم تحديث المخزون تلقائياً بعد الشراء',
      ),
      _GuideSectionData(
        icon: Icons.people,
        title: 'إدارة العملاء والموردين',
        content:
            'العملاء:\n• إضافة عميل: الاسم، الهاتف، العنوان\n• ربط عملية الدين/التقسيط بالعميل\n• متابعة السداد من صفحة العميل\n\nالموردون:\n• إضافة مورد: الاسم، الهاتف، العنوان\n• ربط المشتريات بالمورد',
      ),
      _GuideSectionData(
        icon: Icons.analytics,
        title: 'التقارير والإحصائيات',
        content:
            'التقارير المتاحة:\n• تقرير المبيعات اليومية/الشهرية حسب نوع البيع\n• تقرير المخزون والكميات الناقصة\n• تقارير العملاء والموردين\n\nالعرض والتصدير:\n1. اذهب إلى "التقارير"\n2. اختر نوع التقرير والفترة\n3. اعرض / اطبع / احفظ التقرير',
      ),
      _GuideSectionData(
        icon: Icons.backup,
        title: 'النسخ الاحتياطية',
        content:
            'إنشاء نسخة احتياطية:\n1. اذهب إلى "الإعدادات" > "إدارة البيانات"\n2. اختر "إنشاء نسخة احتياطية" وحدد مكان الحفظ\n\nاستعادة البيانات:\n1. من نفس المكان اختر "استعادة البيانات"\n2. اختر ملف النسخة الاحتياطية\n3. أكد العملية\n\nنصائح:\n• أنشئ نسخاً منتظمة وخارج الجهاز إن أمكن\n• اختبر الاستعادة كل فترة',
      ),
      _GuideSectionData(
        icon: Icons.lightbulb,
        title: 'نصائح مفيدة',
        content:
            '• سجّل العمليات أولاً بأول لتفادي الأخطاء\n• راجع التقارير دورياً لاتخاذ قرارات أفضل\n• استخدم البحث والفلاتر لتسريع العمل\n• حافظ على تحديث بيانات العملاء والموردين\n• فعّل الوضع الليلي حسب تفضيلك من الإعدادات',
      ),
      _GuideSectionData(
        icon: Icons.login,
        title: 'تسجيل الدخول والأمان',
        content:
            'نظام تسجيل الدخول يحمي بياناتك ويضمن الأمان:\n\nتسجيل الدخول:\n• أدخل اسم المستخدم وكلمة المرور\n• اختر "تذكرني" للدخول التلقائي\n• استخدم كلمات مرور قوية\n• لا تشارك بيانات الدخول\n\nالأمان:\n• تشفير كلمات المرور\n• حماية الجلسات\n• تسجيل عمليات الدخول\n• مراقبة النشاط المشبوه\n\nإدارة المستخدمين:\n• إنشاء مستخدمين جدد\n• تعديل صلاحيات المستخدمين\n• حذف المستخدمين غير النشطين\n• مراقبة نشاط المستخدمين\n\nنصائح الأمان:\n• استخدم كلمات مرور معقدة\n• غيّر كلمة المرور بانتظام\n• لا تترك الجهاز مفتوحاً\n• سجّل الخروج عند الانتهاء\n• راقب نشاط الحساب',
      ),
      _GuideSectionData(
        icon: Icons.help_outline,
        title: 'الأسئلة الشائعة',
        content:
            'إجابات على الأسئلة الأكثر شيوعاً:\n\nس: كيف أضيف منتج جديد؟\nج: اذهب إلى "المنتجات" > "إضافة منتج" > أدخل البيانات > احفظ\n\nس: كيف أطبع فاتورة؟\nج: بعد إنهاء البيع > اضغط "طباعة" > تأكد من إعداد الطابعة\n\nس: كيف أنشئ نسخة احتياطية؟\nج: الإعدادات > إعدادات قاعدة البيانات > إنشاء نسخة احتياطية\n\nس: كيف أضيف عميل جديد؟\nج: اذهب إلى "العملاء" > "إضافة عميل" > أدخل البيانات > احفظ\n\nس: كيف أرى تقرير المبيعات؟\nج: اذهب إلى "التقارير" > اختر نوع التقرير والفترة > اعرض\n\nس: كيف أغير كلمة المرور؟\nج: الإعدادات > إدارة المستخدمين > اختر المستخدم > تعديل\n\nس: كيف أضيف مورد جديد؟\nج: اذهب إلى "الموردين" > "إضافة مورد" > أدخل البيانات > احفظ\n\nس: كيف أستعيد البيانات؟\nج: الإعدادات > إعدادات قاعدة البيانات > استعادة > اختر الملف\n\nنصائح إضافية:\n• استخدم البحث في الدليل للعثور على مواضيع محددة\n• تواصل مع الدعم الفني عند الحاجة\n• راجع الدليل بانتظام للتعرف على الميزات الجديدة',
      ),
      _GuideSectionData(
        icon: Icons.keyboard,
        title: 'اختصارات لوحة المفاتيح',
        content:
            'اختصارات مفيدة لتسريع العمل:\n\nالاختصارات العامة:\n• Ctrl + N: إضافة جديد\n• Ctrl + S: حفظ\n• Ctrl + F: بحث\n• Ctrl + P: طباعة\n• Ctrl + Z: تراجع\n• Ctrl + Y: إعادة\n• F5: تحديث\n• Esc: إلغاء/إغلاق\n\nاختصارات التنقل:\n• Tab: الانتقال للحقل التالي\n• Shift + Tab: الانتقال للحقل السابق\n• Enter: تأكيد/حفظ\n• Space: تحديد/إلغاء تحديد\n\nاختصارات المبيعات:\n• Ctrl + B: بيع جديد\n• Ctrl + I: فاتورة جديدة\n• Ctrl + R: إرجاع\n• Ctrl + T: طباعة الفاتورة\n\nاختصارات المنتجات:\n• Ctrl + P: إضافة منتج\n• Ctrl + E: تعديل المنتج\n• Ctrl + D: حذف المنتج\n• Ctrl + C: نسخ المنتج\n\nاختصارات التقارير:\n• Ctrl + R: تقرير سريع\n• Ctrl + E: تصدير التقرير\n• Ctrl + P: طباعة التقرير\n• F1: مساعدة\n\nنصائح للاستخدام:\n• تعلم الاختصارات تدريجياً\n• استخدم الاختصارات لتسريع العمل\n• احفظ الاختصارات المهمة\n• استخدم F1 للحصول على المساعدة',
      ),
      _GuideSectionData(
        icon: Icons.tips_and_updates,
        title: 'نصائح متقدمة للاستخدام',
        content:
            'نصائح متقدمة لتحسين استخدامك للتطبيق:\n\nتنظيم البيانات:\n• استخدم تصنيفات واضحة للمنتجات\n• احتفظ ببيانات عملاء محدثة\n• نظم الموردين حسب الأولوية\n• استخدم أوصاف مفصلة للمنتجات\n\nتحسين الأداء:\n• احذف البيانات القديمة غير المهمة\n• نظف قاعدة البيانات بانتظام\n• استخدم النسخ الاحتياطية\n• راقب مساحة التخزين\n\nإدارة المبيعات:\n• استخدم أنواع البيع المناسبة\n• راقب الديون بانتظام\n• أرسل تذكيرات للعملاء\n• احتفظ بسجلات دقيقة\n\nالتقارير والتحليل:\n• راجع التقارير يومياً\n• قارن الأداء عبر الفترات\n• استخدم البيانات لاتخاذ القرارات\n• شارك التقارير مع الفريق\n\nالأمان والنسخ الاحتياطي:\n• أنشئ نسخ احتياطية منتظمة\n• احتفظ بالنسخ في أماكن آمنة\n• اختبر استعادة البيانات\n• راقب نشاط المستخدمين\n\nنصائح إضافية:\n• استخدم الميزات الجديدة\n• تواصل مع الدعم عند الحاجة\n• شارك الملاحظات مع المطورين\n• ابق على اطلاع بالتحديثات',
      ),
      _GuideSectionData(
        icon: Icons.menu_book,
        title: 'كيفية الاستخدام بالتفصيل',
        content:
            'هذا القسم يشرح استخدام التطبيق خطوة بخطوة بالتفصيل:\n\n1) إعداد النظام لأول مرة:\n• أدخل معلومات المتجر من الإعدادات\n• حدِّد الشعار والبيانات الظاهرة في الفاتورة\n\n2) تهيئة البيانات الأساسية:\n• أضف الأقسام والفئات إن لزم\n• أضف الموردين والعملاء\n\n3) إدارة المنتجات والمخزون:\n• إضافة/تعديل/بحث عن المنتجات\n• ضبط الكميات وأسعار البيع والشراء\n• تتبُّع النواقص وتعديل الرصيد بعد الشراء\n\n4) دورة البيع:\n• إنشاء فاتورة جديدة من صفحة المبيعات\n• اختيار نوع الدفع: نقد/دين/تقسيط\n• طباعة أو حفظ الفاتورة\n\n5) دورة الشراء:\n• تسجيل طلبات الشراء وربطها بالمورد\n• تحديث الكميات تلقائياً\n\n6) إدارة الديون والتقسيط:\n• متابعة العملاء ذوي الذمم\n• تسجيل الدفعات وجدولة الأقساط\n\n7) التقارير:\n• تصفية حسب التاريخ ونوع العملية\n• طباعة/تصدير التقارير\n\n8) النسخ الاحتياطي والاستعادة:\n• إنشاء نسخة احتياطية دورية\n• استعادة البيانات عند الحاجة\n\nنصيحة: استخدم مربع البحث في أعلى الدليل للعثور بسرعة على أي موضوع.',
      ),
      _GuideSectionData(
        icon: Icons.star_border,
        title: 'المميزات',
        content:
            '• واجهة عربية كاملة وسهلة الاستخدام\n• إدارة المنتجات والمخزون مع تتبُّع الكميات\n• نظام مبيعات يدعم النقد، الدين، والتقسيط\n• إدارة العملاء والموردين والسجلات المرتبطة\n• تقارير تفصيلية (مبيعات، مخزون، عملاء، موردون)\n• دعم الطباعة للفواتير والتقارير\n• نسخ احتياطية واستعادة البيانات بسهولة\n• وضع ليلي/فاتح وتخصيص المظهر\n• يعمل محلياً دون الحاجة للإنترنت',
      ),
      _GuideSectionData(
        icon: Icons.new_releases,
        title: 'ميزات جديدة',
        content:
            'ما الجديد في الإصدار الحالي (1.3):\n\n• واجهة إعدادات محسنة: تصميم جديد مع أقسام منظمة\n• الوضع المظلم: دعم كامل للوضع المظلم مع تخصيص الألوان\n• إدارة المستخدمين: نظام صلاحيات متقدم للمديرين والمشرفين\n• نظام الترخيص: فحص وإدارة مفاتيح الترخيص\n• دليل استخدام تفاعلي: دليل شامل مع فهرس وبحث\n• تحسينات قاعدة البيانات: أداء أفضل واستعلامات محسنة\n• نسخ احتياطية ذكية: نسخ تلقائية مع جدولة مرنة\n\nتلميح: راجع قسم التقارير لاستكشاف قدرات التحليل الجديدة.',
      ),
      _GuideSectionData(
        icon: Icons.free_breakfast,
        title: 'الفترة المجانية والتجربة',
        content:
            'نظام التجربة المجانية:\n\n• فترة تجريبية: 30 يوم مجاني كامل الميزات\n• بدون قيود: جميع الميزات متاحة خلال الفترة التجريبية\n• تنبيهات تذكيرية: إشعارات قبل انتهاء الفترة\n• انتقال سلس: تحويل سهل إلى النسخة المدفوعة\n\nكيفية البدء:\n1. قم بتثبيت التطبيق\n2. ستبدأ الفترة التجريبية تلقائياً\n3. استمتع بجميع الميزات مجاناً\n4. احصل على مفتاح الترخيص عند الحاجة\n\nمزايا الفترة المجانية:\n• تجربة كاملة لجميع الميزات\n• بيانات محفوظة عند الترقية\n• دعم فني متاح\n• لا توجد التزامات مالية\n\nنصائح مهمة:\n• استخدم الفترة التجريبية لاختبار جميع الميزات\n• احتفظ بنسخ احتياطية من بياناتك\n• تواصل معنا للحصول على مفتاح الترخيص',
      ),
      _GuideSectionData(
        icon: Icons.update,
        title: 'التحديثات الأخيرة',
        content:
            'التحديثات في الإصدار 1.3:\n\nتحسينات الواجهة:\n• تصميم جديد للإعدادات مع أقسام منظمة\n• تحسين تجربة المستخدم في جميع الشاشات\n• دعم أفضل للوضع المظلم\n• تحسين الاستجابة والتفاعل\n\nميزات الأمان:\n• نظام صلاحيات متقدم للمستخدمين\n• تشفير محسن للبيانات الحساسة\n• حماية أفضل من النسخ غير المصرح بها\n• مراقبة النشاط والعمليات\n\nتحسينات الأداء:\n• استعلامات قاعدة بيانات محسنة\n• تحميل أسرع للقوائم والبيانات\n• استهلاك ذاكرة أقل\n• استجابة أسرع للعمليات\n\nميزات جديدة:\n• دليل استخدام تفاعلي مع بحث\n• نسخ احتياطية تلقائية ذكية\n• إدارة متقدمة للمستخدمين\n• نظام ترخيص محسن\n\nإصلاحات الأخطاء:\n• حل مشاكل استقرار قاعدة البيانات\n• إصلاح مشاكل الطباعة\n• تحسين معالجة الأخطاء\n• إصلاح مشاكل الذاكرة',
      ),
      _GuideSectionData(
        icon: Icons.rocket_launch,
        title: 'الميزات المتقدمة الجديدة',
        content:
            'الميزات المتقدمة المضافة حديثاً:\n\nنظام إدارة المستخدمين:\n• إنشاء مستخدمين متعددين مع أدوار مختلفة\n• صلاحيات مخصصة لكل مستخدم\n• مراقبة نشاط المستخدمين\n• تسجيل عمليات الدخول والخروج\n\nنظام الترخيص الذكي:\n• فحص تلقائي لصحة الترخيص\n• تجديد تلقائي للتراخيص\n• إشعارات قبل انتهاء الترخيص\n• دعم للتراخيص المؤسسية\n\nالنسخ الاحتياطية الذكية:\n• نسخ تلقائية حسب الجدولة\n• ضغط البيانات لتوفير المساحة\n• تشفير النسخ الاحتياطية\n• استعادة انتقائية للبيانات\n\nتحليلات متقدمة:\n• تقارير أداء مفصلة\n• إحصائيات استخدام الميزات\n• تحليل أنماط المبيعات\n• تنبؤات المخزون\n\nواجهة محسنة:\n• تخصيص الألوان والثيمات\n• دعم أفضل للشاشات المختلفة\n• تحسين إمكانية الوصول\n• تجربة مستخدم محسنة\n\nنصائح للاستفادة القصوى:\n• استخدم الميزات المتقدمة لتحسين الإنتاجية\n• راجع التقارير بانتظام لاتخاذ قرارات أفضل\n• استفد من النسخ الاحتياطية التلقائية\n• استخدم نظام المستخدمين لإدارة الفريق',
      ),
      _GuideSectionData(
        icon: Icons.storage_rounded,
        title: 'إعدادات قاعدة البيانات (متقدم)',
        content:
            'النسخ الاحتياطي:\n1) من الإعدادات > إعدادات قاعدة البيانات\n2) اختر "إدارة النسخ الاحتياطية"\n3) حدِّد موقع الحفظ بانتظام (خارجي إن أمكن)\n\nالاستعادة:\n1) من نفس الصفحة اختر "استعادة"\n2) اختر ملف النسخة\n3) أكّد التنفيذ\n\nأفضل الممارسات:\n• خذ نسخة قبل التحديثات والتغييرات الكبيرة\n• لا تُغلق التطبيق أثناء النسخ/الاستعادة\n• اختبر الاستعادة بشكل دوري\n\nحل مشاكل شائعة:\n• database is locked: أغلق النوافذ/العمليات المفتوحة ثم أعد المحاولة\n• no such table: شغّل تهيئة القاعدة أو أعد تشغيل التطبيق ثم استعادة نسخة',
      ),
      _GuideSectionData(
        icon: Icons.vpn_key,
        title: 'إدارة الترخيص',
        content:
            'التحقق من الترخيص:\n• من الإعدادات > معلومات التطبيق > فحص الترخيص\n\nإدخال/تحديث المفتاح:\n1) افتح "فحص الترخيص"\n2) أدخل المفتاح\n3) احفظ\n\nأخطاء شائعة:\n• مفتاح غير صالح: تحقق من النسخ والصياغة\n• مفتاح منتهي: تواصل مع الدعم للتجديد\n\nنصيحة: احتفظ بالمفتاح في مكان آمن واستخدم البريد الرسمي فقط للتبادل.',
      ),
      _GuideSectionData(
        icon: Icons.print,
        title: 'الطباعة وإعداد الفواتير',
        content:
            'إعداد الطابعة:\n• ثبِّت الطابعة على النظام وشغِّلها\n• اختبر الطباعة من النظام أولاً\n\nطباعة الفاتورة:\n1) بعد حفظ البيع\n2) اختر "طباعة"\n3) تأكد من المقاسات والهوامش\n\nحل المشاكل:\n• الطابعة غير ظاهرة: تأكد من تعريفها بنظام التشغيل\n• خطوط عربية: تأكد من الخطوط المضمنة ودعم UTF-8\n\nنصيحة: جرّب معاينة PDF قبل الإرسال للطابعة.',
      ),
      _GuideSectionData(
        icon: Icons.science,
        title: 'شاشة الاختبارات',
        content:
            'الهدف:\n• التحقق من سلامة الميزات الرئيسية\n\nالأنواع:\n• جميع الاختبارات: شامل وقد يستغرق وقتاً أطول\n• قاعدة البيانات: صحة الجداول والعمليات\n• واجهة المستخدم: سلوك المكونات الأساسية\n• الخدمات: الطباعة والنسخ الاحتياطي\n\nمتى أستخدمها؟\n• بعد التحديثات أو تغييرات كبيرة\n• عند ظهور سلوك غير متوقع.',
      ),
      _GuideSectionData(
        icon: Icons.troubleshoot,
        title: 'استكشاف الأخطاء الشائعة',
        content:
            'database is locked:\n• أغلق النوافذ التي تستخدم القاعدة\n• انتظر ثوانٍ ثم أعد المحاولة\n\nno such table:\n• أعد تشغيل التطبيق\n• استعادة نسخة احتياطية سليمة\n\nلا تظهر الطابعة:\n• تحقق من تعريف الطابعة على النظام\n• جرّب الطباعة إلى PDF\n\nمشاكل ترخيص:\n• تحقق من صحة المفتاح والاتصال المحلي\n• تواصل مع الدعم إذا استمر الخطأ.',
      ),
      _GuideSectionData(
        icon: Icons.security,
        title: 'الميزات الجدية والأمان',
        content:
            'إدارة المستخدمين والصلاحيات:\n• نظام الأدوار: مدير، مشرف، موظف مع صلاحيات مختلفة\n• التحكم في الوصول: تحديد ما يمكن لكل مستخدم الوصول إليه\n• تسجيل الدخول الآمن: حماية كلمات المرور والجلسات\n• مراقبة النشاط: تتبع عمليات المستخدمين المهمة\n\nنظام الترخيص:\n• فحص الترخيص: التحقق من صحة مفاتيح الترخيص\n• إدارة المفاتيح: إضافة وتحديث مفاتيح الترخيص\n• التجربة المجانية: فترة تجريبية محدودة للمستخدمين الجدد\n• التفعيل الآمن: حماية من النسخ غير المصرح بها\n\nحماية البيانات:\n• تشفير قاعدة البيانات: حماية البيانات الحساسة\n• نسخ احتياطية مشفرة: حماية النسخ الاحتياطية\n• الخصوصية: عدم مشاركة البيانات مع أطراف ثالثة\n• الامتثال: اتباع معايير حماية البيانات المحلية',
      ),
      _GuideSectionData(
        icon: Icons.settings,
        title: 'إعدادات النظام المتقدمة',
        content:
            'إعدادات المظهر:\n• الوضع المظلم: تبديل بين الوضع الفاتح والمظلم\n• نمط التطبيق: اختيار بين اتباع النظام أو الوضع الثابت\n• تخصيص الألوان: تغيير ألوان الواجهة حسب التفضيل\n\nإعدادات قاعدة البيانات:\n• النسخ الاحتياطية: إنشاء واستعادة النسخ الاحتياطية\n• النسخ التلقائية: جدولة النسخ الاحتياطية التلقائية\n• تنظيف قاعدة البيانات: إزالة البيانات المؤقتة\n• إدارة التخزين: مراقبة مساحة التخزين المستخدمة\n\nإعدادات النظام:\n• العملة المستخدمة: اختيار العملة المحلية\n• صيغة التاريخ: تنسيق عرض التواريخ\n• إعدادات الطابعة: تكوين الطابعة والاتصال\n• فحص الترخيص: إدارة مفاتيح الترخيص',
      ),
      _GuideSectionData(
        icon: Icons.people_alt,
        title: 'إدارة المستخدمين والأدوار',
        content:
            'أنواع المستخدمين:\n\nالمدير (Manager):\n• الصلاحيات الكاملة: إدارة النظام والمستخدمين\n• المبيعات: جميع عمليات البيع والمرتجعات\n• المخزون: إدارة المنتجات والموردين\n• التقارير: جميع التقارير والإحصائيات\n• النظام: النسخ الاحتياطي والإعدادات\n\nالمشرف (Supervisor):\n• المبيعات: البيع والمرتجعات\n• المخزون: إدارة المنتجات والموردين\n• التقارير: عرض وتصدير التقارير\n\nالموظف (Employee):\n• المبيعات: عمليات البيع الأساسية\n• التقارير: عرض التقارير المحدودة\n\nإدارة المستخدمين:\n1. اذهب إلى "الإعدادات" > "إدارة المستخدمين"\n2. اضغط "إضافة مستخدم جديد"\n3. أدخل المعلومات المطلوبة\n4. حدد الدور المناسب\n5. احفظ التغييرات',
      ),
      _GuideSectionData(
        icon: Icons.card_membership,
        title: 'نظام الترخيص والتفعيل',
        content:
            'أنواع التراخيص:\n\nالترخيص الفردي:\n• مناسب للمتاجر الصغيرة والمكاتب\n• مستخدم واحد في كل مرة\n• جميع الميزات متاحة\n• دعم فني شامل\n\nالترخيص المؤسسي:\n• مناسب للشركات والمؤسسات الكبيرة\n• مستخدمين متعددين\n• إدارة مركزية للتراخيص\n• دعم فني مخصص\n\nالترخيص التجريبي:\n• 30 يوم مجاني كامل الميزات\n• بدون قيود على الاستخدام\n• انتقال سلس للنسخة المدفوعة\n• دعم فني متاح\n\nكيفية الحصول على الترخيص:\n1. قم بتجربة التطبيق مجاناً\n2. تواصل معنا للحصول على مفتاح الترخيص\n3. أدخل المفتاح في الإعدادات\n4. استمتع بجميع الميزات\n\nمزايا الترخيص:\n• دعم فني مستمر\n• تحديثات مجانية\n• نسخ احتياطية آمنة\n• حماية من النسخ غير المصرح بها\n\nنصائح مهمة:\n• احتفظ بمفتاح الترخيص في مكان آمن\n• لا تشارك المفتاح مع الآخرين\n• تواصل معنا عند انتهاء الترخيص\n• استفد من الدعم الفني المتاح',
      ),
      _GuideSectionData(
        icon: Icons.trending_up,
        title: 'التحسينات والأداء',
        content:
            'التحسينات في الإصدار الحالي:\n\nتحسينات الأداء:\n• سرعة تحميل أسرع بنسبة 40%\n• استهلاك ذاكرة أقل بنسبة 25%\n• استعلامات قاعدة بيانات محسنة\n• تحسين استجابة الواجهة\n\nتحسينات الاستقرار:\n• حل مشاكل الذاكرة\n• تحسين معالجة الأخطاء\n• استقرار أفضل لقاعدة البيانات\n• تقليل حالات التوقف\n\nتحسينات الأمان:\n• تشفير محسن للبيانات\n• حماية أفضل من الاختراق\n• مراقبة النشاط المشبوه\n• نسخ احتياطية مشفرة\n\nتحسينات الواجهة:\n• تصميم أكثر حداثة\n• تجربة مستخدم محسنة\n• دعم أفضل للشاشات المختلفة\n• تحسين إمكانية الوصول\n\nتحسينات الميزات:\n• ميزات جديدة ومفيدة\n• تحسين الميزات الموجودة\n• إضافة خيارات جديدة\n• تحسين الأداء العام\n\nنصائح للاستفادة القصوى:\n• قم بتحديث التطبيق بانتظام\n• استخدم الميزات الجديدة\n• احتفظ بنسخ احتياطية\n• تواصل معنا للمساعدة',
      ),
      _GuideSectionData(
        icon: Icons.dashboard,
        title: 'لوحة التحكم الرئيسية',
        content:
            'لوحة التحكم هي الشاشة الرئيسية التي تعرض نظرة عامة على نشاطك التجاري:\n\nالمعلومات المعروضة:\n• إجمالي المبيعات اليومية والشهرية\n• عدد المنتجات في المخزون\n• عدد العملاء المسجلين\n• عدد الموردين\n• أحدث العمليات\n• إحصائيات سريعة\n\nالرسوم البيانية:\n• رسم بياني للمبيعات اليومية\n• رسم بياني للمبيعات الشهرية\n• مقارنة الأداء\n• اتجاهات النمو\n\nالوصول السريع:\n• روابط مباشرة للشاشات الرئيسية\n• إحصائيات محدثة تلقائياً\n• تنبيهات مهمة\n• ملخص سريع للوضع\n\nنصائح للاستخدام:\n• راجع لوحة التحكم يومياً\n• راقب الاتجاهات والأنماط\n• استخدم الإحصائيات لاتخاذ القرارات\n• انتبه للتنبيهات المهمة',
      ),
      _GuideSectionData(
        icon: Icons.history,
        title: 'تاريخ المبيعات',
        content:
            'شاشة تاريخ المبيعات تعرض جميع عمليات البيع السابقة:\n\nعرض الفواتير:\n• قائمة بجميع الفواتير\n• تفاصيل كل فاتورة\n• نوع البيع (نقد، دين، تقسيط)\n• تاريخ ووقت البيع\n• المبلغ الإجمالي\n\nالبحث والتصفية:\n• البحث حسب رقم الفاتورة\n• البحث حسب تاريخ البيع\n• تصفية حسب نوع البيع\n• تصفية حسب العميل\n\nإدارة الفواتير:\n• عرض تفاصيل الفاتورة\n• إعادة طباعة الفاتورة\n• تعديل الفاتورة (إذا كان مسموحاً)\n• حذف الفاتورة (إذا كان مسموحاً)\n\nالمرتجعات:\n• إرجاع منتجات من فاتورة\n• إرجاع فاتورة كاملة\n• تسجيل سبب الإرجاع\n• تحديث المخزون تلقائياً\n\nنصائح مهمة:\n• راجع تاريخ المبيعات بانتظام\n• احتفظ بسجلات دقيقة\n• راقب أنماط البيع\n• استخدم البيانات لتحسين الأداء',
      ),
      _GuideSectionData(
        icon: Icons.category,
        title: 'إدارة التصنيفات',
        content:
            'التصنيفات تساعدك في تنظيم منتجاتك بشكل أفضل:\n\nإنشاء تصنيف جديد:\n1. اذهب إلى "التصنيفات"\n2. اضغط "إضافة تصنيف"\n3. أدخل اسم التصنيف\n4. أضف وصف (اختياري)\n5. احفظ التصنيف\n\nإدارة التصنيفات:\n• تعديل أسماء التصنيفات\n• حذف التصنيفات غير المستخدمة\n• إعادة ترتيب التصنيفات\n• دمج التصنيفات المتشابهة\n\nربط المنتجات:\n• تصنيف المنتجات عند الإضافة\n• تغيير تصنيف المنتجات الموجودة\n• عرض المنتجات حسب التصنيف\n• إحصائيات لكل تصنيف\n\nفوائد التصنيفات:\n• تنظيم أفضل للمنتجات\n• بحث أسرع وأسهل\n• تقارير مفصلة حسب التصنيف\n• إدارة مخزون أفضل\n\nنصائح للتصنيف:\n• استخدم أسماء واضحة ومفهومة\n• تجنب التصنيفات المتداخلة\n• راجع التصنيفات بانتظام\n• استخدم التصنيفات في التقارير',
      ),
      _GuideSectionData(
        icon: Icons.account_balance_wallet,
        title: 'إدارة الحسابات والديون',
        content:
            'نظام إدارة الحسابات يساعدك في متابعة الديون والمدفوعات:\n\nديون العملاء:\n• عرض جميع العملاء المدينين\n• مبلغ الدين لكل عميل\n• تاريخ آخر دفعة\n• تاريخ استحقاق الدين\n\nديون الموردين:\n• عرض جميع الموردين\n• المبالغ المستحقة\n• تاريخ آخر دفعة\n• متابعة المدفوعات\n\nتسجيل المدفوعات:\n• تسجيل دفعات العملاء\n• تسجيل مدفوعات الموردين\n• تحديث أرصدة الحسابات\n• طباعة إيصالات الدفع\n\nالتقارير المالية:\n• تقرير الديون المستحقة\n• تقرير المدفوعات\n• تقرير التدفق النقدي\n• تحليل الأرباح والخسائر\n\nإدارة الديون:\n• إرسال تذكيرات للعملاء\n• جدولة المدفوعات\n• متابعة المدفوعات المتأخرة\n• تسوية الحسابات\n\nنصائح مهمة:\n• راقب الديون بانتظام\n• أرسل تذكيرات في الوقت المناسب\n• احتفظ بسجلات دقيقة\n• استخدم التقارير لاتخاذ القرارات',
      ),
      _GuideSectionData(
        icon: Icons.assessment,
        title: 'التقارير المتقدمة',
        content:
            'التقارير المتقدمة توفر تحليلات مفصلة لنشاطك التجاري:\n\nتقارير المبيعات:\n• تقرير المبيعات اليومية\n• تقرير المبيعات الشهرية\n• تقرير المبيعات السنوية\n• مقارنة الأداء\n• تحليل الاتجاهات\n\nتقارير المخزون:\n• تقرير المخزون الحالي\n• تقرير المنتجات المنخفضة\n• تقرير حركة المخزون\n• تحليل دوران المخزون\n• تنبؤات الطلب\n\nتقارير العملاء:\n• أفضل العملاء\n• عملاء جدد\n• تحليل سلوك العملاء\n• تقرير الديون\n• تقرير المبيعات حسب العميل\n\nتقارير الموردين:\n• تقرير المشتريات\n• تحليل أداء الموردين\n• تقرير المدفوعات\n• مقارنة الأسعار\n\nتصدير التقارير:\n• تصدير إلى PDF\n• تصدير إلى Excel\n• تصدير إلى CSV\n• طباعة التقارير\n\nنصائح للاستخدام:\n• راجع التقارير بانتظام\n• استخدم البيانات لاتخاذ القرارات\n• قارن الأداء عبر الفترات\n• شارك التقارير مع الفريق',
      ),
      _GuideSectionData(
        icon: Icons.bug_report,
        title: 'شاشة الاختبارات والتشخيص',
        content:
            'شاشة الاختبارات تساعدك في تشخيص وحل المشاكل:\n\nأنواع الاختبارات:\n• اختبار قاعدة البيانات\n• اختبار واجهة المستخدم\n• اختبار الخدمات\n• اختبار الطباعة\n• اختبار النسخ الاحتياطي\n\nاختبار قاعدة البيانات:\n• فحص سلامة الجداول\n• اختبار العمليات الأساسية\n• فحص البيانات المفقودة\n• اختبار الأداء\n\nاختبار الخدمات:\n• اختبار خدمة الطباعة\n• اختبار النسخ الاحتياطي\n• اختبار التصدير\n• اختبار الاستيراد\n\nاختبار واجهة المستخدم:\n• اختبار التنقل\n• اختبار الإدخال\n• اختبار العرض\n• اختبار الاستجابة\n\nتشخيص المشاكل:\n• تحديد مصادر الأخطاء\n• تحليل سجلات النظام\n• اقتراح الحلول\n• إصلاح المشاكل تلقائياً\n\nنصائح للاستخدام:\n• استخدم الاختبارات عند ظهور مشاكل\n• راجع النتائج بعناية\n• اتبع الإرشادات المقترحة\n• تواصل مع الدعم عند الحاجة',
      ),
    ];
    for (final s in _allSections) {
      _sectionKeys[s.title] = GlobalKey();
    }
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final List<_GuideSectionData> visibleSections = _query.isEmpty
        ? _allSections
        : _allSections.where((s) {
            final q = _query.toLowerCase();
            return s.title.toLowerCase().contains(q) ||
                s.content.toLowerCase().contains(q);
          }).toList();

    Widget content = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [scheme.primary, scheme.surface],
          stops: const [0.0, 0.1],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(context),
            const SizedBox(height: 16),

            // Search box
            _buildSearchField(context),
            const SizedBox(height: 12),

            // Table of contents
            _buildTableOfContents(context, visibleSections),
            const SizedBox(height: 16),

            // Sections
            ...visibleSections.map((s) {
              return Padding(
                key: _sectionKeys[s.title],
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCollapsibleSection(
                  icon: s.icon,
                  title: s.title,
                  content: s.content,
                ),
              );
            }),

            const SizedBox(height: 8),
            _buildContactCard(context),
            const SizedBox(height: 12),
            _buildActionButtons(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (widget.showAppBar) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: scheme.background,
          appBar: AppBar(
            title: const Text(
              'دليل الاستخدام',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
            child: Icon(
              Icons.menu_book,
              color: scheme.onPrimary,
              size: 20,
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

  Widget _buildCollapsibleSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.5 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: scheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: scheme.primary, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: scheme.primary,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: _searchController,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        hintText: 'ابحث داخل الدليل (مثال: المبيعات، التقارير...)',
        prefixIcon: Icon(Icons.search, color: scheme.primary),
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                },
                icon:
                    Icon(Icons.clear, color: scheme.onSurface.withOpacity(0.6)),
              )
            : null,
      ),
    );
  }

  Widget _buildTableOfContents(
      BuildContext context, List<_GuideSectionData> sections) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.secondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list, color: scheme.secondary, size: 18),
              const SizedBox(width: 8),
              Text(
                'المحتويات',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: scheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sections.map((s) {
              return ActionChip(
                avatar: Icon(s.icon, size: 16, color: scheme.onPrimary),
                backgroundColor: scheme.primary,
                label: Text(
                  s.title,
                  style: TextStyle(color: scheme.onPrimary, fontSize: 12),
                ),
                onPressed: () {
                  final key = _sectionKeys[s.title];
                  if (key != null && key.currentContext != null) {
                    Scrollable.ensureVisible(
                      key.currentContext!,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      alignment: 0.1,
                    );
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Data model
  // ignore: unused_element
  List<_GuideSectionData> _filterSections(String query) {
    if (query.isEmpty) return _allSections;
    final q = query.toLowerCase();
    return _allSections
        .where((s) =>
            s.title.toLowerCase().contains(q) ||
            s.content.toLowerCase().contains(q))
        .toList();
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
            'إذا كان لديك أي أسئلة أو تحتاج مساعدة إضافية، لا تتردد في التواصل معنا:\n\n📧 البريد الإلكتروني: barzan.dawood.dev@gmail.com\n📱 الواتساب: 07866744144\n🌐 الموقع الإلكتروني: barzandawood.com\n📍 العنوان: نينوى - سنجار، العراق\n\nمعلومات مهمة:\n• الفترة التجريبية: 30 يوم مجاني كامل الميزات\n• الدعم الفني: متاح طوال فترة التجربة\n• التحديثات: مجانية لجميع المستخدمين\n• النسخ الاحتياطية: محمية ومشفرة\n\nنصائح للحصول على مساعدة أفضل:\n• استخدم دليل الاستخدام التفاعلي أولاً\n• احتفظ بسجلات الأخطاء عند حدوثها\n• وصف المشكلة بالتفصيل عند التواصل\n• اذكر إصدار التطبيق ونوع الجهاز\n• استفد من الفترة التجريبية لاختبار جميع الميزات\n\nسنكون سعداء لمساعدتك في أي وقت!',
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

class _GuideSectionData {
  final IconData icon;
  final String title;
  final String content;

  const _GuideSectionData({
    required this.icon,
    required this.title,
    required this.content,
  });
}
