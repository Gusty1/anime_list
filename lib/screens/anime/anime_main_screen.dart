import 'package:flutter/material.dart';
import '../../widgets/anime/anime_sentence.dart';
import '../../widgets/anime/year_list_card.dart';

class AnimeMainScreen extends StatelessWidget {
  const AnimeMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: const [AnimeSentence(), Expanded(child: YearListCard())],
    );
  }
}
