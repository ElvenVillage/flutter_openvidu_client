import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/error.dart';
import '../models/local_participant.dart';
import '../models/openvidu_events.dart';
import '../models/ov_message.dart';
import '../models/participant.dart';
import '../models/remote_participant.dart';
import '../models/stream_mode.dart';
import '../models/token.dart';
import '../models/video_params.dart';
import '../support/json_rpc.dart';
import '../support/platform/device_info.dart'
    if (dart.library.js) '../support/platform/device_info_web.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class OpenViduClient {
  late Token _token;
  bool _active = true;
  JsonRpc? _rpc;
  String _userId = '';

  EventHandler _handlers = {};

  /* ---------------------------- LOCAL CONNECCTION --------------------------- */
  StreamMode? _mode = StreamMode.frontCamera;
  VideoParams _videoParams = VideoParams.high;

  LocalParticipant? _localParticipant;

  /* --------------------------- REMOTE CONNECTIONS --------------------------- */

  /// map of SID to RemoteParticipant
  UnmodifiableMapView<String, RemoteParticipant> get participants =>
      UnmodifiableMapView(_participants);
  final _participants = <String, RemoteParticipant>{};

  UnmodifiableMapView<String, Participant> get allConnection {
    Map<String, Participant> connections = <String, Participant>{};
    if (_localParticipant != null && _localParticipant?.id != null) {
      connections[_localParticipant!.id] = _localParticipant!;
    }
    connections.addAll(_participants);

    return UnmodifiableMapView(connections);
  }

  /// It creates a new instance of the Token class.
  ///
  /// Args:
  ///   serverUrl (String): The URL of the OpenVidu Server.
  OpenViduClient(String serverUrl) {
    _token = Token(serverUrl);
  }

  /// > Start the local preview, and return the local participant
  ///
  /// Args:
  ///   context (BuildContext): The context of the current page.
  ///   mode (StreamMode): StreamMode.audioAndVideo,
  ///   videoParams (VideoParams): Video parameters, including resolution, frame rate, and bit rate. Defaults to VideoParams
  ///
  /// Returns:
  ///   A Future<LocalParticipant?>
  Future<LocalParticipant?> startLocalPreview(
      BuildContext? context, StreamMode? mode,
      {VideoParams? videoParams = VideoParams.middle,
      disableTracks = false}) async {
    _videoParams = videoParams ?? VideoParams.middle;
    _mode = mode;

    _rpc = JsonRpc(
      onData: _onRpcMessage,
      onError: _onSocketError,
      onDispose: () {},
    );

    try {
      await _rpc?.connect(_token.wss);
      _heartbeat();
    } catch (e) {
      logger.e(e);
      _rpc?.disconnect();
      throw NetworkError();
    }

    try {
      if (_rpc == null) return null;
      // ignore: use_build_context_synchronously
      final stream = mode == null
          ? null
          : await createMediaStream(mode, disableTracks: disableTracks);
      _localParticipant = LocalParticipant.preview(stream, _dispatchEvent);
      return _localParticipant;
    } catch (e) {
      logger.e('[StartPreview] $e');
      throw NotPermissionError();
    }
  }

  /// Stop the local preview
  Future<void> stopLocalPreview() async => disconnect();

  /// It creates a local participant, joins the room, and returns the local participant
  ///
  /// Args:
  ///   token (String): The token you get from the server.
  ///   userName (String): The name of the user who is publishing the stream.
  ///   extraData (Map<String, dynamic>): Extra data to be sent to the server.
  ///
  /// Returns:
  ///   The local participant.
  Future<LocalParticipant?> publishLocalStream({
    required String token,
    required String userName,
    Map<String, dynamic>? extraData,
  }) async {
    // if (_localParticipant == null || _localParticipant?.stream == null) {
    //   throw "Please call startLocalPreview first";
    // }
    _token.setToken(token);
    //try {
    final response = await _joinRoom({"clientData": userName, ...?extraData});
    _userId = response["id"];

    _token.appendInfo(
      role: response["role"],
      coturnIp: response["coturnIp"],
      turnCredential: response["turnCredential"],
      turnUsername: response["turnUsername"],
    );
    Map<String, dynamic> metadata = {};
    try {
      metadata = json.decode(response["metadata"]);
    } catch (e) {
      logger.e(e);
    }
    _localParticipant = await _createParticipant(response["id"], metadata);
    _addAlreadyInRoomConnections(response);
    _dispatchEvent(OpenViduEvent.joinRoom, response);

    return _localParticipant;
    // } catch (e) {
    //   logger.e(e);
    //   throw OtherError();
    // }
  }

  /// It sends a message to the server.
  ///
  /// Args:
  ///   message (OvMessage): The message to be sent.
  ///
  /// Returns:
  ///   A Future<bool>
  Future<bool> sendMessage(OvMessage message) async {
    if (_localParticipant == null || _localParticipant?.stream == null) {
      return false;
    }
    try {
      await _rpc?.send(
        "sendMessage",
        params: {"message": message.toRawJson()},
        hasResult: true,
      );
      return true;
    } catch (e) {
      logger.i('SEND MESSAGE', e.toString());
      return false;
    }
  }

  /// "Subscribe to the remote participant's stream."
  ///
  /// The first parameter is the id of the remote participant. The second parameter is a boolean value that indicates
  /// whether the video should be subscribed to. The third parameter is a boolean value that indicates whether the audio
  /// should be subscribed to. The fourth parameter is a boolean value that indicates whether the speakerphone should be
  /// enabled
  ///
  /// Args:
  ///   id (String): The id of the participant you want to subscribe to.
  ///   video (bool): Whether to subscribe to the video stream. Defaults to true
  ///   audio (bool): Whether to subscribe to the audio stream. Defaults to true
  ///   speakerphone (bool): If true, the audio will be played through the speakerphone. Defaults to false
  ///
  /// Returns:
  ///   A Future<void>
  Future<void> subscribeRemoteStream(String id,
      {bool video = true, bool audio = true, bool speakerphone = false}) async {
    if (!_participants.containsKey(id)) return;

    _participants[id]!.subscribeStream(
      _localParticipant?.stream,
      _dispatchEvent,
      video,
      audio,
      speakerphone,
    );
  }

  Future<void> _addRemoteConnection(Map<String, dynamic> model) async {
    final id = model["id"];
    if (id == _userId) return;
    Map<String, dynamic> metadata = {};
    try {
      metadata = json.decode(model["metadata"]);
    } catch (e) {
      logger.e(e);
    }
    _participants[id] ??= await _createRemoteParticipant(id, metadata);
    // _dispatchEvent(OpenViduEvent.userJoined, model);
    logger.d(model["streams"]);
    if (model["streams"] != null) {
      final stream = model.containsKey('streams') ? model["streams"][0] : null;

      final videoParams = jsonDecode(stream['videoDimensions'] ?? '{}');
      final frameRate = stream['frameRate'] ?? 30;

      _participants[id]?.videoParams = VideoParams(
          frameRate, videoParams['width'] ?? 400, videoParams['height'] ?? 400);
      _dispatchEvent(OpenViduEvent.userPublished, {
        "id": id,
        "audioActive": stream['audioActive'] ?? false,
        "videoActive": stream['videoActive'] ?? false,
      });
    }
  }

  void _addAlreadyInRoomConnections(Map<String, dynamic> model) {
    if (!model.containsKey("value")) return;
    final list = model["value"] as List<dynamic>;
    for (var c in list) {
      _addRemoteConnection(c);
      subscribeRemoteStream(c['id']);
    }
  }

  Future<Map<String, dynamic>> _joinRoom(Map<String, dynamic> metadata) async {
    if (_rpc == null) {
      _rpc = JsonRpc(
        onData: _onRpcMessage,
        onError: _onSocketError,
        onDispose: () {},
      );
      try {
        await _rpc?.connect(_token.wss);
        _heartbeat();
      } catch (e) {
        logger.e(e);
        _rpc?.disconnect();
        throw NetworkError();
      }
    }

    final initializeParams = {
      "token": _token.token,
      "session": _token.sessionId,
      "platform": DeviceInfo.userAgent,
      "secret": "",
      "recorder": false,
      "metadata": json.encode(metadata)
    };

    try {
      return await _rpc?.send(
        Methods.joinRoom,
        params: initializeParams,
        hasResult: true,
      );
    } catch (e) {
      if (e is Map && e['code'] == 401) throw TokenError();
      throw OtherError();
    }
  }

  Future<RemoteParticipant> _createRemoteParticipant(
      String id, Map<String, dynamic> metadata) async {
    return RemoteParticipant(
      id,
      _token,
      _rpc!,
      metadata,
    );
  }

  Future<LocalParticipant> _createParticipant(
      String id, Map<String, dynamic> metadata) async {
    final locaStream = _localParticipant?.stream;
    return LocalParticipant(
      id,
      _token,
      _rpc!,
      metadata,
      _dispatchEvent,
      stream: locaStream,
      mode: _mode,
      videoParams: _videoParams,
    );
  }

  Future<MediaStream> createMediaStream(StreamMode mode,
      {bool disableTracks = false}) async {
    late MediaStream stream;

    stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'facingMode': mode == StreamMode.backCamera ? 'environment' : 'user',
        'width': '1920',
        'height': '1080'
      }
    });

    if (disableTracks) {
      stream.getVideoTracks().forEach((element) {
        element.enabled = false;
      });
      stream.getAudioTracks().forEach((element) {
        element.enabled = false;
      });
    }

    return stream;
  }

  /* ----------------------------- SOCKET MANAGER ----------------------------- */

  /// > It takes an event and a handler function as parameters and adds them to the _handlers map
  ///
  /// Args:
  ///   event (OpenViduEvent): The event to listen for.
  ///   handler (Function(Map<String, dynamic> params)): The function that will be called when the event is triggered.
  void on(OpenViduEvent event, Function(Map<String, dynamic> params) handler) {
    _handlers = {..._handlers, event: handler};
  }

  Future<void> _onRpcMessage(Map<String, dynamic> message) async {
    if (!_active) return;
    if (!message.containsKey("method")) return;

    final method = message["method"];
    final params = message["params"];

    switch (method) {
      case Events.iceCandidate:
        var id = params["senderConnectionId"];
        [
          ..._participants.entries.map((e) => e.value),
          _localParticipant,
        ].firstWhere((c) => (c?.id ?? '') == id)?.addIceCandidate(params);
        break;
      case Events.sendMessage:
        logger.i(message);
        _dispatchEvent(OpenViduEvent.reciveMessage, params);
        break;
      case Events.participantJoined:
        logger.i(message);
        await _addRemoteConnection(params);
        _dispatchEvent(OpenViduEvent.userJoined, params);
        break;
      case Events.participantLeft:
        logger.i(message);
        final id = params["connectionId"];

        if (_participants.containsKey(id)) {
          try {
            var connection = _participants[id];
            connection?.close();
            _participants.remove(id);
          } catch (e) {
            logger.w(e);
          }
          _dispatchEvent(OpenViduEvent.userLeft, params);
          _dispatchEvent(OpenViduEvent.removeStream, {"id": id});
        }
        break;
      case Events.participantPublished:
        logger.i(message);
        final param = params as Map<String, dynamic>;
        final id = params["id"];

        final stream =
            param.containsKey('streams') ? param["streams"][0] : null;
        _dispatchEvent(OpenViduEvent.userPublished, {
          "id": id,
          "audioActive": stream['audioActive'] ?? false,
          "videoActive": stream['videoActive'] ?? false,
          "videoDimensions": stream['videoDimensions']
        });
        await _addRemoteConnection(params);
        break;
      case Events.participantUnpublished:
        logger.i(message);
        final id = params["id"];
        _dispatchEvent(OpenViduEvent.userUnpublished, {"id": id});
        break;
      case Events.streamPropertyChanged:
        logger.i(message);
        final eventStr = params["reason"];
        final id = params["connectionId"];
        final property = params["property"] as String;
        final value = params["newValue"];
        if (_participants.containsKey(id)) {
          final remoteParticipant = _participants[id];
          if (property == 'videoActive') {
            logger.i(remoteParticipant!.videoActive);
            remoteParticipant.videoActive = value == 'true';
            logger.i(remoteParticipant.videoActive);
          }
          if (property == 'audioActive') {
            remoteParticipant!.videoActive = value == 'true';
          }
        }
        final event = OpenViduEvent.values.firstWhere((e) {
          return e.toString().split(".")[1] == eventStr;
        });
        _dispatchEvent(event, {"id": id, "value": value});
        break;
      default:
    }
  }

  void _onSocketError(dynamic error) {
    logger.e('received websocket error $error');
  }

  Future<void> _heartbeat() async {
    try {
      await _rpc?.send(Methods.ping,
          params: {"interval": 5000}, hasResult: true);
    } catch (e) {
      _dispatchEvent(OpenViduEvent.error, {"error": NetworkError()});
    }

    Future<void> loop() async {
      while (_active) {
        await Future.delayed(const Duration(seconds: 3));
        if (!_active) break;

        try {
          await _rpc?.send(Methods.ping, hasResult: true);
        } catch (e) {
          _dispatchEvent(OpenViduEvent.error, {"error": NetworkError()});
        }
      }
    }

    loop();
  }

  void _dispatchEvent(OpenViduEvent event, Map<String, dynamic> params) {
    if (event == OpenViduEvent.error) _active = false;
    if (!_handlers.containsKey(event)) return;
    final handler = _handlers[event];
    if (handler != null) handler(params);
  }

  Future<void> disconnect() async {
    await _rpc?.send(Methods.leaveRoom);

    // for (var track in StreamCreator.stream?.getTracks() ?? []) {
    //   await track?.stop();
    // }
    _active = false;
    // clean up RemoteParticipants
    var participants = _participants.values.toList();
    for (var participant in participants) {
      await participant.close();
    }
    _participants.clear();
    // clean up LocalParticipant
    await _localParticipant?.close();

    debugPrint('Cierra local');
    // if (_localParticipant == null) StreamCreator.stream?.dispose();
    await _rpc?.disconnect();
  }
}
