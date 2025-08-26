import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

/// Searchable, rounded dropdown for dropdown_search 6.0.2
/// - Local list OR server search
/// - Optional trailing action icon (e.g., remove)
/// - "Add "<query>"" when search has no matches (calls onAddNew and selects)
class AppDropdownSearch<T> extends StatelessWidget {
  /// Provide either a local list (localItems) or a server search (onFind).
  final List<T>?
  localItems; // local source (we'll filter by labelOf + search text)
  final Future<List<T>> Function(String filter, LoadProps? lp)?
  onFind; // server

  final String Function(T) labelOf;
  final T? value;
  final ValueChanged<T?>? onChanged;

  final String? label;
  final String? hint;
  final Widget? leadingIcon;

  // Trailing action (e.g., delete row)
  final Widget? actionIcon;
  final VoidCallback? onAction;

  /// When no results: show "Add "<query>"". Return created item (T) to select it (or null on failure).
  final Future<T?> Function(String query)? onAddNew;

  final double borderRadius;
  final double popupMaxHeight;
  final bool enabled;

  const AppDropdownSearch({
    super.key,
    required this.labelOf,
    required this.value,
    required this.onChanged,
    this.localItems,
    this.onFind,
    this.label,
    this.hint,
    this.leadingIcon,
    this.actionIcon,
    this.onAction,
    this.onAddNew,
    this.borderRadius = 14,
    this.popupMaxHeight = 220,
    this.enabled = true,
  });

  OutlineInputBorder _border(
    BuildContext ctx, {
    Color? color,
    double width = 1,
  }) {
    final theme = Theme.of(ctx);
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: color ?? theme.dividerColor, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Build the items provider function required by 6.0.2
    final DropdownSearchOnFind<T>? provider = (onFind != null)
        ? (String filter, LoadProps? lp) => onFind!(filter, lp)
        : (localItems != null)
        ? (String filter, LoadProps? _) async {
            final q = (filter).trim().toLowerCase();
            if (q.isEmpty) return localItems!;
            return localItems!
                .where((e) => labelOf(e).toLowerCase().contains(q))
                .toList();
          }
        : null;

    final field = DropdownSearch<T>(
      key: ValueKey(label), // helps rebuild decoration when used repeatedly
      selectedItem: value,
      items: provider, // ✅ function as required by 6.0.2
      itemAsString: (t) => labelOf(t),
      compareFn: (a, b) => labelOf(a) == labelOf(b),
      onChanged: onChanged,
      enabled: enabled,
      suffixProps: DropdownSuffixProps(
        dropdownButtonProps: const DropdownButtonProps(
          iconClosed: Icon(Icons.keyboard_arrow_down_rounded),
          iconOpened: Icon(Icons.keyboard_arrow_up_rounded),
        ),
        clearButtonProps: const ClearButtonProps(isVisible: false),
      ),
      // Rounded input decoration (matches your dropdown2 look)
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: leadingIcon,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: _border(context),
          enabledBorder: _border(context),
          focusedBorder: _border(
            context,
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
      ),

      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchDelay: Duration.zero,
        fit: FlexFit.loose,
        constraints: BoxConstraints(maxHeight: popupMaxHeight),
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search or type to add…',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        itemBuilder: (ctx, item, isDisabled, isSelected) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(labelOf(item), overflow: TextOverflow.ellipsis),
        ),

        // When there are no matches, offer to add the typed text
        emptyBuilder: (ctx, searchEntry) {
          final q = (searchEntry).trim();
          if (q.isEmpty || onAddNew == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: _AddTile(
              label: 'Add "$q"',
              onTap: () async {
                final created = await onAddNew!(q);
                if (created != null) {
                  onChanged?.call(created);
                  Navigator.of(ctx).maybePop(); // close the popup
                }
              },
            ),
          );
        },
      ),
    );

    if (actionIcon == null) return field;

    // Attach trailing action icon (e.g., remove row), keeping the same UI as before
    return Row(
      children: [
        Expanded(child: field),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Remove',
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onAction,
            child: Padding(padding: const EdgeInsets.all(8), child: actionIcon),
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.add, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(label)),
            ],
          ),
        ),
      ),
    );
  }
}
