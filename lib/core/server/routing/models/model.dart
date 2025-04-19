typedef Json = Map<String, dynamic>;

abstract class Model implements ModelInterface {
  String get collectionName;
}

abstract class ModelInterface {
  Json toJson();
}
