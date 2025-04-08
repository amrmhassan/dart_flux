import 'dart:io';

import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_flux/core/server/parser/interface/serve_folder_interface.dart';
import 'package:dart_flux/core/server/parser/models/file_entity.dart';
import 'package:dart_flux/core/server/parser/models/folder_entity.dart';
import 'package:dart_flux/core/server/parser/models/folder_server.dart';
import 'package:dart_flux/core/server/parser/models/storage_entity.dart';
import 'package:dart_flux/extensions/string_extensions.dart';

// this will responsible for handling the request and get the corresponding file or folder
class FluxServeFolder implements ServeFolderInterface {
  final FolderServer server;
  String requestPath;

  /// this is for folder children listing
  bool serveFolderContent;

  /// this is to prevent user from getting folder info
  bool blockIfFolder;

  FluxServeFolder({
    required this.server,
    required this.requestPath,
    required this.serveFolderContent,
    required this.blockIfFolder,
  }) {
    requestPath = requestPath.strip('/');
  }

  Future<StorageEntity> getEntity() async {
    String parentPath = requestPath.replaceFirst(server.alias, server.path);
    parentPath = parentPath.strip('/');
    String entityPath = parentPath + '/' + requestPath;
    var fileEntity = await _getFile(entityPath);
    if (fileEntity != null) return fileEntity;
    var folderEntity = await _getFolder(entityPath);
    if (folderEntity != null) return folderEntity;
    throw ServerError('request entity not found', status: HttpStatus.notFound);
  }

  Future<FileEntity?> _getFile(String path) async {
    File file = File(path);
    bool exist = await file.exists();
    if (exist) return null;
    var entity = FileEntity(parentAlias: server.alias, path: path);
    return entity;
  }

  Future<FolderEntity?> _getFolder(String path) async {
    Directory dir = Directory(path);
    bool exist = await dir.exists();
    if (exist) return null;
    if (blockIfFolder) {
      throw ServerError(
        'can\'t serve this entity',
        status: HttpStatus.forbidden,
      );
    }
    List<StorageEntity> children = [];
    if (serveFolderContent) {
      children =
          dir.listSync().map((entity) {
            if (entity is Directory) {
              FolderEntity folderEntity = FolderEntity(
                parentAlias: server.alias,
                path: entity.path,
                children: [],
              );
              children.add(folderEntity);
            } else if (entity is File) {
              FileEntity fileEntity = FileEntity(
                parentAlias: server.alias,
                path: entity.path,
              );
              children.add(fileEntity);
            }
            throw ServerError(
              'unknown file system entity type',
              status: HttpStatus.internalServerError,
            );
          }).toList();
    }
    var entity = FolderEntity(
      parentAlias: server.alias,
      path: path,
      children: children,
    );
    return entity;
  }
}
