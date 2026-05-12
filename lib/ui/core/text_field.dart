import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';

class TextField extends StatefulWidget {
  final TextEditingController controller;
  final double width;
  final String? labelText;
  final String? errorText;

  const TextField({
    super.key,
    required this.controller,
    this.width = 300,
    this.labelText,
    this.errorText,
  });

  @override
  State<StatefulWidget> createState() => _TextFieldState();
}

class _TextFieldState extends State<TextField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  late final FocusNode _focusNode;

  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  late _TextSelectionGestureDetectorBuilder _selectionGestureDetectorBuilder;

  @override
  bool get forcePressEnabled => true;

  @override
  bool get selectionEnabled => true;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _selectionGestureDetectorBuilder = _TextSelectionGestureDetectorBuilder(
      state: this,
    );
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _requestKeyboard() {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
    editableTextKey.currentState?.requestKeyboard();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        TextFieldTapRegion(
          child: _selectionGestureDetectorBuilder.buildGestureDetector(
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _backgroundColor,
                border: Border.all(color: _borderColor, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(milliseconds: 150),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  if (widget.labelText != null)
                    ValueListenableBuilder(
                      valueListenable: widget.controller,
                      builder: (context, value, child) {
                        if (value.text.isNotEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          widget.labelText!,
                          style: AppText.defaultTheme.bodySmall.copyWith(
                            color: AppColors.dark.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  EditableText(
                    key: editableTextKey,
                    enableInteractiveSelection: true,
                    selectAllOnFocus: false,
                    rendererIgnoresPointer: true,
                    controller: widget.controller,
                    focusNode: _focusNode,
                    style: AppText.defaultTheme.bodySmall.copyWith(
                      color: AppColors.dark.onSurface,
                    ),
                    cursorColor: _cursorColor,
                    selectionColor: AppColors.dark.secondary,
                    backgroundCursorColor: AppColors.dark.primary,
                    onTapOutside: (_) => _focusNode.unfocus(),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: EdgeInsetsGeometry.only(left: 4),
            child: Text(
              widget.errorText!,
              style: AppText.defaultTheme.caption.copyWith(
                color: AppColors.dark.error,
              ),
            ),
          ),
      ],
    );
  }

  Color get _backgroundColor => AppColors.dark.surfaceContainerHigh;

  Color get _cursorColor => AppColors.dark.onSurface;

  void _handleFocusChange() {
    setState(() {});
  }

  Color get _borderColor {
    if (widget.errorText != null) {
      return AppColors.dark.error;
    } else if (_focusNode.hasFocus) {
      return AppColors.dark.primary;
    } else {
      return AppColors.transparent;
    }
  }
}

class _TextSelectionGestureDetectorBuilder
    extends TextSelectionGestureDetectorBuilder {
  _TextSelectionGestureDetectorBuilder({required _TextFieldState state})
    : _state = state,
      super(delegate: state);

  final _TextFieldState _state;

  @override
  void onSingleTapUp(TapDragUpDetails details) {
    super.onSingleTapUp(details);
    _state._requestKeyboard();
  }

  @override
  void onDragSelectionStart(TapDragStartDetails details) {
    super.onDragSelectionStart(details);
    _state._requestKeyboard();
  }
}
