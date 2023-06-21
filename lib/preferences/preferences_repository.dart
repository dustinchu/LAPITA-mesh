abstract class PreferencesRepository {
  Future<Map<String, dynamic>> getJson(String key,
      {Map<String, dynamic>? defaultValue});

  Future<bool> setJsonStr(String key, String value);
  Future<void> removeTokenMessage(String key);
  Future<bool> setStr(String key, String value);
  Future<String> getStr(String key);
  Future<bool> setList(String keny, List<String> value);
  Future<List<String>> getList(String key);
  Future<bool> setBool(String key, bool value);
  Future<bool> getBool(String key);
}
