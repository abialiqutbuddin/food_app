import 'package:flutter/material.dart';

class QtyPriceRow extends StatelessWidget {
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  final String qtyLabel;
  final String priceLabel;

  const QtyPriceRow({
    super.key,
    required this.qtyCtrl,
    required this.priceCtrl,
    this.qtyLabel = 'Qty',
    this.priceLabel = 'Unit price',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: TextFormField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: qtyLabel))),
        const SizedBox(width: 12),
        Expanded(child: TextFormField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: priceLabel))),
      ],
    );
  }
}