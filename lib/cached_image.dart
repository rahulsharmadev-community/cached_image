library cached_image;

import 'dart:async';
import 'package:cached_image/src/const/kTransparent.dart';
import 'package:crypto/crypto.dart';
import 'src/logic/download_manager.dart';
import 'src/logic/object.dart';
import 'src/logic/storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
part 'src/widget/fade_in_out.dart';

final downloadManage = DownloadManage();

class CachedDataProgress {
  ///[downloadedBytes] represents the downloaded size(in bytes) of the image.
  ///This value increases and reaches the [totalBytes] when image is fully downloaded.
  int downloadedBytes;

  ///[totalBytes] represents the actual size(in bytes) of the image.
  ///This value can be null if the size is not obtained from the image.
  int? totalBytes;

  ///[progressPercentage] gives the download progress of the image
  ValueNotifier<double> progressPercentage;

  ///[isDownloading] will be true if the image is to be download,
  ///and will be false if the image is already in the cache
  bool isDownloading;

  ///[CachedDataProgress] has the data representing the download
  ///progress and total size of the image.
  CachedDataProgress(
      {ValueNotifier<double>? progressPercentage,
      this.totalBytes,
      this.downloadedBytes = 0,
      this.isDownloading = false})
      : progressPercentage = progressPercentage ?? ValueNotifier(0);
}

class _ImageInfo {
  final Uint8List? bytes;
  final String? errorMsg;
  const _ImageInfo.image(this.bytes) : errorMsg = null;
  const _ImageInfo.error(this.errorMsg) : bytes = null;

  bool get hasError => errorMsg != null && bytes == null;
  bool get hasBytes => errorMsg == null && bytes != null;
}

enum RequestResponseType { json, bytes }

class CachedImage extends StatefulWidget {
  final String url;
  final BoxFit? fit;
  final double scale;
  final double? width;
  final double? height;
  final Color? color;
  final Animation<double>? opacity;
  final FilterQuality filterQuality;
  final BlendMode? colorBlendMode;
  final AlignmentGeometry alignment;
  final ImageRepeat repeat;
  final Rect? centerSlice;
  final bool matchTextDirection;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  final bool isAntiAlias;
  final ImageErrorWidgetBuilder? errorBuilder;
  final Widget Function(BuildContext, CachedDataProgress)? loadingBuilder;

  /// Image displayed while the target [image] is loading.
  final ImageProvider? placeholder;

  /// The duration of the fade-out animation for the [placeholder].
  final Duration fadeOutDuration;

  /// The curve of the fade-out animation for the [placeholder].
  final Curve fadeOutCurve;

  /// The duration of the fade-in animation for the [image].
  final Duration fadeInDuration;

  /// The curve of the fade-in animation for the [image].
  final Curve fadeInCurve;

  /// How to inscribe the placeholder image into the space allocated during layout.
  ///
  /// If not value set, it will fallback to [fit].
  final BoxFit? placeholderFit;

  /// The rendering quality of the placeholder image.
  ///
  /// {@macro flutter.widgets.image.filterQuality}
  final FilterQuality? placeholderFilterQuality;

  /// A builder function that is called if an error occurs during placeholder
  /// image loading.
  final ImageErrorWidgetBuilder? placeholderErrorBuilder;

  /// json:  content-type of response is "application/json"
  /// bytes: Get the original bytes, the [Response.data] will be [List<int>].
  final RequestResponseType responseType;

  ///```
  /// {
  /// 'Content-Type': 'application/json',
  /// 'Authorization': 'Bearer $token',
  ///  ......etc
  /// }
  /// ```
  final Map<String, String>? headers;

  final FutureOr<Uint8List> Function(dynamic, void Function(int, int))?
      response;
  final String? location;
  const CachedImage(
    this.url, {
    Key? key,
    this.scale = 1.0,
    this.errorBuilder,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.width,
    this.height,
    this.color,
    this.opacity,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.isAntiAlias = false,
    this.filterQuality = FilterQuality.low,
    this.loadingBuilder,
    this.placeholder,
    this.placeholderErrorBuilder,
    this.placeholderFit,
    this.placeholderFilterQuality,
    this.fadeOutDuration = const Duration(milliseconds: 150),
    this.fadeOutCurve = Curves.easeOut,
    this.fadeInDuration = const Duration(milliseconds: 350),
    this.fadeInCurve = Curves.easeIn,
    this.responseType = RequestResponseType.bytes,
    this.headers,
    this.response,
    this.location,
  }) : super(key: key);
  @override
  State<CachedImage> createState() => _CachedImageState();

