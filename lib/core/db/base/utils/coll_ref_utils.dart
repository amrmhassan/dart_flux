import 'package:dart_flux/core/db/base/interface/db_entity.dart';
import 'package:dart_flux/core/db/base/interface/doc_ref_interface.dart';
import 'package:dart_flux/core/db/base/interface/path_entity.dart';

class CollRefUtils {
  static String getCollId(String name, DocRefInterface? parentDoc) {
    if (parentDoc == null) {
      return name;
    } else {
      return '$name|${parentDoc.id}|${parentDoc.parentColl.name}';
    }
  }

  static PathEntity getCollPath(
    DbEntity entity,
    String name,
    DocRefInterface? parentDoc,
  ) {
    if (parentDoc == null) {
      return PathEntity(name: name, entity: entity, parentPath: null);
    } else {
      return PathEntity(name: name, entity: entity, parentPath: parentDoc.path);
    }
  }
}
