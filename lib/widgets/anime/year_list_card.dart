import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:go_router/go_router.dart';


// 首頁產生2018到今年的卡片 Widget
class YearListCard extends StatelessWidget {
  const YearListCard({super.key});

  List<int> getYears() {
    final int currentYear = DateTime.now().year;
    final int startYear = 2018;
    List<int> years = [];
    for (int year = currentYear; year >= startYear; year--) {
      years.add(year);
    }
    return years;
  }

  @override
  Widget build(BuildContext context) {
    List<int> years = getYears();

    return Container(
      padding: const EdgeInsets.all(5),
      child: ListView.builder(
        itemCount: years.length,
        itemBuilder: (context, index) {
          final int year = years[index];
          return Card(
            elevation: 5,
            margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            // 將 Padding 包裹在 InkWell 中，這樣才有ripple效果
            child: InkWell(
              onTap: () {
                GoRouter.of(context).push('/anime/${years[index]}');
              },
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Center(
                  child: AutoSizeText(
                    year.toString(),
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.titleLarge?.fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}