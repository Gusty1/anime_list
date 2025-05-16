// 定義動漫資訊的 Model 類別
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

  // 構造函數
  AnimeItem({
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

  // Factory 構造函數，用於從 JSON Map 創建 AnimeItem 實例
  factory AnimeItem.fromJson(Map<String, dynamic> json) {
    return AnimeItem(
      name: json['name'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      carrier: json['carrier'] as String,
      season: json['season'] != null ? json['season'].toString() : '',
      originalName: json['originalName'] as String,
      img: json['img'] as String,
      description: json['description'] as String,
      official: json['official'] != null ? json['official'] as String : '',
    );
  }

  // (可選) 將 AnimeItem 實例轉換為 JSON Map：新增 official 欄位
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

  factory AnimeItem.fromMap(Map<String, dynamic> map) {
    return AnimeItem(
      name: map['name'] as String,
      date: map['date'] as String,
      time: map['time'] as String,
      carrier: map['carrier'] as String,
      season: map['season'] != null ? map['season'].toString() : '',
      originalName: map['originalName'] as String,
      img: map['img'] as String,
      description: map['description'] as String,
      official: map['official'] != null ? map['official'].toString() : '',
    );
  }

  // 將 AnimeItem 物件轉換為 資料庫 Map，以便插入或更新
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

  AnimeItem copyWith({
    String? name,
    String? date, // 這裡日期是可選的，以便只修改日期
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

  // (可選) 方便除錯的 toString 方法：新增 official 欄位
  @override
  String toString() {
    return 'AnimeItem(name: $name, date: $date, time: $time, carrier: $carrier, season: $season, originalName: $originalName, img: $img, description: $description, official: $official)';
  }
}