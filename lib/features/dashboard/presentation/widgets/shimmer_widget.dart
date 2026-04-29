import 'package:flutter/material.dart';

/// Shimmer effect widget for loading states
class ShimmerWidget extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerWidget({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        widget.baseColor ??
        (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0));
    final highlightColor =
        widget.highlightColor ??
        (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5));

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

/// Shimmer container with rounded corners
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ShimmerWidget(
      child: Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: child,
      ),
    );
  }
}

/// Shimmer circle (for avatars)
class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ShimmerWidget(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Shimmer text line (for titles, subtitles)
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ShimmerWidget(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
