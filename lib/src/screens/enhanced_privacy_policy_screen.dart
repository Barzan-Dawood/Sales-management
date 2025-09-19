// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class EnhancedPrivacyPolicyScreen extends StatelessWidget {
  final bool showAppBar;

  const EnhancedPrivacyPolicyScreen({
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
            _buildEnhancedSection(
              icon: Icons.info_outline,
              title: 'مقدمة',
              content: '''
نحن في نظام إدارة المكتب نحترم خصوصيتك ونلتزم بحماية معلوماتك. هذا التطبيق يستخدم قاعدة بيانات محلية تماماً ولا نجمع أي معلومات شخصية عن المستخدمين. **مهم جداً:** جميع بياناتك محفوظة محلياً على جهازك فقط ولا يتم إرسالها إلى أي خادم خارجي. آخر تحديث: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

نظام إدارة المكتب هو تطبيق محلي مصمم لمساعدتك في إدارة عملك اليومي بكفاءة وأمان. جميع البيانات محفوظة محلياً على جهازك ولا يتم مشاركتها مع أي طرف ثالث.
''',
            ),
            const SizedBox(height: 20),

            // المعلومات التي نجمعها
            _buildEnhancedSection(
              icon: Icons.data_usage,
              title: 'المعلومات التي نجمعها',
              content: '''
نحن لا نجمع أي معلومات شخصية عن المستخدمين. جميع البيانات محفوظة محلياً على جهازك فقط. التطبيق يعمل بالكامل دون اتصال بالإنترنت ولا يتطلب أي معلومات شخصية للعمل. البيانات المحفوظة محلياً تشمل: معلومات المنتجات والعملاء والمبيعات والموردين والمصاريف. جميع هذه البيانات محفوظة في قاعدة بيانات محلية على جهازك ولا يتم إرسالها إلى أي خادم خارجي.
''',
            ),
            const SizedBox(height: 20),

            // كيفية استخدام المعلومات
            _buildEnhancedSection(
              icon: Icons.security,
              title: 'كيفية استخدام المعلومات',
              content: '''
نظراً لأننا لا نجمع أي معلومات شخصية، فإن جميع البيانات محفوظة محلياً على جهازك فقط. نحن لا نصل إلى بياناتك ولا نشاركها مع أي طرف ثالث. التطبيق يعمل بالكامل محلياً دون الحاجة إلى اتصال بالإنترنت. يمكنك استخدام التطبيق بثقة تامة مع العلم أن جميع بياناتك آمنة ومحفوظة محلياً على جهازك.
''',
            ),
            const SizedBox(height: 20),

            // حماية البيانات
            _buildEnhancedSection(
              icon: Icons.lock,
              title: 'حماية البيانات',
              content: '''
جميع البيانات محفوظة محلياً على جهازك باستخدام تقنيات التشفير المتقدمة. نحن لا نصل إلى بياناتك ولا نشاركها مع أي طرف ثالث. التطبيق يعمل بالكامل محلياً دون الحاجة إلى اتصال بالإنترنت. يمكنك استخدام التطبيق بثقة تامة مع العلم أن جميع بياناتك آمنة ومحفوظة محلياً على جهازك.
''',
            ),
            const SizedBox(height: 20),

            // حقوقك
            _buildEnhancedSection(
              icon: Icons.person,
              title: 'حقوقك',
              content: '''
نظراً لأننا لا نجمع أي معلومات شخصية، فإن جميع البيانات محفوظة محلياً على جهازك فقط. يمكنك الوصول إلى جميع بياناتك في أي وقت من خلال التطبيق. يمكنك أيضاً إنشاء نسخ احتياطية من بياناتك وحذفها في أي وقت. جميع البيانات محفوظة محلياً على جهازك ولا يتم إرسالها إلى أي خادم خارجي.
''',
            ),
            const SizedBox(height: 20),

            // معلومات إضافية
            _buildInfoCard(context),
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
              'سياسة الخصوصية',
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
                  'سياسة الخصوصية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'نظام إدارة المكتب',
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

  Widget _buildEnhancedSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Builder(builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.05),
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
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
    });
  }

  Widget _buildInfoCard(BuildContext context) {
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
                  Icons.info,
                  color: scheme.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'معلومات إضافية',
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
            'هذا التطبيق يعمل بالكامل محلياً ولا يتطلب اتصال بالإنترنت. جميع البيانات محفوظة محلياً على جهازك ولا يتم إرسالها إلى أي خادم خارجي. يمكنك استخدام التطبيق بثقة تامة مع العلم أن جميع بياناتك آمنة ومحفوظة محلياً على جهازك.',
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EnhancedTermsConditionsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.description),
            label: const Text('شروط الاستخدام'),
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

// شاشة شروط الاستخدام المحسنة
class EnhancedTermsConditionsScreen extends StatelessWidget {
  final bool showAppBar;

  const EnhancedTermsConditionsScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
            _buildEnhancedSection(
              icon: Icons.info_outline,
              title: 'مقدمة',
              content: '''
مرحباً بك في نظام إدارة المكتب. باستخدامك لهذا التطبيق، فإنك توافق على الالتزام بشروط الاستخدام هذه. **مهم:** هذا التطبيق يعمل محلياً بالكامل ولا يتطلب اتصال بالإنترنت. آخر تحديث: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

نظام إدارة المكتب هو تطبيق محلي مصمم لمساعدتك في إدارة عملك اليومي بكفاءة وأمان. جميع البيانات محفوظة محلياً على جهازك ولا يتم مشاركتها مع أي طرف ثالث.
''',
            ),
            const SizedBox(height: 20),

