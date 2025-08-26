import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/enums.dart';
import '../../state/controllers/event.dart';
import '../../widgets/dropdown.dart';
import '../../widgets/searchable_dropdown.dart';
import '../../widgets/textfield.dart';
import 'base.dart';

class ThaalForm extends StatefulWidget {
  final int cateringId;
  const ThaalForm({super.key, required this.cateringId});

  @override
  State<ThaalForm> createState() => _ThaalFormState();
}

// Simple row model for this form
class _MenuRow {
  String? name;
  double? price; // only used in PricingMode.fromMenuItems
}

class _ThaalFormState extends State<ThaalForm> {
  final c = Get.find<EventController>();

  final List<_MenuRow> _rows = [ _MenuRow() ];
  final qtyCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  PricingMode mode = PricingMode.manual;

  @override
  void dispose() {
    qtyCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

  double get _unitFromItems {
    return _rows.fold<double>(0, (sum, r) => sum + (r.price ?? 0));
  }

  void _addRow() => setState(() => _rows.add(_MenuRow()));

  void _removeRow(int i) {
    setState(() {
      _rows.removeAt(i);
      if (_rows.isEmpty) _rows.add(_MenuRow());
    });
  }

  bool _hasMenuSelected() =>
      _rows.any((r) => (r.name ?? '').trim().isNotEmpty);

  void _saveManual() {
    if (!_hasMenuSelected()) return;

    final qty  = double.tryParse(qtyCtrl.text) ?? 0;
    final unit = double.tryParse(priceCtrl.text) ?? 0;
    if (qty <= 0 || unit < 0) return;

    final order = c.addOrder(
      cateringId: widget.cateringId,
      pricingType: PricingType.perThaal,
      pricingMode: PricingMode.manual,
      qty: qty,
      unitPrice: unit,
      currency: 'USD',
    );

    for (final r in _rows) {
      if ((r.name ?? '').isEmpty) continue;
      c.addOrderMenuItem(orderId: order.id, menuItemName: r.name!.trim());
    }

    qtyCtrl.clear();
    priceCtrl.clear();
    setState(() {
      _rows
        ..clear()
        ..add(_MenuRow());
    });
  }

  void _saveFromItems() {
    if (!_hasMenuSelected()) return;

    final qty = double.tryParse(qtyCtrl.text) ?? 0;
    if (qty <= 0) return;

    final order = c.addOrder(
      cateringId: widget.cateringId,
      pricingType: PricingType.perThaal,
      pricingMode: PricingMode.fromMenuItems,
      qty: qty,
      unitPrice: _unitFromItems, // auto-summed from per-item prices
      currency: 'USD',
    );

    for (final r in _rows) {
      if ((r.name ?? '').isEmpty) continue;
      c.addOrderMenuItem(
        orderId: order.id,
        menuItemName: r.name!.trim(),
        menuItemPrice: r.price ?? 0,
      );
    }

    qtyCtrl.clear();
    setState(() {
      _rows
        ..clear()
        ..add(_MenuRow());
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = Get.find<EventController>().menuItemNames;

    return Column(
      children: [
        // 1) MENU (dynamic rows)
        FormSection(
          title: 'Thaal — Menu',
          child: Column(
            children: [
              // header bar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .5),
                child: Row(
                  children: [
                    const Expanded(flex: 3, child: Text('Menu item')),
                    if (mode == PricingMode.fromMenuItems)
                      const Expanded(flex: 2, child: Text('Price / item')),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ..._rows.asMap().entries.map((e) {
                final i = e.key;
                final row = e.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      // Menu item dropdown (AppDropdown2)
                      Expanded(
                        flex: 3,
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
                        )
                      ),
                      const SizedBox(width: 12),

                      // Per-item price only in "from items" mode
                      if (mode == PricingMode.fromMenuItems)
                        Expanded(
                          flex: 2,
                          child: RoundedTextField(
                            controller: TextEditingController(
                              text: (row.price == null || row.price!.isNaN)
                                  ? ''
                                  : row.price!.toString(),
                            ),
                            label: 'Price / item',
                            hint: 'e.g. 3.50',
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              row.price = double.tryParse(v);
                              setState(() {}); // refresh auto unit
                            },
                          ),
                        ),
                    ],
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

        // 2) PRICING
        FormSection(
          title: 'Pricing',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pricing mode via AppDropdown2
              AppDropdown2<PricingMode>(
                items: PricingMode.values,
                labelOf: (m) =>
                m == PricingMode.manual ? 'Per Thaal (manual)' : 'From Menu Items',
                value: mode,
                onChanged: (v) => setState(() => mode = v ?? PricingMode.manual),
                label: 'Pricing mode',
                leadingIcon: const Icon(Icons.attach_money),
              ),
              const SizedBox(height: 12),

              if (mode == PricingMode.manual) ...[
                Row(
                  children: [
                    Expanded(
                      child: RoundedTextField(
                        controller: qtyCtrl,
                        label: 'Total thaals',
                        hint: 'e.g. 30',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RoundedTextField(
                        controller: priceCtrl,
                        label: 'Price per thaal',
                        hint: 'e.g. 27.00',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: RoundedTextField(
                        controller: qtyCtrl,
                        label: 'Total thaals',
                        hint: 'e.g. 30',
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Auto unit price from selected items
                    Expanded(
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Price / thaal (auto)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          ),
                        ),
                        child: Text(_unitFromItems.toStringAsFixed(2)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _saveFromItems,
                  child: const Text('Save Thaal (from items)'),
                ),
              ],
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _saveManual,
            child: const Text('Save Thaal'),
          ),
        ),
      ],
    );
  }
}