typedef EventDispatcher = Function(
    OpenViduEvent event, Map<String, dynamic> params);
typedef EventHandler
    = Map<OpenViduEvent, Function(Map<String, dynamic> params)>;

enum OpenViduEvent {
  joinRoom,
  userJoined,
  userLeft,
  userPublished,
  userUnpublished,
  error,
  addStream,
  updatedLocal,
  removeStream,
  publishVideo,
  publishAudio,
  audioTrack,
  videoTrack,
  videoDimensions,
  reciveMessage,
  trackReplaced,
}
