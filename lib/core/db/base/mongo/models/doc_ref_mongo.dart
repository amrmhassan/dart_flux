import 'package:dart_flux/core/db/base/interface/doc_ref_interface.dart';
import 'package:dart_flux/core/db/base/mongo/interface/mongo_db_document_interface.dart';

import 'coll_ref_mongo.dart';

class DocRefMongo extends MongoDbDocumentInterface implements DocRefInterface {
  @override
  final String id;
  @override
  final CollRefMongo parentColl;

  DocRefMongo(this.id, this.parentColl) : super(id, parentColl);
}
