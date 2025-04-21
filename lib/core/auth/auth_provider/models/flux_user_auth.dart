// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dart_flux/core/auth/auth_provider/interface/user_auth_interface.dart';
import 'package:dart_flux/core/server/routing/models/model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'flux_user_auth.g.dart';

@JsonSerializable(explicitToJson: true)
class FluxUserAuth implements UserAuthInterface {
  @override
  String email;

  @override
  String id;

  @override
  String passwordHash;

  @override
  DateTime? revokeDate;
  FluxUserAuth({
    required this.email,
    required this.id,
    required this.passwordHash,
    this.revokeDate,
  });

  factory FluxUserAuth.fromJson(Json json) => _$FluxUserAuthFromJson(json);

  @override
  Json toJson() => _$FluxUserAuthToJson(this);
}
