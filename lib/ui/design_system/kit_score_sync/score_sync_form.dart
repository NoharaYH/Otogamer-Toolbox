import 'package:flutter/material.dart';
import '../constants/sizes.dart';
import '../constants/strings.dart';
import '../kit_shared/confirm_button.dart';
import 'score_sync_token_field.dart';

class ScoreSyncForm extends StatelessWidget {
  final int mode;
  final TextEditingController dfController;
  final TextEditingController lxnsController;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onVerify;
  final VoidCallback? onDfChanged;
  final VoidCallback? onLxnsChanged;
  final Function(String)? onDfPaste;
  final Function(String)? onLxnsPaste;

  const ScoreSyncForm({
    super.key,
    required this.mode,
    required this.dfController,
    required this.lxnsController,
    required this.isLoading,
    this.isDisabled = false,
    required this.onVerify,
    this.onDfChanged,
    this.onLxnsChanged,
    this.onDfPaste,
    this.onLxnsPaste,
  });

  @override
  Widget build(BuildContext context) {
    final needsDf = mode == 0 || mode == 1;
    final needsLxns = mode == 2 || mode == 1;

    return Column(
      key: ValueKey<int>(mode),
      children: [
        SizedBox(height: UiSizes.atomicComponentGap),
        if (needsDf)
          ScoreSyncTokenField(
            controller: dfController,
            hint: UiStrings.inputDivingFishToken,
            onChanged: onDfChanged,
            onPasteConfirmed: onDfPaste,
          ),
        if (needsLxns)
          ScoreSyncTokenField(
            controller: lxnsController,
            hint: UiStrings.inputLxnsToken,
            onChanged: onLxnsChanged,
            onPasteConfirmed: onLxnsPaste,
          ),
        SizedBox(height: UiSizes.atomicComponentGap),
        ConfirmButton(
          text: isDisabled
              ? UiStrings.waitTransferEnd
              : UiStrings.verifyAndSave,
          state: isLoading
              ? ConfirmButtonState.loading
              : ConfirmButtonState.ready,
          borderRadius: UiSizes.buttonRadius,
          onPressed: isDisabled ? null : onVerify,
        ),
      ],
    );
  }
}
