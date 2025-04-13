import 'package:dart_flux/constants/global.dart';
import 'package:dart_flux/core/db/base/interface/coll_ref_interface.dart';
import 'package:dart_flux/core/db/base/mongo/interface/mongo_db_collection_interface.dart';
import 'package:dart_flux/core/db/base/mongo/models/doc_ref_mongo.dart';
import 'package:mongo_dart/mongo_dart.dart';

class CollRefMongo extends MongoDbCollectionInterface
    implements CollRefInterface {
  @override
  final String name;

  CollRefMongo(this.name, Db db) : super(db, name);

  @override
  DocRefMongo doc([String? id]) {
    return DocRefMongo(id ?? dartID.generate(), this);
  }
}
