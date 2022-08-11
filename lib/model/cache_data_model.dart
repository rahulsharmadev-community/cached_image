import 'dart:convert';

class CacheDataModel {
  CacheDataModel({
    required this.key,
    required this.rawImage,
    required this.expireAt,
  });

  final String key;
  final List<int> rawImage;
  final DateTime expireAt;

  CacheDataModel copyWith({
    String? key,
    List<int>? rawImage,
    DateTime? expireAt,
  }) =>
      CacheDataModel(
        key: key ?? this.key,
        rawImage: rawImage ?? this.rawImage,
        expireAt: expireAt ?? this.expireAt,
      );

  factory CacheDataModel.fromJson(String str) =>
      CacheDataModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CacheDataModel.fromMap(Map<String, dynamic> json) => CacheDataModel(
        key: json["key"],
        rawImage: List<int>.from(json["rawImage"].map((x) => x)),
        expireAt: DateTime.parse(json["expireAt"]),
      );

  Map<String, dynamic> toMap() => {
        "key": key,
        "rawImage": List<dynamic>.from(rawImage.map((x) => x)),
        "expireAt": expireAt.toIso8601String(),
      };
}
