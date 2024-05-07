import 'dart:convert';

class CustomIceServer {
  CustomIceServer({
    this.url,
    this.username,
    this.credential,
  });

  final String? url;
  final String? username;
  final String? credential;

  CustomIceServer copyWith({
    String? url,
    String? username,
    String? credential,
  }) =>
      CustomIceServer(
        url: url ?? this.url,
        username: username ?? this.username,
        credential: credential ?? this.credential,
      );

  factory CustomIceServer.fromRawJson(String str) =>
      CustomIceServer.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory CustomIceServer.fromJson(Map<String, dynamic> json) =>
      CustomIceServer(
        url: json["url"],
        username: json["username"],
        credential: json["credential"],
      );

  Map<String, dynamic> toJson() => {
        "url": url,
        "username": username,
        "credential": credential,
      };
}
