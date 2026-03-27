import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/router.dart';
import '../core/app_localizations.dart';
import '../core/app_gradients.dart';
import '../core/animations_helper.dart';
import '../core/constants.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';

class NoteDetailScreen extends StatelessWidget {
  final Note note;
  const NoteDetailScreen({required this.note, super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Stack(
        children: [
          _buildBackground(isDark),
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, loc, isDark),
              SliverToBoxAdapter(
                child: _buildContent(context, loc, isDark),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context, loc),
    );
  }

  // ✅ إصلاح: Positioned مع height مباشرة
  Widget _buildBackground(bool isDark) {
    final catColor = _getCategoryColor();
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 320,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              catColor.withValues(alpha: isDark ? 0.18 : 0.12),
              catColor.withValues(alpha: isDark ? 0.06 : 0.04),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
  ) {
    return SliverAppBar(
      expandedHeight: 210,
      pinned: true,
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: PressScale(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
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
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            size: 18,
          ),
        ),
      ),
      actions: [
        // ✅ إصلاح: قراءة المذكرة المحدثة من Provider
        Consumer<NotesProvider>(
          builder: (context, notesProvider, _) {
            final currentNote = notesProvider.getNoteById(note.id) ?? note;
            return PressScale(
              onTap: () => notesProvider.toggleFavorite(currentNote),
              child: Container(
                margin: const EdgeInsets.only(right: 4, top: 8, bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: currentNote.isFavorite
                      ? AppColors.rose.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                  border: currentNote.isFavorite
                      ? Border.all(
                          color: AppColors.rose.withValues(alpha: 0.30),
                          width: 0.8,
                        )
                      : null,
                ),
                child: Icon(
                  currentNote.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: currentNote.isFavorite
                      ? AppColors.rose
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                  size: 22,
                ),
              ),
            );
          },
        ),
        PressScale(
          onTap: () => Navigator.pushNamed(
            context,
            AppRouter.noteEditor,
            arguments: note,
          ),
          child: Container(
            margin: const EdgeInsets.only(right: 4, top: 8, bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
                width: 0.8,
              ),
            ),
            child: const Icon(
              Icons.edit_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ),
        PopupMenuButton<String>(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.8,
            ),
          ),
          elevation: 12,
          itemBuilder: (_) => [
            _buildPopupItem(
              Icons.chat_rounded,
              loc.translate('talkWithAI'),
              'chat',
              AppColors.cyan,
            ),
            _buildPopupItem(
              Icons.push_pin_rounded,
              note.isPinned ? loc.translate('unpin') : loc.translate('pin'),
              'pin',
              AppColors.gold,
            ),
            _buildPopupItem(
              Icons.copy_rounded,
              loc.translate('copyText'),
              'copy',
              AppColors.primary,
            ),
            _buildPopupItem(
              Icons.delete_rounded,
              loc.translate('delete'),
              'delete',
              AppColors.rose,
            ),
          ],
          onSelected: (value) => _handleMenuAction(context, value, loc, isDark),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeroSection(context, loc, isDark),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
  ) {
    final catColor = _getCategoryColor();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 90, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppGradients.forCategory(note.category),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: catColor.withValues(alpha: 0.30),
                      blurRadius: 10,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(note.categoryEmoji,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      note.getCategoryLabel(loc.isArabic),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (note.mood != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: catColor.withValues(alpha: 0.28),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(note.moodEmoji,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        note.getMoodLabel(loc.isArabic),
                        style: TextStyle(
                          fontSize: 11,
                          color: catColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              if (note.isPinned)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.30),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.push_pin_rounded,
                          size: 11, color: AppColors.gold),
                      const SizedBox(width: 4),
                      Text(
                        loc.isArabic ? 'مثبت' : 'Pinned',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              if (note.isNew)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    loc.isArabic ? 'جديد' : 'NEW',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            note.title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06);
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.padMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNoteStats(context, loc, isDark),
          const SizedBox(height: 20),
          _buildNoteContent(context, isDark),
          const SizedBox(height: 20),
          if (note.tags.isNotEmpty) ...[
            _buildTags(context),
            const SizedBox(height: 20),
          ],
          _buildDateInfo(context, loc, isDark),
          const SizedBox(height: 110),
        ],
      ),
    );
  }

  Widget _buildNoteStats(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.padMD, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip(
                icon: Icons.text_fields_rounded,
                value: '${note.wordCount}',
                label: loc.translate('wordsCount'),
                color: AppColors.primary,
              ),
              _VerticalDivider(isDark: isDark),
              _StatChip(
                icon: Icons.timer_outlined,
                value: '${note.readingMinutes}',
                label: loc.isArabic ? 'دقيقة' : 'min',
                color: AppColors.cyan,
              ),
              _VerticalDivider(isDark: isDark),
              _StatChip(
                icon: note.isEncrypted
                    ? Icons.lock_rounded
                    : Icons.lock_open_rounded,
                value: note.isEncrypted
                    ? (loc.isArabic ? 'مشفّر' : 'Enc.')
                    : (loc.isArabic ? 'عادي' : 'Plain'),
                label: '',
                color:
                    note.isEncrypted ? AppColors.mint : AppColors.textHintDark,
              ),
              _VerticalDivider(isDark: isDark),
              _StatChip(
                icon: Icons.today_rounded,
                value: note.getFormattedDate(loc.isArabic),
                label: '',
                color: AppColors.gold,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05);
  }

