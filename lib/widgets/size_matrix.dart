import 'package:flutter/material.dart';

class SizeRow {
  String? size;
  double qty = 0;
  double price = 0;
}

class SizeMatrixTable extends StatefulWidget {
  final List<String> sizeOptions;
  final void Function(List<SizeRow>) onChanged;

  const SizeMatrixTable({
    super.key,
    required this.sizeOptions,
    required this.onChanged,
  });

  @override
  State<SizeMatrixTable> createState() => _SizeMatrixTableState();
}

class _SizeMatrixTableState extends State<SizeMatrixTable> {
  final List<SizeRow> rows = [];

  void _notify() => widget.onChanged(List<SizeRow>.from(rows));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DataTable(
          columns: const [
            DataColumn(label: Text('Size')),
            DataColumn(label: Text('Qty')),
            DataColumn(label: Text('Price/size')),
            DataColumn(label: Text('')),
          ],
          rows: rows.map((r) {
            final qtyCtrl = TextEditingController(text: r.qty == 0 ? '' : r.qty.toString());
            final priceCtrl = TextEditingController(text: r.price == 0 ? '' : r.price.toString());
            return DataRow(cells: [
              DataCell(
                DropdownButtonFormField<String>(
                  value: r.size,
                  isExpanded: true,
                  items: widget.sizeOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) { setState(() => r.size = v); _notify(); },
                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'Pick size'),
                ),
              ),
              DataCell(
                TextFormField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: InputBorder.none, hintText: '0'),
                  onChanged: (v) { setState(() => r.qty = double.tryParse(v) ?? 0); _notify(); },
                ),
              ),
              DataCell(
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: InputBorder.none, hintText: '0.00'),
                  onChanged: (v) { setState(() => r.price = double.tryParse(v) ?? 0); _notify(); },
                ),
              ),
              DataCell(
                IconButton(
                  tooltip: 'Remove row',
                  onPressed: () { setState(() => rows.remove(r)); _notify(); },
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ]);
          }).toList(),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () { setState(() => rows.add(SizeRow())); _notify(); },
            icon: const Icon(Icons.add),
            label: const Text('Add size'),
          ),
        ),
      ],
    );
  }
}