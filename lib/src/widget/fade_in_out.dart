part of '../../cached_image.dart';

class _AnimatedFadeOutFadeIn extends ImplicitlyAnimatedWidget {
  const _AnimatedFadeOutFadeIn({
    required this.target,
    required this.targetProxyAnimation,
    required this.placeholder,
    required this.placeholderProxyAnimation,
    required this.isTargetLoaded,
    required this.fadeOutDuration,
    required this.fadeOutCurve,
    required this.fadeInDuration,
    required this.fadeInCurve,
    required this.wasSynchronouslyLoaded,
  })  : assert(!wasSynchronouslyLoaded || isTargetLoaded),
        super(duration: fadeInDuration + fadeOutDuration);

  final Widget target;
  final ProxyAnimation targetProxyAnimation;
  final Widget placeholder;
  final ProxyAnimation placeholderProxyAnimation;
  final bool isTargetLoaded;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final Curve fadeInCurve;
  final Curve fadeOutCurve;
  final bool wasSynchronouslyLoaded;

  @override
  _AnimatedFadeOutFadeInState createState() => _AnimatedFadeOutFadeInState();
}

class _AnimatedFadeOutFadeInState
    extends ImplicitlyAnimatedWidgetState<_AnimatedFadeOutFadeIn> {
  Tween<double>? _targetOpacity;
  Tween<double>? _placeholderOpacity;
  Animation<double>? _targetOpacityAnimation;
  Animation<double>? _placeholderOpacityAnimation;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _targetOpacity = visitor(
      _targetOpacity,
      widget.isTargetLoaded ? 1.0 : 0.0,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
    _placeholderOpacity = visitor(
      _placeholderOpacity,
      widget.isTargetLoaded ? 0.0 : 1.0,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  void didUpdateTweens() {
    if (widget.wasSynchronouslyLoaded) {
      // Opacity animations should not be reset if image was synchronously loaded.
      return;
    }

    _placeholderOpacityAnimation =
        animation.drive(TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween:
            _placeholderOpacity!.chain(CurveTween(curve: widget.fadeOutCurve)),
        weight: widget.fadeOutDuration.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(0),
        weight: widget.fadeInDuration.inMilliseconds.toDouble(),
      ),
    ]))
          ..addStatusListener((AnimationStatus status) {
            if (_placeholderOpacityAnimation!.isCompleted) {
              // Need to rebuild to remove placeholder now that it is invisible.
              setState(() {});
            }
          });

    _targetOpacityAnimation =
        animation.drive(TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(0),
        weight: widget.fadeOutDuration.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem<double>(
        tween: _targetOpacity!.chain(CurveTween(curve: widget.fadeInCurve)),
        weight: widget.fadeInDuration.inMilliseconds.toDouble(),
      ),
    ]));

    widget.targetProxyAnimation.parent = _targetOpacityAnimation;
    widget.placeholderProxyAnimation.parent = _placeholderOpacityAnimation;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.wasSynchronouslyLoaded ||
        (_placeholderOpacityAnimation?.isCompleted ?? true)) {
      return widget.target;
    }

    return Stack(
      fit: StackFit.passthrough,
      alignment: AlignmentDirectional.center,
      // Text direction is irrelevant here since we're using center alignment,
      // but it allows the Stack to avoid a call to Directionality.of()
      textDirection: TextDirection.ltr,
      children: <Widget>[
        widget.target,
        widget.placeholder,
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Animation<double>>(
        'targetOpacity', _targetOpacityAnimation));
    properties.add(DiagnosticsProperty<Animation<double>>(
        'placeholderOpacity', _placeholderOpacityAnimation));
  }
}
