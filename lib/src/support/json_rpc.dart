import 'dart:async';
import 'dart:convert';

// import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/error_code.dart' as error_code;
import '../utils/logger.dart';

// class WebSocketException implements Exception {
//   final int code;
//   const WebSocketException._(this.code);

//   static WebSocketException unknown() => const WebSocketException._(0);
//   static WebSocketException connect() => const WebSocketException._(1);

//   @override
//   String toString() => {
//         WebSocketException.unknown(): 'Unknown error',
//         WebSocketException.connect(): 'Failed to connect',
//       }[this]!;
// }

typedef WebSocketOnData = Function(Map<String, dynamic> data);
typedef WebSocketOnError = Function(dynamic error);
typedef WebSocketOnDispose = Function();

class WebSocketEventHandlers {
  final WebSocketOnData? onData;
  final WebSocketOnError? onError;
  final WebSocketOnDispose? onDispose;

  const WebSocketEventHandlers({
    this.onData,
    this.onError,
    this.onDispose,
  });
}

class JsonRpc {
  int _internalId = 0;
  bool isActive = false;
  final Map<int, _Request> _pendingRequests = {};

  late WebSocketOnData _onData;
  late WebSocketOnError _onError;
  late WebSocketOnDispose _onDispose;
  late WebSocketChannel _channel;
  JsonRpc({
    required WebSocketOnData onData,
    required WebSocketOnError onError,
    required WebSocketOnDispose onDispose,
  }) {
    _onData = onData;
    _onError = onError;
    _onDispose = onDispose;
  }

  connect(String url) async {
    logger.d(url);
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      isActive = true;
      _channel.stream.listen(
        (event) {
          event = event.toString().replaceAll('}%/%{', ',');
          final response = json.decode(event) as Map<String, dynamic>;
          _onData(response);
          _handleResponse(response);
        },
        onError: _onError,
        onDone: _onDispose,
      );
    } catch (e) {
      debugPrint(e.toString());
      logger.w(e);
    }
  }

  Future<dynamic> disconnect() async {
    try {
      logger.i('[JsonRpc] disposed');
      isActive = false;
      return await _channel.sink.close();
    } catch (e) {
      return Future.value(null);
    }
  }

  Future<dynamic>? send(
    String method, {
    Map<String, dynamic> params = const {},
    bool hasResult = false,
  }) async {
    if (!isActive) return;
    try {
      final id = _internalId++;
      Map<String, dynamic> dict = <String, dynamic>{};
      dict["method"] = method;
      dict["id"] = id;
      dict['jsonrpc'] = '2.0';
      dict["params"] = params;
      String jsonString = json.encode(dict);
      _channel.sink.add(jsonString);
      if (!hasResult) return null;
      var completer = Completer.sync();
      _pendingRequests[id] = _Request(method, completer);
      return completer.future;
    } on RpcException catch (e) {
      _onError.call(e);
    }
  }

  /// Handles a decoded response from the server.
  void _handleResponse(response) {
    if (response is List) {
      response.forEach(_handleSingleResponse);
    } else {
      _handleSingleResponse(response);
    }
  }

  /// Handles a decoded response from the server after batches have been
  /// resolved.
  void _handleSingleResponse(response) {
    if (!_isResponseValid(response)) return;
    var id = response['id'];
    id = (id is String) ? int.parse(id) : id;
    var request = _pendingRequests.remove(id)!;
    if (response.containsKey('result')) {
      request.completer.complete(response['result']);
    } else if (response.containsKey('error')) {
      _onError(response['error']['message']);
      request.completer.completeError('Unknown failure, please reconnect');
    }
  }

  /// Determines whether the server's response is valid per the spec.
  bool _isResponseValid(response) {
    if (response is! Map) return false;
    if (response['jsonrpc'] != '2.0') return false;
    if (!response.containsKey("id")) return false;
    var id = response['id'];
    id = (id is String) ? int.parse(id) : id;
    if (!_pendingRequests.containsKey(id)) return false;
    if (response.containsKey('result')) {
      return true;
    }
    if (!response.containsKey('error')) return false;
    var error = response['error'];
    if (error is! Map) return false;
    if (error['code'] is! int) return false;
    if (error['message'] is! String) return false;
    return true;
  }
}

class _Request {
  /// THe method that was sent.
  final String method;

  /// The completer to use to complete the response future.
  final Completer completer;

  _Request(this.method, this.completer);
}

class RpcException implements Exception {
  final int code;
  final String message;
  final Object? data;

  RpcException(this.code, this.message, {this.data});
  RpcException.methodNotFound(String methodName)
      : this(error_code.METHOD_NOT_FOUND, 'Unknown method "$methodName".');

  RpcException.invalidParams(String message)
      : this(error_code.INVALID_PARAMS, message);

  Map<String, dynamic> serialize(request) {
    dynamic modifiedData;
    if (data is Map && !(data as Map).containsKey('request')) {
      modifiedData = Map.from(data as Map);
      modifiedData['request'] = request;
    } else if (data == null) {
      modifiedData = {'request': request};
    } else {
      modifiedData = data;
    }

    var id = request is Map ? request['id'] : null;
    if (id is! String && id is! num) id = null;
    return {
      'jsonrpc': '2.0',
      'error': {'code': code, 'message': message, 'data': modifiedData},
      'id': id
    };
  }

  @override
  String toString() {
    var prefix = 'JSON-RPC error $code';
    var errorName = error_code.name(code);
    if (errorName != null) prefix += ' ($errorName)';
    return '$prefix: $message';
  }
}
