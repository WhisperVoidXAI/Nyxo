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
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../providers/model_provider.dart';
import '../providers/chat_provider.dart';
import '../services/database_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? existingNote;
  const NoteEditorScreen({super.key, this.existingNote});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  late TextEditingController _tagCtrl;
  late FocusNode _titleFocus;
  late FocusNode _contentFocus;

  late String _category;
  String? _mood;
  List<String> _tags = [];
  bool _isSaving = false;
  bool _isAiLoading = false;
  int _wordCount = 0;
  int _charCount = 0;
  bool _draftLoaded = false;

  bool get _isEditing => widget.existingNote != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _titleCtrl = TextEditingController(text: widget.existingNote?.title ?? '');
    _contentCtrl =
        TextEditingController(text: widget.existingNote?.content ?? '');
    _tagCtrl = TextEditingController();
    _titleFocus = FocusNode()..addListener(() => setState(() {}));
    _contentFocus = FocusNode()..addListener(() => setState(() {}));
    _category = widget.existingNote?.category ?? 'personal';
    _mood = widget.existingNote?.mood;
    _tags = List.from(widget.existingNote?.tags ?? []);
    _contentCtrl.addListener(_updateCounts);
    _updateCounts();
    if (!_isEditing) {
      _loadDraftIfNeeded();
    }
  }

  void _updateCounts() {
    final text = _contentCtrl.text;
    final cleaned = text
        .replaceAll(RegExp(r'[#*`_>~\[\]()\-=+|]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    setState(() {
      _wordCount = cleaned.isEmpty
          ? 0
          : cleaned
              .split(' ')
              .where((w) => w.trim().isNotEmpty && w.trim().length > 1)
              .length;
      _charCount = text.length;
    });
  }

  void _loadDraftIfNeeded() {
    if (_draftLoaded || _isEditing) return;
    _draftLoaded = true;
    try {
      final db = DatabaseService();
      final draft = db.getSetting<Map>(AppConstants.noteEditorDraftKey);
      if (draft == null) return;

      final title = (draft['title'] as String?) ?? '';
      final content = (draft['content'] as String?) ?? '';
      final category = (draft['category'] as String?) ?? 'personal';
      final mood = draft['mood'] as String?;
      final tagsAny = draft['tags'];
      final tags = tagsAny is List ? tagsAny.cast<String>() : <String>[];

      _titleCtrl.text = title;
      _contentCtrl.text = content;
      _category = category;
      _mood = mood;
      _tags = tags;
      _updateCounts();
    } catch (_) {
      // If draft restore fails, continue with empty/new state.
    }
  }

  Future<void> _persistDraft() async {
    if (_isEditing) return;
    try {
      final db = DatabaseService();
      await db.saveSetting(AppConstants.noteEditorDraftKey, {
        'title': _titleCtrl.text,
        'content': _contentCtrl.text,
        'category': _category,
        'mood': _mood,
        'tags': _tags,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> _clearDraft() async {
    if (_isEditing) return;
    try {
      await DatabaseService().deleteSetting(AppConstants.noteEditorDraftKey);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isEditing) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _persistDraft();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tagCtrl.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(context, loc, isDark),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          AppConstants.padMD,
          AppConstants.padSM,
          AppConstants.padMD,
          AppConstants.padMD + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleField(context, loc, isDark)
                .animate()
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 14),
            _buildCategorySelector(context, loc, isDark)
                .animate()
                .fadeIn(delay: 80.ms),
            const SizedBox(height: 18),
            _buildContentField(context, loc, isDark)
                .animate()
                .fadeIn(delay: 140.ms),
            const SizedBox(height: 18),
            _buildMoodSelector(context, loc, isDark)
                .animate()
                .fadeIn(delay: 200.ms),
            const SizedBox(height: 18),
            _buildTagsField(context, loc, isDark)
                .animate()
                .fadeIn(delay: 260.ms),
            const SizedBox(height: 130),
          ],
        ),
      ),
      floatingActionButton: _buildSaveFAB(context, loc),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: PressScale(
        onTap: () => _confirmDiscard(context, loc),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
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
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            size: 18,
          ),
        ),
      ),
      title: Text(
        _isEditing ? loc.translate('editNote') : loc.translate('newNoteTitle'),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
      actions: [
        // ✅ إصلاح: استخدام ModelProvider بدلاً من AiService مباشرة
        if (context.read<ModelProvider>().isReady) ...[
          _buildAiButton(context, loc),
          const SizedBox(width: 4),
        ],
        if (_isEditing)
          PressScale(
            onTap: () => Navigator.pushNamed(
              context,
              AppRouter.chat,
              arguments: widget.existingNote,
            ),
            child: Container(
              margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                border: Border.all(
                  color: AppColors.cyan.withValues(alpha: 0.20),
                  width: 0.8,
                ),
              ),
              child: const Icon(
                Icons.chat_rounded,
                color: AppColors.cyan,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAiButton(BuildContext context, AppLocalizations loc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopupMenuButton<String>(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      elevation: 12,
      offset: const Offset(0, 44),
      child: Container(
        margin: const EdgeInsets.only(right: 4, top: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: AppGradients.aurora,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.32),
              blurRadius: 12,
              spreadRadius: -3,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isAiLoading
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
            const SizedBox(width: 5),
            const Text(
              'AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (_) => [
        _buildAiMenuItem(
          Icons.title_rounded,
          loc.translate('suggestTitle'),
          'title',
          AppColors.primary,
        ),
        _buildAiMenuItem(
          Icons.auto_fix_high_rounded,
          loc.translate('aiImprove'),
          'improve',
          AppColors.cyan,
        ),
        _buildAiMenuItem(
          Icons.summarize_rounded,
          loc.translate('aiSummarize'),
          'summarize',
          AppColors.gold,
        ),
      ],
      onSelected: (action) => _handleAiAction(action, loc),
    );
  }

  PopupMenuItem<String> _buildAiMenuItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildTitleField(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleCtrl,
          focusNode: _titleFocus,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.3,
              ),
          decoration: InputDecoration(
            hintText: loc.translate('titleHint'),
            hintStyle: TextStyle(
              color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
              fontSize: 22,
              fontWeight: FontWeight.w400,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
          maxLines: null,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _contentFocus.requestFocus(),
        ),
        AnimatedContainer(
          duration: AppConstants.animNormal,
          height: 2,
          decoration: BoxDecoration(
            gradient: _titleFocus.hasFocus
                ? AppGradients.aurora
                : LinearGradient(colors: [
                    isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ]),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
  ) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: AppConstants.categories.map((cat) {
          final isSelected = _category == cat['value'];
          final catColor = cat['color'] as Color;

          return PressScale(
            onTap: () => setState(() => _category = cat['value'] as String),
            child: AnimatedContainer(
              duration: AppConstants.animFast,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? AppGradients.forCategory(cat['value'] as String)
                    : null,
                color: isSelected
                    ? null
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.75)),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: 0.8,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: catColor.withValues(alpha: 0.32),
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
                    loc.isArabic
                        ? cat['label'] as String
                        : cat['labelEn'] as String,
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
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContentField(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.radiusLG),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AnimatedContainer(
          duration: AppConstants.animFast,
          constraints: const BoxConstraints(minHeight: 260),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
            border: Border.all(
              color: _contentFocus.hasFocus
                  ? AppColors.primary.withValues(alpha: 0.55)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: _contentFocus.hasFocus ? 1.5 : 0.8,
            ),
            boxShadow: _contentFocus.hasFocus
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      blurRadius: 18,
                      spreadRadius: -3,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.padMD,
                  vertical: AppConstants.padSM,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.02),
                  border: Border(
                    bottom: BorderSide(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 0.8,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (b) =>
                          AppGradients.primary.createShader(b),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      loc.translate('markdownLabel'),
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textHintDark
                            : AppColors.textHintLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_wordCount ${loc.translate('wordsCount')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_charCount ${loc.translate('charsCount')}',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textHintDark
                            : AppColors.textHintLight,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppConstants.padMD),
                child: TextField(
                  controller: _contentCtrl,
                  focusNode: _contentFocus,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    height: 1.85,
                  ),
                  decoration: InputDecoration(
                    hintText: loc.translate('contentHint'),
                    hintStyle: TextStyle(
                      color: isDark
                          ? AppColors.textHintDark
                          : AppColors.textHintLight,
                      fontSize: 15,
                      height: 1.7,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodSelector(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ShaderMask(
              shaderCallback: (b) => AppGradients.aurora.createShader(b),
              child:
                  const Icon(Icons.mood_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              loc.translate('mood'),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: AppConstants.moods.map((mood) {
              final isSelected = _mood == mood['value'];
              final moodColor = mood['color'] as Color;

              return PressScale(
                onTap: () => setState(() {
                  _mood = isSelected ? null : mood['value'] as String;
                }),
                child: AnimatedContainer(
                  duration: AppConstants.animFast,
                  margin: const EdgeInsets.only(right: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? moodColor.withValues(alpha: 0.16)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white.withValues(alpha: 0.75)),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                    border: Border.all(
                      color: isSelected
                          ? moodColor
                          : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                      width: isSelected ? 1.5 : 0.8,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: moodColor.withValues(alpha: 0.22),
                              blurRadius: 12,
                              spreadRadius: -3,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        mood['emoji'] as String,
                        style: TextStyle(fontSize: isSelected ? 28 : 22),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loc.isArabic
                            ? mood['label'] as String
                            : mood['labelEn'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.normal,
                          color: isSelected
                              ? moodColor
                              : (isDark
                                  ? AppColors.textHintDark
                                  : AppColors.textHintLight),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsField(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
  ) {
    final catColor = AppConstants.categories.firstWhere(
      (c) => c['value'] == _category,
      orElse: () => AppConstants.categories.last,
    )['color'] as Color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ShaderMask(
              shaderCallback: (b) =>
                  AppGradients.forCategory(_category).createShader(b),
              child: const Icon(Icons.label_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              loc.translate('tags'),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 0.8,
                ),
              ),
              child: Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  ..._tags.map((tag) {
                    return PressScale(
                      onTap: () => setState(() => _tags.remove(tag)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: catColor.withValues(alpha: 0.28),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '#$tag',
                              style: TextStyle(
                                fontSize: 12,
                                color: catColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(Icons.close_rounded,
                                size: 11, color: catColor),
                          ],
                        ),
                      ),
                    );
                  }),
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: _tagCtrl,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      decoration: InputDecoration(
                        hintText: loc.translate('newTag'),
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textHintDark
                              : AppColors.textHintLight,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        prefixText: '# ',
                        prefixStyle: TextStyle(
                          color: catColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onSubmitted: (tag) {
                        final t = tag.trim();
                        if (t.isNotEmpty &&
                            !_tags.contains(t) &&
                            _tags.length < AppConstants.maxTagsPerNote) {
                          setState(() {
                            _tags.add(t);
                          });
                          _tagCtrl.clear();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveFAB(BuildContext context, AppLocalizations loc) {
    return PressScale(
      onTap: _isSaving ? null : () => _saveNote(context, loc),
      child: AnimatedContainer(
        duration: AppConstants.animFast,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        decoration: BoxDecoration(
          gradient: _isSaving
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.55),
                    AppColors.cyan.withValues(alpha: 0.55),
                  ],
                )
              : AppGradients.aurora,
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
            _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded,
                    color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              _isSaving ? loc.translate('saving') : loc.translate('save'),
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
    ).animate().scale(delay: 300.ms, curve: Curves.elasticOut);
  }

  // ✅ إصلاح: استخدام ChatProvider بدلاً من AiService مباشرة
  Future<void> _handleAiAction(String action, AppLocalizations loc) async {
    if (_contentCtrl.text.trim().isEmpty) return;
    setState(() => _isAiLoading = true);

    final chatProvider = context.read<ChatProvider>();

    try {
      switch (action) {
        case 'title':
          final title = await chatProvider.suggestTitle(_contentCtrl.text);
          if (title != null && title.isNotEmpty && mounted) {
            setState(() => _titleCtrl.text = title);
          }
          break;

        case 'improve':
          final improved = await chatProvider.improveText(_contentCtrl.text);
          if (improved != null && improved.isNotEmpty && mounted) {
            setState(() => _contentCtrl.text = improved);
            _updateCounts();
          }
          break;

        case 'summarize':
          final summary = await chatProvider.summarize(_contentCtrl.text);
          if (summary != null && summary.isNotEmpty && mounted) {
            _showSummaryDialog(summary, loc);
          }
          break;
      }
    } finally {
      if (mounted) setState(() => _isAiLoading = false);
    }
  }

  void _showSummaryDialog(String summary, AppLocalizations loc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          ),
          title: Row(
            children: [
              ShaderMask(
                shaderCallback: (b) => AppGradients.aurora.createShader(b),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              Text(loc.translate('aiSummarize')),
            ],
          ),
          content: Text(
            summary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.7,
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.translate('ok')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNote(BuildContext context, AppLocalizations loc) async {
    if (_contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.translate('contentRequired')),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          ),
        ),
      );
      return;
    }

    final navigator = Navigator.of(context);
    final notesProvider = context.read<NotesProvider>();

    setState(() => _isSaving = true);

    final content = _contentCtrl.text.trim();
    final title = _titleCtrl.text.trim().isNotEmpty
        ? _titleCtrl.text.trim()
        : content.substring(
            0,
            content.length > AppConstants.maxNoteTitle
                ? AppConstants.maxNoteTitle
                : content.length,
          );

    if (_isEditing) {
      final updated = widget.existingNote!.copyWith(
        title: title,
        content: content,
        category: _category,
        mood: _mood,
        tags: _tags,
      );
      await notesProvider.updateNote(updated);
    } else {
      // ✅ إصلاح: تمرير _category الصحيح
      final note = Note(
        title: title,
        content: content,
        category: _category,
        mood: _mood,
        tags: _tags,
        isEncrypted: true,
      );
      await notesProvider.addNote(note);
    }

    await _clearDraft();
    if (!mounted) return;
    setState(() => _isSaving = false);
    navigator.pop();
  }

  // ✅ إصلاح: تحذير عند التعديل أيضاً
  void _confirmDiscard(BuildContext context, AppLocalizations loc) {
    final original = widget.existingNote;
    final hasChanges = original == null
        ? (_titleCtrl.text.isNotEmpty || _contentCtrl.text.isNotEmpty)
        : (original.title != _titleCtrl.text.trim() ||
            original.content != _contentCtrl.text.trim() ||
            original.category != _category ||
            original.mood != _mood);

    if (!hasChanges) {
      _clearDraft();
      Navigator.pop(context);
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AlertDialog(
          backgroundColor: isDark
              ? AppColors.darkCard.withValues(alpha: 0.97)
              : Colors.white.withValues(alpha: 0.97),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          ),
          icon: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.rose.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: AppColors.rose, size: 26),
          ),
          title: Text(
            loc.isArabic ? 'تجاهل التغييرات؟' : 'Discard changes?',
          ),
          content: Text(
            loc.isArabic
                ? 'سيتم فقدان كل ما كتبته'
                : 'Everything you wrote will be lost',
          ),
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
                Navigator.of(dialogContext).pop(); // close dialog only
                _clearDraft();
                Navigator.of(context).pop(); // close editor screen
              },
              child: Text(loc.isArabic ? 'تجاهل' : 'Discard'),
            ),
          ],
        ),
      ),
    );
  }

}
