/// 一言（Hitokoto）API 回傳的資料模型
/// 用於在首頁顯示隨機動漫名言
class Hitokoto {
  final int id;
  final String uuid;
  final String hitokoto;
  final String type;
  final String from;
  final String? fromWho;
  final String creator;
  final int creatorUid;
  final int reviewer;
  final String commitFrom;
  final String createdAt;
  final int length;

  const Hitokoto({
    required this.id,
    required this.uuid,
    required this.hitokoto,
    required this.type,
    required this.from,
    required this.fromWho,
    required this.creator,
    required this.creatorUid,
    required this.reviewer,
    required this.commitFrom,
    required this.createdAt,
    required this.length,
  });

  /// 從 API JSON 建立 Hitokoto 實例
  factory Hitokoto.fromJson(Map<String, dynamic> json) {
    return Hitokoto(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      hitokoto: json['hitokoto'] as String,
      type: json['type'] as String,
      from: json['from'] as String,
      fromWho: json['from_who'] as String?,
      creator: json['creator'] as String,
      creatorUid: json['creator_uid'] as int,
      reviewer: json['reviewer'] as int,
      commitFrom: json['commit_from'] as String,
      createdAt: json['created_at'] as String,
      length: json['length'] as int,
    );
  }

  /// 轉換為 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'hitokoto': hitokoto,
      'type': type,
      'from': from,
      'from_who': fromWho,
      'creator': creator,
      'creator_uid': creatorUid,
      'reviewer': reviewer,
      'commit_from': commitFrom,
      'created_at': createdAt,
      'length': length,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Hitokoto &&
        other.id == id &&
        other.uuid == uuid &&
        other.hitokoto == hitokoto;
  }

  @override
  int get hashCode => Object.hash(id, uuid, hitokoto);

  @override
  String toString() {
    return 'Hitokoto(id: $id, hitokoto: $hitokoto, from: $from)';
  }
}
