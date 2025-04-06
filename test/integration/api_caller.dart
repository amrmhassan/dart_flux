import 'package:dio/dio.dart';

Dio dioPort(int port) => Dio(
  BaseOptions(
    baseUrl: 'http://localhost:$port',
    validateStatus: (status) => true,
    sendTimeout: Duration(days: 10),
    connectTimeout: Duration(days: 10),
    receiveTimeout: Duration(days: 10),
  ),
);
