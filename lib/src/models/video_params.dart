import 'package:flutter/foundation.dart';

class VideoParams {
  final int frameRate;
  final int width;
  final int height;

  double get aspectRatio => width / height;

  const VideoParams(this.frameRate, this.width, this.height);

  static const VideoParams low =
      kIsWeb ? VideoParams(30, 640, 480) : VideoParams(30, 480, 640);
  static const VideoParams middle =
      kIsWeb ? VideoParams(30, 960, 640) : VideoParams(30, 640, 960);
  static const VideoParams high =
      kIsWeb ? VideoParams(30, 1920, 1080) : VideoParams(30, 1080, 1920);
}
