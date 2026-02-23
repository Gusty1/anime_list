import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_list/providers/router_provider.dart';
import 'package:anime_list/providers/connectivity_provider.dart';
import 'package:anime_list/constants.dart';
import 'package:anime_list/utils/logger.dart';

/// 監聽網路狀態變化的外層 Widget
///
/// 包裝在 [MaterialApp] 的 builder 中，當網路斷線時自動導航至無網路頁面，
/// 網路恢復時返回首頁。透過 [routerProvider] 取得 GoRouter 實例（不再使用全域變數）。
class ConnectivityWatcher extends ConsumerWidget {
  final Widget child;

  const ConnectivityWatcher({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<ConnectivityResult>>(connectivityProvider, (
      previous,
      next,
    ) {
      next.when(
        data: (status) {
          final goRouter = ref.read(routerProvider);
          final currentUri =
              goRouter.routerDelegate.currentConfiguration.uri.toString();

          appLogger.d('網路狀態變化: $status, 當前 URI: $currentUri');

          if (status == ConnectivityResult.none) {
            if (currentUri != noNetwork) {
              appLogger.d('網路中斷，導航到無網路頁面');
              goRouter.go(noNetwork);
            }
          } else {
            if (currentUri == noNetwork) {
              appLogger.d('網路恢復，返回首頁');
              goRouter.go(homeRoute);
            }
          }
        },
        loading: () {
          appLogger.d('網路狀態載入中...');
        },
        error: (err, stack) {
          appLogger.e('監聽網路狀態時發生錯誤: $err');
        },
      );
    });

    return child;
  }
}
