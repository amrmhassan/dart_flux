import 'package:dart_flux/core/server/routing/models/model.dart';

abstract class UserAuthInterface implements ModelInterface {
  late String id;
  late String passwordHash;
  late String email;

  /// this will revoke the jwts before that date
  late DateTime? revokeDate;
}
