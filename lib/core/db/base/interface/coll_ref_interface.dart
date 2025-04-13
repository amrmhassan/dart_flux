import 'package:dart_flux/core/db/base/interface/doc_ref_interface.dart';
import 'package:dart_flux/core/db/base/interface/path_entity.dart';

abstract class CollRefInterface {
  final String name;
  String get id;
  final DocRefInterface? parentDoc;
  PathEntity get path;

  const CollRefInterface(this.name, this.parentDoc);

  DocRefInterface doc(String id);
}
