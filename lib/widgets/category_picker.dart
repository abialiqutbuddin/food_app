import 'package:flutter/material.dart';
import '../../models/enums.dart';

Future<Category?> showCategoryPicker(BuildContext context) async {
  return showDialog<Category>(
    context: context,
    builder: (_) => SimpleDialog(
      title: const Text('Select catering category'),
      children: Category.values.map((cat) {
        return SimpleDialogOption(
          onPressed: () => Navigator.pop(context, cat),
          child: Text(cat.label),
        );
      }).toList(),
    ),
  );
}