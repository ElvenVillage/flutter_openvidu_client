import 'dart:convert';

class KurentoOptions {
  KurentoOptions({
    this.videoMaxRecvBandwidth,
    this.videoMinRecvBandwidth,
    this.videoMaxSendBandwidth,
    this.videoMinSendBandwidth,
    this.allowedFilters,
  });

  final int? videoMaxRecvBandwidth;
  final int? videoMinRecvBandwidth;
  final int? videoMaxSendBandwidth;
  final int? videoMinSendBandwidth;
  final List<String>? allowedFilters;

  KurentoOptions copyWith({
    int? videoMaxRecvBandwidth,
    int? videoMinRecvBandwidth,
    int? videoMaxSendBandwidth,
    int? videoMinSendBandwidth,
    List<String>? allowedFilters,
  }) =>
      KurentoOptions(
        videoMaxRecvBandwidth:
            videoMaxRecvBandwidth ?? this.videoMaxRecvBandwidth,
        videoMinRecvBandwidth:
            videoMinRecvBandwidth ?? this.videoMinRecvBandwidth,
        videoMaxSendBandwidth:
            videoMaxSendBandwidth ?? this.videoMaxSendBandwidth,
        videoMinSendBandwidth:
            videoMinSendBandwidth ?? this.videoMinSendBandwidth,
        allowedFilters: allowedFilters ?? this.allowedFilters,
      );

  factory KurentoOptions.fromRawJson(String str) =>
      KurentoOptions.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory KurentoOptions.fromJson(Map<String, dynamic> json) => KurentoOptions(
        videoMaxRecvBandwidth: json["videoMaxRecvBandwidth"],
        videoMinRecvBandwidth: json["videoMinRecvBandwidth"],
        videoMaxSendBandwidth: json["videoMaxSendBandwidth"],
        videoMinSendBandwidth: json["videoMinSendBandwidth"],
        allowedFilters: json["allowedFilters"] == null
            ? []
            : List<String>.from(json["allowedFilters"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "videoMaxRecvBandwidth": videoMaxRecvBandwidth,
        "videoMinRecvBandwidth": videoMinRecvBandwidth,
        "videoMaxSendBandwidth": videoMaxSendBandwidth,
        "videoMinSendBandwidth": videoMinSendBandwidth,
        "allowedFilters": allowedFilters == null
            ? []
            : List<dynamic>.from(allowedFilters!.map((x) => x)),
      };
}
