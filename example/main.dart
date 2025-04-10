import 'dart:io';

import 'package:dart_flux/core/server/execution/repo/server.dart';
import 'package:dart_flux/core/server/parser/models/folder_server.dart';
import 'package:dart_flux/core/server/routing/repo/router.dart';
import 'package:dart_flux/core/server/utils/send_response.dart';

void main(List<String> args) async {
  Router router = Router().get('/*', (request, response, pathArgs) async {
    return SendResponse.serveFolder(
      response: response,
      server: FolderServer(path: './storage'),
      requestedPath: pathArgs['*'],
      blockIfFolder: false,
      serveFolderContent: true,
    );
  });
  Server server = Server(InternetAddress.anyIPv4, 3000, router);
  await server.run();
}

//  dart run build_runner build --delete-conflicting-outputs
//  dart run build_runner watch --delete-conflicting-outputs
