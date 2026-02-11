import 'package:flutter/material.dart';
import '../constants/sizes.dart';

class TransferContentAnimator extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const TransferContentAnimator({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<TransferContentAnimator> createState() =>
      _TransferContentAnimatorState();
}

class _TransferContentAnimatorState extends State<TransferContentAnimator>
    with SingleTickerProviderStateMixin {
  late Widget _currentChild;
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  // We need to keep the "old" child visible during fade out
  // But actually, we want the CURRENT child to fade out, THEN switch, THEN fade in.

  int _currentOperationId = 0;

  @override
  void initState() {
    super.initState();
    _currentChild = widget.child;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.value = 1.0; // Start fully visible
  }

  @override
  void didUpdateWidget(covariant TransferContentAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger transition only if the child key changes (e.g. switching tabs)
    if (widget.child.key != oldWidget.child.key) {
      _triggerTransition(widget.child);
    } else {
      // FIX: If key is the same (e.g. loading state changed), update content immediately
      // This ensures visual updates within the same page are not ignored.
      _currentChild = widget.child;
    }
  }

  Future<void> _triggerTransition(Widget nextChild) async {
    if (!mounted) return;

    // Increment operation ID to identify this specific transition request
    final int opId = ++_currentOperationId;

    // 1. FADE OUT
    // If controller is already reversing, this just joins the ride.
    // If it was forwarding, it reverses from current point.
    await _controller.reverse();

    // Check if this operation is still the latest one
    if (!mounted || opId != _currentOperationId) return;

    // 2. CHANGE CHILD
    setState(() {
      _currentChild = widget.child;
    });

    // 3. WAIT FOR RESIZE
    await Future.delayed(widget.duration);

    if (!mounted || opId != _currentOperationId) return;

    // 4. FADE IN
    await _controller.forward();

    // Only clear transitioning flag if we are still the latest operation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: widget.duration,
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: UiSizes.cardInnerPadding,
          ),
          // We wrap _currentChild to ensure layout constraints are passed down
          // Key is crucial for framework to differentiate widgets if needed,
          // but here we rely on _currentChild's internal key.
          child: _currentChild,
        ),
      ),
    );
  }
}
