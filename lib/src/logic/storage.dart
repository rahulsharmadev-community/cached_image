import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CachedStorage {
  String _rootPath = '';
  String get rootPath => _rootPath;
  final String defaultLocation;
  Map<String, (int count, Uint8List bytes)> _tempCached = {};
  CachedStorage([this.defaultLocation = '']) {
    _initialize();
  }

  FutureOr<void> _initialize() async {
    if (Platform.isAndroid) {
      getExternalStorageDirectory().then(
          (value) => _rootPath = _normalizeExternalStorage(value?.path ?? ''));
    } else if (Platform.isIOS) {
      getDownloadsDirectory().then(
          (value) => _rootPath = _normalizeExternalStorage(value?.path ?? ''));
    }
    await requestPermission();
  }

  Timer? debounce;
  List<String> get _removeList {
    var ls = <String>[];
    for (var e in _tempCached.entries) {
      if (e.value.$1 == 0) ls.add(e.key);
    }
    return ls;
  }

  void disposeFromTempCached(String token) {
    final temp = _tempCached[token];
    if (temp != null) {
      var count = temp.$1 - 1;
      _tempCached[token] = (count, temp.$2);

      if (debounce != null) debounce!.cancel();
      debounce = Timer(Duration(seconds: 30), () {
        _removeList.forEach((e) {
          _tempCached.remove(e);
        });
      });
    }
  }

  /// token = file name + file format
  FutureOr<Uint8List?> read(String token, [String? location]) async {
    var temp = _getFromTempCached(token);
    if (temp != null) return temp;
    if (await requestPermission()) {
      var path = '$rootPath${locationClener(location ?? defaultLocation)}$token'
          .replaceAll('//', '/');
      var file = File(path);
      if (file.existsSync()) {
        var _bytes = await file.readAsBytes();
        _tempCached.addAll({token: (1, _bytes)});
        return _bytes;
      }
    }
    return null;
  }

  /// token = file name + file format
  FutureOr<void> writeNewFile(String token, Uint8List bytes,
      [String? location]) async {
    if (await requestPermission()) {
      var path = '$rootPath${locationClener(location ?? defaultLocation)}$token'
          .replaceAll('//', '/');
      if (File(path).existsSync()) return;
      final file = await File(path).create(recursive: true);
      await file.writeAsBytes(bytes);
      _tempCached.addAll({token: (1, bytes)});
    }
  }

  Uint8List? _getFromTempCached(String token) {
    final temp = _tempCached[token];

    if (temp != null) {
      _tempCached.addAll({token: (temp.$1 + 1, temp.$2)});
      return temp.$2;
    }
    return null;
  }

  (bool value, DateTime expiry)? _cachedOn;
  get _now => DateTime.now();

  FutureOr<bool> requestPermission() async {
    var isGranted = (_cachedOn?.$2.isAfter(_now) ?? false)
        ? _cachedOn!.$1
        : await Permission.storage.isGranted;
    print(isGranted);
    if (!isGranted) {
      var state = await Permission.storage.request();
      _cachedOn = (state.isGranted, _now.add(Duration(minutes: 2)));
      print(state);
      return state.isGranted;
    }
    return true;
  }

  String locationClener(String string) {
    if (string.trim().isEmpty) return '/';
    final ls = <String>[];
    for (String s in string.split('/')) {
      s = s.trim();
      if (s.isEmpty) continue;
      if (s != '/' && RegExp(r'^[a-zA-Z0-9 ]*$').hasMatch(s)) {
        ls.add(s);
      } else {
        throw 'Invalid location, "$s" occur error';
      }
    }
    return '/${ls.join('/')}/';
  }

  FutureOr<void> clearAll(String location) =>
      Directory('$_rootPath${locationClener(location)}')
          .delete(recursive: true);

  String _normalizeExternalStorage(String temp) {
    var path = '';
    var split = temp.split('/');
    for (var e in split) {
      path += '/$e';
      if (e.toLowerCase() == 'android') break;
    }
    final s = '${path.substring(1)}/media/${split[split.length - 2]}';
    Directory(s).createSync(recursive: true);
    return s;
  }
}
