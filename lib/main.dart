import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import './router.dart';
import './services/preferences_service.dart';
import './providers/theme_provider.dart';
import './widgets/connectivity_watcher.dart';

// 將 main 函數改為異步，以便執行異步初始化
Future<void> main() async {
  // 確保 Flutter 服務已經初始化
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // 使用 flutter_native_splash 會放一張圖片，並等待異步初始化完成
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 初始化 PreferenceService 實例
  final prefsService = PreferencesService();
  await prefsService.init();

  // 在這裡可以執行其他異步初始化任務

  // 確保所有異步初始化完成後再移除 Splash Screen
  FlutterNativeSplash.remove();

  runApp(
    // ProviderScope 來自 flutter_riverpod，使用 ProviderScope 包裹你的應用程式根部
    ProviderScope(
      // 使用 overrides 來提供已經初始化好的 PreferencesService 實例
      overrides: [
        // 使用 overrideWithValue 覆蓋 preferencesServiceProvider
        preferencesServiceProvider.overrideWithValue(prefsService),
      ],
      //控制有無網路的切換，用自訂widget包裝
      child: ConnectivityWatcher(child: const MyApp()),
    ),
  );
}

// 將 MyApp 改為 ConsumerWidget，以便使用 ref 讀取 Provider
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  // build 方法接收一個 WidgetRef 參數 ，通常簡寫為 ref
  Widget build(BuildContext context, WidgetRef ref) {
    // 監聽 themeNotifierProvider 的 boolean 狀態 (是否為暗色模式啟用)
    final bool isDarkModeEnabled = ref.watch(themeNotifierProvider); // 讀取 boolean 狀態

    // 根據 boolean 狀態決定要使用的 ThemeMode (只有 Light 或 Dark)
    final ThemeMode themeModeToApply =
        isDarkModeEnabled ? ThemeMode.dark : ThemeMode.light; // 轉換為 ThemeMode

    return MaterialApp.router(
      // 使用 flex_color_scheme 定義亮色主題
      theme: FlexThemeData.light(
        scheme: FlexScheme.blumineBlue,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 20,
        appBarOpacity: 0.95,
        subThemesData: const FlexSubThemesData(blendOnLevel: 20, blendOnColors: false),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
      ),
      // 使用 flex_color_scheme 定義暗色主題
      darkTheme: FlexThemeData.dark(
        scheme: FlexScheme.blumineBlue,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 15,
        appBarOpacity: 0.90,
        subThemesData: const FlexSubThemesData(blendOnLevel: 20, blendOnColors: false),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
      ),
      // 將轉換後的 ThemeMode 賦給 MaterialApp.router 的 themeMode
      themeMode: themeModeToApply,
      routerConfig: router,
      debugShowCheckedModeBanner: false, // 是否隱藏 debug 標誌
    );
  }
}
