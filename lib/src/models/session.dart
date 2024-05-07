import 'dart:convert';

import 'custom_ice_server.dart';
import 'kurento_options.dart';
import 'publisher.dart';
import 'subscriber.dart';

class Session {
  Session({
    this.id,
    this.object,
    this.type,
    this.status,
    this.sessionId,
    this.createdAt,
    this.activeAt,
    this.location,
    this.ip,
    this.platform,
    this.token,
    this.serverData,
    this.clientData,
    this.record,
    this.role,
    this.kurentoOptions,
    this.rtspUri,
    this.adaptativeBitrate,
    this.onlyPlayWithSubscribers,
    this.networkCache,
    this.publishers,
    this.subscribers,
    this.customIceServers,
  });

  final String? id;
  final String? object;
  final String? type;
  final String? status;
  final String? sessionId;
  final int? createdAt;
  final int? activeAt;
  final String? location;
  final String? ip;
  final String? platform;
  final String? token;
  final String? serverData;
  final String? clientData;
  final bool? record;
  final String? role;
  final KurentoOptions? kurentoOptions;
  final dynamic rtspUri;
  final dynamic adaptativeBitrate;
  final dynamic onlyPlayWithSubscribers;
  final dynamic networkCache;
  final List<Publisher>? publishers;
  final List<Subscriber>? subscribers;
  final List<CustomIceServer>? customIceServers;

  Session copyWith({
    String? id,
    String? object,
    String? type,
    String? status,
    String? sessionId,
    int? createdAt,
    int? activeAt,
    String? location,
    String? ip,
    String? platform,
    String? token,
    String? serverData,
    String? clientData,
    bool? record,
    String? role,
    KurentoOptions? kurentoOptions,
    dynamic rtspUri,
    dynamic adaptativeBitrate,
    dynamic onlyPlayWithSubscribers,
    dynamic networkCache,
    List<Publisher>? publishers,
    List<Subscriber>? subscribers,
    List<CustomIceServer>? customIceServers,
  }) =>
      Session(
        id: id ?? this.id,
        object: object ?? this.object,
        type: type ?? this.type,
        status: status ?? this.status,
        sessionId: sessionId ?? this.sessionId,
        createdAt: createdAt ?? this.createdAt,
        activeAt: activeAt ?? this.activeAt,
        location: location ?? this.location,
        ip: ip ?? this.ip,
        platform: platform ?? this.platform,
        token: token ?? this.token,
        serverData: serverData ?? this.serverData,
        clientData: clientData ?? this.clientData,
        record: record ?? this.record,
        role: role ?? this.role,
        kurentoOptions: kurentoOptions ?? this.kurentoOptions,
        rtspUri: rtspUri ?? this.rtspUri,
        adaptativeBitrate: adaptativeBitrate ?? this.adaptativeBitrate,
        onlyPlayWithSubscribers:
            onlyPlayWithSubscribers ?? this.onlyPlayWithSubscribers,
        networkCache: networkCache ?? this.networkCache,
        publishers: publishers ?? this.publishers,
        subscribers: subscribers ?? this.subscribers,
        customIceServers: customIceServers ?? this.customIceServers,
      );

  factory Session.fromRawJson(String str) => Session.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: json["id"],
        object: json["object"],
        type: json["type"],
        status: json["status"],
        sessionId: json["sessionId"],
        createdAt: json["createdAt"],
        activeAt: json["activeAt"],
        location: json["location"],
        ip: json["ip"],
        platform: json["platform"],
        token: json["token"],
        serverData: json["serverData"],
        clientData: json["clientName"],
        record: json["record"],
        role: json["role"],
        kurentoOptions: json["kurentoOptions"] == null
            ? null
            : KurentoOptions.fromJson(json["kurentoOptions"]),
        rtspUri: json["rtspUri"],
        adaptativeBitrate: json["adaptativeBitrate"],
        onlyPlayWithSubscribers: json["onlyPlayWithSubscribers"],
        networkCache: json["networkCache"],
        publishers: json["publishers"] == null
            ? []
            : List<Publisher>.from(
                json["publishers"]!.map((x) => Publisher.fromJson(x))),
        subscribers: json["subscribers"] == null
            ? []
            : List<Subscriber>.from(
                json["subscribers"]!.map((x) => Subscriber.fromJson(x))),
        customIceServers: json["customIceServers"] == null
            ? []
            : List<CustomIceServer>.from(json["customIceServers"]!
                .map((x) => CustomIceServer.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "object": object,
        "type": type,
        "status": status,
        "sessionId": sessionId,
        "createdAt": createdAt,
        "activeAt": activeAt,
        "location": location,
        "ip": ip,
        "platform": platform,
        "token": token,
        "serverData": serverData,
        "clientName": clientData,
        "record": record,
        "role": role,
        "kurentoOptions": kurentoOptions?.toJson(),
        "rtspUri": rtspUri,
        "adaptativeBitrate": adaptativeBitrate,
        "onlyPlayWithSubscribers": onlyPlayWithSubscribers,
        "networkCache": networkCache,
        "publishers": publishers == null
            ? []
            : List<dynamic>.from(publishers!.map((x) => x.toJson())),
        "subscribers": subscribers == null
            ? []
            : List<dynamic>.from(subscribers!.map((x) => x.toJson())),
        "customIceServers": customIceServers == null
            ? []
            : List<dynamic>.from(customIceServers!.map((x) => x.toJson())),
      };
}
