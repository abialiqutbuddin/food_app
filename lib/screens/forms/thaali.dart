import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/enums.dart';
import '../../state/controllers/event.dart';
import '../../widgets/dropdown.dart';
import '../../widgets/searchable_dropdown.dart';
import '../../widgets/textfield.dart';
import 'base.dart';

class ThaaliForm extends StatefulWidget {
  final int cateringId;
  const ThaaliForm({super.key, required this.cateringId});

  @override
  State<ThaaliForm> createState() => _ThaaliFormState();
}

// Row models for this form
class _MenuRow {
  String? name;
}

class _SizeRow {
  String? size; // 'Small' | 'Medium' | 'Large'
  final qtyCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  void dispose() {
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

class _ThaaliFormState extends State<ThaaliForm> {
  final c = Get.find<EventController>();

  final List<_MenuRow> _menuRows = [ _MenuRow() ];
  final List<_SizeRow> _sizeRows = [ _SizeRow() ];

  @override
  void dispose() {
    for (final r in _sizeRows) {
      r.dispose();
    }
    super.dispose();
  }

  // Helpers
  bool get _hasMenu => _menuRows.any((r) => (r.name ?? '').trim().isNotEmpty);

  void _addMenuRow() => setState(() => _menuRows.add(_MenuRow()));
  void _removeMenuRow(int i) {
    setState(() {
      _menuRows.removeAt(i);
      if (_menuRows.isEmpty) _menuRows.add(_MenuRow());
    });
  }

  void _addSizeRow() => setState(() => _sizeRows.add(_SizeRow()));
  void _removeSizeRow(int i) {
    setState(() {
      _sizeRows[i].dispose();
      _sizeRows.removeAt(i);
      if (_sizeRows.isEmpty) _sizeRows.add(_SizeRow());
    });
  }

  void _save() {
    if (!_hasMenu) return;

    // collect shared menu names
    final sharedMenu = _menuRows
        .map((r) => (r.name ?? '').trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (sharedMenu.isEmpty) return;

    // create one order per size row
    for (final row in _sizeRows) {
      final size = (row.size ?? '').trim();
      final qty  = double.tryParse(row.qtyCtrl.text) ?? 0;
      final unit = double.tryParse(row.priceCtrl.text) ?? 0;

      if (size.isEmpty || qty <= 0 || unit < 0) continue;

      final order = c.addOrder(
        cateringId: widget.cateringId,
        pricingType: PricingType.perSize,   // thaali is priced per size
        pricingMode: PricingMode.manual,    // price comes from this row
        qty: qty,
        unitPrice: unit,
        currency: 'USD',
        // If you later store size at order-level in DB, add it here.
      );

      // attach the shared menu items WITHOUT size (size belongs to the thaali, not the items)
      for (final name in sharedMenu) {
        c.addOrderMenuItem(orderId: order.id, menuItemName: name);
      }
    }

    // optional clear
    setState(() {
      _menuRows
        ..clear()
        ..add(_MenuRow());
      for (final r in _sizeRows) {
        r.dispose();
      }
      _sizeRows
        ..clear()
        ..add(_SizeRow());
    });
  }

  @override
  Widget build(BuildContext context) {
    final thaaliSizes = (c as dynamic).thaaliSizes ?? const ['Small','Medium','Large'];

    return Column(
      children: [
        // 1) Shared Menu (same across all sizes)
        FormSection(
          title: 'Thaali — Shared Menu',
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .5),
                child: const Row(
                  children: [
                    Expanded(child: Text('Menu item')),
                    SizedBox(width: 40),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ..._menuRows.asMap().entries.map((e) {
                final i = e.key;
                final row = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppDropdownSearch<String>(
                    localItems: c.menuItemNames,        // List<String>
                    labelOf: (s) => s,
                    value: row.name,
                    onChanged: (v) => setState(() => row.name = v),
                    onAddNew: (text) async {
                      // hit your API to create the item and return the canonical string
                      // final created = await api.menu.create(text);
                      // if (created.ok) { c.addMenuName(created.name); return created.name; }
                      return text; // demo
                    },
                    label: 'Menu item',
                    hint: 'Search or add…',
                    leadingIcon: const Icon(Icons.restaurant_menu),
                    actionIcon: const Icon(Icons.delete_outline),
                    onAction: () => _removeMenuRow(i),
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addMenuRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Add item'),
                ),
              ),
            ],
          ),
        ),

        // 2) Sizes (each row produces one order)
        FormSection(
          title: 'Thaali Sizes (each row creates one order)',
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .5),
                child: const Row(
                  children: [
                    Expanded(flex: 2, child: Text('Size')),
                    Expanded(flex: 2, child: Text('Qty')),
                    Expanded(flex: 2, child: Text('Price / size')),
                    SizedBox(width: 40),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ..._sizeRows.asMap().entries.map((e) {
                final i = e.key;
                final row = e.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      // Size
                      Expanded(
                        flex: 2,
                        child: AppDropdown2<String>(
                          items: thaaliSizes,
                          labelOf: (s) => s,
                          value: row.size,
                          onChanged: (v) => setState(() => row.size = v),
                          label: 'Size',
                          hint: 'Select size',
                          leadingIcon: const Icon(Icons.straighten),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Qty
                      Expanded(
                        flex: 2,
                        child: RoundedTextField(
                          controller: row.qtyCtrl,
                          label: 'Qty',
                          hint: 'e.g. 5',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Price / size
                      Expanded(
                        flex: 2,
                        child: RoundedTextField(
                          controller: row.priceCtrl,
                          label: 'Price / size',
                          hint: 'e.g. 10.00',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Remove size row
                      IconButton(
                        tooltip: 'Remove row',
                        onPressed: () => _removeSizeRow(i),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addSizeRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Add size'),
                ),
              ),
            ],
          ),
        ),

        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _save,
            child: const Text('Add order'),
          ),
        ),
      ],
    );
  }
}