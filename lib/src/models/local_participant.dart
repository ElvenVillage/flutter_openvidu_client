import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../utils/constants.dart';
import '../utils/logger.dart';
import '../widgets/screen_select_dialog.dart';
import 'openvidu_events.dart';
import 'participant.dart';
import 'stream_mode.dart';
import 'video_params.dart';

class LocalParticipant extends Participant {
  final bool _published = false;
  bool _audioOnly = false;
  String typeOfVideo = "CAMERA";
  int frameRate = 0;
  int width = 0;
  int height = 0;

  @override
  VideoParams? get videoParams => VideoParams(frameRate, width, height);

  StreamMode? _mode = StreamMode.frontCamera;
  late EventDispatcher _dispatchEvent;

  LocalParticipant.preview(
    MediaStream? stream,
    EventDispatcher dispatchEvent,
  ) : super.preview() {
    _dispatchEvent = dispatchEvent;
    this.stream = stream;
    audioActive =
        stream?.getAudioTracks().any((item) => item.enabled == true) ?? false;
    videoActive =
        stream?.getVideoTracks().any((item) => item.enabled == true) ?? false;
  }

  LocalParticipant(
    super.id,
    super.token,
    super.rpc,
    super.metadata,
    EventDispatcher dispatchEvent, {
    required MediaStream? stream,
    required StreamMode? mode,
    required VideoParams videoParams,
  }) {
    _dispatchEvent = dispatchEvent;
    _mode = mode;
    this.stream = stream;
    audioActive = true;

    if (mode == StreamMode.audio) {
      _audioOnly = true;
    } else {
      _audioOnly = false;
      videoActive = true;
    }

    if (mode == StreamMode.screen) typeOfVideo = "SCREEN";

    audioActive =
        stream?.getAudioTracks().any((item) => item.enabled == true) ?? false;
    videoActive =
        stream?.getVideoTracks().any((item) => item.enabled == true) ?? false;

    frameRate = videoParams.frameRate;
    width = videoParams.width;
    height = videoParams.height;
    publishLocalStream();
  }

  StreamMode? get mode => _mode;

  Future<void> publishLocalStream() async {
    //if (stream == null || _published == true) return;
    try {
      final connection = await peerConnection;
      switch (sdpSemantics) {
        case "plan-b":
          connection.addStream(stream!);

          break;
        case "unified-plan":
          stream?.getTracks().forEach((track) {
            connection.addTrack(track, stream!);
          });
          break;
        default:
      }

      final offer = await connection.createOffer(constraints);
      connection.setLocalDescription(offer);

      final result = await rpc.send(
        Methods.publishVideo,
        params: {
          'audioOnly': _audioOnly,
          'hasAudio': true,
          'doLoopback': false,
          'hasVideo': true,
          'audioActive': true,
          'videoActive': true,
          'typeOfVideo': typeOfVideo,
          'frameRate': frameRate,
          'videoDimensions': json.encode({"width": width, "height": height}),
          'sdpOffer': offer.sdp
        },
        hasResult: true,
      );

      streamId = result["id"];
      final answer = RTCSessionDescription(result['sdpAnswer'], 'answer');
      await connection.setRemoteDescription(answer);
    } catch (e) {
      logger.e(e);
    }
  }

  Future<void> _stopStream() async {
    if (stream != null) {
      stream!.getTracks().forEach((track) async {
        await track.stop();
      });
      await stream!.dispose();
      stream = null;
    }
  }

