import 'dart:async';

import 'package:mongo_dart/mongo_dart.dart';

abstract class MongoDbCollectionInterface extends DbCollection {
  MongoDbCollectionInterface(super.db, super.collectionName);

  /// this just convert the normal stream find method into a future return
  Future<List<Map<String, dynamic>>> futureFind([selector]) async {
    Completer<List<Map<String, dynamic>>> completer =
        Completer<List<Map<String, dynamic>>>();

    List<Map<String, dynamic>> data = [];

    var stream = find(selector).listen((event) {
      data.add(event);
    });
    stream.onDone(() {
      completer.complete(data);
    });
    return completer.future;
  }

  Future<List<Map<String, dynamic>>> getAllDocuments() async {
    return futureFind();
  }

  /// this method depends on the _id property, so if you inserted a custom _id it will sort by your custom _id and this will cause a mis-sorting
  Future<Map<String, dynamic>> lastDocument() async {
    var selector = where.limit(1).sortBy('_id', descending: true);
    var res = await futureFind(selector);
    return res.first;
  }

  /// this method depends on the _id property, so if you inserted a custom _id it will sort by your custom _id and this will cause a mis-sorting
  Future<Map<String, dynamic>> firstDocument() async {
    var selector = where.limit(1).sortBy('_id');
    var res = await futureFind(selector);
    return res.first;
  }
}
