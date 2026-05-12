import 'package:flutter/cupertino.dart';
import 'package:yelauncher/ui/core/text_field.dart';

class TextFormField extends FormField<String> {
  final TextEditingController controller;
  final String labelText;

  TextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    super.validator,
    super.autovalidateMode,
  }) : super(
         builder: (FormFieldState<String> field) {
           final _TextFormFieldState state = field as _TextFormFieldState;
           return TextField(
             controller: state._effectiveController,
             errorText: state.errorText,
             labelText: labelText,
           );
         },
       );

  @override
  FormFieldState<String> createState() => _TextFormFieldState();
}

class _TextFormFieldState extends FormFieldState<String> {
  TextEditingController get _effectiveController => _textFormField.controller;

  TextFormField get _textFormField => super.widget as TextFormField;

  @override
  void initState() {
    super.initState();
    _textFormField.controller.addListener(_handleControllerChanged);
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    if (_effectiveController.text != value) {
      didChange(_effectiveController.text);
    }
  }

  @override
  void dispose() {
    _textFormField.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  @override
  void reset() {
    super.reset();
    setState(() {
      _effectiveController.text = widget.initialValue ?? '';
    });
  }
}
