import 'dart:async';
import 'dart:isolate';
import 'package:cached_image/cached_image.dart';
import 'package:dio/dio.dart';
import 'object.dart';

class DownloadManage {
  Map<String, DownloadObject> urls = {};

  bool wait100micros = true;
  Dio dio = Dio();
  // Future<Response>
  void download(DownloadObject object) async {
    urls.addAll({object.url: object});
    if (wait100micros) {
      wait100micros = false;
      await Future.delayed(const Duration(microseconds: 100), _download);
      wait100micros = true;
    }
  }

  get current => DateTime.now();
  void _download() async {
    if (urls.isEmpty) return;
    final futures = <Future>[];
    // // print('urls:${urls.length}, Loaded at $current');
    for (var e in urls.entries) {
      var future = dio
          .get(e.value.url,
              options: Options(responseType: ResponseType.bytes),
              onReceiveProgress: e.value.onReceiveProgress)
          .then((_) {
        urls.remove('${_.realUri}');
        // print('1 remove, remaning ${urls.length}');
        return e.value.response(_);
      }).onError((error, stackTrace) {
        e.value.onError;
        return Response(requestOptions: RequestOptions());
      });
      futures.add(future);
    }
    // print('urls:${urls.length}, Downloading Start $current');
    try {
      if (CachedImage.isolate) {
        final isolate = await Isolate.spawn(_isolatedTask, futures);
        isolate.kill(priority: 0);
      } else {
        await Future.wait(futures);
      }
    } catch (_) {
      // print('$current Isolate Exception: $_');
    }
  }
}

/// Top level function
void _isolatedTask(List<Future> futures) async {
  try {
    await Future.wait(futures);
  } catch (_) {
    // print('Downloading Exception: $_');
  }
}
