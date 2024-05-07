import 'dart:convert';

class Subscriber {
  Subscriber({
    this.streamId,
    this.createdAt,
  });

  final String? streamId;
  final int? createdAt;

  Subscriber copyWith({
    String? streamId,
    int? createdAt,
  }) =>
      Subscriber(
        streamId: streamId ?? this.streamId,
        createdAt: createdAt ?? this.createdAt,
      );

  factory Subscriber.fromRawJson(String str) =>
      Subscriber.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Subscriber.fromJson(Map<String, dynamic> json) => Subscriber(
        streamId: json["streamId"],
        createdAt: json["createdAt"],
      );

  Map<String, dynamic> toJson() => {
        "streamId": streamId,
        "createdAt": createdAt,
      };
}
