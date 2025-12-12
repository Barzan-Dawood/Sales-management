import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth/auth_provider.dart';
import '../services/db/database_service.dart';
import '../models/user_model.dart';
import '../utils/dark_mode_utils.dart';

class GroupsManagementScreen extends StatefulWidget {
  const GroupsManagementScreen({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const GroupsManagementScreen(),
    );
  }

  @override
  State<GroupsManagementScreen> createState() => _GroupsManagementScreenState();
}

class _GroupsManagementScreenState extends State<GroupsManagementScreen> {
  List<Map<String, dynamic>> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      if (!mounted) return;
      final db = context.read<DatabaseService>();
      final groups = await db.getAllGroups();

      if (!mounted) return;

      // تحميل الصلاحيات لكل مجموعة وإنشاء نسخة قابلة للتعديل
      final groupsWithPermissions = <Map<String, dynamic>>[];
      for (final group in groups) {
        final groupId = group['id'] as int;
        final permissions = await db.getGroupPermissions(groupId);
        // إنشاء نسخة جديدة من Map لتجنب مشكلة read-only
        final groupCopy = Map<String, dynamic>.from(group);
        groupCopy['permissions'] = permissions;
        groupsWithPermissions.add(groupCopy);
      }

      if (!mounted) return;
      setState(() {
        _groups = groupsWithPermissions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل المجموعات: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // التحقق من الصلاحية
    if (!authProvider.hasPermission(UserPermission.manageUsers)) {
      return Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(24),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                'ليس لديك صلاحية للوصول إلى هذه الصفحة',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      );
    }

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('إدارة المجموعات والصلاحيات'),
              backgroundColor: Theme.of(context).colorScheme.surface,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddEditGroupDialog(),
                  tooltip: 'إضافة مجموعة جديدة',
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'إغلاق',
                ),
              ],
            ),
            Flexible(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadGroups,
                      child: _groups.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.group_outlined,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'لا توجد مجموعات',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: _showAddEditGroupDialog,
                                    icon: const Icon(Icons.add),
                                    label: const Text('إضافة مجموعة جديدة'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _groups.length,
                              itemBuilder: (context, index) {
                                final group = _groups[index];
                                return _buildGroupCard(group);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final permissions =
        group['permissions'] as Map<SystemSection, List<UserPermission>>? ?? {};
    final totalPermissions =
        permissions.values.fold<int>(0, (sum, list) => sum + list.length);
    final isActive = (group['active'] ?? 1) == 1;

    return Card(
      color: DarkModeUtils.getCardColor(context),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green : Colors.grey,
          child: Icon(
            Icons.group,
            color: Colors.white,
          ),
        ),
        title: Text(
          group['name'] ?? '',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? null : Colors.grey,
          ),
        ),
        subtitle: Text(
          group['description'] ?? 'لا يوجد وصف',
          style: TextStyle(
            color: isActive ? Colors.grey[600] : Colors.grey,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text('$totalPermissions صلاحية'),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('تعديل'),
                    ],
                  ),
                  onTap: () {
                    Future.delayed(Duration.zero, () {
                      _showAddEditGroupDialog(group: group);
                    });
                  },
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(
                        isActive ? Icons.block : Icons.check_circle,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(isActive ? 'تعطيل' : 'تفعيل'),
                    ],
                  ),
                  onTap: () {
                    Future.delayed(Duration.zero, () {
                      _toggleGroupStatus(group);
                    });
                  },
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('حذف', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  onTap: () {
                    Future.delayed(Duration.zero, () {
                      _showDeleteConfirmation(group);
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (permissions.isNotEmpty) ...[
                  const Text(
                    'الصلاحيات حسب الأقسام:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...permissions.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key.displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: entry.value.map((permission) {
                              return Chip(
                                label: Text(
                                  permission.displayName,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                padding: EdgeInsets.zero,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }),
                ] else
                  const Text(
                    'لا توجد صلاحيات لهذه المجموعة',
                    style: TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEditGroupDialog({Map<String, dynamic>? group}) async {
    final nameController = TextEditingController(text: group?['name'] ?? '');
    final descriptionController =
        TextEditingController(text: group?['description'] ?? '');

    // تحميل الصلاحيات الحالية للمجموعة
    Map<SystemSection, List<UserPermission>> currentPermissions = {};
    if (group != null) {
      if (!mounted) return;
      final db = context.read<DatabaseService>();
      currentPermissions = await db.getGroupPermissions(group['id'] as int);
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _GroupEditDialog(
        nameController: nameController,
        descriptionController: descriptionController,
        initialPermissions: currentPermissions,
        isEdit: group != null,
      ),
    );

    if (result != null && mounted) {
      final db = context.read<DatabaseService>();

      try {
        if (group == null) {
          // إنشاء مجموعة جديدة
          await db.createGroup(
            name: result['name'] as String,
            description: result['description'] as String?,
            permissions: result['permissions']
                as Map<SystemSection, List<UserPermission>>,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء المجموعة بنجاح')),
          );
        } else {
          // تحديث مجموعة موجودة
          await db.updateGroup(
            groupId: group['id'] as int,
            name: result['name'] as String,
            description: result['description'] as String?,
            permissions: result['permissions']
                as Map<SystemSection, List<UserPermission>>,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث المجموعة بنجاح')),
          );
        }

        if (mounted) {
          _loadGroups();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleGroupStatus(Map<String, dynamic> group) async {
    if (!mounted) return;

    final db = context.read<DatabaseService>();
    final isActive = (group['active'] ?? 1) == 1;

    try {
      await db.updateGroup(
        groupId: group['id'] as int,
        active: !isActive,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive ? 'تم تعطيل المجموعة' : 'تم تفعيل المجموعة'),
          ),
        );
        _loadGroups();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(Map<String, dynamic> group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
            'هل أنت متأكد من حذف المجموعة "${group['name']}"؟\n\nسيتم إلغاء ربط جميع المستخدمين بهذه المجموعة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final db = context.read<DatabaseService>();

      try {
        await db.deleteGroup(group['id'] as int);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف المجموعة بنجاح')),
          );
          _loadGroups();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في حذف المجموعة: $e')),
          );
        }
      }
    }
  }
}

class _GroupEditDialog extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final Map<SystemSection, List<UserPermission>> initialPermissions;
  final bool isEdit;

  const _GroupEditDialog({
    required this.nameController,
    required this.descriptionController,
    required this.initialPermissions,
    required this.isEdit,
  });

  @override
  State<_GroupEditDialog> createState() => _GroupEditDialogState();
}

class _GroupEditDialogState extends State<_GroupEditDialog> {
  late Map<SystemSection, List<UserPermission>> _selectedPermissions;

  @override
  void initState() {
    super.initState();
    // عمل deep copy للصلاحيات لتجنب تعديل القيم الأصلية
    _selectedPermissions = {};
    for (final entry in widget.initialPermissions.entries) {
      _selectedPermissions[entry.key] = List.from(entry.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title:
                  Text(widget.isEdit ? 'تعديل المجموعة' : 'إضافة مجموعة جديدة'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: widget.nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المجموعة *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: widget.descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'الوصف',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'الصلاحيات حسب الأقسام:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...SystemSection.values.map((section) {
                      return _buildSectionPermissions(section);
                    }),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (widget.nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('الرجاء إدخال اسم المجموعة')),
                        );
                        return;
                      }

                      Navigator.pop(context, {
                        'name': widget.nameController.text.trim(),
                        'description':
                            widget.descriptionController.text.trim().isEmpty
                                ? null
                                : widget.descriptionController.text.trim(),
                        'permissions': _selectedPermissions,
                      });
                    },
                    child: Text(widget.isEdit ? 'تحديث' : 'إضافة'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionPermissions(SystemSection section) {
    final sectionPermissions =
        SectionPermissionMapper.getPermissionsForSection(section);
    final selectedForSection = _selectedPermissions[section] ?? [];
    final allSelected =
        sectionPermissions.every((p) => selectedForSection.contains(p));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Checkbox(
          value: allSelected,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _selectedPermissions[section] = List.from(sectionPermissions);
              } else {
                _selectedPermissions.remove(section);
              }
            });
          },
        ),
        title: Text(
          section.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
            '${selectedForSection.length} من ${sectionPermissions.length}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sectionPermissions.map((permission) {
                final isSelected = selectedForSection.contains(permission);
                return FilterChip(
                  label: Text(permission.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        // الحصول على القائمة أو إنشاء واحدة جديدة
                        final permissionsList =
                            _selectedPermissions.putIfAbsent(
                          section,
                          () => <UserPermission>[],
                        );
                        // إضافة الصلاحية إذا لم تكن موجودة
                        if (!permissionsList.contains(permission)) {
                          permissionsList.add(permission);
                        }
                      } else {
                        _selectedPermissions[section]?.remove(permission);
                        if (_selectedPermissions[section]?.isEmpty == true) {
                          _selectedPermissions.remove(section);
                        }
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
