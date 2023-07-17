// ignore_for_file: unused_field, non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:logs/logs.dart';
import 'package:synchronized/synchronized.dart';
import 'package:path_provider/path_provider.dart';

/// Interface which is used to persist and retrieve state changes.
abstract class StorageInterface {
  List<dynamic> get values;
  List<dynamic> get keys;

  int get length;

  /// Returns value for key
  dynamic read(String key);

  /// Persists key value pair
  Future<void> write(Map<String, dynamic> map);

  /// Deletes key value pair
  Future<void> delete(List<String> key);

  /// Clears all key value pairs from storage
  Future<void> clear();

  /// Close the storage instance which will free any allocated resources.
  /// A storage instance can no longer be used once it is closed.
  Future<void> close();

  bool get isOpen;

  Future<void> deleteFromDisk();
}

class CachedStorage implements StorageInterface {
  CachedStorage._()
      : _lock = Lock(),
        logs = Logs('CachedStorage');
  final Logs logs;
  final Lock _lock;

  late Box<dynamic> _box;
  static late final String? path;

  static Future<CachedStorage> openCachedBox(
      String password, String key) async {
    var storage = CachedStorage._();
    await storage._openHiveBox(password, key);
    if (!_hasInstance) {
      _instance = storage;
      _hasInstance = true;
    }
    return _instance;
  }

  static Future<void> init({Directory? cachedDirectory}) async {
    Directory? dir = (kIsWeb)
        ? null
        : cachedDirectory ?? await getApplicationDocumentsDirectory();
    path = dir != null ? '${dir.path}/CACHED_STORAGE' : null;
    return Hive.init(path);
  }

  /// It will take care of repeatedly opening and closing
  /// the box by resetting the [_box] variable.
  Future<void> _openHiveBox(String password, String key) async {
    _box = Hive.isBoxOpen(key)
        ? Hive.box(key)
        : _box = await _lock.synchronized(() => Hive.openBox<dynamic>(key,
            encryptionCipher:
                HiveAesCipher(sha256.convert(utf8.encode(password)).bytes)));
  }

  static late CachedStorage _instance;
  static bool _hasInstance = false;

  @override
  get isOpen => _box.isOpen;

  @override
  get length => _box.length;

  @override
  get values => _box.values.toList();

  @override
  get keys => _box.keys.toList();

  @override
  read(String key) {
    logs.verbose('Read on ${_box.name}\nkey:$key');
    return isOpen ? _box.get(key) : null;
  }

  @override
  clear() async {
    logs.info('Clear ${_box.name}');
    if (isOpen) await _lock.synchronized(() => _box.clear());
  }

  @override
  close() async {
    logs.info('Close ${_box.name}');
    if (isOpen) await _lock.synchronized(() => _box.close());
  }

  @override
  delete(List<String> key) async {
    logs.info('Delete form ${_box.name}\nkey: $key');
    if (isOpen) await _lock.synchronized(() => _box.deleteAll(key));
  }

  @override
  write(Map<String, dynamic> map) async {
    logs.verbose('Write on ${_box.name}\nvalue:${map.keys}');
    if (isOpen) await _lock.synchronized(() => _box.putAll(map));
  }

  @override
  deleteFromDisk() async {
    final isExit = await Hive.boxExists(_box.name, path: path);
    if (isExit) {
      await _lock.synchronized<void>(() async {
        kIsWeb ? {await clear(), await close()} : await _box.deleteFromDisk();
      });
    }
  }
}
