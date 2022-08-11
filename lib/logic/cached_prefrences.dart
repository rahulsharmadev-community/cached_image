import 'dart:developer';

import 'package:cached_image/model/cache_data_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CachedPreferences {
  CachedPreferences._();
  static late final SharedPreferences _cachedPreferences;
  static final _key = '${'cached_image_preferences'.hashCode}';

  static Future<bool> init() async {
    // As we all know, _cachedPreferences is only initialised once.
    // So after first time it simply occure error.
    return await SharedPreferences.getInstance().then<bool>((value) async {
      _cachedPreferences = value;
      await _removeExpiredData();
      return true;
    }).catchError((e) {
      return true;
    });
  }

  /// ```
  /// var list = List<int> list = [1, 3, 5, 6, 4];
  ///   try {
  ///       var value = list.singleWhere((e) => e.n == 9);
  ///       print(value);\
  ///         } on StateError catch (e) {
  ///       print('Error: ${e.message} Found');
  ///     }
  /// ```
  static CacheDataModel when(String key) =>
      cachedList.singleWhere((e) => e.key == key);

  static List<String> get _rawCached =>
      _cachedPreferences.getStringList(_key) ?? [];

  static List<CacheDataModel> get cachedList =>
      _rawCached.map((e) => CacheDataModel.fromJson(e)).toList();

  static Future<bool> update(CacheDataModel model) async {
    var temp = cachedList
      ..removeWhere((p0) => p0.key == model.key)
      ..add(model);
    return await _cachedPreferences
        .setStringList(model.key, temp.map((e) => e.toJson()).toList())
        .then((_) {
      log('Cache Activity: Update');
      return true;
    }).catchError((_) {
      log('Cache Activity: Update->Error');
      return false;
    });
  }

  static Future<bool> add(CacheDataModel model) async =>
      await _cachedPreferences
          .setStringList(_key, _rawCached + [model.toJson()])
          .then((_) {
        log('Cache Activity: Add');
        return true;
      }).catchError((_) {
        log('Cache Activity: Add->Error');
        return false;
      });

  static Future<bool> remove(CacheDataModel model) async =>
      await _cachedPreferences
          .setStringList(_key, _rawCached..remove(model.toJson()))
          .then((_) {
        log('Cache Activity: Remove');
        return true;
      }).catchError((_) {
        log('Cache Activity: Remove->Error');
        return false;
      });
  static Future<bool> _removeExpiredData() async {
    var temp = cachedList
      ..removeWhere((e) => e.expireAt.isAfter(DateTime.now()));
    return temp.isEmpty
        ? false
        : await _cachedPreferences
            .setStringList(_key, temp.map((e) => e.toJson()).toList())
            .then((_) {
            log('Cache Activity: RemoveList $temp');
            return true;
          }).catchError((_) {
            log('Cache Activity: RemoveList->Error');
            return false;
          });
  }

  static Future<bool> removeAll() async => await _cachedPreferences.clear();
}
