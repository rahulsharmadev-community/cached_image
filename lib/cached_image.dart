library cached_image;

import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:cached_image/logic/cached_prefrences.dart';
import 'package:cached_image/model/cache_data_model.dart';
import 'package:flutter/widgets.dart';

class CachedImage extends StatefulWidget {
  final Uri uri;

  final double scale;

  final ImageFrameBuilder? frameBuilder;

  final ImageErrorWidgetBuilder? errorBuilder;

  final double? width;

  final double? height;

  final Color? color;

  final Animation<double>? opacity;

  final FilterQuality filterQuality;

  final BlendMode? colorBlendMode;

  final BoxFit? fit;

  final AlignmentGeometry alignment;

  final ImageRepeat repeat;

  final Rect? centerSlice;

  final bool matchTextDirection;

  final bool gaplessPlayback;

  final String? semanticLabel;

  final bool excludeFromSemantics;

  final bool isAntiAlias;
  CachedImage(
    String src, {
    Key? key,
    this.scale = 1.0,
    this.frameBuilder,
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
    this.gaplessPlayback = false,
    this.isAntiAlias = false,
    this.filterQuality = FilterQuality.low,
  })  : uri = Uri.parse(src),
        super(key: key);

  @override
  State<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends State<CachedImage> {
  bool isLoading = false;
  late final CacheDataModel cachedImage;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _featchFromCache();
  }

  Future<void> _featchFromCache() async {
    if (await CachedPreferences.init()) {
      try {
        cachedImage = CachedPreferences.when(widget.uri.toString());
        log('Image Found: 200');
        CachedPreferences.update(
            cachedImage.copyWith(expireAt: _nextExpireDate));
        isLoading = true;
      } on StateError catch (_) {
        log('Image Not Found: 404');
        cachedImage = CacheDataModel(
            key: widget.uri.toString(),
            rawImage: (await _imageUint8List(widget.uri)),
            expireAt: _nextExpireDate);
        await CachedPreferences.add(cachedImage);
        isLoading = true;
      }
    }
    if (mounted) setState(() {});
  }

  DateTime get _nextExpireDate => DateTime.now().add(const Duration(days: 30));

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? _buildImage(Uint8List.fromList(cachedImage.rawImage))
        : const Offstage();
  }

  Image _buildImage(Uint8List bytes) => Image.memory(bytes,
      scale: widget.scale,
      frameBuilder: widget.frameBuilder,
      errorBuilder: widget.errorBuilder,
      semanticLabel: widget.semanticLabel,
      excludeFromSemantics: widget.excludeFromSemantics,
      width: widget.width,
      height: widget.height,
      color: widget.color,
      opacity: widget.opacity,
      colorBlendMode: widget.colorBlendMode,
      fit: widget.fit,
      alignment: widget.alignment,
      repeat: widget.repeat,
      centerSlice: widget.centerSlice,
      matchTextDirection: widget.matchTextDirection,
      gaplessPlayback: widget.gaplessPlayback,
      isAntiAlias: widget.isAntiAlias,
      filterQuality: widget.filterQuality);

  Future<List<int>> _imageUint8List(Uri uri) async {
    try {
      return List.from((await http.get(uri)).bodyBytes);
    } on HttpException catch (_) {
      throw 'Http Response Error';
    }
  }
}
