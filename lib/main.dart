import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'core/theme.dart';
import 'core/router.dart';
import 'core/app_localizations.dart';
import 'core/app_gradients.dart';
import 'core/constants.dart';
import 'core/animations_helper.dart';

import 'providers/model_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/task_provider.dart';
import 'providers/app_lock_provider.dart';

import 'services/database_service.dart';
import 'services/encryption_service.dart';

import 'core/responsive.dart';

// ─── Main ─────────────────────────────────────────────────────────
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      title: 'Beyond Silence',
      center: true,
      minimumSize: Size(900, 620),
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.darkBg,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await _initializeServices();

  runApp(const SmartDiaryApp());
}

Future<void> _initializeServices() async {
  await EncryptionService().initialize();
  await DatabaseService().initialize();
}

// ─── Root App ─────────────────────────────────────────────────────
class SmartDiaryApp extends StatelessWidget {
  const SmartDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ModelProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => AppLockProvider()..load()),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, localeProvider, themeProvider, _) {
          if (!localeProvider.isLoaded || !themeProvider.isLoaded) {
            return _buildLoadingApp();
          }

          return MaterialApp(
            title: 'Beyond Silence',
            debugShowCheckedModeBanner: false,
            restorationScopeId: 'app',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: localeProvider.locale,
            supportedLocales: const [
              Locale('ar'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              Responsive.init(context);
              final wrapped = Directionality(
                textDirection: localeProvider.textDirection,
                child: ScrollConfiguration(
                  behavior: _SmoothScrollBehavior(),
                  child: RepaintBoundary(child: child!),
                ),
              );
              if (Platform.isWindows) {
                return Column(
                  children: [
                    const _DesktopDragBar(),
                    Expanded(child: wrapped),
                  ],
                );
              }
              return wrapped;
            },
            home: localeProvider.isFirstRun
                ? const LanguageSelectionScreen()
                : const AppLifecycleHandler(
                    child: _AppNavigator(),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingApp() {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF0A0A0F),
        body: SizedBox.expand(
          child: Center(
            child: SizedBox(
              width: 96,
              height: 96,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppGradients.aurora,
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                  size: 46,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── App Navigator ────────────────────────────────────────────────
class _AppNavigator extends StatefulWidget {
  const _AppNavigator();

  @override
  State<_AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<_AppNavigator> {
  static final GlobalKey<NavigatorState> _navKey =
      GlobalKey<NavigatorState>(debugLabel: 'AppNavigator');

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navKey,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppRouter.splash,
      observers: [_RoutePersistObserver()],
    );
  }
}

class _RoutePersistObserver extends NavigatorObserver {
  void _save(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null) return;
    DatabaseService().saveSetting(AppConstants.lastRouteKey, name);
  }

  @override
  void didPush(Route route, Route<dynamic>? previousRoute) {
    _save(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _save(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

// ─── Language Selection Screen ────────────────────────────────────
class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgCtrl;
  String? _selectedCode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectLanguage(String code) async {
    if (_isLoading) return;
    setState(() {
      _selectedCode = code;
      _isLoading = true;
    });
    await context.read<LocaleProvider>().setLocale(Locale(code));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          _buildBackground(),
          Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.darkBackground,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.padXL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatWidget(
                      amplitude: 8,
                      period: const Duration(seconds: 4),
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          gradient: AppGradients.aurora,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.55),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_stories_rounded,
                          color: Colors.white,
                          size: 54,
                        ),
                      ),
                    )
                        .animate()
                        .scale(
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(),
                    const SizedBox(height: 36),
                    Text(
                      AppConstants.appName,
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'اختر لغتك / Choose your language',
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 15,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(
                          delay: const Duration(milliseconds: 320),
                        ),
                    const SizedBox(height: 8),
                    Text(
                      'يمكنك تغييرها لاحقاً · You can change it later',
                      style: const TextStyle(
                        color: AppColors.textHintDark,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(
                          delay: const Duration(milliseconds: 400),
                        ),
                    const SizedBox(height: 44),
                    ...LocaleProvider.supportedLocales
                        .asMap()
                        .entries
                        .map((entry) {
                      final lang = entry.value;
                      final code = lang['code']!;
                      final isSelected = _selectedCode == code;
                      final isAr = code == 'ar';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: PressScale(
                          onTap:
                              _isLoading ? null : () => _selectLanguage(code),
                          child: AnimatedContainer(
                            duration: AppConstants.animNormal,
                            width: double.infinity,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: isSelected ? AppGradients.aurora : null,
                              color: isSelected ? null : AppColors.darkCard,
                              borderRadius:
                                  BorderRadius.circular(AppConstants.radiusLG),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : AppColors.darkBorder,
                                width: 0.8,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.40),
                                        blurRadius: 22,
                                        spreadRadius: -4,
                                        offset: const Offset(0, 8),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppConstants.radiusLG),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(width: 16),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lang['name']!,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: isAr ? 0 : 0.3,
                                          ),
                                        ),
                                        Text(
                                          isAr
                                              ? 'اللغة الرسمية للتطبيق'
                                              : 'Official app language',
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white70
                                                : AppColors.textHintDark,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    if (_isLoading && isSelected)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(
                            delay:
                                Duration(milliseconds: 480 + entry.key * 100),
                          );
                    }),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _FeatureChip(
                          icon: Icons.lock_rounded,
                          label: 'Privacy · خصوصية',
                          color: AppColors.mint,
                        ),
                        _FeatureChip(
                          icon: Icons.wifi_off_rounded,
                          label: 'Offline · بلا إنترنت',
                          color: AppColors.primary,
                        ),
                        _FeatureChip(
                          icon: Icons.psychology_rounded,
                          label: 'AI · ذكاء',
                          color: AppColors.gold,
                        ),
                      ],
                    ).animate().fadeIn(
                          delay: const Duration(milliseconds: 700),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _bgCtrl,
      builder: (_, __) => Stack(
        children: [
          Positioned(
            top: -80 + _bgCtrl.value * 30,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(
                  alpha: 0.05 + _bgCtrl.value * 0.03,
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
                  alpha: 0.03 + _bgCtrl.value * 0.02,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feature Chip ─────────────────────────────────────────────────
class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.24),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── App Lifecycle Handler ────────────────────────────────────────
class AppLifecycleHandler extends StatefulWidget {
  final Widget child;
  const AppLifecycleHandler({super.key, required this.child});

  @override
  State<AppLifecycleHandler> createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends State<AppLifecycleHandler>
    with WidgetsBindingObserver {
  bool _isLockDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _promptForLockIfNeeded();
    }
  }

  Future<void> _promptForLockIfNeeded() async {
    if (_isLockDialogOpen || !mounted) return;
    final appLock = context.read<AppLockProvider>();
    if (!appLock.isEnabled || !appLock.hasPin) return;

    _isLockDialogOpen = true;
    final pinCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('App Lock'),
          content: TextField(
            controller: pinCtrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: const InputDecoration(hintText: 'Enter PIN'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (appLock.verify(pinCtrl.text.trim())) {
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Unlock'),
            ),
          ],
        );
      },
    );
    _isLockDialogOpen = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ─── Smooth Scroll Behavior ───────────────────────────────────────
class _SmoothScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

// ─── Desktop Drag Bar ─────────────────────────────────────────────
class _DesktopDragBar extends StatelessWidget {
  const _DesktopDragBar();

  @override
  Widget build(BuildContext context) {
    return DragToMoveArea(
      child: Container(
        height: 30,
        color: const Color(0xFF0A0A0F),
        alignment: Alignment.center,
        child: const Text(
          'Beyond Silence',
          style: TextStyle(
            color: Color(0xFFB8B8C7),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
