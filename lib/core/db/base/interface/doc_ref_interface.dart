import 'package:dart_flux/core/db/base/interface/coll_ref_interface.dart';

abstract class DocRefInterface {
  final String id;
  final CollRefInterface parentColl;

  const DocRefInterface(this.id, this.parentColl);
}
