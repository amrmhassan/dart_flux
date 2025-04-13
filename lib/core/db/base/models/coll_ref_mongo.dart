import 'package:dart_flux/core/db/base/interface/coll_ref_interface.dart';
import 'package:dart_flux/core/db/base/interface/db_entity.dart';
import 'package:dart_flux/core/db/base/interface/mongo_db_collection_interface.dart';
import 'package:dart_flux/core/db/base/interface/path_entity.dart';
import 'package:dart_flux/core/db/base/models/doc_ref_mongo.dart';
import 'package:dart_flux/core/db/base/utils/coll_ref_utils.dart';
import 'package:mongo_dart/mongo_dart.dart';

class CollRefMongo extends MongoDbCollectionInterface
    implements DbEntity, CollRefInterface {
  @override
  final String name;
  @override
  final DocRefMongo? parentDoc;
  final Db _db;

  CollRefMongo(this.name, this.parentDoc, this._db)
    : super(_db, CollRefUtils.getCollId(name, parentDoc));

  @override
  String get id => CollRefUtils.getCollId(name, parentDoc);

  @override
  PathEntity get path => CollRefUtils.getCollPath(this, name, parentDoc);

  @override
  DocRefMongo doc(String id) {
    return DocRefMongo(id, this, _db);
  }
}
