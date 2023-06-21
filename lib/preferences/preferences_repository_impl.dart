import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'preferences_repository.dart';

class PreferencesRepositoryImpl implements PreferencesRepository {
  final String nodeKey = "node";
  @override
  Future<Map<String, dynamic>> getJson(String key,
      {Map<String, dynamic>? defaultValue}) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(key)) {
      return json.decode(prefs.getString(key)!);
    } else {
      return defaultValue ?? {};
    }
  }

  @override
  Future<bool> setJsonStr(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }

  @override
  Future<bool> setStr(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }

  @override
  Future<String> getStr(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? "";
  }

  @override
  Future<void> removeTokenMessage(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    // return prefs.setString(key, value);
  }

  @override
  Future<bool> setList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(key, value);
  }

  @override
  Future<List<String>> getList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? [];
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(key, value);
  }

  @override
  Future<bool> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? true;
  }
}