            // القبول بالشروط
            _buildEnhancedSection(
              icon: Icons.check_circle_outline,
              title: 'القبول بالشروط',
              content: '''
باستخدامك لهذا التطبيق، فإنك تؤكد أنك قد قرأت وفهمت هذه الشروط وتوافق على الالتزام بها. إذا كنت لا توافق على أي من هذه الشروط، فيرجى عدم استخدام التطبيق. هذه الشروط تنطبق على جميع المستخدمين والزوار الذين يصلون إلى التطبيق أو يستخدمونه.
''',
            ),
            const SizedBox(height: 20),

            // الاستخدام المسموح
            _buildEnhancedSection(
              icon: Icons.verified_user,
              title: 'الاستخدام المسموح',
              content: '''
يُسمح لك باستخدام هذا التطبيق للأغراض التجارية والشخصية المشروعة فقط. يجب عليك عدم استخدام التطبيق لأي غرض غير قانوني أو محظور. أنت مسؤول عن جميع الأنشطة التي تحدث تحت حسابك. يجب عليك الحفاظ على سرية كلمة المرور الخاصة بك وعدم مشاركتها مع الآخرين.
''',
            ),
            const SizedBox(height: 20),

            // القيود والمنع
            _buildEnhancedSection(
              icon: Icons.block,
              title: 'القيود والمنع',
              content: '''
يُمنع منعاً باتاً استخدام التطبيق لأي من الأغراض التالية: انتهاك أي قانون أو لائحة محلية أو وطنية أو دولية، إرسال أو نقل أي محتوى غير قانوني أو ضار أو مهدد أو مسيء أو تشهيري أو فاحش أو غير أخلاقي، التدخل في عمل التطبيق أو الخوادم أو الشبكات المتصلة بالتطبيق، محاولة الوصول غير المصرح به إلى أي جزء من التطبيق أو الأنظمة المتصلة به.
''',
            ),
            const SizedBox(height: 20),

            // الملكية الفكرية
            _buildEnhancedSection(
              icon: Icons.copyright,
              title: 'الملكية الفكرية',
              content: '''
جميع المحتويات الموجودة في هذا التطبيق، بما في ذلك النصوص والرسوم والصور والبرامج والكود المصدري، محمية بحقوق الطبع والنشر والعلامات التجارية وغيرها من حقوق الملكية الفكرية. لا يجوز لك نسخ أو تعديل أو توزيع أو بيع أو تأجير أي جزء من التطبيق دون الحصول على إذن كتابي صريح منا.
''',
            ),
            const SizedBox(height: 20),

            // إخلاء المسؤولية
            _buildEnhancedSection(
              icon: Icons.warning_amber,
              title: 'إخلاء المسؤولية',
              content: '''
يتم توفير هذا التطبيق "كما هو" دون أي ضمانات من أي نوع، صريحة أو ضمنية. نحن لا نضمن أن التطبيق سيعمل دون انقطاع أو خالي من الأخطاء. نحن غير مسؤولين عن أي أضرار مباشرة أو غير مباشرة قد تنتج عن استخدام التطبيق. المستخدم يتحمل المسؤولية الكاملة عن استخدام التطبيق والبيانات المدخلة فيه.
''',
            ),
            const SizedBox(height: 20),

            // التعديلات على الشروط
            _buildEnhancedSection(
              icon: Icons.edit,
              title: 'التعديلات على الشروط',
              content: '''
نحتفظ بالحق في تعديل هذه الشروط في أي وقت دون إشعار مسبق. التعديلات ستصبح فعالة فور نشرها في التطبيق. استمرارك في استخدام التطبيق بعد التعديلات يعني موافقتك على الشروط الجديدة. ننصحك بمراجعة هذه الشروط بانتظام للاطلاع على أي تحديثات.
''',
            ),
            const SizedBox(height: 20),

            // القانون الحاكم
            _buildEnhancedSection(
              icon: Icons.gavel,
              title: 'القانون الحاكم',
              content: '''
هذه الشروط تحكمها وتفسرها قوانين جمهورية العراق. أي نزاع ينشأ من أو يتعلق بهذه الشروط سيخضع للاختصاص الحصري للمحاكم العراقية. في حالة وجود أي نزاع، سنحاول حله ودياً أولاً قبل اللجوء إلى القضاء.
''',
            ),
            const SizedBox(height: 20),

            // معلومات الاتصال
            _buildEnhancedSection(
              icon: Icons.contact_support,
              title: 'معلومات الاتصال',
              content: '''
إذا كان لديك أي أسئلة حول هذه الشروط، يرجى التواصل معنا عبر: البريد الإلكتروني: barzan.dawood.dev@gmail.com العنوان: نينوى - سنجار، العراق. سنكون سعداء لمساعدتك والإجابة على استفساراتك في أقرب وقت ممكن.
''',
            ),
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
              'شروط الاستخدام',
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
              'assets/images/pos.png',
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
                  'شروط الاستخدام',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'نظام إدارة المكتب',
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

  Widget _buildEnhancedSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Builder(builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.05),
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
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
    });
  }

  Widget _buildActionButtons(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EnhancedPrivacyPolicyScreen(),
                ),
              );
            },
            icon: const Icon(Icons.privacy_tip),
            label: const Text('سياسة الخصوصية'),
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
