import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/download_screen.dart';
import '../screens/home_screen.dart';
import '../screens/note_editor_screen.dart';
import '../screens/note_detail_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/tasks_screen.dart';
import '../models/note.dart';

class AppRouter {
  AppRouter._();

  // ─── Route Names ──────────────────────────────────────────────
  static const String splash = '/';
  static const String download = '/download';
  static const String home = '/home';
  static const String noteEditor = '/note-editor';
  static const String noteDetail = '/note-detail';
  static const String chat = '/chat';
  static const String tasks = '/tasks';

  // ─── Route Generator ──────────────────────────────────────────
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(
          const SplashScreen(),
          settings,
          type: _TransitionType.fade,
        );

      case download:
        return _buildRoute(
          const DownloadScreen(),
          settings,
          type: _TransitionType.slideUp,
        );

      case home:
        return _buildRoute(
          const HomeScreen(),
          settings,
          type: _TransitionType.fade,
        );

      case noteEditor:
        final note =
            settings.arguments is Note ? settings.arguments as Note : null;
        return _buildRoute(
          NoteEditorScreen(existingNote: note),
          settings,
          type: _TransitionType.slideUp,
        );

      case noteDetail:
        if (settings.arguments is! Note) {
          return _buildErrorRoute(
            settings,
            'noteDetail requires a Note argument',
          );
        }
        return _buildRoute(
          NoteDetailScreen(note: settings.arguments as Note),
          settings,
          type: _TransitionType.slide,
        );

      case tasks:
        return _buildRoute(
          const TasksScreen(),
          settings,
          type: _TransitionType.slideUp,
        );

      case chat:
        final note =
            settings.arguments is Note ? settings.arguments as Note : null;
        return _buildRoute(
          ChatScreen(contextNote: note),
          settings,
          type: _TransitionType.slideUp,
        );

      default:
        return _buildErrorRoute(
          settings,
          'Route not found: ${settings.name}',
        );
    }
  }

  static Route<dynamic> _buildErrorRoute(
    RouteSettings settings,
    String message,
  ) {
    return _buildRoute(
      _ErrorScreen(message: message, routeName: settings.name ?? 'unknown'),
      settings,
      type: _TransitionType.fade,
    );
  }

  // ─── Transition Builder ───────────────────────────────────────
  static PageRoute<T> _buildRoute<T>(
    Widget page,
    RouteSettings settings, {
    _TransitionType type = _TransitionType.fade,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _buildTransition(type, animation, secondaryAnimation, child);
      },
    );
  }

  static Widget _buildTransition(
    _TransitionType type,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fadeIn = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    switch (type) {
      case _TransitionType.fade:
        return FadeTransition(opacity: fadeIn, child: child);

      case _TransitionType.slide:
        final slideTween = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(fadeIn);
        return SlideTransition(
          position: slideTween,
          child: FadeTransition(opacity: fadeIn, child: child),
        );

      case _TransitionType.slideUp:
        final slideTween = Tween<Offset>(
          begin: const Offset(0.0, 0.08),
          end: Offset.zero,
        ).animate(fadeIn);
        final scaleTween = Tween<double>(
          begin: 0.95,
          end: 1.0,
        ).animate(fadeIn);
        return FadeTransition(
          opacity: fadeIn,
          child: SlideTransition(
            position: slideTween,
            child: ScaleTransition(scale: scaleTween, child: child),
          ),
        );
    }
  }
}

enum _TransitionType { fade, slide, slideUp }

class _ErrorScreen extends StatelessWidget {
  final String message;
  final String routeName;

  const _ErrorScreen({
    required this.message,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    assert(() {
      debugPrint('🚨 Router Error: $message');
      return true;
    }());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed(AppRouter.home);
      }
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
