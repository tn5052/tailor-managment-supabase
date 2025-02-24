import 'package:flutter/material.dart';

enum ExportFilterType { all, customer, measurement }

class ExportFilterDialog extends StatefulWidget {
  const ExportFilterDialog({Key? key}) : super(key: key);

  @override
  _ExportFilterDialogState createState() => _ExportFilterDialogState();
}

class _ExportFilterDialogState extends State<ExportFilterDialog> {
  ExportFilterType _filterType = ExportFilterType.all;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Export Filters"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<ExportFilterType>(
            value: _filterType,
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _filterType = val;
                });
              }
            },
            items: ExportFilterType.values
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.toString().split('.').last),
                    ))
                .toList(),
          ),
          // Additional filter fields (e.g., date range) can be added here
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_filterType),
          child: const Text("Export"),
        ),
      ],
    );
  }
}
