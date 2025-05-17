import 'package:flutter/material.dart';
import '../../models/anime_item.dart';
import './anime_card.dart';

// 動畫清單的放動畫卡片的ListView
class AnimeList extends StatelessWidget {
  final List<AnimeItem> animeList;

  const AnimeList({super.key, required this.animeList});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      itemCount: animeList.length,
      itemBuilder: (context, index) {
        final item = animeList[index];
        // 動畫卡片
        return AnimeCard(animeItem: item);
      },
    );
  }
}
