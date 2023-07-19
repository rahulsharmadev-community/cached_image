// ignore_for_file: unused_field, non_constant_identifier_names

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:logs/logs.dart';
import 'package:synchronized/synchronized.dart';
import 'package:path_provider/path_provider.dart';

/// Interface which is used to persist and retrieve state changes.
abstract class StorageInterface {
  bool get isOpen;
  Future<int> get length;
  List<dynamic> get values;
  Future<List<String>> get keys;

  /// Returns value for key
  Future<dynamic> read(String key);

  /// Persists key value pair
  void write(Map<String, dynamic> map);

  /// Deletes key value pair
  Future<void> delete(List<String> key);

  /// Clears all key value pairs from storage
  Future<void> clear();

  /// Close the storage instance which will free any allocated resources.
  /// A storage instance can no longer be used once it is closed.
  Future<void> close();

  Future<void> deleteFromDisk();
}

class CachedStorage implements StorageInterface {
  CachedStorage(this.password, this.key)
      : _lock = Lock(),
        logs = Logs('CachedStorage');
  final Logs logs;
  final Lock _lock;
  Box<dynamic>? _box;

  ///`box` ensures that null is never returned when accessing the `_box` object.\
  /// If the `openCachedBox` method is not called yet,
  /// it will be automatically invoked to ensure everything works correctly.
  ///
  /// If `(_box != null && isOpen)` evaluates to true, the existing _box is returned;\
  /// otherwise, the `openCachedBox` method is called.
  Future<Box> get box async =>
      ((_box != null && isOpen) ? _box : await openCachedBox())!;

  static late final String? _path;
  final String password;
  final String key;

  /// Not necessary in the browser
  /// Only in iOS, android, windows, macos, linux
  ///
  /// [Defalut]: await getApplicationDocumentsDirectory()).path + '/CACHED_STORAGE'
  static Future<void> init({String? path}) async {
    _path = (kIsWeb)
        ? null
        : path ??
            (await getApplicationDocumentsDirectory()).path + '/CACHED_STORAGE';
    return Hive.init(path);
  }

  /// It will take care of repeatedly opening and closing
  /// the box by resetting the [box] variable.
  Future<Box?> openCachedBox() async {
    return _box =
        Hive.isBoxOpen(key) ? Hive.box(key) : await Hive.openBox<dynamic>(key);
  }

  Map<String, dynamic> _queue = {};
  bool _isWriting = false;

  @override
  get isOpen => Hive.isBoxOpen(key);

  @override
  get length async => (await box).length;

  @override
  get values async => (await box).values.toList();

  @override
  get keys async => (await box).keys.map((e) => '$e').toList();

  _writing(Map<String, dynamic> map) async {
    _isWriting = true;
    var bx = (await box);
    await _lock.synchronized(() => bx.putAll(map)).whenComplete(
        () => logs.verbose('Write on ${bx.name}\nvalue:${map.keys}'));

    final keys = map.keys.toList();
    keys.forEach((key) => _queue.remove(key));
    _isWriting = false;
    if (_queue.isNotEmpty) await _writing(_queue);
  }

  /// If the key is present, invokes [update] with the
  /// current Uint8List and stores the new Uint8List in the map.
  @override
  write(Map<String, dynamic> map) {
    _queue.addAll(map);
    if (!_isWriting) _writing(map);
  }

  @override
  read(String key) async {
    var bx = (await box);
    logs.verbose('Read on ${bx.name}\nkey:$key');
    return isOpen ? bx.get(key) : null;
  }

  @override
  clear() async {
    var bx = (await box);
    await _lock
        .synchronized(() async => bx.clear())
        .whenComplete(() => logs.info('Clear ${bx.name}'));
  }

  @override
  close() async {
    var bx = (await box);
    await _lock
        .synchronized(() async => bx.close())
        .whenComplete(() => logs.info('Close ${bx.name}'));
  }

  @override
  delete(List<String> key) async {
    var bx = (await box);
    await _lock
        .synchronized(() async => bx.deleteAll(key))
        .whenComplete(() => logs.info('Delete form ${bx.name}\nkey: $key'));
  }

  @override
  deleteFromDisk() async {
    final isExit = await Hive.boxExists(key, path: _path);
    if (isExit) {
      var bx = (await box);
      await _lock.synchronized<void>(() async {
        if (kIsWeb) {
          await bx.clear();
          await bx.close();
        } else
          await bx.deleteFromDisk();
      }).whenComplete(() =>
          logs.info('delete From Disk ${bx.name}\nkey: $key\npath: $_path'));
    }
  }
}
