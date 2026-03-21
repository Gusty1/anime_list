import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:anime_list/widgets/my_scaffold_wrapper.dart';
import 'package:anime_list/screens/anime/anime_main_screen.dart';
import 'package:anime_list/screens/anime/anime_list_screen.dart';
import 'package:anime_list/screens/favorite/favorite_main_screen.dart';
import 'package:anime_list/screens/setting/setting_main_screen.dart';
import 'package:anime_list/screens/no_network_screen.dart';
import 'package:anime_list/screens/error_screen.dart';
import 'package:anime_list/constants.dart';
import 'package:anime_list/utils/logger.dart';
import 'package:anime_list/widgets/anime/anime_bottom_bar.dart';
import 'package:anime_list/widgets/favorite/refresh_btn.dart';

import 'package:anime_list/main.dart' show navigatorKey;

/// 透過 Riverpod Provider 提供 GoRouter 實例
///
/// 將路由從全域變數改為 Provider，方便測試和解耦。
/// [ConnectivityWatcher] 等需要存取 router 的 Widget 透過 ref 取用。
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: homeRoute,
    routes: <RouteBase>[
      // 首頁：年份列表 + 一言
      GoRoute(
        path: homeRoute,
        builder:
            (context, state) => const MyScaffoldWrapper(
              title: appTitle,
              body: AnimeMainScreen(),
            ),
      ),

      // 動畫清單頁面（依年份），含底部季番導航列
      GoRoute(
        path: '/anime/:year',
        builder: (context, state) {
          final String year = state.pathParameters['year']!;
          return MyScaffoldWrapper(
            title: '$year 年動畫清單',
            body: AnimeListScreen(year: year),
            bottomNavigationBar: AnimeBottomBar(year: year),
          );
        },
      ),

      // 收藏頁面，含重新載入浮動按鈕
      GoRoute(
        path: favoriteRoute,
        builder:
            (context, state) => const MyScaffoldWrapper(
              title: favoriteTitle,
              body: FavoriteMainScreen(),
              floatingActionButton: RefreshBtn(),
            ),
      ),

      // 設定頁面
      GoRoute(
        path: settingsRoute,
        builder:
            (context, state) => const MyScaffoldWrapper(
              title: settingsTitle,
              body: SettingMainScreen(),
            ),
      ),

      // 無網路頁面
      GoRoute(
        path: noNetwork,
        builder: (context, state) => const NoNetworkScreen(),
      ),
    ],

    // 應用程式啟動時檢查網路狀態，無網路時導向無網路頁面
    redirect: (context, state) async {
      if (state.uri.toString() != noNetwork) {
        try {
          final connectivityResult = await Connectivity().checkConnectivity();
          // connectivity_plus 7.x 回傳 List<ConnectivityResult>，
          // [ConnectivityResult.none] 不是空列表，必須用 every() 判斷所有介面均為 none
          final hasNoNetwork = connectivityResult.every(
            (r) => r == ConnectivityResult.none,
          );
          if (hasNoNetwork) {
            appLogger.d('應用程式啟動時無網路，導向 /no-network');
            return noNetwork;
          }
        } catch (e) {
          appLogger.e('啟動時檢查網路發生錯誤: $e');
          return noNetwork;
        }
      }
      return null;
    },

    // 處理錯誤路由
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
});
