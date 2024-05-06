import 'dart:developer';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import 'local_participant.dart';
import 'openvidu_events.dart';
import 'participant.dart';

class RemoteParticipant extends Participant {
  RemoteParticipant(super.id, super.token, super.rpc, super.metadata);

  Future<void> subscribeStream(
    MediaStream? localStream,
    EventDispatcher dispatchEvent,
    bool video,
    bool audio,
    bool speakerphone,
  ) async {
    final connection = await peerConnection;

    connection.onRenegotiationNeeded = () => _createOffer(connection);

    if (sdpSemantics == SdpSemantics.planB) {
      connection.onAddStream = (stream) {
        this.stream = stream;
        audioActive = audio;
        videoActive = video;
        dispatchEvent(OpenViduEvent.addStream,
            {"id": id, "stream": stream, "metadata": metadata});
      };

      connection.onRemoveStream = (stream) {
        this.stream = stream;
        dispatchEvent(OpenViduEvent.removeStream,
            {"id": id, "stream": stream, "metadata": metadata});
      };

      if (localStream != null) {
        connection.addStream(localStream);
      }
    }

    if (sdpSemantics == SdpSemantics.unifiedPlan) {
      connection.onAddTrack = (stream, track) {
        this.stream = stream;
        audioActive = audio;
        videoActive = video;
        dispatchEvent(OpenViduEvent.addStream,
            {"id": id, "stream": stream, "metadata": metadata});
      };

      connection.onRemoveTrack = (stream, track) {
        this.stream = stream;
        dispatchEvent(OpenViduEvent.removeStream,
            {"id": id, "stream": stream, "metadata": metadata});
      };

      if (localStream != null) {
        final localTracks = localStream.getTracks();
        for (var track in localTracks) {
          connection.addTrack(track, localStream);
        }
      } else {
        // setting transceiver before creating offer!

        log("setting receive-only transceiver");
        final audioT = await connection.addTransceiver(
            kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
            init: RTCRtpTransceiverInit(
                direction: TransceiverDirection.RecvOnly));
        final videoT = await connection.addTransceiver(
            kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
            init: RTCRtpTransceiverInit(
                direction: TransceiverDirection.RecvOnly));

        log("video mid ${videoT.mid}");
        log("audio mid ${audioT.mid}");
      }
    }
  }

  _createOffer(RTCPeerConnection connection) async {
    final offer = await connection.createOffer({
      'mandatory': {
        'OfferToReceiveAudio': !(runtimeType == LocalParticipant),
        'OfferToReceiveVideo': !(runtimeType == LocalParticipant),
      },
      "optional": [
        {"DtlsSrtpKeyAgreement": true},
      ],
    });

    await connection.setLocalDescription(offer);

    var result = await rpc.send(
      Methods.receiveVideoFrom,
      params: {'sender': id, 'sdpOffer': offer.sdp},
      hasResult: true,
    );
    logger.d(result);

    final answer = RTCSessionDescription(result['sdpAnswer'], 'answer');

    await connection.setRemoteDescription(answer);
  }

  @override
  Future<void> close() {
    stream?.getTracks().forEach((track) async {
      await track.stop();
      log(track.toString());
    });
    stream?.dispose();
    return super.close();
  }
}
