// 定義動漫名言的model
class Hitokoto {
  final int id;
  final String uuid;
  final String hitokoto;
  final String type;
  final String from;

  // from_who 可能是 null，所以使用 String? (nullable String)
  final String? fromWho;
  final String creator;
  final int creatorUid;
  final int reviewer;
  final String commitFrom;
  final String createdAt;
  final int length;

  // 構造函數
  Hitokoto({
    required this.id,
    required this.uuid,
    required this.hitokoto,
    required this.type,
    required this.from,
    required this.fromWho, // fromWho 可能是 null
    required this.creator,
    required this.creatorUid,
    required this.reviewer,
    required this.commitFrom,
    required this.createdAt,
    required this.length,
  });

  // Factory 構造函數，用於從 JSON Map 創建 Hitokoto 實例
  factory Hitokoto.fromJson(Map<String, dynamic> json) {
    return Hitokoto(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      hitokoto: json['hitokoto'] as String,
      type: json['type'] as String,
      from: json['from'] as String,
      // json['from_who'] 可能會是 null，這裡進行了處理
      fromWho: json['from_who'] as String?,
      creator: json['creator'] as String,
      creatorUid: json['creator_uid'] as int,
      reviewer: json['reviewer'] as int,
      commitFrom: json['commit_from'] as String,
      createdAt: json['created_at'] as String,
      length: json['length'] as int,
    );
  }

  // (可選) 將 Hitokoto 實例轉換為 JSON Map
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

  // (可選) 方便除錯的 toString 方法
  @override
  String toString() {
    return 'Hitokoto(id: $id, uuid: $uuid, hitokoto: $hitokoto, type: $type, from: $from, fromWho: $fromWho, creator: $creator, creatorUid: $creatorUid, reviewer: $reviewer, commitFrom: $commitFrom, createdAt: $createdAt, length: $length)';
  }
}