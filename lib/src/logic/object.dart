import 'dart:async';
import 'package:dio/dio.dart' as dio;
import 'package:equatable/equatable.dart';

class DownloadObject extends Equatable {
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
  List<Object?> get props => [url, onReceiveProgress, response, onError];
}
