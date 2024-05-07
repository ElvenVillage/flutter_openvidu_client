import 'dart:convert';

import 'media_options.dart';

class Publisher {
  Publisher({
    this.createdAt,
    this.streamId,
    this.mediaOptions,
  });

  final int? createdAt;
  final String? streamId;
  final MediaOptions? mediaOptions;

  Publisher copyWith({
    int? createdAt,
    String? streamId,
    MediaOptions? mediaOptions,
  }) =>
      Publisher(
        createdAt: createdAt ?? this.createdAt,
        streamId: streamId ?? this.streamId,
        mediaOptions: mediaOptions ?? this.mediaOptions,
      );

  factory Publisher.fromRawJson(String str) =>
      Publisher.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Publisher.fromJson(Map<String, dynamic> json) => Publisher(
        createdAt: json["createdAt"],
        streamId: json["streamId"],
        mediaOptions: json["mediaOptions"] == null
            ? null
            : MediaOptions.fromJson(json["mediaOptions"]),
      );

  Map<String, dynamic> toJson() => {
        "createdAt": createdAt,
        "streamId": streamId,
        "mediaOptions": mediaOptions?.toJson(),
      };
}
