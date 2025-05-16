import 'package:flutter/material.dart';
import '../../models/anime_item.dart';
import './anime_card.dart';

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
        return AnimeCard(animeItem: item);
      },
    );
  }
}
