// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/delete_account.dart';
import '../models/update_profile.dart';
import '../models/user.dart';

part 'account_client.g.dart';

@RestApi()
abstract class AccountClient {
  factory AccountClient(Dio dio, {String? baseUrl}) = _AccountClient;

  /// Set my name
  @PUT('/account')
  Future<User> accountUpdate({@Body() required UpdateProfile body});

  /// Delete my account (F04).
  ///
  /// Type the address of the account to confirm. Not while the user has a negative share. The wallet, its incomes and the user's rules go; positive shares stay in the piggy banks as nobody's money; households where the user is alone go too.
  @POST('/account/delete')
  Future<void> accountDelete({@Body() required DeleteAccount body});
}
