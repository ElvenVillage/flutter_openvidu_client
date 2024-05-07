import 'dart:convert';

class Filter {
  Filter({
    this.type,
    this.options,
  });

  final String? type;
  final String? options;

  Filter copyWith({
    String? type,
    String? options,
  }) =>
      Filter(
        type: type ?? this.type,
        options: options ?? this.options,
      );

  factory Filter.fromRawJson(String str) => Filter.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Filter.fromJson(Map<String, dynamic> json) => Filter(
        type: json["type"],
        options: json["options"],
      );

  Map<String, dynamic> toJson() => {
        "type": type,
        "options": options,
      };
}
