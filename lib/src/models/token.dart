class Token {
  final String url;

  late String _host;
  late String _wss;
  late String _sessionId;
  late String _token;
  late String _role;
  late String _version;
  late String _coturnIp;
  late String _turnUsername;
  late String _turnCredential;

  String get host => _host;
  String get wss => _wss;
  String get sessionId => _sessionId;
  String get token => _token;
  String get role => _role;
  String get version => _version;
  String get coturnIp => _coturnIp;
  String get turnUsername => _turnUsername;
  String get turnCredential => _turnCredential;

  Token(this.url) {
    _host = url;
    Uri uri = Uri.parse(url);
    uri = uri.replace(scheme: 'wss', path: 'openvidu');
    _wss = uri.toString();
  }

  void setToken(String token) {
    final uri = Uri.parse(token);
    _sessionId = uri.queryParameters["sessionId"] ?? '';
    _token = token;
    _role = uri.queryParameters["role"] ?? '';
    _version = uri.queryParameters["version"] ?? '';
    _coturnIp = uri.queryParameters["coturnIp"] ?? '';
    _turnUsername = uri.queryParameters["turnUsername"] ?? '';
    _turnCredential = uri.queryParameters["turnCredential"] ?? '';
  }

  void appendInfo({
    String? role,
    String? coturnIp,
    String? turnUsername,
    String? turnCredential,
  }) {
    if (role != null) _role = role;
    if (coturnIp != null) _coturnIp = coturnIp;
    if (turnUsername != null) _turnUsername = turnUsername;
    if (turnCredential != null) _turnCredential = turnCredential;
  }
}
