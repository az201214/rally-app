import 'package:flutter/material.dart';

import 'rally_text_field.dart';

/// Password input with a built-in visibility toggle.
class PasswordTextField extends StatefulWidget {
  const PasswordTextField({
    this.controller,
    this.focusNode,
    this.validator,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    super.key,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FormFieldValidator<String>? validator;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _isObscured = true;

  void _toggleVisibility() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RallyTextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      validator: widget.validator,
      labelText: widget.labelText,
      hintText: widget.hintText,
      prefixIcon: widget.prefixIcon,
      obscureText: _isObscured,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      suffixIcon: IconButton(
        onPressed: _toggleVisibility,
        icon: Icon(
          _isObscured ? Icons.visibility_rounded : Icons.visibility_off_rounded,
        ),
      ),
    );
  }
}
