import 'dart:io';

import 'package:dart_flux/core/app/models/fast_flux_app.dart';
import 'package:dart_flux/core/server/routing/repo/router.dart';

void main(List<String> args) async {
  Directory dir = Directory('./lib');
  var children = dir.listSync();
  children.forEach((c) {
    bool isDir = c is File;
    print(isDir);
  });
}
