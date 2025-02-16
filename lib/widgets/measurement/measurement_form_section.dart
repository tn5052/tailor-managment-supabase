import 'package:flutter/material.dart';

class MeasurementFormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color? color;

  const MeasurementFormSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color?.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class MeasurementFieldGrid extends StatelessWidget {
  final bool isDesktop;
  final List<Widget> fields;

  const MeasurementFieldGrid({
    super.key,
    required this.isDesktop,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isDesktop ? 3 : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: isDesktop ? 3 : 6,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: fields,
        );
      },
    );
  }
}

class MeasurementTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? suffixText;
  final bool required;
  final bool isNumber;
  final int? maxLines;

  const MeasurementTextField({
    super.key,
    required this.controller,
    required this.label,
    this.suffixText,
    this.required = false,
    this.isNumber = false,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffixText,
        filled: true,
        fillColor: Colors.grey.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      maxLines: maxLines,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      validator: required
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter ${label.toLowerCase()}';
              }
              if (isNumber && double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            }
          : null,
    );
  }
}
