import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 監聽網路連線狀態的 StreamProvider
///
/// connectivity_plus 7.x 回傳 `Stream<List<ConnectivityResult>>`，
/// 透過 `.map()` 轉換為單一 `ConnectivityResult` 以簡化下游使用。
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  final rawStream = Connectivity().onConnectivityChanged;

  return rawStream.map((results) {
    // 過濾掉 none，取第一個有效連線方式；全部都是 none 才視為斷線
    final active = results.where((r) => r != ConnectivityResult.none);
    return active.isNotEmpty ? active.first : ConnectivityResult.none;
  });
});
