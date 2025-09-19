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
