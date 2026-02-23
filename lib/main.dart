import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:anime_list/services/preferences_service.dart';
import 'package:anime_list/services/update_checker.dart';
import 'package:anime_list/providers/theme_provider.dart';
import 'package:anime_list/providers/router_provider.dart';
import 'package:anime_list/widgets/connectivity_watcher.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter/services.dart';
import 'package:anime_list/l10n/zh_tw_feedback_localizations.dart';

/// 全域 NavigatorKey，用於在 Navigator context 可用前顯示 Dialog
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// 應用程式入口點
Future<void> main() async {
  // 確保 Flutter 引擎已初始化
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();

  // 保留 Splash Screen 直到初始化完成
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 鎖定螢幕方向為直向
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 初始化 SharedPreferences
  final prefsService = PreferencesService();
  await prefsService.init();

  // 移除 Splash Screen
  FlutterNativeSplash.remove();

  runApp(
    ProviderScope(
      overrides: [
        // 提供已初始化的 PreferencesService 實例
        preferencesServiceProvider.overrideWithValue(prefsService),
      ],
      child: const MyApp(),
    ),
  );
}

/// 應用程式根 Widget
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // App 啟動後延遲 2 秒自動檢查更新（等待 UI 穩定後再顯示）
    Future.delayed(const Duration(seconds: 2), _checkUpdateOnStartup);
  }

  /// 啟動時自動檢查更新
  Future<void> _checkUpdateOnStartup() async {
    final updateInfo = await UpdateChecker.checkForUpdate();
    if (updateInfo != null && updateInfo.hasUpdate) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        UpdateChecker.showUpdateDialog(ctx, updateInfo);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 監聽深色模式設定
    final bool isDarkMode = ref.watch(themeNotifierProvider);

    // 透過 Provider 取得 GoRouter 實例
    final router = ref.watch(routerProvider);

    return BetterFeedback(
      // 使用繁體中文在地化
      localizationsDelegates: const [ZhTwFeedbackLocalizations.delegate],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Anime List',
        // 使用 FlexColorScheme 設定主題
        theme: FlexThemeData.light(
          scheme: FlexScheme.aquaBlue,
          useMaterial3: true,
        ),
        darkTheme: FlexThemeData.dark(
          scheme: FlexScheme.aquaBlue,
          useMaterial3: true,
        ),
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        routerConfig: router,
        // 在 Widget 樹外層包裹 ConnectivityWatcher 進行網路狀態監聯
        builder: (context, child) {
          return ConnectivityWatcher(child: child!);
        },
      ),
    );
  }
}
