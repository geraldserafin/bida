// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'email.dart';

part 'delete_account.g.dart';

@JsonSerializable()
class DeleteAccount {
  const DeleteAccount({required this.email});

  factory DeleteAccount.fromJson(Map<String, Object?> json) =>
      _$DeleteAccountFromJson(json);

  final Email email;

  Map<String, Object?> toJson() => _$DeleteAccountToJson(this);
}
