import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_list/providers/favorite_provider.dart';

/// 收藏頁面右下角的重新載入浮動按鈕
///
/// 點擊後透過 `ref.invalidate()` 使 [favoriteProvider] 失效並重新載入資料。
class RefreshBtn extends ConsumerWidget {
  const RefreshBtn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () {
        // 使 favoriteProvider 失效，觸發重新載入
        ref.invalidate(favoriteProvider);
      },
      elevation: 4.0,
      child: const Icon(Icons.refresh),
    );
  }
}
