import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/enums.dart';
import '../../state/controllers/event.dart';
import '../../widgets/dropdown.dart';
import '../../widgets/searchable_dropdown.dart';
import '../../widgets/textfield.dart';
import 'base.dart';

class TrayForm extends StatefulWidget {
  final int cateringId;
  const TrayForm({super.key, required this.cateringId});

  @override
  State<TrayForm> createState() => _TrayFormState();
}

class _RowModel {
  String? item;
  String? size;
  final qtyCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  void dispose() {
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

class _TrayFormState extends State<TrayForm> {
  final c = Get.find<EventController>();
  final rows = <_RowModel>[_RowModel()];

  @override
  void dispose() {
    for (final r in rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _addRow() => setState(() => rows.add(_RowModel()));

  void _removeRow(int index) {
    setState(() {
      rows[index].dispose();
      rows.removeAt(index);
      if (rows.isEmpty) rows.add(_RowModel());
    });
  }

  void _saveAll() {
    for (final r in rows) {
      final item = r.item?.trim();
      final size = r.size?.trim();
      final qty  = double.tryParse(r.qtyCtrl.text) ?? 0;
      final unit = double.tryParse(r.priceCtrl.text) ?? 0;

      if ((item == null || item.isEmpty) || (size == null || size.isEmpty)) continue;
      if (qty <= 0 || unit < 0) continue;

      final order = c.addOrder(
        cateringId: widget.cateringId,
        pricingType: PricingType.perTray,
        pricingMode: PricingMode.manual,
        qty: qty,
        unitPrice: unit,
        currency: 'USD',
      );

      c.addOrderMenuItem(orderId: order.id, menuItemName: item, size: size);
    }

    setState(() {
      for (final r in rows) {
        r.dispose();
      }
      rows
        ..clear()
        ..add(_RowModel());
    });
  }

  @override
  Widget build(BuildContext context) {
    final sizeOptions = (c as dynamic).traySizes ?? c.sizes; // prefer tray-only sizes if you exposed them

    return Column(
      children: [
        FormSection(
          title: 'Party Tray — Items',
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .5),
                child: const Row(
                  children: [
                    Expanded(flex: 3, child: Text('Menu item')),
                    Expanded(flex: 2, child: Text('Tray size')),
                    Expanded(flex: 2, child: Text('Qty')),
                    Expanded(flex: 2, child: Text('Price/tray')),
                    //Expanded(flex: 1, child: Text('Actions')),
                    SizedBox(width: 40),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Rows
              ...List.generate(rows.length, (i) {
                final r = rows[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Menu item (AppDropdown2) with delete action
                      Expanded(
                          flex: 4,
                          child: AppDropdownSearch<String>(
                            localItems: c.menuItemNames,        // List<String>
                            labelOf: (s) => s,
                            value: r.item,
                            onChanged: (v) => setState(() => r.item = v),
                            onAddNew: (text) async {
                              // hit your API to create the item and return the canonical string
                              // final created = await api.menu.create(text);
                              // if (created.ok) { c.addMenuName(created.name); return created.name; }
                              return text; // demo
                            },
                            label: 'Menu item',
                            hint: 'Search or add…',
                            leadingIcon: const Icon(Icons.restaurant_menu),
                            // actionIcon: const Icon(Icons.delete_outline),
                            // onAction: () => _removeRow(i),
                          )
                      ),
                      const SizedBox(width: 5),

                      // Size (AppDropdown2)
                      Expanded(
                        flex: 3,
                        child: AppDropdown2<String>(
                          items: sizeOptions,
                          labelOf: (s) => s,
                          value: r.size,
                          onChanged: (v) => setState(() => r.size = v),
                          label: 'Tray size',
                          hint: 'Select size',
                          leadingIcon: const Icon(Icons.straighten),
                        ),
                      ),
                      const SizedBox(width: 5),

                      // Qty (RoundedTextField)
                      Expanded(
                        flex: 2,
                        child: RoundedTextField(
                          controller: r.qtyCtrl,
                          label: 'Qty',
                          hint: 'e.g. 4',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 5),

                      // Price/tray (RoundedTextField)
                      Expanded(
                        flex: 2,
                        child: RoundedTextField(
                          controller: r.priceCtrl,
                          label: 'Price/tray',
                          hint: 'e.g. 25.00',
                          keyboardType: TextInputType.number,
                        ),
                      ),

                      IconButton(icon: Icon(Icons.delete_outline_rounded), onPressed: () {_removeRow(i); },),
                    ],
                  ),
                );
              }),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Add row'),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _saveAll,
                  child: const Text('Add order'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}