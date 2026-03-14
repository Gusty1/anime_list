import 'package:anime_list/constants.dart';

/// 動漫資訊的資料模型
/// 用於存放從 API 或本地資料庫取得的動漫項目資訊
class AnimeItem {
  final String name;
  final String date;
  final String time;
  final String carrier;
  final String season;
  final String originalName;
  final String img;
  final String description;
  final String official;

  const AnimeItem({
    required this.name,
    required this.date,
    required this.time,
    required this.carrier,
    required this.season,
    required this.originalName,
    required this.img,
    required this.description,
    required this.official,
  });

  // ---------------------------------------------------------------------------
  // 計算屬性 (Computed Getters)
  // ---------------------------------------------------------------------------

  /// 完整的圖片 URL，自動判斷是否需要加上基底路徑
  String get fullImageUrl => img.startsWith('http') ? img : '$imageBaseUrl$img';

  /// 將英文的原作類型轉換為中文顯示文字
  String get displayCarrier {
    switch (carrier) {
      case 'Novel':
        return '小說';
      case 'Comic':
        return '漫畫';
      case 'Original':
        return '原創';
      case 'Game':
        return '遊戲';
      default:
        return carrier;
    }
  }

  // ---------------------------------------------------------------------------
  // 序列化 / 反序列化
  // ---------------------------------------------------------------------------

  /// 從 API 回傳的 JSON Map 建立 AnimeItem
  factory AnimeItem.fromJson(Map<String, dynamic> json) {
    return AnimeItem(
      name: (json['name'] as String?) ?? '',
      date: (json['date'] as String?) ?? '',
      time: (json['time'] as String?) ?? '',
      carrier: (json['carrier'] as String?) ?? '',
      season: json['season']?.toString() ?? '',
      originalName: (json['originalName'] as String?) ?? '',
      img: (json['img'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      official: json['official']?.toString() ?? '',
    );
  }

  /// 轉換為 JSON Map（用於分享等場景）
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date,
      'time': time,
      'carrier': carrier,
      'season': season,
      'originalName': originalName,
      'img': img,
      'description': description,
      'official': official,
    };
  }

  /// 從 SQLite 資料庫的 Map 建立 AnimeItem
  factory AnimeItem.fromMap(Map<String, dynamic> map) {
    return AnimeItem(
      name: (map['name'] as String?) ?? '',
      date: (map['date'] as String?) ?? '',
      time: (map['time'] as String?) ?? '',
      carrier: (map['carrier'] as String?) ?? '',
      season: map['season']?.toString() ?? '',
      originalName: (map['originalName'] as String?) ?? '',
      img: (map['img'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      official: map['official']?.toString() ?? '',
    );
  }

  /// 轉換為 SQLite 資料庫 Map（用於插入或更新）
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': date,
      'time': time,
      'carrier': carrier,
      'season': season,
      'originalName': originalName,
      'img': img,
      'description': description,
      'official': official,
    };
  }

  // ---------------------------------------------------------------------------
  // copyWith / 相等性 / toString
  // ---------------------------------------------------------------------------

  /// 複製並修改部分欄位的便捷方法
  AnimeItem copyWith({
    String? name,
    String? date,
    String? time,
    String? carrier,
    String? season,
    String? originalName,
    String? img,
    String? description,
    String? official,
  }) {
    return AnimeItem(
      name: name ?? this.name,
      date: date ?? this.date,
      time: time ?? this.time,
      carrier: carrier ?? this.carrier,
      season: season ?? this.season,
      originalName: originalName ?? this.originalName,
      img: img ?? this.img,
      description: description ?? this.description,
      official: official ?? this.official,
    );
  }

  /// 覆寫相等性判斷，配合 Riverpod 3 的 `==` 過濾機制
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnimeItem &&
        other.name == name &&
        other.date == date &&
        other.time == time &&
        other.carrier == carrier &&
        other.season == season &&
        other.originalName == originalName &&
        other.img == img &&
        other.description == description &&
        other.official == official;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      date,
      time,
      carrier,
      season,
      originalName,
      img,
      description,
      official,
    );
  }

  @override
  String toString() {
    return 'AnimeItem(name: $name, date: $date, time: $time, '
        'carrier: $carrier, season: $season, originalName: $originalName, '
        'img: $img, description: $description, official: $official)';
  }
}
