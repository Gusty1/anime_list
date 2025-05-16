import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavoriteRefreshProviderNotifier extends Notifier<bool> {

  @override
  // build 方法用於初始化 Notifier 的狀態
  bool build() {
    // 這裡設定初始狀態。
    return false;
  }

  void setRefresh() {
    state = !state;
  }
}

final favoriteRefreshProvider = NotifierProvider<FavoriteRefreshProviderNotifier, bool>(
      () => FavoriteRefreshProviderNotifier(),
);