import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// A text field with its label above it ("Pole tekstowe" in the design).
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.enabled = true,
    this.textAlign = TextAlign.start,
    this.suffixText,
    this.fieldKey,
    this.autofillHints,
    this.inputFormatters,
    this.textInputAction,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool enabled;
  final TextAlign textAlign;
  final String? suffixText;
  final Key? fieldKey;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          key: fieldKey,
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          autofocus: autofocus,
          enabled: enabled,
          textAlign: textAlign,
          autofillHints: autofillHints,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction,
          style: TextStyle(fontSize: 16, height: 1.5, color: c.text),
          decoration: InputDecoration(hintText: hint, suffixText: suffixText),
        ),
      ],
    );
  }
}

/// The small bold label above a field or a group of chips ("Etykieta").
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.of(context).textSoft,
      ),
    );
  }
}

/// An upper-case caption above a section ("Nadtytuł").
class Overline extends StatelessWidget {
  const Overline(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: Theme.of(context).textTheme.labelSmall);
}

/// A label on the left and a value on the right, e.g. "Data   Dziś, 25.11".
class ValueRow extends StatelessWidget {
  const ValueRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.strong = false,
    this.small = false,
    this.onTap,
    this.divided = false,
  });

  final String label;
  final String value;
  final Color? valueColor;

  /// Both texts bold, for a total.
  final bool strong;

  /// The muted 14 px label and 13 px value of a summary.
  final bool small;
  final VoidCallback? onTap;

  /// Hairlines above and below, as a row of a form.
  final bool divided;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final labelStyle = strong
        ? TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.text)
        : small
        ? TextStyle(fontSize: 14, height: 1.45, color: c.textMuted)
        : TextStyle(fontSize: 15, height: 1.5, color: c.textSoft);
    final valueStyle = TextStyle(
      fontSize: small ? 13 : 15,
      fontWeight: FontWeight.w600,
      color: valueColor ?? c.text,
    );
    Widget row = Row(
      children: [
        Expanded(child: Text(label, style: labelStyle)),
        const SizedBox(width: 12),
        Text(value, style: valueStyle),
      ],
    );
    if (divided) {
      row = Container(
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          border: Border.symmetric(horizontal: BorderSide(color: c.border)),
        ),
        alignment: Alignment.center,
        child: row,
      );
    }
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}