  static bool isolate = false;
  static CachedStorage? storage;

  static void initialize([String defaultLocation = '']) =>
      storage ??= CachedStorage(defaultLocation);

  static void clearAll(String location) => storage!.clearAll(location);
}

class _CachedImageState extends State<CachedImage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  _ImageInfo? _imageInfo;
  final CachedDataProgress _progressData = CachedDataProgress();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTaskAsync());
  }

  ///[_loadTaskAsync] Not public API.
  FutureOr<void> _loadTaskAsync() async {
    _imageInfo = await _loadImage(widget.url);
    if (mounted) setState(() {});
  }

  bool hasCached = false;

  ///[_loadImage] Not public API.
  Future<_ImageInfo> _loadImage(String url) async {
    var token = _getToken;
    final bytes = await CachedImage.storage!.read(token, widget.location);
    if (bytes != null) {
      hasCached = true;
      return _ImageInfo.image(bytes);
    } else {
      final downloadResp = await _downloadImageAndUpdateProgress(url);
      if (downloadResp.$1 != null && downloadResp.$2 == null) {
        await CachedImage.storage!
            .writeNewFile(token, downloadResp.$1!, widget.location);
        return _ImageInfo.image(downloadResp.$1!);
      } else {
        return _ImageInfo.error(downloadResp.$2);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    CachedImage.storage?.disposeFromTempCached(_getToken);
    super.dispose();
  }

  Widget _debugBuildErrorWidget(BuildContext context, Object error) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        const Positioned.fill(
          child: Placeholder(
            color: Color(0xCF8D021F),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: FittedBox(
            child: Text(
              '$error',
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                shadows: <Shadow>[
                  Shadow(blurRadius: 1.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<_ImageInfo>('ImageInfo', _imageInfo));
    description.add(DiagnosticsProperty<CachedDataProgress>(
        'CachedDataProgress', _progressData));
  }

  bool targetLoaded = false;
  static const Animation<double> _kOpaqueAnimation =
      AlwaysStoppedAnimation<double>(1.0);

  // These ProxyAnimations are changed to the fade in animation by
  // [_AnimatedFadeOutFadeInState]. Otherwise these animations are reset to
  // their defaults by [_resetAnimations].
  final ProxyAnimation _imageAnimation = ProxyAnimation(_kOpaqueAnimation);
  final ProxyAnimation _placeholderAnimation =
      ProxyAnimation(_kOpaqueAnimation);

  Image _image(
          {required ImageProvider image,
          ImageErrorWidgetBuilder? errorBuilder,
          ImageFrameBuilder? frameBuilder,
          BoxFit? fit,
          required FilterQuality filterQuality,
          required Animation<double> opacity,
          Widget Function(BuildContext, Widget, ImageChunkEvent?)?
              loadingBuilder,
          String? semanticLabel,
          Color? color,
          BlendMode? colorBlendMode}) =>
      Image(
        image: image,
        opacity: opacity,
        color: color,
        fit: fit,
        semanticLabel: semanticLabel,
        loadingBuilder: loadingBuilder,
        errorBuilder: errorBuilder,
        frameBuilder: frameBuilder,
        colorBlendMode: colorBlendMode,
        width: widget.width,
        height: widget.height,
        alignment: widget.alignment,
        matchTextDirection: widget.matchTextDirection,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        filterQuality: filterQuality,
      );
  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.loadingBuilder != null && _progressData.isDownloading) {
      return widget.loadingBuilder!(context, _progressData);
    } else if (_imageInfo == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
      );
    } else {
      if (_imageInfo!.hasError) {
        final stack = StackTrace.fromString(_imageInfo!.errorMsg!);
        if (widget.errorBuilder != null) {
          return widget.errorBuilder!(context, _imageInfo!.errorMsg!, stack);
        }
        if (kDebugMode) {
          return _debugBuildErrorWidget(context, _imageInfo!.errorMsg!);
        }
      }
      var kPlaceholder = ResizeImage.resizeIfNeeded(
          widget.width?.toInt(),
          widget.height?.toInt(),
          MemoryImage(kTransparent, scale: widget.scale));

      var image = MemoryImage(_imageInfo!.bytes!, scale: widget.scale);

      var hasNoFade = (widget.fadeInDuration == Duration.zero ||
          widget.fadeOutDuration == Duration.zero);
      Widget result = _image(
        image: image,
        fit: widget.fit,
        color: widget.color,
        opacity: _imageAnimation,
        errorBuilder: widget.errorBuilder,
        filterQuality: widget.filterQuality,
        colorBlendMode: widget.colorBlendMode,
        semanticLabel: widget.semanticLabel,
        frameBuilder: hasNoFade || hasCached
            ? null
            : (BuildContext context, Widget child, int? frame,
                bool wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) {
                  targetLoaded = true;
                }
                return _AnimatedFadeOutFadeIn(
                  target: child,
                  targetProxyAnimation: _imageAnimation,
                  placeholder: _image(
                    image: widget.placeholder ?? kPlaceholder,
                    errorBuilder: widget.placeholderErrorBuilder,
                    opacity: _placeholderAnimation,
                    fit: widget.placeholderFit ?? widget.fit,
                    filterQuality:
                        widget.placeholderFilterQuality ?? widget.filterQuality,
                  ),
                  isTargetLoaded: targetLoaded,
                  placeholderProxyAnimation: _placeholderAnimation,
                  wasSynchronouslyLoaded: wasSynchronouslyLoaded,
                  fadeInDuration: widget.fadeInDuration,
                  fadeOutDuration: widget.fadeOutDuration,
                  fadeInCurve: widget.fadeInCurve,
                  fadeOutCurve: widget.fadeOutCurve,
                );
              },
      );

      if (!widget.excludeFromSemantics) {
        result = Semantics(
          container: widget.semanticLabel != null,
          image: true,
          label: widget.semanticLabel ?? '',
          child: result,
        );
      }
      return result;
    }
  }

  Future<(Uint8List? bytes, String? error)> _downloadImageAndUpdateProgress(
      String url) async {
    //set is downloading flag to true
    _progressData.isDownloading = true;
    if (mounted) setState(() {});
    if (widget.loadingBuilder != null) {
      widget.loadingBuilder!(context, _progressData);
    }

    void onReceiveProgress(received, total) {
      if (received < 0 || total < 0) return;
      if (widget.loadingBuilder != null) {
        _progressData.downloadedBytes = received;
        _progressData.totalBytes = total;
        _progressData.progressPercentage.value =
            double.parse((received / total).toStringAsFixed(2));
        widget.loadingBuilder!(context, _progressData);
      }
    }

    Response? responseTemp;
    Uint8List? bytesResponse;

    FutureOr<Response> responseFunction(
      Response resp,
      void Function(int, int) onProgress,
    ) async {
      bytesResponse = widget.response != null
          ? await widget.response!(resp.data, onProgress)
          : resp.data;
      responseTemp = resp;
      return resp;
    }

    try {
      downloadManage.download(DownloadObject(
          url: url,
          headers: widget.headers,
          onReceiveProgress: onReceiveProgress,
          response: responseFunction,
          responseType: ResponseType.values.byName(widget.responseType.name)));
      await waitForResponse(() => responseTemp == null);

      final response = responseTemp!;
      final bytes = bytesResponse!;

      _progressData.isDownloading = false;
      if (response.statusCode != 200) {
        var msg = '${response.statusCode}: ${response.statusMessage}';
        return (null, msg);
      } else if (response.data.isEmpty && mounted) {
        return (null, 'Image is empty.');
      }
      return (bytes, null);
    } catch (e) {
      return (null, '$e');
    }
  }

  Future<void> waitForResponse(bool Function() value) async {
    while (value()) {
      await Future.delayed(
          const Duration(milliseconds: 10)); // Adjust the delay as needed
    }
  }

  String get _getToken {
    var url = _urlCleaner(widget.url);
    var ext = url.substring(url.lastIndexOf('.') + 1);
    return '${sha256.convert(url.codeUnits)}.$ext';
  }

  String _urlCleaner(String url) {
    int x = url.lastIndexOf('?');
    return x == -1 ? url : url.substring(0, x);
  }
}
