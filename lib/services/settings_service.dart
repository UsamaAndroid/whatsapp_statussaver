import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _autoSaveKey = 'auto_save';
  static const _saveFolderKey = 'save_folder_path';
  static const _guideShownKey = 'guide_shown';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  bool get autoSave => _prefs.getBool(_autoSaveKey) ?? false;

  Future<void> setAutoSave(bool value) async {
    await _prefs.setBool(_autoSaveKey, value);
  }

  String? get saveFolderPath => _prefs.getString(_saveFolderKey);

  Future<void> setSaveFolderPath(String path) async {
    await _prefs.setString(_saveFolderKey, path);
  }

  bool get guideShown => _prefs.getBool(_guideShownKey) ?? false;

  Future<void> setGuideShown(bool value) async {
    await _prefs.setBool(_guideShownKey, value);
  }
}
