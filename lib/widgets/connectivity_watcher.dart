import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../router.dart';
import '../providers/connectivity_provider.dart';
import '../constants.dart';
import '../utils/logger.dart';

// 監聽網路變化的widget，也是包裝myApp的widget
class ConnectivityWatcher extends ConsumerWidget {
  final Widget child;

  //接收的child是myApp
  const ConnectivityWatcher({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<ConnectivityResult>>(connectivityProvider, (previous, next) {
      next.when(
        data: (status) {
          // 直接使用全局 router 實例
          final goRouter = router;
          // 使用 goRouter 實例來獲取當前 URI 和執行導航
          final currentUriString = goRouter.routerDelegate.currentConfiguration.uri.toString();
          appLogger.i("網路狀態變化: $status, 當前 URI: $currentUriString");

          if (status == ConnectivityResult.none) {
            if (currentUriString != noNetwork) {
              appLogger.i('網路中斷。導航到無網路畫面');
              goRouter.go(noNetwork);
            }
          } else {
            if (currentUriString == noNetwork) {
              appLogger.i('網路恢復。返回首頁');
              goRouter.go(homeRoute);
            }
          }
        },
        loading: () {
          appLogger.i('網路狀態載入中...');
        },
        error: (err, stack) {
          appLogger.e('獲取網路狀態 Stream 時發生錯誤: $err');
        },
      );
    });

    return child;
  }
}
