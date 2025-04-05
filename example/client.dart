import 'dart:async';

import 'package:dio/dio.dart';

void main(List<String> args) async {
  Dio dio = Dio();
  int count = 0;
  bool closed = false;
  int seconds = 10;
  Future.delayed(Duration(seconds: seconds)).then((v) {
    closed = true;
  });
  while (true) {
    if (closed) {
      print('count: $count in $seconds seconds');
      break;
    }
    await dio.get('http://localhost:3000/');
    count++;
  }
}
