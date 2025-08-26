import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class AppDropdown2<T> extends StatelessWidget {
  final List<T> items;
  final String Function(T) labelOf;
  final T? value;
  final ValueChanged<T?>? onChanged;

  final String? label;      // Input label
  final String? hint;       // Placeholder
  final String? errorText;  // For validation

  final Widget? leadingIcon; // left icon inside field
  final Widget? actionIcon;  // trailing icon (e.g., delete/remove)
  final VoidCallback? onAction;

  final bool isExpanded;
  final double borderRadius;
  final double dropdownMaxHeight;

  const AppDropdown2({
    super.key,
    required this.items,
    required this.labelOf,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.errorText,
    this.leadingIcon,
    this.actionIcon,
    this.onAction,
    this.isExpanded = true,
    this.borderRadius = 30,
    this.dropdownMaxHeight = 300,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: theme.dividerColor, width: 1),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
    );

    // We wrap the field and the trailing action button in a Row
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField2<T>(
            value: value,
            isExpanded: isExpanded,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              errorText: errorText,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: leadingIcon,
              border: inputBorder,
              enabledBorder: inputBorder,
              focusedBorder: focusedBorder,
            ),
            items: items
                .map((e) => DropdownMenuItem<T>(
              value: e,
              child: Text(labelOf(e), overflow: TextOverflow.ellipsis),
            ))
                .toList(),
            onChanged: onChanged,
            buttonStyleData: const ButtonStyleData(
              padding: EdgeInsets.zero,
              height: 30,
            ),
            iconStyleData: const IconStyleData(
              iconEnabledColor: null,
              iconSize: 18,
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: dropdownMaxHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              offset: const Offset(0, -2),
            ),
            menuItemStyleData: const MenuItemStyleData(
              height: 44,
              padding: EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),

        if (actionIcon != null) ...[
          const SizedBox(width: 8),
          Tooltip(
            message: 'Action',
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: actionIcon,
              ),
            ),
          ),
        ],
      ],
    );
  }
}