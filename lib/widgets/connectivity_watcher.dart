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
/// 網路恢復時返回斷線前的原始頁面（而非固定跳回首頁）。
/// 透過 [routerProvider] 取得 GoRouter 實例。
class ConnectivityWatcher extends ConsumerStatefulWidget {
  final Widget child;

  const ConnectivityWatcher({super.key, required this.child});

  @override
  ConsumerState<ConnectivityWatcher> createState() =>
      _ConnectivityWatcherState();
}

class _ConnectivityWatcherState extends ConsumerState<ConnectivityWatcher> {
  /// 斷線前所在的頁面 URI，用於網路恢復後導回原位
  String _previousUri = homeRoute;

  @override
  Widget build(BuildContext context) {
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
              // 記錄斷線前的位置，以便恢復後返回
              _previousUri = currentUri;
              appLogger.d('網路中斷，記錄位置 $_previousUri，導航到無網路頁面');
              goRouter.go(noNetwork);
            }
          } else {
            if (currentUri == noNetwork) {
              appLogger.d('網路恢復，返回原始頁面: $_previousUri');
              goRouter.go(_previousUri);
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

    return widget.child;
  }
}
