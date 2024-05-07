import 'dart:convert';

import 'filter.dart';

class MediaOptions {
  MediaOptions({
    this.hasAudio,
    this.audioActive,
    this.hasVideo,
    this.videoActive,
    this.typeOfVideo,
    this.frameRate,
    this.videoDimensions,
    this.filter,
  });

  final bool? hasAudio;
  final bool? audioActive;
  final bool? hasVideo;
  final bool? videoActive;
  final String? typeOfVideo;
  final int? frameRate;
  final String? videoDimensions;
  final Filter? filter;

  MediaOptions copyWith({
    bool? hasAudio,
    bool? audioActive,
    bool? hasVideo,
    bool? videoActive,
    String? typeOfVideo,
    int? frameRate,
    String? videoDimensions,
    Filter? filter,
  }) =>
      MediaOptions(
        hasAudio: hasAudio ?? this.hasAudio,
        audioActive: audioActive ?? this.audioActive,
        hasVideo: hasVideo ?? this.hasVideo,
        videoActive: videoActive ?? this.videoActive,
        typeOfVideo: typeOfVideo ?? this.typeOfVideo,
        frameRate: frameRate ?? this.frameRate,
        videoDimensions: videoDimensions ?? this.videoDimensions,
        filter: filter ?? this.filter,
      );

  factory MediaOptions.fromRawJson(String str) =>
      MediaOptions.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory MediaOptions.fromJson(Map<String, dynamic> json) => MediaOptions(
        hasAudio: json["hasAudio"],
        audioActive: json["audioActive"],
        hasVideo: json["hasVideo"],
        videoActive: json["videoActive"],
        typeOfVideo: json["typeOfVideo"],
        frameRate: json["frameRate"],
        videoDimensions: json["videoDimensions"],
        filter: json["filter"] == null ? null : Filter.fromJson(json["filter"]),
      );

  Map<String, dynamic> toJson() => {
        "hasAudio": hasAudio,
        "audioActive": audioActive,
        "hasVideo": hasVideo,
        "videoActive": videoActive,
        "typeOfVideo": typeOfVideo,
        "frameRate": frameRate,
        "videoDimensions": videoDimensions,
        "filter": filter?.toJson(),
      };
}