  Future<void> _changeToCam() async {
    stream?.getVideoTracks()[0].stop();
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': {
        'mandatory': {
          'facingMode': 'user',
          'optional': [],
        },
      }
    };
    await _stopStream();
    stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _mode = StreamMode.frontCamera;
    final connection = await peerConnection;
    final senders = await connection.senders;

    for (var sender in senders) {
      if (sender.track!.kind == 'video') {
        sender.replaceTrack(stream!.getVideoTracks()[0]);
      }
    }
    _dispatchEvent(
        OpenViduEvent.updatedLocal, {'mode': _mode, 'localParticipant': this});
  }

  Future<void> _changeToScreen(BuildContext context) async {
    try {
      Map<String, dynamic> mediaConstraints = {
        'audio': false,
        'video': true,
      };
      await _stopStream();
      if (WebRTC.platformIsDesktop) {
        // ignore: use_build_context_synchronously
        final source = await showDialog<DesktopCapturerSource>(
          context: context,
          builder: (context) => ScreenSelectDialog(),
        );
        stream = await navigator.mediaDevices.getDisplayMedia(<String, dynamic>{
          'video': source == null
              ? true
              : {
                  'deviceId': {'exact': source.id},
                  'mandatory': {'frameRate': 30.0}
                }
        });
      } else {
        stream = await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
      }

      final connection = await peerConnection;
      final senders = await connection.senders;

      for (var sender in senders) {
        if (sender.track!.kind == 'video') {
          sender.replaceTrack(stream?.getVideoTracks()[0]);
        }
      }

      _mode = StreamMode.screen;
      stream?.getVideoTracks()[0].onEnded = () async {
        await _changeToCam();
      };

      _dispatchEvent(OpenViduEvent.updatedLocal,
          {'mode': _mode, 'localParticipant': this});
    } catch (e) {
      logger.e(e);
    }
  }

  /// It changes the stream mode from camera to screen and vice versa.
  ///
  /// Args:
  ///   context (BuildContext): The context of the current screen.
  ///
  /// Returns:
  ///   A Future<void>
  Future<void> shareScreen(BuildContext context) async {
    try {
      if (stream == null) return;
      if (_mode == StreamMode.screen) {
        _changeToCam();
      } else {
        _changeToScreen(context);
      }
    } catch (e) {
      logger.e(e);
    }
  }

  /// It gets the current peer connection, gets the senders, and then loops through the senders to find the audio sender and
  /// replace the track with the new track
  ///
  /// Args:
  ///   deviceId (String): The device id of the audio input device.
  Future<void> setAudioInput(String deviceId) async {
    final connection = await peerConnection;
    final senders = await connection.senders;

    for (var sender in senders) {
      if (sender.track!.kind == 'audio') {
        sender.replaceTrack(stream?.getTrackById(deviceId));
      }
    }
  }

  /// It gets the first video track from the stream, and then switches the camera to the deviceId passed in
  ///
  /// Args:
  ///   deviceId (String): The device id of the camera you want to switch to.
  ///
  /// Returns:
  ///   A Future<void>
  Future<void> setVideoInput(String deviceId) async {
    final track = stream?.getVideoTracks().firstOrNull;
    if (track == null) return;
    await Helper.switchCamera(track, deviceId, stream);
  }

  /// > If the stream is not null, get the list of cameras, get the first video track, get the new track, and switch the
  /// camera
  ///
  /// Returns:
  ///   A Future<void>
  void switchCamera() async {
    if (stream == null) return;
    final devices = await Helper.cameras;
    final track = stream?.getVideoTracks().firstOrNull;
    if (track == null) return;
    final newTrack = devices.firstWhereOrNull((el) => el.deviceId != track.id);
    if (newTrack == null) return;
    Helper.switchCamera(track, newTrack.deviceId, stream);
  }

  /// It disables all the tracks of the local stream and dispatches an event to notify the change
  ///
  /// Returns:
  ///   A Future<void>
  Future<void> unpublishAllTracks() async {
    if (stream == null) return;
    stream!.getTracks().forEach((MediaStreamTrack e) => e.enabled = false);
    videoActive = false;
    audioActive = false;
    _dispatchEvent(
        OpenViduEvent.updatedLocal, {'mode': _mode, 'localParticipant': this});
    if (!_published) return;
    await _streamPropertyChanged("videoActive", videoActive, "publishVideo");
    await _streamPropertyChanged("audioActive", audioActive, "publishAudio");
  }

  /// It enables or disables the video track of the local stream, and then it sends a request to the OpenVidu Server to
  /// update the stream property
  ///
  /// Args:
  ///   enable (bool): true to enable the video, false to disable it
  ///
  /// Returns:
  ///   A Future<void>
  Future<void> publishVideo(bool enable) async {
    if (stream == null) return;
    stream!
        .getVideoTracks()
        .forEach((MediaStreamTrack e) => e.enabled = enable);

    videoActive = enable;
    _dispatchEvent(
        OpenViduEvent.updatedLocal, {'mode': _mode, 'localParticipant': this});
    if (!_published) return;
    await _streamPropertyChanged("videoActive", videoActive, "publishVideo");
  }

  /// If the stream is not null, then enable or disable the audio track of the stream, depending on the value of the enable
  /// parameter
  ///
  /// Args:
  ///   enable (bool): boolean
  ///
  /// Returns:
  ///   A Future<void>
  Future<void> publishAudio(bool enable) async {
    if (stream == null) return;
    stream!.getAudioTracks().forEach((e) => e.enabled = enable);
    audioActive = enable;
    _dispatchEvent(
        OpenViduEvent.updatedLocal, {'mode': _mode, 'localParticipant': this});
    if (!_published) return;
    await _streamPropertyChanged("audioActive", audioActive, "publishAudio");
  }

  Future<void> _streamPropertyChanged(
    String property,
    Object value,
    String reason,
  ) async {
    if (!rpc.isActive) return;
    await rpc.send(
      "streamPropertyChanged",
      params: {
        "streamId": streamId,
        "property": property,
        "newValue": value,
        "reason": reason,
      },
    );
  }
}
