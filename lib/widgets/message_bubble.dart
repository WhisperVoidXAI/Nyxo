import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/chat_message.dart';
import '../core/theme.dart';
import '../core/app_localizations.dart';
import '../core/animations_helper.dart';
import '../core/app_gradients.dart';
import '../core/constants.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isStreaming;

  const MessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _AiAvatar(isStreaming: isStreaming),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  _buildBubble(context, isUser, isDark),
                  const SizedBox(height: 4),
                  _buildMeta(context, isUser, isDark),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const _UserAvatar(),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 280.ms)
        .slideY(begin: 0.05, curve: Curves.easeOutCubic);
  }

  Widget _buildBubble(BuildContext context, bool isUser, bool isDark) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.76,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(22),
          topRight: const Radius.circular(22),
          bottomLeft: Radius.circular(isUser ? 22 : 5),
          bottomRight: Radius.circular(isUser ? 5 : 22),
        ),
        gradient: isUser ? AppGradients.aurora : null,
        boxShadow: isUser
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: -4,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(22),
          topRight: const Radius.circular(22),
          bottomLeft: Radius.circular(isUser ? 22 : 5),
          bottomRight: Radius.circular(isUser ? 5 : 22),
        ),
        child: BackdropFilter(
          filter: isUser
              ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
              : ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            // ✅ إصلاح: لون صحيح في الثيم الفاتح
            decoration: isUser
                ? null
                : BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : AppColors.lightCard.withValues(alpha: 0.95),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.09)
                          : AppColors.lightBorder.withValues(alpha: 0.85),
                      width: 0.8,
                    ),
                  ),
            child: message.isLoading
                ? const _LoadingDots()
                : message.hasError
                    ? _ErrorContent(isUser: isUser)
                    : _MessageContent(
                        message: message,
                        isUser: isUser,
                        isStreaming: isStreaming,
                        isDark: isDark,
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeta(BuildContext context, bool isUser, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(
        right: isUser ? 4 : 44,
        left: isUser ? 44 : 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.formattedTime,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
            ),
          ),
          if (message.tokensUsed != null && !isUser) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  width: 0.6,
                ),
              ),
              child: Text(
                '${message.tokensUsed} tok',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (!isUser && message.wordCount > 0) ...[
            const SizedBox(width: 5),
            Text(
              AppLocalizations.of(context).isArabic
                  ? '${message.wordCount} كلمات'
                  : '${message.wordCount} words',
              style: TextStyle(
                fontSize: 9,
                color:
                    isDark ? AppColors.textHintDark : AppColors.textHintLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXXL)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.78)
                  : Colors.white.withValues(alpha: 0.92),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppConstants.radiusXXL)),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.09)
                    : AppColors.lightBorder,
                width: 0.8,
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkElevated
                          : AppColors.lightElevated,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSM),
                    ),
                    child: Text(
                      message.preview,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _OptionTile(
                    icon: Icons.copy_rounded,
                    label: loc.translate('copyMessage'),
                    color: AppColors.primary,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: message.content));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.translate('copied')),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusSM),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  _OptionTile(
                    icon: Icons.analytics_outlined,
                    label: '${message.wordCount} '
                        '${loc.translate('wordsCount')} · '
                        '${message.charCount} '
                        '${loc.translate('charsCount')}',
                    color: AppColors.cyan,
                    onTap: () => Navigator.pop(context),
                    isInfo: true,
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageContent extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;
  final bool isStreaming;
  final bool isDark;

  const _MessageContent({
    required this.message,
    required this.isUser,
    required this.isStreaming,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarkdownBody(
          data: message.content,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: isUser
                  ? Colors.white
                  : (isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight),
              fontSize: 15,
              height: 1.70,
            ),
            strong: TextStyle(
              color: isUser ? Colors.white : AppColors.primaryLight,
              fontWeight: FontWeight.w800,
            ),
            em: TextStyle(
              color: isUser
                  ? Colors.white70
                  : (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
              fontStyle: FontStyle.italic,
            ),
            code: TextStyle(
              fontFamily: 'monospace',
              backgroundColor:
                  isDark ? const Color(0xFF0A0A16) : const Color(0xFFEDE9FF),
              color: isUser ? Colors.white : AppColors.primary,
              fontSize: 13,
            ),
            codeblockDecoration: BoxDecoration(
              color: isDark ? const Color(0xFF08080F) : const Color(0xFFF0EEFF),
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 0.8,
              ),
            ),
            blockquoteDecoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isUser ? Colors.white60 : AppColors.primary,
                  width: 3.5,
                ),
                right: BorderSide(
                  color: isUser ? Colors.white60 : AppColors.primary,
                  width: 3.5,
                ),
              ),
              color: (isUser ? Colors.white : AppColors.primary)
                  .withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
            ),
            listBullet: TextStyle(
              color: isUser ? Colors.white70 : AppColors.primary,
            ),
          ),
        ),
        if (isStreaming) ...[
          const SizedBox(height: 6),
          _StreamCursor(),
        ],
      ],
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              gradient: AppGradients.primary,
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                delay: Duration(milliseconds: i * 170),
                duration: 480.ms,
                begin: const Offset(0.4, 0.4),
                end: const Offset(1.0, 1.0),
                curve: Curves.easeOut,
              )
              .then()
              .scale(
                duration: 480.ms,
                begin: const Offset(1.0, 1.0),
                end: const Offset(0.4, 0.4),
                curve: Curves.easeIn,
              );
        }),
      ),
    );
  }
}

class _StreamCursor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2.5,
      height: 20,
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.40),
            blurRadius: 6,
            spreadRadius: -1,
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .fadeIn(duration: 520.ms)
        .then()
        .fadeOut(duration: 520.ms);
  }
}

class _ErrorContent extends StatelessWidget {
  final bool isUser;
  const _ErrorContent({required this.isUser});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.rose.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: AppColors.rose,
            size: 15,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          loc.isArabic ? 'حدث خطأ — اضغط للإعادة' : 'Error — tap to retry',
          style: const TextStyle(
            color: AppColors.rose,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AiAvatar extends StatelessWidget {
  final bool isStreaming;
  const _AiAvatar({this.isStreaming = false});

  @override
  Widget build(BuildContext context) {
    return GlowPulse(
      glowColor: AppColors.primary,
      blurRadius: 16,
      active: isStreaming,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          gradient: AppGradients.aurora,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.32),
              blurRadius: 12,
              spreadRadius: -2,
            ),
          ],
        ),
        child: const Icon(
          Icons.auto_awesome_rounded,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.lightSurface,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.14),
            blurRadius: 10,
            spreadRadius: -3,
          ),
        ],
      ),
      child: const Icon(
        Icons.person_rounded,
        size: 19,
        color: AppColors.primary,
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isInfo;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.padMD, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          border: Border.all(
            color: color.withValues(alpha: 0.20),
            width: 0.8,
          ),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isInfo
              ? Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textHintDark
                  : AppColors.textHintLight
              : null,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}
