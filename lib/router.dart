import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:go_router/go_router.dart';
import '../widgets/my_scaffold_wrapper.dart';
import './screens/anime/anime_main_screen.dart';
import './screens/anime/anime_list_screen.dart';
import './screens/favorite/favorite_main_screen.dart';
import './screens/setting/setting_main_screen.dart';
import '../screens/no_network_screen.dart';
import './screens/error_screen.dart';
import './constants.dart';
import './utils/logger.dart';
import './widgets/anime/anime_bottom_bar.dart';
import './widgets/favorite/refresh_btn.dart';

// 定義 GoRouter 實例，使用 final 關鍵字，並在外部可訪問
final GoRouter router = GoRouter(
  initialLocation: homeRoute,
  routes: <RouteBase>[
    //首頁
    GoRoute(
      path: homeRoute,
      builder:
          (context, state) => MyScaffoldWrapper(title: appTitle, body: const AnimeMainScreen()),
    ),
    //動畫清單頁面
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
    // 收藏頁面
    GoRoute(
      path: favoriteRoute,
      builder:
          (context, state) => MyScaffoldWrapper(
            title: favoriteTitle,
            body: const FavoriteMainScreen(),
            floatingActionButton: const RefreshBtn(),
          ),
    ),
    //設定頁面
    GoRoute(
      path: settingsRoute,
      builder:
          (context, state) => MyScaffoldWrapper(title: settingsTitle, body: SettingMainScreen()),
    ),
    // 無網路頁面
    GoRoute(
      path: noNetwork,
      builder: (context, state) {
        return const NoNetworkScreen();
      },
    ),
  ],
  // 如果一開始就沒有網路，會先導向無網路畫面，而不是嘗試導向 '/' 或其他初始路徑
  redirect: (context, state) async {
    // 只有在目標路徑不是 '/no-network' 時才檢查，避免無限循環
    if (state.uri.toString() != noNetwork) {
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        // *** 將判斷條件從 == 改為檢查列表是否為空 ***
        // 分析器認為 connectivityResult 是 List<ConnectivityResult>，判斷列表是否為空，表示沒有連接
        if (connectivityResult.isEmpty) {
          appLogger.i('應用程式啟動時無網路。導向 /no-network');
          return noNetwork; // 導向無網路畫面
        }
        // 如果列表不為空，表示有某種類型的連接，可以繼續導航
        // 你也可以檢查列表中是否包含特定的連接類型，例如：
        // if (connectivityResult.contains(ConnectivityResult.wifi)) { ... }
      } catch (e) {
        // 處理檢查網路時的潛在錯誤，例如權限問題
        appLogger.e('應用程式啟動時檢查網路發生錯誤: $e');
        // 發生錯誤時，繼續導向無網路畫面
        return noNetwork;
      }
    }
    return null; // 繼續原來的導航
  },
  // 處理錯誤路由
  errorBuilder: (context, state) => ErrorScreen(error: state.error),
);
