import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/router.dart';
import '../core/constants.dart';
import '../core/app_localizations.dart';
import '../core/app_gradients.dart';
import '../core/animations_helper.dart';
import '../core/glass_widget.dart';
import '../providers/notes_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/task_provider.dart';
import '../providers/app_lock_provider.dart';
import '../widgets/note_card.dart';
import '../widgets/empty_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearching = false;
  int _currentNavIndex = 0;
  bool _isScrolled = false;
  late AnimationController _bgCtrl;

  static const List<Map<String, dynamic>> _categories = [
    {'value': 'all', 'emoji': '📚'},
    {'value': 'personal', 'emoji': '📔'},
    {'value': 'work', 'emoji': '💼'},
    {'value': 'ideas', 'emoji': '💡'},
    {'value': 'health', 'emoji': '❤️'},
    {'value': 'travel', 'emoji': '✈️'},
    {'value': 'favorites', 'emoji': '⭐'},
  ];

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotesProvider>().loadNotes();
        context.read<TaskProvider>().loadTasks();
      }
    });
  }

  void _onScroll() {
    final scrolled = _scrollController.offset > 10;
    if (scrolled != _isScrolled) {
      setState(() => _isScrolled = scrolled);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    context.read<TaskProvider>().setLanguage(loc.isArabic);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Stack(
        children: [
          _buildAnimatedBackground(isDark),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(loc, isDark),
                _buildStatsBar(loc, isDark),
                _buildCategoryFilter(loc, isDark),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => context.read<NotesProvider>().loadNotes(),
                    color: AppColors.primary,
                    backgroundColor:
                        isDark ? AppColors.darkCard : AppColors.lightCard,
                    child: _buildNotesList(loc, isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<NotesProvider>(
        builder: (_, p, __) =>
            p.filteredNotes.isEmpty ? const SizedBox.shrink() : _buildFAB(loc),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomBar(loc, isDark),
    );
  }

  Widget _buildAnimatedBackground(bool isDark) {
    return Positioned.fill(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _bgCtrl,
          builder: (_, __) => Container(
            decoration: BoxDecoration(
              gradient: AppGradients.background(isDark),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -80 + _bgCtrl.value * 25,
                  right: -80,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(
                        alpha: 0.04 + _bgCtrl.value * 0.02,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -60 + _bgCtrl.value * 20,
                  left: -60,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cyan.withValues(
                        alpha: 0.03 + _bgCtrl.value * 0.015,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(AppLocalizations loc, bool isDark) {
    return AnimatedSwitcher(
      duration: AppConstants.animNormal,
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: _isSearching
          ? _buildSearchBar(loc, isDark)
          : _buildNormalAppBar(loc, isDark),
    );
  }

  Widget _buildNormalAppBar(AppLocalizations loc, bool isDark) {
    return Padding(
      key: const ValueKey('normal'),
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Beyond Silence',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        fontSize: 28,
                      ),
                  softWrap: true,
                ),
                Consumer<NotesProvider>(
                  builder: (_, p, __) => Text(
                    '${p.totalNotes} ${loc.translate('totalNotes')} · ${p.todayCount} ${loc.translate('todayNotes')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          _AppBarButton(
            icon: Icons.search_rounded,
            onTap: () => setState(() => _isSearching = true),
          ),
          _AppBarButton(
            icon: Icons.auto_awesome_rounded,
            color: AppColors.primary,
            onTap: () => Navigator.pushNamed(context, AppRouter.chat),
            hasGlow: true,
          ),
          _AppBarButton(
            icon: Icons.tune_rounded,
            onTap: () => _showSettingsSheet(context, loc, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations loc, bool isDark) {
    return Padding(
      key: const ValueKey('search'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 14,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    decoration: InputDecoration(
                      hintText: loc.translate('searchHint'),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (q) => context.read<NotesProvider>().search(q),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PressScale(
            onTap: () {
              setState(() => _isSearching = false);
              _searchController.clear();
              context.read<NotesProvider>().clearSearch();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.white.withValues(alpha: 0.80),
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 0.8,
                ),
              ),
              child: Icon(
                Icons.close_rounded,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(AppLocalizations loc, bool isDark) {
    return Consumer<NotesProvider>(
      builder: (_, p, __) {
        if (p.totalNotes == 0) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                            AppColors.cyan.withValues(alpha: 0.04),
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
                      value: p.totalNotes,
                      label: loc.translate('notes'),
                      icon: Icons.auto_stories_rounded,
                      color: AppColors.primary,
                    ),
                    _Divider(isDark: isDark),
                    _StatItem(
                      value: p.favoriteCount,
                      label: loc.translate('favorites'),
                      icon: Icons.favorite_rounded,
                      color: AppColors.rose,
                    ),
                    _Divider(isDark: isDark),
                    _StatItem(
                      value: p.todayCount,
                      label: loc.translate('todayNotes'),
                      icon: Icons.today_rounded,
                      color: AppColors.gold,
                    ),
                    _Divider(isDark: isDark),
                    _StatItem(
                      value: p.totalWords,
                      label: loc.translate('wordsCount'),
                      icon: Icons.text_fields_rounded,
                      color: AppColors.mint,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 150.ms).slideY(begin: -0.06);
      },
    );
  }

  Widget _buildCategoryFilter(AppLocalizations loc, bool isDark) {
    return Consumer<NotesProvider>(
      builder: (_, p, __) => SizedBox(
        height: 52,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          itemCount: _categories.length,
          itemBuilder: (_, i) {
            final cat = _categories[i];
            final isSelected = p.selectedCategory == cat['value'];
            final label = loc.translate(cat['value'] as String);
            final count = p.countByCategory(cat['value'] as String);

            return PressScale(
              onTap: () => context
                  .read<NotesProvider>()
                  .filterByCategory(cat['value'] as String),
              child: AnimatedContainer(
                duration: AppConstants.animFast,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppGradients.primary : null,
                  color: isSelected
                      ? null
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.75)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                    width: 0.8,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.32),
                            blurRadius: 12,
                            spreadRadius: -3,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat['emoji'] as String,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                      ),
                    ),
                    if (count > 0 && isSelected) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotesList(AppLocalizations loc, bool isDark) {
    return Consumer<NotesProvider>(
      builder: (context, p, _) {
        if (p.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                    backgroundColor: isDark
                        ? AppColors.darkElevated
                        : AppColors.lightElevated,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  loc.translate('loading'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        if (p.filteredNotes.isEmpty) {
          return EmptyState(
            icon: p.isSearching
                ? Icons.search_off_rounded
                : Icons.note_add_rounded,
            title: p.isSearching
                ? loc.translate('noSearchResults')
                : loc.translate('noNotes'),
            subtitle: p.isSearching
                ? loc.translate('noSearchResultsSubtitle')
                : loc.translate('noNotesSubtitle'),
            buttonText: p.isSearching ? null : loc.translate('newNote'),
            onButtonPressed: p.isSearching
                ? null
                : () => Navigator.pushNamed(context, AppRouter.noteEditor),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          itemCount: p.filteredNotes.length,
          itemBuilder: (_, i) {
            final note = p.filteredNotes[i];
            return NoteCard(
              note: note,
              index: i,
              onTap: () => Navigator.pushNamed(
                context,
                AppRouter.noteDetail,
                arguments: note,
              ),
              onFavoriteToggle: () => p.toggleFavorite(note),
              onPinToggle: () => p.togglePin(note),
              onDelete: () => p.deleteNote(note.id),
            );
          },
        );
      },
    );
  }

  Widget _buildFAB(AppLocalizations loc) {
    return PressScale(
      onTap: () => Navigator.pushNamed(context, AppRouter.noteEditor),
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
            BoxShadow(
              color: AppColors.cyan.withValues(alpha: 0.15),
              blurRadius: 14,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              loc.translate('newNote'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(delay: 400.ms, curve: Curves.elasticOut);
  }

  Widget _buildBottomBar(AppLocalizations loc, bool isDark) {
    return GlassBar(
      isBottom: true,
      height: 72,
      child: Row(
        children: [
          _NavItem(
            icon: Icons.auto_stories_outlined,
            activeIcon: Icons.auto_stories_rounded,
            label: loc.translate('notes'),
            isActive: _currentNavIndex == 0,
            onTap: () => setState(() => _currentNavIndex = 0),
          ),
          _NavItem(
            icon: Icons.auto_awesome_outlined,
            activeIcon: Icons.auto_awesome_rounded,
            label: loc.translate('assistant'),
            isActive: _currentNavIndex == 1,
            onTap: () {
              setState(() => _currentNavIndex = 1);
              Navigator.pushNamed(context, AppRouter.chat).then((_) {
                if (mounted) setState(() => _currentNavIndex = 0);
              });
            },
          ),
          _NavItem(
            icon: Icons.checklist_outlined,
            activeIcon: Icons.checklist_rounded,
            label: loc.isArabic ? 'المهام' : 'Tasks',
            isActive: _currentNavIndex == 2,
            onTap: () {
              setState(() => _currentNavIndex = 2);
              Navigator.pushNamed(context, AppRouter.tasks).then((_) {
                if (mounted) setState(() => _currentNavIndex = 0);
              });
            },
            badge: Consumer<TaskProvider>(
              builder: (_, tp, __) => tp.overdueCount > 0
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.rose,
                        shape: BoxShape.circle,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FrostedPanel(
        topRadius: AppConstants.radiusXXL,
        padding: const EdgeInsets.fromLTRB(
          AppConstants.padLG,
          AppConstants.padSM,
          AppConstants.padLG,
          AppConstants.padLG,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                loc.translate('settings'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryLight,
                    ),
              ),
              const SizedBox(height: 24),
              Consumer<ThemeProvider>(
                builder: (_, tp, __) => _SettingsTile(
                  icon: tp.isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  title: tp.getThemeName(loc.isArabic),
                  subtitle: loc.isArabic
                      ? 'تغيير مظهر التطبيق'
                      : 'Change app appearance',
                  color: AppColors.primary,
                  trailing: _ThemeToggle(
                    isDark: tp.isDark,
                    onToggle: tp.toggleTheme,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Consumer<LocaleProvider>(
                builder: (_, lp, __) => _SettingsTile(
                  icon: Icons.translate_rounded,
                  title: loc.translate('language'),
                  subtitle: lp.languageName,
                  color: AppColors.cyan,
                  trailing: PressScale(
                    onTap: lp.toggleLocale,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.32),
                            blurRadius: 12,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Text(
                        lp.isArabic ? 'EN' : 'ع',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _SettingsTile(
                icon: Icons.lock_rounded,
                title: loc.translate('privacySecurity'),
                subtitle: loc.translate('encryptNotesSub'),
                color: AppColors.mint,
                trailing: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.mint,
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),
              Consumer<AppLockProvider>(
                builder: (_, lock, __) => _SettingsTile(
                  icon: Icons.lock_clock_rounded,
                  title: loc.isArabic ? 'قفل التطبيق' : 'App Lock',
                  subtitle: lock.isEnabled
                      ? (loc.isArabic ? 'مفعل' : 'Enabled')
                      : (loc.isArabic ? 'غير مفعل' : 'Disabled'),
                  color: AppColors.gold,
                  trailing: Switch(
                    value: lock.isEnabled,
                    onChanged: (v) async {
                      if (v) {
                        await _showSetPinDialog(context, lock, loc.isArabic);
                      } else {
                        await lock.disableAndClear();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSetPinDialog(
    BuildContext context,
    AppLockProvider lock,
    bool isArabic,
  ) async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'تعيين رقم القفل' : 'Set lock PIN'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: InputDecoration(
            hintText: isArabic ? '4-6 أرقام' : '4-6 digits',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final pin = ctrl.text.trim();
              if (pin.length >= 4 && pin.length <= 6) {
                await lock.setPin(pin);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: Text(isArabic ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets (unchanged) ──────────────────────────────────────

class _AppBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final bool hasGlow;

  const _AppBarButton({
    required this.icon,
    required this.onTap,
    this.color,
    this.hasGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = color ??
        (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    return PressScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.16),
            width: 0.8,
          ),
          boxShadow: hasGlow
              ? [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.28),
                    blurRadius: 12,
                    spreadRadius: -3,
                  ),
                ]
              : null,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

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
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CountingNumber(
              value: value,
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Widget? badge;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PressScale(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: AppConstants.animFast,
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    key: ValueKey(isActive),
                    color:
                        isActive ? AppColors.primary : AppColors.textHintDark,
                    size: 24,
                  ),
                ),
                if (badge != null)
                  Positioned(top: -2, right: -2, child: badge!),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.textHintDark,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
            AnimatedContainer(
              duration: AppConstants.animFast,
              margin: const EdgeInsets.only(top: 3),
              height: 2,
              width: isActive ? 20 : 0,
              decoration: BoxDecoration(
                gradient: isActive ? AppGradients.primary : null,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const _ThemeToggle({required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: AppConstants.animNormal,
        width: 52,
        height: 30,
        decoration: BoxDecoration(
          gradient: isDark ? AppGradients.primary : null,
          color: isDark ? null : AppColors.lightBorder,
          borderRadius: BorderRadius.circular(15),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.30),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: AnimatedAlign(
          duration: AppConstants.animNormal,
          curve: Curves.easeOutCubic,
          alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  spreadRadius: -1,
                ),
              ],
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              size: 13,
              color: isDark ? AppColors.primary : AppColors.textHintLight,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          border: Border.all(
            color: color.withValues(alpha: 0.20),
            width: 0.8,
          ),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: trailing,
    );
  }
}
