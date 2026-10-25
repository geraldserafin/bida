// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/auth_result.dart';
import '../models/request_link.dart';
import '../models/user.dart';
import '../models/verify_code.dart';
import '../models/verify_token.dart';

part 'auth_client.g.dart';

@RestApi()
abstract class AuthClient {
  factory AuthClient(Dio dio, {String? baseUrl}) = _AuthClient;

  /// E-mail a sign-in link and code.
  ///
  /// Always answers 204, whether or not the address has an account. The e-mail has a link (opened in the browser app) and a 6-digit code (typed in the mobile app), valid for 15 minutes.
  @POST('/auth/magic-link')
  Future<void> authRequestLink({@Body() required RequestLink body});

  /// Sign in with the code from the e-mail.
  ///
  /// Creates the account on the first sign-in. A code stops working after 5 wrong tries.
  @POST('/auth/magic-link/code')
  Future<AuthResult> authVerifyCode({@Body() required VerifyCode body});

  /// Sign in with the token from the e-mailed link
  @POST('/auth/magic-link/token')
  Future<AuthResult> authVerifyToken({@Body() required VerifyToken body});

  /// The signed-in user
  @GET('/auth/me')
  Future<User> authMe();

  /// End this session.
  ///
  /// The token stops working at once and the cookie is cleared.
  @POST('/auth/logout')
  Future<void> authLogout();
}
