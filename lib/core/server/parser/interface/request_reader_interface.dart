import 'dart:async';
import 'dart:io';

abstract class RequestReaderInterface {
  late HttpRequest request;

  Future<dynamic> readJson();

  Future<String> readString();

  Future<List<int>> readBytes();
}
