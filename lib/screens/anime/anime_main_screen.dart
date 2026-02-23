import 'package:flutter/material.dart';
import 'package:anime_list/widgets/anime/anime_sentence.dart';
import 'package:anime_list/widgets/anime/year_list_card.dart';

/// 動畫主頁面
///
/// 上方顯示動漫名言（[AnimeSentence]），
/// 下方為年份卡片列表（[YearListCard]）。
class AnimeMainScreen extends StatelessWidget {
  const AnimeMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [AnimeSentence(), Expanded(child: YearListCard())],
      ),
    );
  }
}
