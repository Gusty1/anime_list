import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import './router.dart';
import 'services/preferences_service.dart';
import 'providers/theme_provider.dart';

// 將 main 函數改為異步，以便執行異步初始化
Future<void> main() async {
  // 確保 Flutter 服務已經初始化
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // 初始化 PreferenceService 實例
  // 呼叫這個方法，直到明確呼叫 remove() 之前，原生的 Splash Screen 會一直顯示
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  final prefsService = PreferencesService();
  await prefsService.init(); // 等待異步初始化完成

  FlutterNativeSplash.remove();

  runApp(
    // 使用 ProviderScope 包裹你的應用程式根部
    // ProviderScope 來自 flutter_riverpod
    ProviderScope(
      // 使用 overrides 來提供已經初始化好的 PreferencesService 實例
      overrides: [
        // 使用 overrideWithValue 覆蓋 preferencesServiceProvider，
        // 將 main 函數中創建並初始化好的 prefsService 實例提供出去
        preferencesServiceProvider.overrideWithValue(prefsService),
      ],
      child: const MyApp(),
    ),
  );
}

// 將 MyApp 改為 ConsumerWidget，以便使用 ref 讀取 Provider
// ConsumerWidget 來自 flutter_riverpod
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  // build 方法接收一個 WidgetRef 參數 (通常簡寫為 ref)
  Widget build(BuildContext context, WidgetRef ref) { // <-- build 方法簽名
    // 監聽 themeNotifierProvider 的 boolean 狀態 (是否為暗色模式啟用)
    // ref.watch 來自 flutter_riverpod
    final bool isDarkModeEnabled = ref.watch(themeNotifierProvider); // <-- 讀取 boolean 狀態

    // 根據 boolean 狀態決定要使用的 ThemeMode
    // 如果 isDarkModeEnabled 為 true，使用 ThemeMode.dark
    // 否則，使用 ThemeMode.light
    // 這個方案是基於 boolean 偏好覆蓋系統設定
    final ThemeMode themeModeToApply = isDarkModeEnabled ? ThemeMode.dark : ThemeMode.light; // <-- 轉換為 ThemeMode

    return MaterialApp.router(
      // 使用 flex_color_scheme 定義亮色主題
      theme: FlexThemeData.light(
        scheme: FlexScheme.blumineBlue,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 20,
        appBarOpacity: 0.95,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 20,
          blendOnColors: false,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
      ),
      // 使用 flex_color_scheme 定義暗色主題
      darkTheme: FlexThemeData.dark(
        scheme: FlexScheme.blumineBlue,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 15,
        appBarOpacity: 0.90,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 20,
          blendOnColors: false,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
      ),
      themeMode: themeModeToApply, // 將轉換後的 ThemeMode 賦給 MaterialApp.router 的 themeMode
      routerConfig: router,
      debugShowCheckedModeBanner: false,//是否關閉右上角的debug標籤
    );
  }
}