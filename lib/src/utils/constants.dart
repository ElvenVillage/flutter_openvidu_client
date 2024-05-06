class Methods {
  static const String ping = 'ping';
  static const String joinRoom = 'joinRoom';
  static const String publishVideo = 'publishVideo';
  static const String videoData = 'videoData';
  static const String prepareReceiveVideoFrom = 'prepareReceiveVideoFrom';
  static const String receiveVideoFrom = 'receiveVideoFrom';
  static const String onIceCandidate = 'onIceCandidate';
  static const String unpublishVideo = 'unpublishVideo';
  static const String unsubscribeFromVideo = 'unsubscribeFromVideo';
  static const String leaveRoom = 'leaveRoom';
  static const String sendMessage = 'sendMessage';
  static const String forceUnpublish = 'forceUnpublish';
  static const String forceDisconnect = 'forceDisconnect';
  static const String applyFilter = 'applyFilter';
  static const String removeFilter = 'removeFilter';
  static const String execFilterMethod = 'execFilterMethod';
  static const String addFilterEventListener = 'addFilterEventListener';
  static const String removeFilterEventListener = 'removeFilterEventListener';
  static const String connect = 'connect';
  static const String reconnectStream = 'reconnectStream';
  static const String subscribeToSpeechToText = 'subscribeToSpeechToText';
  static const String unsubscribeFromSpeechToText =
      'unsubscribeFromSpeechToText';
}

class Events {
  static const iceCandidate = 'iceCandidate';
  static const sendMessage = 'sendMessage';
  static const participantJoined = 'participantJoined';
  static const participantLeft = 'participantLeft';
  static const participantEvicted = 'participantEvicted';
  static const participantPublished = 'participantPublished';
  static const participantUnpublished = 'participantUnpublished';
  static const streamPropertyChanged = 'streamPropertyChanged';
  static const connectionPropertyChanged = 'connectionPropertyChanged';
  static const recordingStarted = 'recordingStarted';
  static const recordingStopped = 'recordingStopped';
  static const filterEventDispatched = 'filterEventDispatched';
  static const networkQualityLevelChanged = 'networkQualityLevelChanged';
  static const speechToTextMessage = 'speechToTextMessage';
  static const speechToTextDisconnected = 'speechToTextDisconnected';
  static const forciblyReconnectSubscriber = 'forciblyReconnectSubscriber';
}
