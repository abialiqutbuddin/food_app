import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/enums.dart';
import '../../state/controllers/event.dart';
import '../../widgets/dropdown.dart';
import '../../widgets/searchable_dropdown.dart';
import '../../widgets/textfield.dart';
import 'base.dart';

class BbqForm extends StatefulWidget {
  final int cateringId;
  const BbqForm({super.key, required this.cateringId});

  @override
  State<BbqForm> createState() => _BbqFormState();
}

class _MenuRow {
  String? name;
}

class _BbqFormState extends State<BbqForm> {
  final c = Get.find<EventController>();

  final peopleCtrl = TextEditingController();
  final priceCtrl  = TextEditingController();

  final List<_MenuRow> _rows = [ _MenuRow() ];

  @override
  void dispose() {
    peopleCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

  bool get _hasAnyMenu =>
      _rows.any((r) => (r.name ?? '').trim().isNotEmpty);

  void _addRow() => setState(() => _rows.add(_MenuRow()));

  void _removeRow(int i) {
    setState(() {
      _rows.removeAt(i);
      if (_rows.isEmpty) _rows.add(_MenuRow());
    });
  }

  void _save() {
    if (!_hasAnyMenu) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one menu item')),
      );
      return;
    }

    final qty  = double.tryParse(peopleCtrl.text) ?? 0;
    final unit = double.tryParse(priceCtrl.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter # of people')),
      );
      return;
    }
    if (unit < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid price per head')),
      );
      return;
    }

    final order = c.addOrder(
      cateringId: widget.cateringId,
      pricingType: PricingType.perPerson,
      pricingMode: PricingMode.manual,
      qty: qty,
      unitPrice: unit,
      currency: 'USD',
    );

    // Attach all selected items (no size, no per-item price)
    for (final r in _rows) {
      final name = (r.name ?? '').trim();
      if (name.isEmpty) continue;
      c.addOrderMenuItem(orderId: order.id, menuItemName: name);
    }

    // Clear inputs
    peopleCtrl.clear();
    priceCtrl.clear();
    setState(() {
      _rows
        ..clear()
        ..add(_MenuRow());
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('BBQ order added')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuOptions = c.menuItemNames;

    return Column(
      children: [
        // MENU
        FormSection(
          title: 'Menu items',
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.5),
                child: const Row(
                  children: [
                    Expanded(child: Text('Menu item')),
                    SizedBox(width: 40),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ..._rows.asMap().entries.map((e) {
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
                    onAction: () => _removeRow(i),
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Add item'),
                ),
              ),
            ],
          ),
        ),

        // PEOPLE & PRICE
        FormSection(
          title: 'People & Price',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: RoundedTextField(
                      controller: peopleCtrl,
                      label: '# of people',
                      hint: 'e.g. 80',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RoundedTextField(
                      controller: priceCtrl,
                      label: 'Price per head',
                      hint: 'e.g. 12.00',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _save,
                child: const Text('BBQ order'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}