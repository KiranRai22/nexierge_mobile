import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shimmer effect — sliding diagonal gradient on a neutral block.
///
/// Mirrors the dashboard loading style so every screen converges on a
/// single skeleton language. Dark-mode aware via the ambient [Theme].
class ShimmerWidget extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const ShimmerWidget({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final baseColor = widget.baseColor ?? c.shimmerBase;
    final highlightColor = widget.highlightColor ?? c.shimmerHighlight;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(percent: _animation.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double percent;

  const _SlidingGradientTransform({required this.percent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * percent, 0, 0);
  }
}

/// Rectangular shimmer block.
class ShimmerContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Widget? child;

  const ShimmerContainer({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.margin,
    this.padding,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerWidget(
      child: Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: context.appColors.shimmerBase,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: child,
      ),
    );
  }
}

/// Circular shimmer block — for avatars and round icons.
class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return ShimmerWidget(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: context.appColors.shimmerBase,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Single shimmer text line.
class ShimmerText extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerText({
    super.key,
    this.width = 100,
    this.height = 16,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerWidget(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.appColors.shimmerBase,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
