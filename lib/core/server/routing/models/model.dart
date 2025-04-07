typedef Json = Map<String, dynamic>;

abstract class Model {
  Json toJson();
  Model fromJson(Json json);
  String get collectionName;
}
