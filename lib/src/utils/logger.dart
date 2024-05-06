import 'package:logger/logger.dart';

final logger = Logger();

extension ObjectExt on Object {
  String get objectId => '$runtimeType#$hashCode';
}
