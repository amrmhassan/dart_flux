import 'doc_ref_interface.dart';

abstract class CollRefInterface {
  final String name;

  const CollRefInterface(this.name);

  DocRefInterface doc([String? id]);
}
