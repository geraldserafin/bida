// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/month_summary.dart';
import '../models/overview.dart';

part 'overview_client.g.dart';

@RestApi()
abstract class OverviewClient {
  factory OverviewClient(Dio dio, {String? baseUrl}) = _OverviewClient;

  /// Money over a stretch of time.
  ///
  /// Income, what was put into envelopes and spent between the two days (both included), the pool that is left, and the figures of every envelope. Balances roll over from earlier days.
  @GET('/overview')
  Future<Overview> overviewGet({
    @Query('from') required String from,
    @Query('to') required String to,
    @Query('timeZone') String? timeZone,
  });

  /// History by month.
  ///
  /// Every month from the first with activity until now, newest first.
  @GET('/overview/months')
  Future<List<MonthSummary>> overviewMonths({
    @Query('startDay') String? startDay,
    @Query('timeZone') String? timeZone,
  });
}
