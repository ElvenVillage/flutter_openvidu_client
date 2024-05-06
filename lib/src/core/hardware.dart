import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../utils/logger.dart';

class MediaDevice {
  const MediaDevice(this.deviceId, this.label, this.kind);

  final String deviceId;
  final String label;
  final String kind;

  @override
  bool operator ==(covariant MediaDevice other) {
    if (identical(this, other)) return true;

    return other.deviceId == deviceId &&
        other.kind == kind &&
        other.label == label;
  }

  @override
  int get hashCode {
    return deviceId.hashCode ^ kind.hashCode ^ label.hashCode;
  }

  @override
  String toString() {
    return 'MediaDevice{deviceId: $deviceId, label: $label, kind: $kind}';
  }
}

class Hardware {
  Hardware._internal() {
    navigator.mediaDevices.ondevicechange = _onDeviceChange;
    enumerateDevices().then((devices) {
      selectedAudioInput ??=
          devices.firstWhereOrNull((element) => element.kind == 'audioinput');
      selectedAudioOutput ??=
          devices.firstWhereOrNull((element) => element.kind == 'audiooutput');
      selectedVideoInput ??=
          devices.firstWhereOrNull((element) => element.kind == 'videoinput');
    });
  }

  static final Hardware instance = Hardware._internal();

  final StreamController<List<MediaDevice>> onDeviceChange =
      StreamController.broadcast();

  MediaDevice? selectedAudioInput;

  MediaDevice? selectedAudioOutput;

  MediaDevice? selectedVideoInput;

  Future<List<MediaDevice>> enumerateDevices({String? type}) async {
    try {
      var infos = await navigator.mediaDevices.enumerateDevices();
      var devices =
          infos.map((e) => MediaDevice(e.deviceId, e.label, e.kind!)).toList();
      if (type != null && type.isNotEmpty) {
        devices = devices.where((d) => d.kind == type).toList();
      }
      return devices;
    } catch (e) {
      logger.e(e);
      return [];
    }
  }

  Future<List<MediaDevice>> audioInputs() async {
    return enumerateDevices(type: 'audioinput');
  }

  Future<List<MediaDevice>> audioOutputs() async {
    return enumerateDevices(type: 'audiooutput');
  }

  Future<List<MediaDevice>> videoInputs() async {
    return enumerateDevices(type: 'videoinput');
  }

  Future<void> selectAudioOutput(MediaDevice device) async {
    if (WebRTC.platformIsWeb) {
      throw UnimplementedError('selectAudioOutput not support on web');
    }
    selectedAudioOutput = device;
    await Helper.selectAudioOutput(device.deviceId);
  }

  Future<void> selectAudioInput(MediaDevice device) async {
    if (WebRTC.platformIsWeb || WebRTC.platformIsIOS) {
      throw UnimplementedError(
          'selectAudioInput is only supported on Android/Windows/macOS');
    }
    selectedAudioInput = device;
    await Helper.selectAudioInput(device.deviceId);
  }

  Future<void> setSpeakerphoneOn(bool enable) async {
    if (WebRTC.platformIsMobile) {
      await Helper.setSpeakerphoneOn(enable);
    } else {
      throw UnimplementedError('setSpeakerphoneOn only support on iOS/Android');
    }
  }

  Future<MediaStream> openCamera(
      {MediaDevice? device, bool? facingMode}) async {
    var constraints = <String, dynamic>{
      if (facingMode != null) 'facingMode': facingMode ? 'user' : 'environment',
    };
    if (device != null) {
      if (WebRTC.platformIsWeb) {
        constraints['deviceId'] = device.deviceId;
      } else {
        constraints['optional'] = [
          {'sourceId': device.deviceId}
        ];
      }
    }
    selectedVideoInput = device;
    return navigator.mediaDevices.getUserMedia(<String, dynamic>{
      'audio': false,
      'video': device != null ? constraints : true,
    });
  }

  dynamic _onDeviceChange(dynamic _) async {
    var devices = await enumerateDevices();
    selectedAudioInput ??=
        devices.firstWhereOrNull((element) => element.kind == 'audioinput');
    selectedAudioOutput ??=
        devices.firstWhereOrNull((element) => element.kind == 'audiooutput');
    selectedVideoInput ??=
        devices.firstWhereOrNull((element) => element.kind == 'videoinput');
    onDeviceChange.add(devices);
  }
}
