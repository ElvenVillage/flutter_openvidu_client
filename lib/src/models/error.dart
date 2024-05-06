// ignore_for_file: constant_identifier_names

class OpenViduError extends Error {
  OpenViduErrorCode code;
  String message;
  OpenViduError(this.code, this.message);
}

enum OpenViduErrorCode {
  NotPermission,
  Network,
  Token,
  Other,
}

class NotPermissionError extends OpenViduError {
  NotPermissionError()
      : super(
          OpenViduErrorCode.NotPermission,
          "No permissions, please manually give camera and microphone permissions",
        );
}

class TokenError extends OpenViduError {
  TokenError()
      : super(
          OpenViduErrorCode.Token,
          "Token is invalid or expired",
        );
}

class NetworkError extends OpenViduError {
  NetworkError()
      : super(
          OpenViduErrorCode.Network,
          "Communication with server failed",
        );
}

class OtherError extends OpenViduError {
  OtherError()
      : super(
          OpenViduErrorCode.Other,
          "Unknown failure, please reconnect",
        );
}
