import 'package:go_router/go_router.dart';
import '../widgets/my_scaffold_wrapper.dart';
import './screens/anime/anime_main_screen.dart';
import './screens/favorite/favorite_main_screen.dart';
import './screens/setting/setting_main_screen.dart';
import './screens/error_screen.dart';
import './constants.dart';

// 定義 GoRouter 實例，使用 final 關鍵字，並在外部可訪問
final GoRouter router = GoRouter(
  routes: <RouteBase>[
    //首頁
    GoRoute(
      path: homeRoute,
      builder:
          (context, state) => MyScaffoldWrapper(
            title: appTitle,
            body: const AnimeMainScreen(),
          ),
    ),
    //收藏頁面
    GoRoute(
      path: favoriteRoute,
      builder:
          (context, state) => MyScaffoldWrapper(
        title: favoriteTitle,
        body: const FavoriteMainScreen(),
      ),
    ),
    //設定頁面
    GoRoute(
      path: settingsRoute,
      builder:
          (context, state) => MyScaffoldWrapper(
        title: settingsTitle,
        body:  SettingMainScreen()
      ),
    ),
  ],
  // 處理錯誤路由
  errorBuilder: (context, state) => ErrorScreen(error: state.error),
);
