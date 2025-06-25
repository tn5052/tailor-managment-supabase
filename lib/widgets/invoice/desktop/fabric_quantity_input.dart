import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/inventory_design_config.dart';

class FabricQuantityInput extends StatefulWidget {
  final double value;
  final double available;
  final String unit;
  final ValueChanged<double> onChanged;

  const FabricQuantityInput({
    super.key,
    required this.value,
    required this.available,
    required this.unit,
    required this.onChanged,
  });

  @override
  State<FabricQuantityInput> createState() => _FabricQuantityInputState();
}

class _FabricQuantityInputState extends State<FabricQuantityInput> {
  late TextEditingController _controller;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _validateAndUpdateValue();
    }
  }

  void _validateAndUpdateValue() {
    final value = double.tryParse(_controller.text) ?? 0;
    if (value > widget.available) {
      _controller.text = widget.available.toString();
      widget.onChanged(widget.available);
    } else if (value < 0) {
      _controller.text = '0';
      widget.onChanged(0);
    } else {
      widget.onChanged(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingS,
        vertical: InventoryDesignConfig.spacingXS,
      ),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceLight,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        border: Border.all(color: InventoryDesignConfig.borderPrimary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: () {
              final newValue = widget.value - 0.5;
              if (newValue >= 0) {
                _controller.text = newValue.toString();
                widget.onChanged(newValue);
              }
            },
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
                border: InputBorder.none,
                suffix: Text(
                  widget.unit,
                  style: InventoryDesignConfig.bodySmall,
                ),
              ),
              onSubmitted: (_) => _validateAndUpdateValue(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: () {
              final newValue = widget.value + 0.5;
              if (newValue <= widget.available) {
                _controller.text = newValue.toString();
                widget.onChanged(newValue);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
