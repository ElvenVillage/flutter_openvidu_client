import 'dart:io';

import '../../openvidu_client.dart';
import '../support/json_rpc.dart';
import '../utils/constants.dart';
import 'token.dart';

class SdpSemantics {
  static const planB = 'plan-b';
  static const unifiedPlan = 'unified-plan';
}

abstract class Participant {
  late String id;
  late Token token;
  late JsonRpc rpc;
  MediaStream? stream;
  String? streamId;
  late Future<RTCPeerConnection> peerConnection;
  Map<String, dynamic>? metadata;
  bool audioActive = false;
  bool videoActive = false;
  VideoParams? videoParams;

  final Map<String, dynamic> constraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
    'offerToReceiveAudio': true,
    'offerToReceiveVideo': true,
  };

  String get sdpSemantics =>
      Platform.isAndroid ? SdpSemantics.unifiedPlan : SdpSemantics.planB;

  final Map<String, dynamic> _config = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ]
  };

  final List<RTCIceCandidate> _candidateTemps = [];

  Participant(this.id, this.token, this.rpc, this.metadata) {
    peerConnection = _getPeerConnection();
  }

  Participant.preview() {
    peerConnection = _getPrePeerConnection();
  }

  Future<RTCPeerConnection> _getPrePeerConnection() async {
    final connection =
        await createPeerConnection(_getPrevConfiguration(), _config);
    connection.onIceCandidate = (candidate) {
      Map<String, dynamic> iceCandidateParams = {
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
        'candidate': candidate.candidate,
      };
      rpc.send(Methods.onIceCandidate, params: iceCandidateParams);
    };

    connection.onSignalingState = (state) {
      if (state == RTCSignalingState.RTCSignalingStateStable) {
        for (var i in _candidateTemps) {
          connection.addCandidate(i);
        }
        _candidateTemps.clear();
      }
    };

    return connection;
  }

  Future<RTCPeerConnection> _getPeerConnection() async {
    final connection = await createPeerConnection(_getConfiguration(), _config);

    connection.onIceCandidate = (candidate) async {
      Map<String, dynamic> iceCandidateParams = {
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
        'candidate': candidate.candidate,
        "endpointName": streamId ?? id
      };
      Future.delayed(
          const Duration(seconds: 1),
          () async => await rpc.send(Methods.onIceCandidate,
              params: iceCandidateParams));
    };

    connection.onSignalingState = (state) {
      if (state == RTCSignalingState.RTCSignalingStateStable) {
        for (var i in _candidateTemps) {
          connection.addCandidate(i);
        }
        _candidateTemps.clear();
      }
    };

    return connection;
  }

  Map<String, dynamic> _getPrevConfiguration() {
    return {
      "iceServers": [
        {
          "urls": [
            "turn:173.194.72.127:19305?transport=udp",
            "turn:[2404:6800:4008:C01::7F]:19305?transport=udp",
            "turn:173.194.72.127:443?transport=tcp",
            "turn:[2404:6800:4008:C01::7F]:443?transport=tcp"
          ],
          "username": "CKjCuLwFEgahxNRjuTAYzc/s6OMT",
          "credential": "u1SQDR/SQsPQIxXNWQT7czc/G4c="
        },
        {
          "urls": ["stun:stun.l.google.com:19302"]
        }
      ]
    };
  }

  Map<String, dynamic> _getConfiguration() {
    final stun = "stun:${token.coturnIp}:3478";
    final turn1 = "turn:${token.coturnIp}:3478";
    final turn2 = "$turn1?transport=tcp";

    return {
      "sdpSemantics": sdpSemantics,
      'iceServers': [
        {
          "urls": [stun]
        },
        {
          "urls": [turn1, turn2],
          "username": token.turnUsername,
          "credential": token.turnCredential
        },
      ]
    };
  }

  Future<void> close() async {
    stream?.getTracks().forEach((track) async {
      await track.stop();
    });
    final connection = await peerConnection;
    connection.close();
    // connection.dispose();
    // stream?.dispose();
  }

  Future<void> addIceCandidate(Map<String, dynamic> candidate) async {
    var connection = await peerConnection;
    final rtcIceCandidate = RTCIceCandidate(
      candidate["candidate"],
      candidate["sdpMid"],
      candidate["sdpMLineIndex"],
    );
    if (connection.signalingState ==
        RTCSignalingState.RTCSignalingStateStable) {
      await connection.addCandidate(rtcIceCandidate);
    } else {
      _candidateTemps.add(rtcIceCandidate);
    }
  }
}
