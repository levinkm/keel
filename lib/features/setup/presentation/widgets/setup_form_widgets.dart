import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keel/core/theme/app_colors.dart';

class SetupColHeader extends StatelessWidget {
  final String text;
  const SetupColHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextTertiary,
          letterSpacing: 0.3,
        ),
      );
}

class SetupField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  const SetupField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );
}

class SetupDropdown<T> extends StatefulWidget {
  final T value;
  final List<(T, String)> items;
  final VoidCallback onChanged;
  final ValueChanged<T> onSelect;

  const SetupDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.onSelect,
  });

  @override
  State<SetupDropdown<T>> createState() => _SetupDropdownState<T>();
}

class _SetupDropdownState<T> extends State<SetupDropdown<T>> {
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: _value,
      isDense: true,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: widget.items
          .map((e) => DropdownMenuItem(
                value: e.$1,
                child: Text(e.$2, style: const TextStyle(fontSize: 13)),
              ))
          .toList(),
      onChanged: (v) {
        if (v == null) return;
        setState(() => _value = v);
        widget.onSelect(v);
        widget.onChanged();
      },
    );
  }
}
