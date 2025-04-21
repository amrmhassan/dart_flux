import 'package:dart_flux/core/server/routing/models/model.dart';

abstract class UserInterface implements ModelInterface {
  late String id;
  late String email;
  late Map<String, dynamic>? data;
}
