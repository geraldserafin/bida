// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/add_contribution.dart';
import '../models/contribution.dart';

part 'contributions_client.g.dart';

@RestApi()
abstract class ContributionsClient {
  factory ContributionsClient(Dio dio, {String? baseUrl}) =
      _ContributionsClient;

  /// List what was paid into a period.
  ///
  /// Newest first.
  @GET('/periods/{id}/contributions')
  Future<List<Contribution>> contributionsList({
    @Path('id') required String id,
  });

  /// Record money paid into a period.
  ///
  /// In the name of the signed-in user, or of nobody with `external`. The planned income of the period is a separate number.
  @POST('/periods/{id}/contributions')
  Future<Contribution> contributionsAdd({
    @Path('id') required String id,
    @Body() required AddContribution body,
  });

  /// Delete a contribution.
  ///
  /// Whoever recorded it, or an owner of the space. Money from outside has no author, so only an owner deletes it.
  @DELETE('/contributions/{id}')
  Future<void> contributionsDelete({@Path('id') required String id});
}
