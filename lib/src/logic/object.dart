import 'dart:async';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

class DownloadObject extends Equatable {
  final String url;
  final Function(int, int) onReceiveProgress;
  final FutureOr<Response> Function(Response<dynamic>) response;
  final Function? onError;

  const DownloadObject(
      {required this.url,
      required this.onReceiveProgress,
      required this.response,
      this.onError});

  @override
  List<Object?> get props => [url, onReceiveProgress, response, onError];
}
