import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:anime_list/constants.dart';

/// 首頁年份卡片列表
///
/// 顯示從 [startYear] 到今年的年份卡片，
/// 點擊卡片導航至對應年份的動畫清單頁面。
class YearListCard extends StatelessWidget {
  const YearListCard({super.key});

  /// 年份列表（由新到舊排序），App 生命週期內只計算一次
  static final List<int> _years = _buildYears();

  /// 卡片漸變透明度步距（每往後一張卡片，左側漸層不透明度遞減此值）
  static const double _opacityStep = 0.04;

  static List<int> _buildYears() {
    final int currentYear = DateTime.now().year;
    return List.generate(
      currentYear - startYear + 1,
      (index) => currentYear - index,
    );
  }

  @override
  Widget build(BuildContext context) {
    final years = _years;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ListView.builder(
        itemCount: years.length,
        itemBuilder: (context, index) {
          final int year = years[index];
          // 依據索引微調色調，讓卡片有視覺漸變
          final double opacity = 1.0 - (index * _opacityStep).clamp(0.0, 0.4);

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => GoRouter.of(context).push('/anime/$year'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer.withValues(alpha: opacity),
                      colorScheme.surface,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '$year 年',
                        style: TextStyle(
                          fontSize:
                              Theme.of(context).textTheme.titleLarge?.fontSize,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
