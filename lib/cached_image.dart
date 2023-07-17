library cached_image;

// ignore_for_file: non_constant_identifier_names
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui' as ui;
import 'src/storage/cached_storage.dart';
import 'package:logs/logs.dart';

export 'src/storage/cached_storage.dart' show CachedStorage;

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
  }) : super(key: key);
  @override
  State<CachedImage> createState() => _CachedImageState();

  static const _password = 'password.cached_images';
  static const _key = 'key.cached_images';

  static final CachedStorage CachedManager = CachedStorage(_password, _key);

  static Future<void> open() async => CachedManager.openCachedBox();

  static Future<void> close() => CachedManager.close();

  static Future<void> clear() => CachedManager.clear();

  static Future<Uint8List?> getImage(String key) async =>
      await CachedManager.read(key);

  /// If the key is present, invokes [update] with the
  /// current Uint8List and stores the new Uint8List in the map.
  static void addNewImages(Map<String, Uint8List> map) =>
      CachedManager.write(map);

  static Future<void> removeImages(List<String> keys) =>
      CachedManager.delete(keys);
}

class _CachedImageState extends State<CachedImage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final Logs logs = Logs('CachedImage');
  @override
  bool get wantKeepAlive => true;
  _ImageInfo? _imageInfo;
  final CachedDataProgress _progressData = CachedDataProgress();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) => _loadTaskAsync(),
    );
  }

  ///[_loadTaskAsync] Not public API.
  FutureOr<void> _loadTaskAsync() async {
    await CachedImage.open();
    _imageInfo = await _loadImage(widget.url);
    if (mounted) setState(() {});
  }

  ///[_loadImage] Not public API.
  Future<_ImageInfo> _loadImage(url) async {
    final bytes = await CachedImage.getImage(url);
    if (bytes != null) {
      return _byteToImage(bytes);
    } else {
      final downloadResp = await _downloadImageAndUpdateProgress(url);
      if (downloadResp.$1 != null && downloadResp.$2 == null) {
        CachedImage.addNewImages({url: downloadResp.$1!});
        return _byteToImage(downloadResp.$1!);
      } else {
        return _ImageInfo.error(downloadResp.$2);
      }
    }
  }

  ///[_byteToImage] Not public API.
  Future<_ImageInfo> _byteToImage(Uint8List byte) async {
    try {
      final buffer = await ImmutableBuffer.fromUint8List(byte);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final codec = await descriptor.instantiateCodec();
      ui.FrameInfo frameInfo = await codec.getNextFrame();
      if (mounted) {
        buffer.dispose();
        descriptor.dispose();
        codec.dispose();
      }
      return _ImageInfo.image(frameInfo.image);
    } catch (e) {
      return _ImageInfo.error('$e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_imageInfo == null) {
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
      Widget result = RawImage(
        image: _imageInfo!.image,
        width: widget.width,
        height: widget.height,
        scale: widget.scale,
        color: widget.color,
        opacity: widget.opacity,
        colorBlendMode: widget.colorBlendMode,
        fit: widget.fit,
        alignment: widget.alignment,
        repeat: widget.repeat,
        centerSlice: widget.centerSlice,
        matchTextDirection: widget.matchTextDirection,
        isAntiAlias: widget.isAntiAlias,
        filterQuality: widget.filterQuality,
      );
      if (!widget.excludeFromSemantics) {
        result = Semantics(
          container: widget.semanticLabel != null,
          image: true,
          label: widget.semanticLabel ?? '',
          child: result,
        );
      }
      if (widget.loadingBuilder != null) {
        result = widget.loadingBuilder!(context, _progressData);
      }

      return result;
    }
  }

  Future<(Uint8List? bytes, String? error)> _downloadImageAndUpdateProgress(
      String url) async {
    try {
      //set is downloading flag to true
      _progressData.isDownloading = true;
      if (widget.loadingBuilder != null) {
        widget.loadingBuilder!(context, _progressData);
      }

      Dio dio = Dio();
      Response response = await dio
          .get(url, options: Options(responseType: ResponseType.bytes),
              onReceiveProgress: (received, total) {
        if (received < 0 || total < 0) return;
        if (widget.loadingBuilder != null) {
          _progressData.downloadedBytes = received;
          _progressData.totalBytes = total;
          _progressData.progressPercentage.value =
              double.parse((received / total).toStringAsFixed(2));
          widget.loadingBuilder!(context, _progressData);
        }
      });
      _progressData.isDownloading = false;
      final Uint8List bytes = response.data;
      if (response.statusCode != 200) {
        var msg = '${response.statusCode}: ${response.statusMessage}';
        logs.severeError(msg);
        return (null, msg);
      } else if (response.data.isEmpty && mounted) {
        logs.severeError('Image is empty.');
        return (null, 'Image is empty.');
      }
      return (bytes, null);
    } catch (e) {
      logs.severeError('$e');
      return (null, '$e');
    }
  }
}

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
  final ui.Image? image;
  final String? errorMsg;
  const _ImageInfo.image(this.image) : errorMsg = null;
  const _ImageInfo.error(this.errorMsg) : image = null;

  bool get hasError => errorMsg != null && image == null;
  bool get hasBytes => errorMsg == null && image != null;
}
