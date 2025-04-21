// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:json_annotation/json_annotation.dart';

import 'package:dart_flux/core/auth/auth_provider/interface/user_interface.dart';
import 'package:dart_flux/core/server/routing/models/model.dart';

part 'flux_user.g.dart';

@JsonSerializable(explicitToJson: true)
class FluxUser extends UserInterface {
  @override
  String email;

  @override
  String id;
  FluxUser({required this.email, required this.id, required this.data});

  factory FluxUser.fromJson(Json json) => _$FluxUserFromJson(json);

  @override
  Json toJson() => _$FluxUserToJson(this);

  @override
  Map<String, dynamic>? data;
}
