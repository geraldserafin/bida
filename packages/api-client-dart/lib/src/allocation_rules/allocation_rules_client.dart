// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/allocation_rule.dart';
import '../models/save_allocation_rule.dart';

part 'allocation_rules_client.g.dart';

@RestApi()
abstract class AllocationRulesClient {
  factory AllocationRulesClient(Dio dio, {String? baseUrl}) =
      _AllocationRulesClient;

  /// List allocation rules.
  ///
  /// The user's own, newest first.
  @GET('/allocation-rules')
  Future<List<AllocationRule>> allocationRulesList();

  /// Create an allocation rule.
  ///
  /// Puts a sum into an envelope every month. For a sub-envelope the money comes out of what the user put into its parent.
  @POST('/allocation-rules')
  Future<AllocationRule> allocationRulesCreate({
    @Body() required SaveAllocationRule body,
  });

  /// Edit an allocation rule.
  ///
  /// Setting `active` to false pauses it.
  @PUT('/allocation-rules/{id}')
  Future<AllocationRule> allocationRulesUpdate({
    @Path('id') required String id,
    @Body() required SaveAllocationRule body,
  });

  /// Delete an allocation rule.
  ///
  /// Allocations it already made are kept.
  @DELETE('/allocation-rules/{id}')
  Future<void> allocationRulesDelete({@Path('id') required String id});
}
