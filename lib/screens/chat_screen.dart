import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/app_localizations.dart';
import '../core/app_gradients.dart';
import '../core/animations_helper.dart';
import '../core/constants.dart';
import '../models/note.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final Note? contextNote;
  const ChatScreen({super.key, this.contextNote});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  bool _showScrollBtn = false;
  bool _hasText = false;
  late AnimationController _sendBtnCtrl;
  late AnimationController _bgCtrl;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();

    _sendBtnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _scrollCtrl.addListener(_onScroll);
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });

    _msgCtrl.addListener(() {
      final hasText = _msgCtrl.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
        hasText ? _sendBtnCtrl.forward() : _sendBtnCtrl.reverse();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatProvider>().loadMessages(note: widget.contextNote);
      }
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _sendBtnCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final atBottom = _scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 120;
    if (_showScrollBtn == atBottom) {
      setState(() => _showScrollBtn = !atBottom);
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollCtrl.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      if (animated) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      extendBodyBehindAppBar: false,
      // ✅ إصلاح لوحة المفاتيح: false ونتحكم يدوياً
      resizeToAvoidBottomInset: false,
      appBar: _buildAppBar(context, loc, isDark),
      body: Stack(
        children: [
          _buildAnimatedBackground(isDark),
          SafeArea(
            child: Column(
              children: [
                if (widget.contextNote != null)
                  _buildContextBanner(context, loc, isDark),
                Expanded(
                  child: Stack(
                    children: [
                      _buildMessagesList(context, loc),
                      if (_showScrollBtn) _buildScrollButton(loc, isDark),
                    ],
                  ),
                ),
                // ✅ إصلاح: input يتحرك مع لوحة المفاتيح
                _buildInputArea(context, loc, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(bool isDark) {
    return AnimatedBuilder(
      animation: _bgCtrl,
      builder: (_, __) => Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: AppGradients.background(isDark),
            ),
          ),
          Positioned(
            top: -60 + _bgCtrl.value * 30,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 100 + _bgCtrl.value * 20,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withValues(alpha: 0.03),
              ),
            ),
          ),
        ],
      ),
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
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      leading: PressScale(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
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
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            size: 18,
          ),
        ),
      ),
      title: Row(
        children: [
          Consumer<ChatProvider>(
            builder: (_, p, __) => GlowPulse(
              glowColor: AppColors.primary,
              active: p.isGenerating,
              blurRadius: 18,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppGradients.aurora,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => AppGradients.primary.createShader(b),
                  child: Text(
                    loc.translate('aiAssistant'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                  ),
                ),
                Consumer<ChatProvider>(
                  builder: (_, p, __) => AnimatedSwitcher(
                    duration: AppConstants.animNormal,
                    child: Text(
                      key: ValueKey(p.isGenerating),
                      p.isGenerating
                          ? loc.translate('typing')
                          : (widget.contextNote?.title ??
                              loc.translate('generalChat')),
                      style: TextStyle(
                        fontSize: 11,
                        color: p.isGenerating
                            ? AppColors.primary
                            : AppColors.textHintDark,
                        fontWeight: p.isGenerating
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // ✅ زر محادثة جديدة
        PressScale(
          onTap: () {
            context.read<ChatProvider>().newConversation();
          },
          child: Container(
            margin: const EdgeInsets.only(right: 4, top: 8, bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.20),
                width: 0.8,
              ),
            ),
            child: const Icon(
              Icons.add_comment_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),
        // ✅ زر قائمة المحادثات
        PressScale(
          onTap: () => _showConversationsList(context, loc, isDark),
          child: Container(
            margin: const EdgeInsets.only(right: 4, top: 8, bottom: 8),
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
              Icons.chat_bubble_outline_rounded,
              color: AppColors.cyan,
              size: 20,
            ),
          ),
        ),
        // ✅ زر حذف المحادثة
        Consumer<ChatProvider>(
          builder: (_, p, __) => p.hasMessages
              ? PressScale(
                  onTap: () => _confirmClear(context, loc, isDark),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.rose.withValues(alpha: 0.10),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSM),
                      border: Border.all(
                        color: AppColors.rose.withValues(alpha: 0.20),
                        width: 0.8,
                      ),
                    ),
                    child: const Icon(
                      Icons.delete_sweep_rounded,
                      color: AppColors.rose,
                      size: 20,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildContextBanner(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.padMD,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.cyan.withValues(alpha: 0.07),
                ],
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusLG),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.28),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate('talkingAbout'),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textHintDark,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        widget.contextNote!.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.contextNote!.categoryEmoji,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1);
  }

  Widget _buildMessagesList(BuildContext context, AppLocalizations loc) {
    return Consumer<ChatProvider>(
      builder: (_, p, __) {
        if (!p.hasMessages) {
          _lastMessageCount = 0; // 👈 إعادة تعيين عند إفراغ المحادثة
          return _buildEmptyChat(context, loc);
        }

        // ✅ اسكرول فقط عند إضافة رسالة جديدة وليس عند تغيير المحادثة
        if (p.messageCount > _lastMessageCount) {
          _lastMessageCount = p.messageCount;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _scrollToBottom();
          });
        } else if (p.messageCount != _lastMessageCount) {
          // تغيّرت المحادثة (switch) → اسكرول فوري بدون أنيميشن
          _lastMessageCount = p.messageCount;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _scrollToBottom(animated: false);
          });
        }

        return ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: p.messages.length,
          itemBuilder: (_, i) {
            final msg = p.messages[i];
            final isLastMsg = i == p.messages.length - 1;
            final isStreaming = isLastMsg && p.isGenerating && msg.isAssistant;
            return MessageBubble(
              key: ValueKey<String>(msg.id),
              message: msg,
              isStreaming: isStreaming,
            ).animate().fadeIn(
                  delay: Duration(milliseconds: i == 0 ? 0 : 80),
                  duration: const Duration(milliseconds: 300),
                );
          },
        );
      },
    );
  }

  Widget _buildEmptyChat(BuildContext context, AppLocalizations loc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlowPulse(
              glowColor: AppColors.primary,
              blurRadius: 30,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: AppGradients.aurora,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.40),
                      blurRadius: 30,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ).animate().scale(
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 28),
            ShaderMask(
              shaderCallback: (b) => AppGradients.primary.createShader(b),
              child: Text(
                loc.translate('aiGreeting'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
            const SizedBox(height: 12),
            Text(
              widget.contextNote != null
                  ? loc.translate('aiGreetingNote')
                  : loc.translate('aiGreetingGeneral'),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 450.ms),
            const SizedBox(height: 28),
            _buildSuggestions(context, loc),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(BuildContext context, AppLocalizations loc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final suggestions = loc.isArabic
        ? ['✍️ ساعدني بكتابة فكرة', '📝 لخّص مذكرتي', '💡 اقترح عليّ']
        : [
            '✍️ Help me write an idea',
            '📝 Summarize my note',
            '💡 Suggest something'
          ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: suggestions.asMap().entries.map((e) {
        return PressScale(
          onTap: () {
            _msgCtrl.text = e.value;
            setState(() => _hasText = true);
            _sendBtnCtrl.forward();
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  e.value,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ).animate().fadeIn(
              delay: Duration(milliseconds: 550 + e.key * 80),
            );
      }).toList(),
    );
  }

  Widget _buildScrollButton(AppLocalizations loc, bool isDark) {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Center(
        child: PressScale(
          onTap: () => _scrollToBottom(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.65)
                      : Colors.white.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 12,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      loc.isArabic ? 'للأسفل' : 'Scroll down',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ).animate().fadeIn().slideY(begin: 0.2),
    );
  }

  // ✅ إصلاح لوحة المفاتيح: AnimatedPadding مع viewInsets
  Widget _buildInputArea(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
  ) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        Colors.black.withValues(alpha: 0.55),
                        AppColors.darkSurface.withValues(alpha: 0.40),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.90),
                        AppColors.lightBg.withValues(alpha: 0.75),
                      ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : AppColors.lightBorder.withValues(alpha: 0.70),
                  width: 0.8,
                ),
              ),
            ),
            child: Consumer<ChatProvider>(
              builder: (_, p, __) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: AppConstants.animNormal,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: _focusNode.hasFocus
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.15),
                                    blurRadius: 16,
                                    spreadRadius: -2,
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.07)
                                    : Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: _focusNode.hasFocus
                                      ? AppColors.primary
                                          .withValues(alpha: 0.55)
                                      : (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder),
                                  width: _focusNode.hasFocus ? 1.3 : 0.8,
                                ),
                              ),
                              child: TextField(
                                controller: _msgCtrl,
                                focusNode: _focusNode,
                                enabled: !p.isGenerating,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                                maxLines: 5,
                                minLines: 1,
                                decoration: InputDecoration(
                                  hintText: p.isGenerating
                                      ? loc.translate('thinking')
                                      : loc.translate('chatHint'),
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? AppColors.textHintDark
                                        : AppColors.textHintLight,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                ),
                                textInputAction: TextInputAction.newline,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedSwitcher(
                      duration: AppConstants.animFast,
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: p.isGenerating
                          ? _buildStopButton(p)
                          : _buildSendButton(p),
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

  Widget _buildSendButton(ChatProvider p) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PressScale(
      key: const ValueKey('send'),
      onTap: _hasText ? _sendMessage : null,
      child: AnimatedContainer(
        duration: AppConstants.animFast,
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: _hasText ? AppGradients.primary : null,
          // ✅ لون يتغير مع الثيم
          color: _hasText
              ? null
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          shape: BoxShape.circle,
          boxShadow: _hasText
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    blurRadius: 18,
                    spreadRadius: -3,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.send_rounded,
          // ✅ لون الأيقونة يتغير مع الثيم
          color: _hasText
              ? Colors.white
              : (isDark ? AppColors.textHintDark : AppColors.textHintLight),
          size: 22,
        ),
      ),
    );
  }

  Widget _buildStopButton(ChatProvider p) {
    return PressScale(
      key: const ValueKey('stop'),
      onTap: () => p.stopGeneration(),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.rose.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.rose.withValues(alpha: 0.40),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.rose.withValues(alpha: 0.15),
              blurRadius: 14,
              spreadRadius: -2,
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.rose,
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    setState(() => _hasText = false);
    _sendBtnCtrl.reverse();
    context.read<ChatProvider>().sendMessage(text);
  }

  // ✅ إصلاح: حذف BackdropFilter لمنع الشاشة السوداء
  void _confirmClear(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.darkCard.withValues(alpha: 0.97)
            : Colors.white.withValues(alpha: 0.97),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.8,
          ),
        ),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.rose.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_sweep_rounded,
            color: AppColors.rose,
            size: 28,
          ),
        ),
        title: Text(loc.translate('clearChat')),
        content: Text(loc.translate('clearChatConfirm')),
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
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              if (!context.mounted) return;
              await context.read<ChatProvider>().clearMessages();
            },
            child: Text(loc.translate('clear')),
          ),
        ],
      ),
    );
  }

  // ✅ قائمة المحادثات المتعددة
  void _showConversationsList(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCard.withValues(alpha: 0.97)
                : Colors.white.withValues(alpha: 0.97),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.radiusXXL),
            ),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.8,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (b) =>
                          AppGradients.primary.createShader(b),
                      child: Text(
                        loc.isArabic ? 'المحادثات' : 'Conversations',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                      ),
                    ),
                    const Spacer(),
                    // زر محادثة جديدة
                    PressScale(
                      onTap: () {
                        Navigator.pop(context);
                        context.read<ChatProvider>().newConversation();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: AppGradients.primary,
                          borderRadius: BorderRadius.circular(20),
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
                            const Icon(Icons.add_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 5),
                            Text(
                              loc.isArabic ? 'جديدة' : 'New',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // قائمة المحادثات
                Consumer<ChatProvider>(
                  builder: (_, p, __) {
                    final ids = p.conversationIds;
                    if (ids.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          loc.isArabic ? 'لا توجد محادثات' : 'No conversations',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ids.length,
                      itemBuilder: (_, i) {
                        final id = ids[i];
                        final isActive = id == p.activeConversationId;
                        return PressScale(
                          onTap: () {
                            p.switchConversation(id);
                            Navigator.pop(context);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primary.withValues(alpha: 0.10)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.white.withValues(alpha: 0.75)),
                              borderRadius:
                                  BorderRadius.circular(AppConstants.radiusMD),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.primary.withValues(alpha: 0.35)
                                    : (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder),
                                width: isActive ? 1.3 : 0.8,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.10),
                                        blurRadius: 12,
                                        spreadRadius: -3,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppColors.primary
                                            .withValues(alpha: 0.15)
                                        : (isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.06)
                                            : AppColors.lightElevated),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isActive
                                        ? Icons.chat_bubble_rounded
                                        : Icons.chat_bubble_outline_rounded,
                                    color: isActive
                                        ? AppColors.primary
                                        : AppColors.textHintDark,
                                    size: 17,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.getConversationTitle(
                                            id, loc.isArabic),
                                        style: TextStyle(
                                          fontWeight: isActive
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isActive
                                              ? AppColors.primary
                                              : (isDark
                                                  ? AppColors.textPrimaryDark
                                                  : AppColors.textPrimaryLight),
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (isActive)
                                        Text(
                                          loc.isArabic
                                              ? 'المحادثة الحالية'
                                              : 'Current chat',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // ✅ حذف المحادثة بدون BackdropFilter
                                if (id != 'general')
                                  PressScale(
                                    onTap: () async {
                                      await p.deleteConversation(id);
                                      setS(() {});
                                      if (!context.mounted) return;
                                      if (p.conversationIds.isEmpty) {
                                        Navigator.pop(context);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: AppColors.rose
                                            .withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.rose
                                              .withValues(alpha: 0.20),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.delete_rounded,
                                        color: AppColors.rose,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
