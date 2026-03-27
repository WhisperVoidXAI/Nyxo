import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/task.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/app_localizations.dart';
import '../core/app_gradients.dart';
import '../core/animations_helper.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final int index;
  final VoidCallback onToggleDone;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const TaskCard({
    super.key,
    required this.task,
    required this.index,
    required this.onToggleDone,
    required this.onDelete,
    this.onEdit,
  });

  Color get _priorityColor => task.priorityColor;

  LinearGradient get _priorityGradient {
    switch (task.priority) {
      case 'high':
        return AppGradients.health;
      case 'low':
        return AppGradients.travel;
      default:
        return AppGradients.ideas;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = loc.isArabic;

    return PressScale(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          boxShadow: [
            BoxShadow(
              color: _priorityColor.withValues(
                alpha: task.isDone ? 0.04 : 0.13,
              ),
              blurRadius: 18,
              spreadRadius: -5,
              offset: const Offset(0, 7),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white
                        .withValues(alpha: task.isDone ? 0.025 : 0.055)
                    : Colors.white.withValues(alpha: task.isDone ? 0.65 : 0.88),
                borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                border: Border.all(
                  color: _priorityColor.withValues(
                      alpha: task.isDone ? 0.08 : 0.20),
                  width: 0.8,
                ),
              ),
              child: Column(
                children: [
                  _buildTopBar(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppConstants.padMD,
                      AppConstants.padMD,
                      AppConstants.padMD,
                      AppConstants.padSM,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, loc, isArabic, isDark),
                        if (task.notes != null && task.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildNotes(context, isDark),
                        ],
                        const SizedBox(height: 10),
                        Divider(
                          height: 1,
                          color: _priorityColor.withValues(alpha: 0.10),
                        ),
                        const SizedBox(height: 8),
                        _buildFooter(context, loc, isArabic, isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: index * 60),
          duration: 350.ms,
          curve: Curves.easeOut,
        )
        .slideY(begin: 0.07, curve: Curves.easeOutCubic);
  }

  Widget _buildTopBar() {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        gradient: task.isDone
            ? LinearGradient(colors: [
                AppColors.textHintDark.withValues(alpha: 0.28),
                AppColors.textHintDark.withValues(alpha: 0.10),
              ])
            : _priorityGradient,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLG),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations loc,
    bool isArabic,
    bool isDark,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Checkbox ─────────────────────────────────────────
        GestureDetector(
          onTap: onToggleDone,
          child: AnimatedContainer(
            duration: AppConstants.animNormal,
            curve: Curves.easeOutCubic,
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              gradient: task.isDone ? _priorityGradient : null,
              color: task.isDone ? null : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: task.isDone
                    ? Colors.transparent
                    : _priorityColor.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: task.isDone
                  ? [
                      BoxShadow(
                        color: _priorityColor.withValues(alpha: 0.30),
                        blurRadius: 8,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: task.isDone
                ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),

        // ─── Title & badges ───────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.emoji != null ? '${task.emoji} ${task.title}' : task.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: task.isDone ? AppColors.textHintDark : null,
                      decoration:
                          task.isDone ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.textHintDark,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  // Priority badge
                  _Badge(
                    icon: task.priorityIcon,
                    label: task.getPriorityLabel(isArabic),
                    color: _priorityColor,
                  ),
                  if (task.hasDueDate) ...[
                    const SizedBox(width: 6),
                    _Badge(
                      icon: task.isOverdue
                          ? Icons.warning_rounded
                          : Icons.event_rounded,
                      label: task.getFormattedDueDate(isArabic),
                      color:
                          task.isOverdue ? AppColors.rose : AppColors.primary,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotes(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _priorityColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        border: Border.all(
          color: _priorityColor.withValues(alpha: 0.10),
          width: 0.8,
        ),
      ),
      child: Text(
        task.notes!,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: task.isDone ? AppColors.textHintDark : null,
            ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    AppLocalizations loc,
    bool isArabic,
    bool isDark,
  ) {
    return Row(
      children: [
        if (task.completedAt != null) ...[
          const Icon(Icons.check_circle_outline_rounded,
              size: 12, color: AppColors.mint),
          const SizedBox(width: 4),
          Text(
            isArabic ? 'مكتملة' : 'Completed',
            style: const TextStyle(fontSize: 10, color: AppColors.mint),
          ),
        ] else ...[
          Icon(Icons.radio_button_unchecked_rounded,
              size: 12, color: AppColors.textHintDark),
          const SizedBox(width: 4),
          Text(
            isArabic ? 'معلّقة' : 'Pending',
            style: const TextStyle(fontSize: 10, color: AppColors.textHintDark),
          ),
        ],
        const Spacer(),
        if (onEdit != null)
          _FooterButton(
            icon: Icons.edit_rounded,
            color: AppColors.primary,
            onTap: onEdit!,
          ),
        const SizedBox(width: 6),
        _FooterButton(
          icon: Icons.delete_outline_rounded,
          color: AppColors.rose,
          onTap: () => _showDeleteConfirm(context, loc, isArabic),
        ),
      ],
    );
  }

  void _showDeleteConfirm(
    BuildContext context,
    AppLocalizations loc,
    bool isArabic,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.50),
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        ),
        icon: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.rose.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child:
              const Icon(Icons.delete_rounded, color: AppColors.rose, size: 28),
        ),
        title: Text(isArabic ? 'حذف المهمة' : 'Delete Task'),
        content: Text(isArabic
            ? 'هل تريد حذف هذه المهمة؟'
            : 'Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rose,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onDelete();
            },
            child: Text(isArabic ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── _Badge ───────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.26),
          width: 0.7,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _FooterButton ────────────────────────────────────────────────
class _FooterButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FooterButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(AppConstants.radiusXS),
          border: Border.all(
            color: color.withValues(alpha: 0.18),
            width: 0.8,
          ),
        ),
        child: Icon(icon, color: color, size: 15),
      ),
    );
  }
}
