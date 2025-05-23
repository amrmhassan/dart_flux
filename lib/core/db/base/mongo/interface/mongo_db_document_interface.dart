import 'package:dart_flux/core/db/base/mongo/models/coll_ref_mongo.dart';
import 'package:mongo_dart/mongo_dart.dart';

abstract class MongoDbDocumentInterface {
  final String _id;
  final CollRefMongo _collRef;
  const MongoDbDocumentInterface(this._id, this._collRef);

  /// this will update certain values presented in the doc object
  Future<WriteResult> update(
    Map<String, dynamic> doc, {
    bool upsert = false,
  }) async {
    var selector = where.eq('_id', _id);
    var updateQuery = modify;
    doc.forEach((key, value) {
      updateQuery = updateQuery.set(key, value);
    });
    return _collRef.updateOne(selector, updateQuery, upsert: upsert);
  }

  /// this will delete the document
  Future<WriteResult> delete() async {
    var selector = where.eq('_id', _id);
    return _collRef.deleteOne(selector);
  }

  /// this will remove the old document and add another one with the same id
  Future<WriteResult> set(Map<String, dynamic> doc) async {
    doc['_id'] = _id;
    return _collRef.insertOne(doc);
  }

  Future<Map<String, dynamic>?> getData() async {
    var selector = where.eq('_id', _id);
    return _collRef.findOne(selector);
  }
}
