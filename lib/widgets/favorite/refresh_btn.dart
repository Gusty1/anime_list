import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/favorite_refresh_provider.dart';

 class RefreshBtn extends ConsumerStatefulWidget {
   const RefreshBtn({super.key});

   @override
   ConsumerState<RefreshBtn> createState() => _RefreshBtnState();
 }

 class _RefreshBtnState extends ConsumerState<RefreshBtn> {
   @override
   Widget build(BuildContext context) {
     return FloatingActionButton(
       // 1. onPressed 是必須的屬性：定義當按鈕被點擊時要執行的函數
       onPressed: () {
         final favoriteRefreshNotifier = ref.read(favoriteRefreshProvider.notifier);
         favoriteRefreshNotifier.setRefresh();
       },
       elevation: 4.0, // 設定按鈕的陰影高
       child: const Icon(Icons.refresh),
     );
   }
 }
