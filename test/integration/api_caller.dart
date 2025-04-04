import 'package:dio/dio.dart';

Dio dioPort(int port) => Dio(BaseOptions(baseUrl: 'http://localhost:$port'));
