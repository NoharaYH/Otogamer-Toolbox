import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';
import '../constants/strings.dart';
import '../kit_shared/kit_animation_engine.dart';
import '../kit_shared/kit_bounce_scaler.dart';
import '../kit_shared/confirmation_box.dart';

class ScoreSyncTokenField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback? onChanged;
  final Function(String)? onPasteConfirmed;
  final bool isDisabled;

  const ScoreSyncTokenField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onPasteConfirmed,
    this.isDisabled = false,
  });

  @override
  State<ScoreSyncTokenField> createState() => _ScoreSyncTokenFieldState();
}

class _ScoreSyncTokenFieldState extends State<ScoreSyncTokenField>
    with SingleTickerProviderStateMixin {
  bool _showToken = false;
  String? _currentClipboard;

  late AnimationController _pasteBoxController;
  late Animation<double> _sizeFactor;
  late Animation<double> _opacityFactor;

  @override
  void initState() {
    super.initState();
    _pasteBoxController = AnimationController(
      vsync: this,
      duration: KitAnimationEngine.expandDuration,
      reverseDuration: KitAnimationEngine.collapseDuration,
    );

    _sizeFactor = CurvedAnimation(
      parent: _pasteBoxController,
      curve: KitAnimationEngine.decelerateCurve,
      reverseCurve: KitAnimationEngine.accelerateCurve,
    );

    // Fade in starts after size reaches 30% (0.3), finishes at 100% (1.0).
    // During reverse, it fades out completely before size shrinks back to 30%.
    _opacityFactor = CurvedAnimation(
      parent: _pasteBoxController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      reverseCurve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _pasteBoxController.dispose();
    super.dispose();
  }

  void _showPasteBox(String text) {
    setState(() => _currentClipboard = text);
    _pasteBoxController.forward();
  }

  void _hidePasteBox() {
    _pasteBoxController.reverse().then((_) {
      if (mounted && _pasteBoxController.isDismissed) {
        setState(() => _currentClipboard = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = widget.controller.text.isNotEmpty;
    final bgColor = hasContent ? UiColors.grey100 : UiColors.grey300;

    return IgnorePointer(
      ignoring: widget.isDisabled,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 150),
        tween: Tween<double>(
          begin: widget.isDisabled ? 1.0 : 0.0,
          end: widget.isDisabled ? 1.0 : 0.0,
        ),
        builder: (context, value, child) {
          return ColorFiltered(
            colorFilter: ColorFilter.mode(
              Color.lerp(UiColors.transparent, UiColors.disabledMask, value)!,
              BlendMode.srcATop,
            ),
            child: child,
          );
        },
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                if (!hasContent) {
                  await _handlePasteWithConfirmation();
                }
              },
              child: Container(
                margin: const EdgeInsets.only(
                  bottom: UiSizes.atomicComponentGap,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border.all(
                    color: UiColors.grey500.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(UiSizes.buttonRadius),
                ),
                padding: const EdgeInsets.only(
                  left: UiSizes.cardContentPadding,
                  top: 4,
                  bottom: 4,
                  right: 4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        obscureText: !_showToken,
                        onChanged: (val) {
                          _hidePasteBox();
                          widget.onChanged?.call();
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: widget.hint,
                          hintStyle: const TextStyle(
                            fontFamily: 'Roboto',
                            color: UiColors.grey600,
                            fontSize: 13,
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0, left: 4.0),
                      child: KitBounceScaler(
                        onTap: () => setState(() => _showToken = !_showToken),
                        child: Icon(
                          _showToken ? Icons.visibility : Icons.visibility_off,
                          color: UiColors.grey500,
                          size: 20,
                        ),
                      ),
                    ),
                    if (hasContent)
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: KitBounceScaler(
                          onTap: () {
                            widget.controller.clear();
                            _hidePasteBox();
                            widget.onChanged?.call();
                          },
                          child: const Icon(
                            Icons.cancel,
                            color: UiColors.grey500,
                            size: 20,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: KitBounceScaler(
                          onTap: _handlePasteWithConfirmation,
                          child: const Icon(
                            Icons.content_paste,
                            color: UiColors.grey500,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizeTransition(
              sizeFactor: _sizeFactor,
              axisAlignment: -1.0, // Top aligned, expands downwards linearly
              child: FadeTransition(
                opacity: _opacityFactor,
                child: Container(
                  margin: const EdgeInsets.only(
                    bottom: UiSizes.atomicComponentGap,
                  ),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: UiColors.white,
                    border: Border.all(
                      color: UiColors.grey500.withValues(alpha: 0.5),
                    ),
                    borderRadius: BorderRadius.circular(UiSizes.buttonRadius),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: UiSizes.atomicComponentGap,
                    horizontal: UiSizes.cardContentPadding,
                  ),
                  child: _currentClipboard != null
                      ? ConfirmationBox(
                          label: const Text(
                            UiStrings.pasteConfirm,
                            style: TextStyle(
                              fontSize: 11,
                              color: UiColors.grey500,
                            ),
                          ),
                          body: Text(
                            _showToken
                                ? _currentClipboard!
                                : '•' * _currentClipboard!.length.clamp(0, 20),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: UiColors.grey800,
                              fontFamily: 'Roboto',
                            ),
                            maxLines: 1,
                            overflow: _showToken
                                ? TextOverflow.ellipsis
                                : TextOverflow.clip,
                          ),
                          onConfirm: () {
                            final textToPaste = _currentClipboard!;
                            _hidePasteBox();
                            widget.controller.text = textToPaste;
                            widget.onPasteConfirmed?.call(textToPaste);
                          },
                          onCancel: _hidePasteBox,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePasteWithConfirmation() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.isNotEmpty) {
      if (!mounted) return;
      _showPasteBox(text);
    }
  }
}
