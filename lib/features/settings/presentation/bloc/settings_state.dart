part of 'settings_cubit.dart';

@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState.initial() = _Initial;
  const factory SettingsState.loading() = _Loading;
  const factory SettingsState.loaded(
    Map<String, String> settings,
    DbStats stats,
  ) = _Loaded;
  const factory SettingsState.error(String message) = _Error;
}
