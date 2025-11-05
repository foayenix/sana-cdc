import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_checkin.freezed.dart';
part 'daily_checkin.g.dart';

@freezed
class DailyCheckin with _$DailyCheckin {
  const factory DailyCheckin({
    required String id,
    required DateTime date,
    required int sleepQuality,
    required int energyLevel,
    required int mood,
    required int stressLevel,
  }) = _DailyCheckin;

  factory DailyCheckin.fromJson(Map<String, dynamic> json) =>
      _$DailyCheckinFromJson(json);
}

@freezed
class CheckinRequest with _$CheckinRequest {
  const factory CheckinRequest({
    required int sleepQuality,
    required int energyLevel,
    required int mood,
    required int stressLevel,
  }) = _CheckinRequest;

  factory CheckinRequest.fromJson(Map<String, dynamic> json) =>
      _$CheckinRequestFromJson(json);
}

@freezed
class CheckinResponse with _$CheckinResponse {
  const factory CheckinResponse({
    required bool success,
    required CheckinData data,
  }) = _CheckinResponse;

  factory CheckinResponse.fromJson(Map<String, dynamic> json) =>
      _$CheckinResponseFromJson(json);
}

@freezed
class CheckinData with _$CheckinData {
  const factory CheckinData({
    required DailyCheckin checkin,
    required int updatedScore,
    required String updatedStatus,
  }) = _CheckinData;

  factory CheckinData.fromJson(Map<String, dynamic> json) =>
      _$CheckinDataFromJson(json);
}
