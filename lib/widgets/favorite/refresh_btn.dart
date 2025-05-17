import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/favorite_refresh_provider.dart';

// 收藏頁面的右下角重新整理按鈕
 class RefreshBtn extends ConsumerStatefulWidget {
   const RefreshBtn({super.key});

   @override
   ConsumerState<RefreshBtn> createState() => _RefreshBtnState();
 }

 class _RefreshBtnState extends ConsumerState<RefreshBtn> {
   @override
   Widget build(BuildContext context) {
     return FloatingActionButton(
       onPressed: () {
         final favoriteRefreshNotifier = ref.read(favoriteRefreshProvider.notifier);
         favoriteRefreshNotifier.setRefresh();
       },
       elevation: 4.0,
       child: const Icon(Icons.refresh),
     );
   }
 }
