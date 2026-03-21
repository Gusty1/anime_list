import 'package:flutter_test/flutter_test.dart';
import 'package:anime_list/utils/date_helper.dart';
import 'package:anime_list/models/anime_item.dart';

/// 輔助函式：建立測試用的最小 AnimeItem
AnimeItem _makeItem({required String date, required String time}) {
  return AnimeItem(
    name: 'Test Anime',
    date: date,
    time: time,
    carrier: 'Novel',
    season: 'TV',
    originalName: 'テスト',
    img: 'test.jpg',
    description: 'desc',
    official: '',
  );
}

void main() {
  group('DateHelper.parseAnimeDate', () {
    test('解析 MM/DD 格式，需傳入年份', () {
      final result = DateHelper.parseAnimeDate('04/05', year: '2025');
      expect(result, isNotNull);
      expect(result!.year, 2025);
      expect(result.month, 4);
      expect(result.day, 5);
    });

    test('解析 YYYY/MM/DD 格式，不需年份', () {
      final result = DateHelper.parseAnimeDate('2025/10/01');
      expect(result, isNotNull);
      expect(result!.year, 2025);
      expect(result.month, 10);
      expect(result.day, 1);
    });

    test('MM/DD 格式但未提供年份，回傳 null', () {
      final result = DateHelper.parseAnimeDate('04/05');
      expect(result, isNull);
    });

    test('格式不合法，回傳 null', () {
      final result = DateHelper.parseAnimeDate('invalid-date', year: '2025');
      expect(result, isNull);
    });
  });

  group('DateHelper.parseAnimeDateWithTime', () {
    test('解析 MM/DD 加時間', () {
      final result = DateHelper.parseAnimeDateWithTime(
        '07/06',
        '23:00',
        year: '2025',
      );
      expect(result, isNotNull);
      expect(result!.hour, 23);
      expect(result.minute, 0);
    });

    test('時間格式不合法，回傳 null', () {
      final result = DateHelper.parseAnimeDateWithTime(
        '07/06',
        'bad-time',
        year: '2025',
      );
      expect(result, isNull);
    });
  });

  group('DateHelper.compareAnimeByDateTime', () {
    final earlier = _makeItem(date: '01/01', time: '12:00');
    final later = _makeItem(date: '01/02', time: '12:00');

    test('升冪：較早的排前面', () {
      final result = DateHelper.compareAnimeByDateTime(
        earlier,
        later,
        year: '2025',
      );
      expect(result, isNegative);
    });

    test('降冪：較晚的排前面', () {
      final result = DateHelper.compareAnimeByDateTime(
        earlier,
        later,
        descending: true,
        year: '2025',
      );
      expect(result, isPositive);
    });

    test('相同日期時間，回傳 0', () {
      final same1 = _makeItem(date: '03/15', time: '18:30');
      final same2 = _makeItem(date: '03/15', time: '18:30');
      final result = DateHelper.compareAnimeByDateTime(
        same1,
        same2,
        year: '2025',
      );
      expect(result, 0);
    });
  });

  group('DateHelper.filterByWeekday', () {
    // 2025/01/06 是星期一（DateTime.monday == 1）
    // 2025/01/07 是星期二（DateTime.tuesday == 2）
    final monday = _makeItem(date: '01/06', time: '20:00');
    final tuesday = _makeItem(date: '01/07', time: '20:00');
    final allItems = [monday, tuesday];

    test('過濾出星期一的動畫', () {
      final result = DateHelper.filterByWeekday(
        allItems,
        DateTime.monday,
        '2025',
      );
      expect(result.length, 1);
      expect(result.first.date, '01/06');
    });

    test('查無符合星期時，回傳空列表', () {
      final result = DateHelper.filterByWeekday(
        allItems,
        DateTime.wednesday,
        '2025',
      );
      expect(result, isEmpty);
    });

    test('同天多部動畫依時間升冪排序', () {
      final early = _makeItem(date: '01/06', time: '02:00');
      final late_ = _makeItem(date: '01/06', time: '23:00');
      final result = DateHelper.filterByWeekday(
        [late_, early],
        DateTime.monday,
        '2025',
      );
      expect(result.first.time, '02:00');
    });
  });
}
