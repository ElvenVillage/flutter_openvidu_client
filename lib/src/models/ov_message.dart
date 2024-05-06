import 'dart:convert';

class OvMessage {
  OvMessage({
    required this.to,
    this.data,
    this.type = "signal:chat",
  });

  final List<String> to;
  final String? data;
  final String type;

  OvMessage copyWith({
    List<String>? to,
    String? data,
    String? type,
  }) =>
      OvMessage(
        to: to ?? this.to,
        data: data ?? this.data,
        type: type ?? this.type,
      );

  factory OvMessage.fromRawJson(String str) =>
      OvMessage.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory OvMessage.fromJson(Map<String, dynamic> json) => OvMessage(
        to: json["to"] == null
            ? []
            : List<String>.from(json["to"]!.map((x) => x)),
        data: json["data"],
        type: json["type"],
      );

  Map<String, dynamic> toJson() => {
        "to": List<dynamic>.from(to.map((x) => x)),
        "data": data,
        "type": type,
      };
}
