import 'package:flutter/material.dart';

class MenuItemsEditor extends StatefulWidget {
  final List<String> menuOptions;
  final bool showPricePerItem; // true for per-item pricing flows
  final bool showSize; // for tray/thaali
  final List<String> sizeOptions;
  final void Function(String name, {String? size, double? price}) onAdd;

  const MenuItemsEditor({
    super.key,
    required this.menuOptions,
    this.showPricePerItem = false,
    this.showSize = false,
    this.sizeOptions = const [],
    required this.onAdd,
  });

  @override
  State<MenuItemsEditor> createState() => _MenuItemsEditorState();
}

class _MenuItemsEditorState extends State<MenuItemsEditor> {
  String? selectedItem;
  String? selectedSize;
  final priceCtrl = TextEditingController();

  @override
  void dispose() {
    priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Menu item'),
          items: widget.menuOptions.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (v) => setState(() => selectedItem = v),
        ),
        if (widget.showSize)
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Size'),
            items: widget.sizeOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => selectedSize = v),
          ),
        if (widget.showPricePerItem)
          TextFormField(
            controller: priceCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Price (per item/unit)'),
          ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add'),
          onPressed: () {
            if (selectedItem == null) return;
            final price = widget.showPricePerItem ? double.tryParse(priceCtrl.text) : null;
            widget.onAdd(selectedItem!, size: selectedSize, price: price);
            setState(() {
              selectedItem = null;
              selectedSize = null;
              priceCtrl.clear();
            });
          },
        ),
      ],
    );
  }
}