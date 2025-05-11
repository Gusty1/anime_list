// 定義動漫資訊的 Model 類別
class AnimeItem {
  final String name;
  final String date;
  final String week;
  final String time;
  final String carrier;
  final String season; // 根據JSON範例使用 String
  final String originalName;
  final String img; // 圖片 URL 使用 String
  final String description;

  // 構造函數
  AnimeItem({
    required this.name,
    required this.date,
    required this.week,
    required this.time,
    required this.carrier,
    required this.season,
    required this.originalName,
    required this.img,
    required this.description,
  });

  // Factory 構造函數，用於從 JSON Map 創建 AnimeItem 實例
  factory AnimeItem.fromJson(Map<String, dynamic> json) {
    return AnimeItem(
      name: json['name'] as String,
      date: json['date'] as String,
      week: json['week'] as String,
      time: json['time'] as String,
      carrier: json['carrier'] as String,
      season: json['season'] as String, // 根據JSON範例從 String 讀取
      originalName: json['originalName'] as String,
      img: json['img'] as String,
      description: json['description'] as String,
    );
  }

  // (可選) 將 AnimeItem 實例轉換為 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date,
      'week': week,
      'time': time,
      'carrier': carrier,
      'season': season,
      'originalName': originalName,
      'img': img,
      'description': description,
    };
  }

  // (可選) 方便除錯的 toString 方法
  @override
  String toString() {
    return 'AnimeItem(name: $name, date: $date, week: $week, time: $time, carrier: $carrier, season: $season, originalName: $originalName, img: $img, description: $description)';
  }
}