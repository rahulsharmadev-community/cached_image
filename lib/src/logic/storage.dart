import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CachedStorage {
  String _rootPath = '';
  String get rootPath => _rootPath;
  final String defaultLocation;
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

  /// token = file name + file format
  FutureOr<Uint8List?> read(String token, [String? location]) async {
    if (await requestPermission()) {
      var path = '$rootPath${locationClener(location ?? defaultLocation)}$token'
          .replaceAll('//', '/');
      var file = File(path);
      if (file.existsSync()) {
        return await file.readAsBytes();
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
    }
  }

  (bool value, DateTime expiry)? _tempCache;
  get _now => DateTime.now();

  FutureOr<bool> requestPermission() async {
    var isGranted = (_tempCache?.$2.isAfter(_now) ?? false)
        ? _tempCache!.$1
        : !await Permission.storage.isGranted;
    if (isGranted) {
      var state = await Permission.storage.request();
      _tempCache = (state.isGranted, _now.add(Duration(minutes: 1)));
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
