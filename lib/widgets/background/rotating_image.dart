import 'package:flutter/material.dart';

class RotatingImage extends StatefulWidget {
  final String assetPath;
  final Duration duration;
  final double scale;
  final bool reverse;

  const RotatingImage({
    super.key,
    required this.assetPath,
    required this.duration,
    this.scale = 1.0,
    this.reverse = false,
  });

  @override
  State<RotatingImage> createState() => _RotatingImageState();
}

class _RotatingImageState extends State<RotatingImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void didUpdateWidget(RotatingImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double angle = _controller.value * 2 * 3.14159;
            return Transform.rotate(
              angle: widget.reverse ? -angle : angle,
              child: Transform.scale(scale: widget.scale, child: child!),
            );
          },
          child: Image.asset(widget.assetPath, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
