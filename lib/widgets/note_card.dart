import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/note.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/app_localizations.dart';
import '../core/app_gradients.dart';
import '../core/animations_helper.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onDelete;
  final VoidCallback? onPinToggle;
  final int index;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onDelete,
    this.onPinToggle,
    required this.index,
  });

  Color get _categoryColor {
    final cat = AppConstants.categories.firstWhere(
      (c) => c['value'] == note.category,
      orElse: () => AppConstants.categories.last,
    );
    return cat['color'] as Color;
  }

  LinearGradient get _categoryGradient =>
      AppGradients.forCategory(note.category);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PressScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          boxShadow: [
            BoxShadow(
              color: _categoryColor.withValues(alpha: isDark ? 0.12 : 0.09),
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
                    ? Colors.white.withValues(alpha: 0.055)
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                border: Border.all(
                  color: isDark
                      ? _categoryColor.withValues(alpha: 0.16)
                      : _categoryColor.withValues(alpha: 0.22),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryBar(),
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
                        _buildHeader(context, loc, isDark),
                        const SizedBox(height: 10),
                        _buildPreview(context),
                        const SizedBox(height: 12),
                        Divider(
                          height: 1,
                          color: _categoryColor.withValues(alpha: 0.14),
                        ),
                        const SizedBox(height: 10),
                        _buildFooter(context, loc, isDark),
                        if (note.tags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildTags(),
                        ],
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
          delay: Duration(milliseconds: index * 65),
          duration: 380.ms,
          curve: Curves.easeOut,
        )
        .slideY(begin: 0.07, curve: Curves.easeOutCubic);
  }

  Widget _buildCategoryBar() {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        gradient: _categoryGradient,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLG),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _categoryColor.withValues(alpha: 0.22),
                _categoryColor.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            border: Border.all(
              color: _categoryColor.withValues(alpha: 0.22),
              width: 0.8,
            ),
          ),
          child: Center(
            child: Text(
              note.categoryEmoji,
              style: const TextStyle(fontSize: 17),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.05,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (note.isPinned)
                Row(
                  children: [
                    Icon(
                      Icons.push_pin_rounded,
                      size: 10,
                      color: _categoryColor.withValues(alpha: 0.75),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      loc.isArabic ? 'مثبّتة' : 'Pinned',
                      style: TextStyle(
                        fontSize: 10,
                        color: _categoryColor.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        _ActionButton(
          onTap: onFavoriteToggle,
          icon: note.isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          color: note.isFavorite ? AppColors.rose : AppColors.textHintDark,
          activeColor: AppColors.rose,
          isActive: note.isFavorite,
        ),
        if (onPinToggle != null) ...[
          const SizedBox(width: 2),
          _ActionButton(
            onTap: onPinToggle!,
            icon: note.isPinned
                ? Icons.push_pin_rounded
                : Icons.push_pin_outlined,
            color: note.isPinned ? _categoryColor : AppColors.textHintDark,
            activeColor: _categoryColor,
            isActive: note.isPinned,
          ),
        ],
        const SizedBox(width: 2),
        _ActionButton(
          onTap: () => _showDeleteConfirm(context),
          icon: Icons.delete_outline_rounded,
          color: AppColors.textHintDark,
          activeColor: AppColors.rose,
          isActive: false,
        ),
      ],
    );
  }

  Widget _buildPreview(BuildContext context) {
    return Text(
      note.preview,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.60,
          ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(
          Icons.access_time_rounded,
          size: 11,
          color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
        ),
        const SizedBox(width: 3),
        Text(
          note.getFormattedDate(loc.isArabic),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(width: 8),
        Container(
          width: 2,
          height: 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${note.wordCount} ${loc.translate('wordsCount')}',
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
          ),
        ),
        const Spacer(),
        if (note.hasMood) ...[
          Text(note.moodEmoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
        ],
        if (note.isEncrypted) const _EncryptedBadge(),
        if (note.isNew) ...[
          const SizedBox(width: 5),
          _NewBadge(loc: loc),
        ],
      ],
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: note.tags
          .take(4)
          .map((tag) => _TagChip(tag: tag, color: _categoryColor))
          .toList(),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.50),
      builder: (dialogContext) => AlertDialog(
        // ✅ بدون BackdropFilter
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
        title: Text(loc.translate('deleteNote')),
        content: Text(loc.translate('deleteConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(loc.translate('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rose,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop(); // ✅ أغلق أولاً
              onDelete(); // ✅ ثم نفّذ
            },
            child: Text(loc.translate('delete')),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color color;
  final Color activeColor;
  final bool isActive;

  const _ActionButton({
    required this.onTap,
    required this.icon,
    required this.color,
    required this.activeColor,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.10)
              : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppConstants.radiusXS),
          border: isActive
              ? Border.all(
                  color: activeColor.withValues(alpha: 0.22),
                  width: 0.8,
                )
              : null,
        ),
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  final Color color;
  const _TagChip({required this.tag, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.24),
          width: 0.8,
        ),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EncryptedBadge extends StatelessWidget {
  const _EncryptedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: AppColors.mint.withValues(alpha: 0.22),
          width: 0.8,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 9, color: AppColors.mint),
          SizedBox(width: 3),
          Text('🔒', style: TextStyle(fontSize: 9)),
        ],
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  final AppLocalizations loc;
  const _NewBadge({required this.loc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 6,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Text(
        loc.isArabic ? 'جديد' : 'NEW',
        style: const TextStyle(
          fontSize: 9,
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
