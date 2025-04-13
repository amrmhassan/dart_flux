import 'package:dart_flux/core/db/base/interface/coll_ref_interface.dart';
import 'package:dart_flux/core/db/base/interface/path_entity.dart';

abstract class DocRefInterface {
  final String id;
  final CollRefInterface parentColl;
  PathEntity get path;

  const DocRefInterface(this.id, this.parentColl);

  CollRefInterface collection(String name);
}
