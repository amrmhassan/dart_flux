import 'dart:io';

import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_flux/core/server/parser/interface/serve_folder_interface.dart';
import 'package:dart_flux/core/server/parser/models/file_entity.dart';
import 'package:dart_flux/core/server/parser/models/folder_entity.dart';
import 'package:dart_flux/core/server/parser/models/folder_server.dart';
import 'package:dart_flux/core/server/parser/models/storage_entity.dart';
import 'package:dart_flux/core/server/routing/models/flux_response.dart';
import 'package:dart_flux/core/server/utils/send_response.dart';
import 'package:dart_flux/extensions/string_extensions.dart';

// this will responsible for handling the request and get the corresponding file or folder
class FluxServeFolder implements ServeFolderInterface {
  final FolderServer server;
  FluxResponse response;
  String requestedPath;

  /// this is for folder children listing
  bool serveFolderContent;

  /// this is to prevent user from getting folder info
  bool blockIfFolder;

  FluxServeFolder({
    required this.response,
    required this.server,
    required this.requestedPath,
    this.serveFolderContent = false,
    this.blockIfFolder = true,
  }) {
    requestedPath = requestedPath.strip('/').replaceAll('..', '');
  }

  String _truncatedEntityPath(String path) {
    if (!path.contains(server.path)) {
      throw ServerError('can\'t truncated path');
    }
    return path.replaceFirst(server.path, server.alias);
  }

  String _getFullPath(String path) {
    if (path.contains(server.path)) {
      throw ServerError('path already contains parent path');
    }
    if (!path.contains(server.alias)) {
      throw ServerError('no alias found');
    }
    path = path.replaceFirst(server.alias, server.path);
    return path;
  }

  Future<FluxResponse> serve() async {
    var entity = await _getEntity();
    if (entity is FileEntity) {
      String fullPath = _getFullPath(entity.path);
      return SendResponse.file(response, File(fullPath));
    } else if (entity is FolderEntity) {
      var res = await _getFolderResponse(entity);
      return SendResponse.json(response, res);
    }
    throw ServerError(
      'entity not known',
      status: HttpStatus.internalServerError,
    );
  }

  Future<List<Map<String, dynamic>>> _getFolderResponse(
    FolderEntity entity,
  ) async {
    var items = entity.children.map((i) => i.toJson()).toList();

    return items;
  }

  Future<StorageEntity> _getEntity() async {
    String parentPath;
    String? alias = server.alias;
    if (alias.isEmpty) {
      parentPath = server.path;
    } else {
      parentPath = requestedPath.replaceFirst(alias, server.path);
    }
    parentPath = parentPath.strip('/');
    String entityPath = parentPath + '/' + requestedPath;
    var fileEntity = await _getFile(entityPath);
    if (fileEntity != null) return fileEntity;
    var folderEntity = await _getFolder(entityPath);
    if (folderEntity != null) return folderEntity;
    throw ServerError(
      'requested entity not found',
      status: HttpStatus.notFound,
    );
  }

  Future<FileEntity?> _getFile(String path) async {
    File file = File(path);
    bool exist = await file.exists();
    if (!exist) return null;
    var entity = FileEntity(
      parentAlias: server.alias,
      path: _truncatedEntityPath(path),
    );
    return entity;
  }

  Future<FolderEntity?> _getFolder(String path) async {
    Directory dir = Directory(path);
    bool exist = await dir.exists();
    if (!exist) return null;
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
                path: _truncatedEntityPath(entity.path),
                children: [],
              );
              return folderEntity;
            } else if (entity is File) {
              FileEntity fileEntity = FileEntity(
                parentAlias: server.alias,
                path: _truncatedEntityPath(entity.path),
              );
              return fileEntity;
            } else {
              throw ServerError(
                'unknown file system entity type',
                status: HttpStatus.internalServerError,
              );
            }
          }).toList();
    }
    var entity = FolderEntity(
      parentAlias: server.alias,
      path: _truncatedEntityPath(path),
      children: children,
    );
    return entity;
  }
}
