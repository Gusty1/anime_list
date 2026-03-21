import 'package:flutter/material.dart';
import 'package:anime_list/models/anime_item.dart';
import 'package:anime_list/widgets/anime/anime_card.dart';

// 動畫清單的放動畫卡片的ListView
class AnimeList extends StatelessWidget {
  final List<AnimeItem> animeList;

  /// 是否為收藏頁視圖，傳遞給 [AnimeCard] 控制日期前綴顯示。
  final bool isFavoriteView;

  const AnimeList({
    super.key,
    required this.animeList,
    this.isFavoriteView = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      itemCount: animeList.length,
      itemBuilder: (context, index) {
        final item = animeList[index];
        // 動畫卡片
        return AnimeCard(
          key: ValueKey(item.name),
          animeItem: item,
          isFavoriteView: isFavoriteView,
        );
      },
    );
  }
}
