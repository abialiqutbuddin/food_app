import 'package:flutter/material.dart';

class MenuPick {
  String? name;
  double? price;
  MenuPick({this.name, this.price});
}

class MenuDropdownList extends StatefulWidget {
  final List<String> options;
  final bool showPricePerItem;
  final String title;
  final void Function(List<MenuPick>) onChanged;

  const MenuDropdownList({
    super.key,
    required this.options,
    required this.onChanged,
    this.showPricePerItem = false,
    this.title = 'Menu items',
  });

  @override
  State<MenuDropdownList> createState() => _MenuDropdownListState();
}

class _MenuDropdownListState extends State<MenuDropdownList> {
  final List<MenuPick> _rows = [MenuPick()];

  void _notify() => widget.onChanged(List<MenuPick>.from(_rows));

  @override
  Widget build(BuildContext context) {
    const rowGap = SizedBox(height: 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...List.generate(_rows.length, (i) {
          final pick = _rows[i];
          final priceCtrl = TextEditingController(
            text: pick.price == null ? '' : pick.price!.toString(),
          );

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: LayoutBuilder(builder: (context, c) {
                final isWide = c.maxWidth > 500;
                final itemField = Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: pick.name,
                    isExpanded: true,
                    menuMaxHeight: 320,
                    decoration: const InputDecoration(labelText: 'Menu item'),
                    items: widget.options.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) {
                      setState(() { pick.name = v; _rows[i] = pick; });
                      _notify();
                    },
                  ),
                );

                final priceField = widget.showPricePerItem
                    ? Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: isWide ? 12 : 0, top: isWide ? 0 : 12),
                    child: TextFormField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price/item'),
                      onChanged: (v) {
                        setState(() { pick.price = double.tryParse(v); _rows[i] = pick; });
                        _notify();
                      },
                    ),
                  ),
                )
                    : const SizedBox.shrink();

                final removeBtn = IconButton(
                  tooltip: 'Remove',
                  onPressed: () {
                    setState(() { _rows.removeAt(i); });
                    _notify();
                  },
                  icon: const Icon(Icons.delete_outline),
                );

                return isWide
                    ? Row(children: [
                  itemField,
                  if (widget.showPricePerItem) priceField,
                  const SizedBox(width: 8),
                  removeBtn,
                ])
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    itemField,
                    if (widget.showPricePerItem) priceField,
                    Align(alignment: Alignment.centerRight, child: removeBtn),
                  ],
                );
              }),
            ),
          );
        }),
        rowGap,
        TextButton.icon(
          onPressed: () { setState(() => _rows.add(MenuPick())); _notify(); },
          icon: const Icon(Icons.add),
          label: const Text('Add another'),
        ),
      ],
    );
  }
}