  Widget _buildNoteContent(BuildContext context, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.radiusLG),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.padLG),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.8,
            ),
          ),
          child: MarkdownBody(
            data: note.content,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontSize: 16,
                height: 1.85,
              ),
              h1: TextStyle(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
              h2: TextStyle(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
              h3: TextStyle(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              strong: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
              em: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontStyle: FontStyle.italic,
              ),
              code: TextStyle(
                fontFamily: 'monospace',
                backgroundColor:
                    isDark ? const Color(0xFF0D0D1A) : const Color(0xFFEDE9FF),
                color: AppColors.primary,
                fontSize: 14,
              ),
              codeblockDecoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF0D0D1A) : const Color(0xFFEDE9FF),
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.20),
                  width: 0.8,
                ),
              ),
              // ✅ إصلاح: يدعم RTL و LTR معاً
              blockquoteDecoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.primary, width: 3),
                  right: BorderSide(color: AppColors.primary, width: 3),
                ),
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildTags(BuildContext context) {
    final catColor = _getCategoryColor();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: note.tags.map((tag) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: catColor.withValues(alpha: 0.22),
                  width: 0.8,
                ),
              ),
              child: Text(
                '#$tag',
                style: TextStyle(
                  color: catColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildDateInfo(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(
          Icons.access_time_rounded,
          size: 13,
          color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
        ),
        const SizedBox(width: 5),
        Text(
          note.getFormattedDate(loc.isArabic),
          style: TextStyle(
            color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
            fontSize: 12,
          ),
        ),
        if (note.isModified) ...[
          const SizedBox(width: 12),
          Icon(
            Icons.edit_outlined,
            size: 11,
            color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
          ),
          const SizedBox(width: 4),
          Text(
            loc.isArabic ? 'تم التعديل' : 'Modified',
            style: TextStyle(
              color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
              fontSize: 11,
            ),
          ),
        ],
        const Spacer(),
        PressScale(
          onTap: () {
            Clipboard.setData(ClipboardData(text: note.content));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loc.translate('copied')),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.copy_rounded,
                  size: 12,
                  color:
                      isDark ? AppColors.textHintDark : AppColors.textHintLight,
                ),
                const SizedBox(width: 4),
                Text(
                  loc.translate('copyText'),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.textHintDark
                        : AppColors.textHintLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildFAB(BuildContext context, AppLocalizations loc) {
    return PressScale(
      onTap: () => Navigator.pushNamed(
        context,
        AppRouter.chat,
        arguments: note,
      ),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          gradient: AppGradients.aurora,
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.42),
              blurRadius: 22,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              loc.translate('talkWithAI'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(delay: 300.ms, curve: Curves.elasticOut);
  }

  Color _getCategoryColor() {
    final cat = AppConstants.categories.firstWhere(
      (c) => c['value'] == note.category,
      orElse: () => AppConstants.categories.last,
    );
    return cat['color'] as Color;
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    AppLocalizations loc,
    bool isDark,
  ) {
    switch (action) {
      case 'chat':
        Navigator.pushNamed(context, AppRouter.chat, arguments: note);
        break;
      case 'pin':
        context.read<NotesProvider>().togglePin(note);
        break;
      case 'copy':
        Clipboard.setData(ClipboardData(text: note.content));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.translate('copied')),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
          ),
        );
        break;
      case 'delete':
        _confirmDelete(context, loc, isDark);
        break;
    }
  }

  void _confirmDelete(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: AlertDialog(
          backgroundColor: isDark
              ? AppColors.darkCard.withValues(alpha: 0.97)
              : Colors.white.withValues(alpha: 0.97),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
            side: BorderSide(
              color: AppColors.rose.withValues(alpha: 0.20),
              width: 0.8,
            ),
          ),
          icon: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.rose.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.rose.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.delete_rounded,
              color: AppColors.rose,
              size: 28,
            ),
          ),
          title: Text(loc.translate('deleteNote')),
          content: Text(loc.translate('deleteConfirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.translate('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rose,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () {
                context.read<NotesProvider>().deleteNote(note.id);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text(loc.translate('delete')),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (label.isNotEmpty)
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textHintDark,
              fontSize: 9,
            ),
          ),
      ],
    );
  }
}

// ─── Vertical Divider ─────────────────────────────────────────────
class _VerticalDivider extends StatelessWidget {
  final bool isDark;
  const _VerticalDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.8,
      height: 28,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }
}
