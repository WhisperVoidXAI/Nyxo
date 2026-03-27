import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/app_localizations.dart';
import '../core/app_gradients.dart';
import '../core/animations_helper.dart';
import '../core/glass_widget.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TaskProvider>().loadTasks();
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Stack(
        children: [
          _buildBg(isDark),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(loc, isDark),
                _buildStats(loc, isDark),
                _buildFilters(loc, isDark),
                Expanded(child: _buildList(loc, isDark)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(loc, isDark),
    );
  }

  // ─── Background ───────────────────────────────────────────────
  Widget _buildBg(bool isDark) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
            gradient: AppGradients.background(isDark),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -60 + _bgCtrl.value * 20,
                right: -60,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(
                      alpha: 0.04 + _bgCtrl.value * 0.02,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -40 + _bgCtrl.value * 15,
                left: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.mint.withValues(
                      alpha: 0.03 + _bgCtrl.value * 0.015,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────
  Widget _buildAppBar(AppLocalizations loc, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          PressScale(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 0.8,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_rounded,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.isArabic ? 'المهام' : 'Tasks',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                Consumer<TaskProvider>(
                  builder: (_, p, __) => Text(
                    loc.isArabic
                        ? '${p.pendingCount} معلّقة · ${p.doneCount} مكتملة'
                        : '${p.pendingCount} pending · ${p.doneCount} done',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats Bar ────────────────────────────────────────────────
  Widget _buildStats(AppLocalizations loc, bool isDark) {
    return Consumer<TaskProvider>(
      builder: (_, p, __) {
        if (p.totalCount == 0) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.padMD, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.primary.withValues(alpha: 0.08),
                            AppColors.mint.withValues(alpha: 0.04),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.80),
                            AppColors.primary.withValues(alpha: 0.04),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  border: Border.all(
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : AppColors.lightBorder,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      value: p.totalCount,
                      label: loc.isArabic ? 'الكل' : 'Total',
                      icon: Icons.checklist_rounded,
                      color: AppColors.primary,
                    ),
                    _Divider(isDark: isDark),
                    _StatItem(
                      value: p.pendingCount,
                      label: loc.isArabic ? 'معلّقة' : 'Pending',
                      icon: Icons.radio_button_unchecked_rounded,
                      color: AppColors.gold,
                    ),
                    _Divider(isDark: isDark),
                    _StatItem(
                      value: p.doneCount,
                      label: loc.isArabic ? 'مكتملة' : 'Done',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.mint,
                    ),
                    _Divider(isDark: isDark),
                    _StatItem(
                      value: p.overdueCount,
                      label: loc.isArabic ? 'متأخرة' : 'Overdue',
                      icon: Icons.warning_rounded,
                      color: AppColors.rose,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.05);
      },
    );
  }

  // ─── Filters ──────────────────────────────────────────────────
  Widget _buildFilters(AppLocalizations loc, bool isDark) {
    final filters = [
      {'f': TaskFilter.all, 'l': loc.isArabic ? 'الكل' : 'All'},
      {'f': TaskFilter.pending, 'l': loc.isArabic ? 'معلّقة' : 'Pending'},
      {'f': TaskFilter.done, 'l': loc.isArabic ? 'مكتملة' : 'Done'},
      {'f': TaskFilter.today, 'l': loc.isArabic ? 'اليوم' : 'Today'},
      {'f': TaskFilter.overdue, 'l': loc.isArabic ? 'متأخرة' : 'Overdue'},
    ];

    return Consumer<TaskProvider>(
      builder: (_, p, __) => SizedBox(
        height: 46,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          itemCount: filters.length,
          itemBuilder: (_, i) {
            final isSel = p.currentFilter == filters[i]['f'];
            return PressScale(
              onTap: () => p.setFilter(filters[i]['f'] as TaskFilter),
              child: AnimatedContainer(
                duration: AppConstants.animFast,
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isSel ? AppGradients.primary : null,
                  color: isSel
                      ? null
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.75)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSel
                        ? Colors.transparent
                        : (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  filters[i]['l'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.normal,
                    color: isSel ? Colors.white : null,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── List ─────────────────────────────────────────────────────
  Widget _buildList(AppLocalizations loc, bool isDark) {
    return Consumer<TaskProvider>(
      builder: (_, p, __) {
        if (p.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final list = p.filteredTasks;

        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.checklist_rounded,
                    color: AppColors.primary,
                    size: 38,
                  ),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 20),
                Text(
                  loc.isArabic ? 'لا توجد مهام' : 'No tasks',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 8),
                Text(
                  loc.isArabic
                      ? 'اضغط + لإضافة مهمة جديدة'
                      : 'Tap + to add a new task',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final task = list[i];
            return TaskCard(
              task: task,
              index: i,
              onToggleDone: () => p.toggleDone(task),
              onDelete: () => p.deleteTask(task.id),
              onEdit: () => _showSheet(context, loc, isDark, existing: task),
            );
          },
        );
      },
    );
  }

  // ─── FAB ──────────────────────────────────────────────────────
  Widget _buildFAB(AppLocalizations loc, bool isDark) {
    return PressScale(
      onTap: () => _showSheet(context, loc, isDark),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          gradient: AppGradients.aurora,
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.45),
              blurRadius: 22,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              loc.isArabic ? 'مهمة جديدة' : 'New Task',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(delay: 400.ms, curve: Curves.elasticOut);
  }

  // ─── Bottom Sheet ─────────────────────────────────────────────
  void _showSheet(
    BuildContext context,
    AppLocalizations loc,
    bool isDark, {
    Task? existing,
  }) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    String priority = existing?.priority ?? 'medium';
    DateTime? dueDate = existing?.dueDate;
    String? emoji = existing?.emoji;

    const emojis = ['📝', '✅', '🎯', '💡', '🔥', '⭐', '📌', '🚀'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: FrostedPanel(
            topRadius: AppConstants.radiusXXL,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    Text(
                      existing != null
                          ? (loc.isArabic ? 'تعديل المهمة' : 'Edit Task')
                          : (loc.isArabic ? 'مهمة جديدة' : 'New Task'),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 20),

                    // ─── Emoji Row ────────────────────────────
                    SizedBox(
                      height: 44,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: emojis.length,
                        itemBuilder: (_, i) {
                          final e = emojis[i];
                          final isSel = emoji == e;
                          return PressScale(
                            onTap: () => setS(() => emoji = isSel ? null : e),
                            child: AnimatedContainer(
                              duration: AppConstants.animFast,
                              margin: const EdgeInsets.only(right: 8),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: isSel ? AppGradients.primary : null,
                                color: isSel
                                    ? null
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.white.withValues(alpha: 0.75)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSel
                                      ? Colors.transparent
                                      : (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder),
                                  width: 0.8,
                                ),
                              ),
                              child: Center(
                                child: Text(e,
                                    style: const TextStyle(fontSize: 18)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ─── Title ────────────────────────────────
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        hintText:
                            loc.isArabic ? 'عنوان المهمة...' : 'Task title...',
                        prefixIcon: const Icon(Icons.task_alt_rounded,
                            color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ─── Notes ────────────────────────────────
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: loc.isArabic
                            ? 'ملاحظات (اختياري)...'
                            : 'Notes (optional)...',
                        prefixIcon: const Icon(Icons.notes_rounded,
                            color: AppColors.textHintDark),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ─── Priority ─────────────────────────────
                    Text(
                      loc.isArabic ? 'الأولوية' : 'Priority',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: AppConstants.priorityTypes.map((p) {
                        final isSel = priority == p['value'];
                        final color = p['value'] == 'high'
                            ? AppColors.rose
                            : p['value'] == 'low'
                                ? AppColors.mint
                                : AppColors.gold;
                        return Expanded(
                          child: PressScale(
                            onTap: () => setS(() => priority = p['value']!),
                            child: AnimatedContainer(
                              duration: AppConstants.animFast,
                              margin: EdgeInsets.only(
                                right: p['value'] != 'low' ? 8 : 0,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? color.withValues(alpha: 0.18)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.04)
                                        : Colors.white.withValues(alpha: 0.75)),
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radiusMD),
                                border: Border.all(
                                  color: isSel
                                      ? color
                                      : (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder),
                                  width: isSel ? 1.5 : 0.8,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    p['value'] == 'high'
                                        ? Icons.keyboard_double_arrow_up_rounded
                                        : p['value'] == 'low'
                                            ? Icons
                                                .keyboard_double_arrow_down_rounded
                                            : Icons.remove_rounded,
                                    color:
                                        isSel ? color : AppColors.textHintDark,
                                    size: 20,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    loc.isArabic ? p['label']! : p['labelEn']!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSel
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                      color: isSel ? color : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // ─── Due Date ─────────────────────────────
                    PressScale(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: dueDate ?? DateTime.now(),
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 1)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) {
                          if (!context.mounted) return;
                          final t = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          final selected = DateTime(
                            d.year,
                            d.month,
                            d.day,
                            t?.hour ?? 9,
                            t?.minute ?? 0,
                          );
                          setS(() => dueDate = selected);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: dueDate != null
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.white.withValues(alpha: 0.75)),
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMD),
                          border: Border.all(
                            color: dueDate != null
                                ? AppColors.primary.withValues(alpha: 0.25)
                                : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event_rounded,
                              color: dueDate != null
                                  ? AppColors.primary
                                  : AppColors.textHintDark,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                dueDate != null
                                    ? '${dueDate!.day}/${dueDate!.month}/${dueDate!.year} ${dueDate!.hour.toString().padLeft(2, '0')}:${dueDate!.minute.toString().padLeft(2, '0')}'
                                    : (loc.isArabic
                                        ? 'تاريخ الاستحقاق (اختياري)'
                                        : 'Due date (optional)'),
                                style: TextStyle(
                                  color: dueDate != null
                                      ? AppColors.primary
                                      : AppColors.textHintDark,
                                  fontWeight: dueDate != null
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (dueDate != null)
                              GestureDetector(
                                onTap: () => setS(() => dueDate = null),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: AppColors.textHintDark,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ─── Save Button ──────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty) return;
                          final prov = context.read<TaskProvider>();

                          if (existing != null) {
                            await prov.updateTask(
                              existing.copyWith(
                                title: titleCtrl.text.trim(),
                                notes: notesCtrl.text.trim().isEmpty
                                    ? null
                                    : notesCtrl.text.trim(),
                                priority: priority,
                                dueDate: dueDate,
                                emoji: emoji,
                              ),
                            );
                          } else {
                            await prov.addTask(Task(
                              title: titleCtrl.text.trim(),
                              notes: notesCtrl.text.trim().isEmpty
                                  ? null
                                  : notesCtrl.text.trim(),
                              priority: priority,
                              dueDate: dueDate,
                              emoji: emoji,
                            ));
                          }

                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Text(loc.isArabic ? 'حفظ' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textHintDark
                    : AppColors.textHintLight,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.8,
      height: 26,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }
}
