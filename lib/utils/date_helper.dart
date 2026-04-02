import 'package:anime_list/models/anime_item.dart';
import 'logger.dart';

/// 日期解析與排序的工具類別
/// 集中管理所有與動漫日期相關的邏輯，避免散落在各個 Widget 中重複實作
class DateHelper {
  DateHelper._(); // 防止外部實例化

  /// 解析動漫日期字串為 DateTime
  ///
  /// 支援兩種格式：
  /// - `MM/DD`（列表頁使用，需要額外傳入 [year]）
  /// - `YYYY/MM/DD`（收藏頁使用，已包含年份）
  ///
  /// 解析失敗時回傳 null
  static DateTime? parseAnimeDate(String date, {String? year}) {
    try {
      final parts = date.split('/');

      if (parts.length == 3) {
        // 格式：YYYY/MM/DD（收藏頁）
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      } else if (parts.length == 2 && year != null) {
        // 格式：MM/DD（列表頁，需要傳入年份）
        return DateTime(
          int.parse(year),
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }

      return null;
    } catch (e) {
      appLogger.d('DateHelper: 解析日期 "$date" 失敗 - $e');
      return null;
    }
  }

  /// 解析動漫日期與時間字串為 DateTime
  ///
  /// 時間格式為 `HH:mm`
  static DateTime? parseAnimeDateWithTime(
    String date,
    String time, {
    String? year,
  }) {
    try {
      final dateTime = parseAnimeDate(date, year: year);
      if (dateTime == null) return null;

      final timeParts = time.split(':');
      if (timeParts.length != 2) return null;

      return DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (e) {
      appLogger.d('DateHelper: 解析日期時間 "$date $time" 失敗 - $e');
      return null;
    }
  }

  /// 比較兩個動漫項目的日期時間，用於排序
  ///
  /// [descending] 為 true 時由新到舊排序（收藏頁）；
  /// 為 false 時由舊到新（列表頁）。
  static int compareAnimeByDateTime(
    AnimeItem a,
    AnimeItem b, {
    bool descending = false,
    String? year,
  }) {
    try {
      final dateTimeA = parseAnimeDateWithTime(a.date, a.time, year: year);
      final dateTimeB = parseAnimeDateWithTime(b.date, b.time, year: year);

      // 無法解析的項目排到最後
      if (dateTimeA == null && dateTimeB == null) return 0;
      if (dateTimeA == null) return 1;
      if (dateTimeB == null) return -1;

      return descending
          ? dateTimeB.compareTo(dateTimeA)
          : dateTimeA.compareTo(dateTimeB);
    } catch (e) {
      appLogger.d('DateHelper: 排序比較 "${a.name}" 和 "${b.name}" 時發生錯誤 - $e');
      return 0;
    }
  }

  /// 根據星期幾過濾動漫列表
  ///
  /// [weekday] 使用 `DateTime.monday` ~ `DateTime.sunday` 常數
  static List<AnimeItem> filterByWeekday(
    List<AnimeItem> list,
    int weekday,
    String year,
  ) {
    final filteredList =
        list.where((item) {
          final date = parseAnimeDate(item.date, year: year);
          if (date == null) return false;
          return date.weekday == weekday;
        }).toList();

    // 過濾後依日期時間由舊到新排序
    filteredList.sort((a, b) => compareAnimeByDateTime(a, b, year: year));

    return filteredList;
  }

  /// 過濾出「其他」類別的動漫：date 為空或無法解析為有效日期的項目
  ///
  /// 適用於無法歸入星期一~日的資料，例如 OVA、特別篇、日期未定等。
  static List<AnimeItem> filterOther(
    List<AnimeItem> list,
    String year,
  ) {
    final filteredList =
        list.where((item) {
          if (item.date.isEmpty) return true;
          final date = parseAnimeDate(item.date, year: year);
          return date == null;
        }).toList();

    return filteredList;
  }
}
