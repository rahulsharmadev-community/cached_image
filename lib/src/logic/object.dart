import 'dart:async';
import 'package:dio/dio.dart' as dio;

class DownloadObject {
  final String url;
  final Function(int, int) onReceiveProgress;

  final FutureOr<dio.Response> Function(
    dio.Response<dynamic>,
    void Function(int, int) onReceiveProgress,
  ) response;
  final Map<String, String>? headers;
  final dio.ResponseType responseType;
  final Function? onError;

  const DownloadObject({
    required this.url,
    required this.onReceiveProgress,
    required this.response,
    required this.responseType,
    this.onError,
    this.headers,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadObject &&
          runtimeType == other.runtimeType &&
          url == other.url;

  @override
  int get hashCode => url.hashCode;
}
