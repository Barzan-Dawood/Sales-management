import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/db/database_service.dart';
import 'category_products_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _query = '';

  InputDecoration _pill(BuildContext context, String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withOpacity(0.4),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(children: [
              FilledButton.icon(
                  onPressed: () => _openEditor(),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة قسم')),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  decoration: _pill(context, 'بحث عن قسم', Icons.search),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Map<String, Object?>>>(
                future: db.getCategories(query: _query),
                builder: (context, snap) {
                  if (!snap.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final items = snap.data!;
                  if (items.isEmpty)
                    return const Center(child: Text('لا توجد أقسام'));
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 4),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 420,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 3.2,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final c = items[index];
                          final color =
                              Color((c['color'] as int?) ?? 0xFF607D8B);
                          final iconData = IconData(
                              (c['icon'] as int?) ?? Icons.folder.codePoint,
                              fontFamily: 'MaterialIcons');
                          return _FancyCategoryCard(
                            name: c['name']?.toString() ?? '',
                            color: color,
                            iconData: iconData,
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => CategoryProductsScreen(
                                  categoryId: c['id'] as int,
                                  categoryName:
                                      c['name']?.toString() ?? 'القسم',
                                  categoryColor: color,
                                ),
                              ));
                            },
                            onEdit: () => _openEditor(category: c),
                            onDelete: () => _delete(c['id'] as int),
                            countFuture: db.database.rawQuery(
                                'SELECT COUNT(*) c FROM products WHERE category_id = ?',
                                [c['id']]).then((r) => (r.first['c'] as int)),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _delete(int id) async {
    final db = context.read<DatabaseService>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف القسم'),
        content: const Text('هل تريد حذف هذا القسم؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) {
      await db.deleteCategory(id);
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _openEditor({Map<String, Object?>? category}) async {
    final db = context.read<DatabaseService>();
    final formKey = GlobalKey<FormState>();
    final name =
        TextEditingController(text: category?['name']?.toString() ?? '');
    int selectedColor = (category?['color'] as int?) ?? 0xFF607D8B;
    int selectedIcon = (category?['icon'] as int?) ?? Icons.folder.codePoint;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setStateDialog) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Text(category == null ? 'إضافة قسم' : 'تعديل قسم',
                                style: Theme.of(context).textTheme.titleLarge),
                            const Spacer(),
                            IconButton(
                                onPressed: () => Navigator.pop(context, false),
                                icon: const Icon(Icons.close)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: name,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          decoration:
                              _pill(context, 'اسم القسم', Icons.category),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 16),
                        Text('الأيقونة',
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final ic in _iconOptions)
                              ChoiceChip(
                                label: Icon(ic),
                                selected: selectedIcon == ic.codePoint,
                                onSelected: (_) => setStateDialog(
                                    () => selectedIcon = ic.codePoint),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('اللون',
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final col in _colorOptions)
                              GestureDetector(
                                onTap: () => setStateDialog(
                                    () => selectedColor = col.value),
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: col,
                                  child: selectedColor == col.value
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 16)
                                      : null,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            FilledButton(
                              onPressed: () {
                                if (!formKey.currentState!.validate()) return;
                                Navigator.pop(context, true);
                              },
                              child: const Text('حفظ'),
                            ),
                            const Spacer(),
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('إلغاء')),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
    if (ok == true) {
      await db.upsertCategory({
        'name': name.text.trim(),
        'icon': selectedIcon,
        'color': selectedColor
      }, id: category?['id'] as int?);
      if (!mounted) return;
      setState(() {});
    }
  }
}

class _FancyCategoryCard extends StatefulWidget {
  const _FancyCategoryCard({
    required this.name,
    required this.color,
    required this.iconData,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.countFuture,
  });

  final String name;
  final Color color;
  final IconData iconData;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Future<int> countFuture;

  @override
  State<_FancyCategoryCard> createState() => _FancyCategoryCardState();
}

class _FancyCategoryCardState extends State<_FancyCategoryCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [widget.color.withOpacity(0.9), widget.color.withOpacity(0.6)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Stack(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: widget.onTap,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -8,
                      bottom: -8,
                      child: Icon(widget.iconData,
                          size: 84, color: Colors.white.withOpacity(0.12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            child: Icon(widget.iconData,
                                size: 22, color: widget.color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15),
                                ),
                                const SizedBox(height: 6),
                                FutureBuilder<int>(
                                  future: widget.countFuture,
                                  builder: (context, snap) {
                                    final count = snap.data ?? 0;
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: BackdropFilter(
                                        filter: ui.ImageFilter.blur(
                                            sigmaX: 6, sigmaY: 6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.25),
                                            border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.35)),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text('عدد المنتجات: $count',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12)),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Row(children: [
                _actionCircle(
                    icon: Icons.edit,
                    tooltip: 'تعديل',
                    color: Colors.white,
                    iconColor: widget.color,
                    onTap: widget.onEdit),
                const SizedBox(width: 6),
                _actionCircle(
                    icon: Icons.delete_outline,
                    tooltip: 'حذف',
                    color: Colors.white,
                    iconColor: Colors.red.shade700,
                    onTap: widget.onDelete),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCircle(
      {required IconData icon,
      required String tooltip,
      required Color color,
      required Color iconColor,
      required VoidCallback onTap}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 30,
          height: 30,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ]),
          child: Icon(icon, color: iconColor, size: 16),
        ),
      ),
    );
  }
}

const _iconOptions = <IconData>[
  Icons.phone_iphone,
  Icons.phone_android,
  Icons.devices_other,
  Icons.watch,
  Icons.headphones,
  Icons.speaker,
  Icons.memory,
  Icons.usb,
  Icons.cable,
  Icons.router,
  Icons.wifi,
  Icons.lan,
  Icons.network_check,
  Icons.settings_input_antenna,
  Icons.electrical_services,
  Icons.lightbulb,
  Icons.power,
  Icons.bolt,
];

const _colorOptions = <Color>[
  Color(0xFF1E88E5),
  Color(0xFF43A047),
  Color(0xFFF4511E),
  Color(0xFF8E24AA),
  Color(0xFF00897B),
  Color(0xFF6D4C41),
  Color(0xFF546E7A),
  Color(0xFFFFB300),
];
