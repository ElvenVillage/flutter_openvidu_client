# openvidu_client

OpenVidu Flutter client.

## Getting Started

First, add the `openvidu_client` package to your [pubspec dependencies](https://pub.dev/packages/google_fonts/install).

To import `OpenViduClient`:

```dart
import 'package:openvidu_client/openvidu_client.dart';
```

### OpenViduClient

To use `OpenViduClient` create a instance with the URL of the OpenVidu Server:

```dart
client = OpenViduClient('https://demos.openvidu.io/openvidu');
```

### startLocalPreview

Start the local preview, and return the local participant

```dart
localParticipant =  await _openvidu.startLocalPreview(context, StreamMode.frontCamera);
```

### on

Config listener to the events that are emitted by the OpenVidu library; remember subscribe remotes inside **OpenViduEvent.userJoined** and **OpenViduEvent.userPublished**.

```dart
void listenSessionEvents() {
    client.on(OpenViduEvent.userJoined, (params) async {
      await client.subscribeRemoteStream(params["id"]);
    });
    client.on(OpenViduEvent.userPublished, (params) {
      await client.subscribeRemoteStream(params["id"],
          video: params["videoActive"], audio: params["audioActive"]);
    });

    client.on(OpenViduEvent.addStream, (params) {
      remoteParticipants = {...client.participants};
       //Catch changes on remote participant
    });

    client.on(OpenViduEvent.removeStream, (params) {
      remoteParticipants = {...client.participants};
       //Catch changes on remote participant
    });

    client.on(OpenViduEvent.publishVideo, (params) {
      remoteParticipants = {...client.participants};
       //Catch changes on remote participant
    });
    client.on(OpenViduEvent.publishAudio, (params) {
      //Catch changes on remote participant
    });
    client.on(OpenViduEvent.updatedLocal, (params) {
      localParticipant = params['localParticipant'];
      //Update the local participant
    });
    client.on(OpenViduEvent.reciveMessage, (params) {
      //Capture message received
    });
    client.on(OpenViduEvent.userUnpublished, (params) {
      remoteParticipants = {...client.participants};
       //Catch changes on remote participant
    });

    client.on(OpenViduEvent.error, (params) {
      //Capture error messages
    });
  }
```

### publishLocalStream

It joins to the room, and returns the local participant

- token (String): The token you get from the server.
- userName (String): The name of the user who is publishing the stream.
- extraData (Map<String, dynamic>): Extra data to be sent to the server.

---

### LocalParticipant

#### shareScreen

It changes the stream mode from camera to screen and vice versa.

### setAudioInput

Replace the track with the new track by deviceId

### setVideoInput

Switches the camera to the deviceId passed in

### switchCamera

Can switch between cameras

### unpublishAllTracks

It disables all the tracks of the local stream

### publishVideo

It enables or disables the video track of the local stream

### publishAudio

Enable or disable the audio track of the stream, depending on the value of the parameter
