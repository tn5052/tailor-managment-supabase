import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../../models/invoice_product.dart';
import '../../../theme/inventory_design_config.dart';

class InvoiceProductSelector extends StatelessWidget {
  final List<InvoiceProduct> selectedProducts;
  final Function(List<InvoiceProduct>) onProductsChanged;

  const InvoiceProductSelector({
    super.key,
    required this.selectedProducts,
    required this.onProductsChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedProducts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      itemCount: selectedProducts.length,
      separatorBuilder:
          (context, index) =>
              const SizedBox(height: InventoryDesignConfig.spacingM),
      itemBuilder:
          (context, index) => _buildProductCard(selectedProducts[index], index),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceAccent,
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusXL,
              ),
            ),
            child: Icon(
              PhosphorIcons.package(),
              size: 48,
              color: InventoryDesignConfig.textTertiary,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingL),
          Text(
            'No products selected',
            style: InventoryDesignConfig.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingS),
          Text(
            'Add products from inventory or create custom ones',
            style: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(InvoiceProduct product, int index) {
    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        border: Border.all(color: InventoryDesignConfig.borderPrimary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  (product.inventoryType ?? 'custom') == 'fabric'
                      ? InventoryDesignConfig.infoColor.withOpacity(0.1)
                      : InventoryDesignConfig.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    (product.inventoryType ?? 'custom') == 'fabric'
                        ? InventoryDesignConfig.infoColor.withOpacity(0.3)
                        : InventoryDesignConfig.successColor.withOpacity(0.3),
              ),
            ),
            child: Icon(
              (product.inventoryType ?? 'custom') == 'fabric'
                  ? PhosphorIcons.scissors()
                  : PhosphorIcons.package(),
              size: 18,
              color:
                  (product.inventoryType ?? 'custom') == 'fabric'
                      ? InventoryDesignConfig.infoColor
                      : InventoryDesignConfig.successColor,
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: InventoryDesignConfig.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (product.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    product.description,
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: InventoryDesignConfig.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: InventoryDesignConfig.spacingS),
                Row(
                  children: [
                    Text(
                      'Qty: ${product.quantity % 1 == 0 ? product.quantity.toInt() : product.quantity} ${product.unit}',
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        color: InventoryDesignConfig.textSecondary,
                      ),
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingM),
                    Text(
                      '@${NumberFormat.currency(symbol: 'AED ').format(product.unitPrice)}',
                      style: InventoryDesignConfig.bodySmall.copyWith(
                        color: InventoryDesignConfig.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          Text(
            NumberFormat.currency(symbol: 'AED ').format(product.totalPrice),
            style: InventoryDesignConfig.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: InventoryDesignConfig.successColor,
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingS),
          IconButton(
            onPressed: () => _removeProduct(index),
            icon: Icon(
              PhosphorIcons.trash(),
              size: 16,
              color: InventoryDesignConfig.errorColor,
            ),
            tooltip: 'Remove product',
          ),
        ],
      ),
    );
  }

  void _removeProduct(int index) {
    final updatedProducts = List<InvoiceProduct>.from(selectedProducts);
    updatedProducts.removeAt(index);
    onProductsChanged(updatedProducts);
  }
}
