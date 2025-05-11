
import 'package:flutter/material.dart';
import '../../widgets/anime/anime_sentence.dart';

class AnimeMainScreen extends StatelessWidget {
  const AnimeMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: const [AnimeSentence()]);
  }
}
