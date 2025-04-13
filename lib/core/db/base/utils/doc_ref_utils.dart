import 'package:dart_flux/core/db/base/interface/coll_ref_interface.dart';
import 'package:dart_flux/core/db/base/interface/db_entity.dart';
import 'package:dart_flux/core/db/base/interface/path_entity.dart';

class DocRefUtils {
  static PathEntity getDocPath(
    String id,
    DbEntity entity,
    CollRefInterface parentColl,
  ) {
    return PathEntity(name: id, entity: entity, parentPath: parentColl.path);
  }
}
