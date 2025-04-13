import 'package:dart_flux/core/db/base/interface/db_entity.dart';
import 'package:dart_flux/core/db/base/interface/doc_ref_interface.dart';
import 'package:dart_flux/core/db/base/interface/path_entity.dart';
import 'package:dart_flux/core/db/base/models/mongo_db_document.dart';
import 'package:dart_flux/core/db/base/utils/doc_ref_utils.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'coll_ref_mongo.dart';

class DocRefMongo extends MongoDbDocument implements DbEntity, DocRefInterface {
  @override
  final String id;
  @override
  final CollRefMongo parentColl;
  final Db _db;

  DocRefMongo(this.id, this.parentColl, this._db) : super(id, parentColl);

  @override
  PathEntity get path => DocRefUtils.getDocPath(id, this, parentColl);

  @override
  CollRefMongo collection(String name) {
    return CollRefMongo(name, this, _db);
  }
}
