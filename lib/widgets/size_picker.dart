import 'package:flutter/material.dart';

class SizePicker extends StatelessWidget {
  final List<String> sizeOptions;
  final void Function(String size) onAdd;

  const SizePicker({super.key, required this.sizeOptions, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    String? selected;
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Size'),
            items: sizeOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => selected = v,
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add size'),
          onPressed: () {
            if (selected != null) onAdd(selected!);
          },
        ),
      ],
    );
  }
}