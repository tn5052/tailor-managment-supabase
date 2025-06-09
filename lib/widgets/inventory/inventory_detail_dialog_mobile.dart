import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'inventory_design_config.dart';

class InventoryDetailDialogMobile extends StatefulWidget {
  final Map<String, dynamic> item;
  final String inventoryType; // 'fabric' or 'accessory'
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const InventoryDetailDialogMobile({
    Key? key,
    required this.item,
    required this.inventoryType,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> item,
    required String inventoryType,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder:
          (context) => InventoryDetailDialogMobile(
            item: item,
            inventoryType: inventoryType,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
    );
  }

  @override
  State<InventoryDetailDialogMobile> createState() =>
      _InventoryDetailDialogMobileState();
}

class _InventoryDetailDialogMobileState
    extends State<InventoryDetailDialogMobile>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _sheetAnimation;
  late Animation<double> _contentOpacityAnimation;

  final ScrollController _scrollController = ScrollController();
  final FocusNode _sheetFocusNode = FocusNode();

  double _keyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupKeyboardListener();

    // Request focus for accessibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sheetFocusNode.requestFocus();
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _sheetAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _contentOpacityAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  void _setupKeyboardListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mediaQuery = MediaQuery.of(context);
      final keyboardHeight = mediaQuery.viewInsets.bottom;

      if (keyboardHeight != _keyboardHeight) {
        setState(() {
          _keyboardHeight = keyboardHeight;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _sheetFocusNode.dispose();
    super.dispose();
  }

  void _handleClose() async {
    // Haptic feedback
    HapticFeedback.lightImpact();

    // Animate out
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final statusBarHeight = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    return AnimatedBuilder(
      animation: _sheetAnimation,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(
            0.4 * _sheetAnimation.value,
          ),
          body: GestureDetector(
            onTap: _handleClose,
            child: Stack(
              children: [
                // Main sheet content
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: screenHeight * 0.92,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      (screenHeight * 0.92) * (1 - _sheetAnimation.value),
                    ),
                    child: _buildSheetContent(
                      screenHeight,
                      statusBarHeight,
                      bottomPadding,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetContent(
    double screenHeight,
    double statusBarHeight,
    double bottomPadding,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Focus(
        focusNode: _sheetFocusNode,
        child: Column(
          children: [
            // Handle and header
            _buildHeader(),

            // Content
            Expanded(
              child: AnimatedBuilder(
                animation: _contentOpacityAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _contentOpacityAnimation.value,
                    child: _buildContent(),
                  );
                },
              ),
            ),

            // Action buttons at bottom
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isFabric = widget.inventoryType == 'fabric';
    final itemName =
        widget.item[isFabric ? 'fabric_item_name' : 'accessory_item_name'];

    return Container(
      decoration: const BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(
              top: InventoryDesignConfig.spacingM,
              bottom: InventoryDesignConfig.spacingS,
            ),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: InventoryDesignConfig.borderPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header content
          Padding(
            padding: const EdgeInsets.fromLTRB(
              InventoryDesignConfig.spacingXL,
              InventoryDesignConfig.spacingS,
              InventoryDesignConfig.spacingXL,
              InventoryDesignConfig.spacingL,
            ),
            child: Row(
              children: [
                // Item icon with color
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _parseColor(widget.item['color_code'] ?? ''),
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                    border: Border.all(
                      color: InventoryDesignConfig.borderPrimary,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _parseColor(
                          widget.item['color_code'] ?? '',
                        ).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isFabric
                        ? PhosphorIcons.scissors()
                        : _getAccessoryIcon(
                          widget.item[isFabric
                              ? 'fabric_type'
                              : 'accessory_type'],
                        ),
                    color: Colors.white,
                    size: 24,
                  ),
                ),

                const SizedBox(width: InventoryDesignConfig.spacingL),

                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemName ?? 'Unknown Item',
                        style: InventoryDesignConfig.headlineMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: InventoryDesignConfig.spacingXS),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: InventoryDesignConfig.spacingS,
                              vertical: InventoryDesignConfig.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              color: InventoryDesignConfig.primaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                InventoryDesignConfig.radiusS,
                              ),
                            ),
                            child: Text(
                              widget.item[isFabric
                                      ? 'fabric_type'
                                      : 'accessory_type'] ??
                                  'Uncategorized',
                              style: InventoryDesignConfig.bodySmall.copyWith(
                                color: InventoryDesignConfig.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: InventoryDesignConfig.spacingS),
                          Text(
                            widget.item[isFabric
                                    ? 'fabric_code'
                                    : 'accessory_code'] ??
                                'No Code',
                            style: InventoryDesignConfig.code,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Close button
                _buildHeaderActionButton(
                  icon: PhosphorIcons.x(),
                  onTap: _handleClose,
                  color: InventoryDesignConfig.textSecondary,
                  semanticLabel: 'Close details',
                ),
              ],
            ),
          ),

          // Divider
          Container(height: 1, color: InventoryDesignConfig.borderSecondary),
        ],
      ),
    );
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required String semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        left: InventoryDesignConfig.spacingXL,
        right: InventoryDesignConfig.spacingXL,
        top: InventoryDesignConfig.spacingL,
        bottom: InventoryDesignConfig.spacingXL + _keyboardHeight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key metrics cards
          _buildMetricsSection(),

          const SizedBox(height: InventoryDesignConfig.spacingXXL),

          // Basic information
          _buildInformationSection(),

          const SizedBox(height: InventoryDesignConfig.spacingXXL),

          // Inventory details
          _buildInventorySection(),

          const SizedBox(height: InventoryDesignConfig.spacingXXL),

          // Pricing information
          _buildPricingSection(),
        ],
      ),
    );
  }

  Widget _buildMetricsSection() {
    final quantityAvailable = widget.item['quantity_available'] ?? 0;
    final minimumStockLevel = widget.item['minimum_stock_level'] ?? 0;
    final costPerUnit = (widget.item['cost_per_unit'] ?? 0.0) as double;
    final sellingPrice =
        (widget.item['selling_price_per_unit'] ?? 0.0) as double;
    final isLowStock = quantityAvailable <= minimumStockLevel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: InventoryDesignConfig.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: InventoryDesignConfig.spacingL),

        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Stock Level',
                value: '$quantityAvailable',
                subtitle: '${widget.item['unit_type'] ?? 'units'}',
                icon:
                    isLowStock
                        ? PhosphorIcons.warning()
                        : PhosphorIcons.package(),
                color:
                    isLowStock
                        ? InventoryDesignConfig.errorColor
                        : InventoryDesignConfig.successColor,
                semanticLabel:
                    'Current stock: $quantityAvailable ${widget.item['unit_type'] ?? 'units'}',
              ),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
            Expanded(
              child: _buildMetricCard(
                title: 'Selling Price',
                value: '\$${sellingPrice.toStringAsFixed(2)}',
                subtitle: 'per ${widget.item['unit_type'] ?? 'unit'}',
                icon: PhosphorIcons.tag(),
                color: InventoryDesignConfig.primaryColor,
                semanticLabel:
                    'Selling price: \$${sellingPrice.toStringAsFixed(2)} per ${widget.item['unit_type'] ?? 'unit'}',
              ),
            ),
          ],
        ),

        const SizedBox(height: InventoryDesignConfig.spacingM),

        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Cost Price',
                value: '\$${costPerUnit.toStringAsFixed(2)}',
                subtitle: 'per ${widget.item['unit_type'] ?? 'unit'}',
                icon: PhosphorIcons.currencyDollar(),
                color: InventoryDesignConfig.warningColor,
                semanticLabel:
                    'Cost price: \$${costPerUnit.toStringAsFixed(2)} per ${widget.item['unit_type'] ?? 'unit'}',
              ),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
            Expanded(
              child: _buildMetricCard(
                title: 'Profit Margin',
                value:
                    '${_calculateProfitMargin(costPerUnit, sellingPrice).toStringAsFixed(1)}%',
                subtitle: 'per unit',
                icon: PhosphorIcons.trendUp(),
                color: InventoryDesignConfig.successColor,
                semanticLabel:
                    'Profit margin: ${_calculateProfitMargin(costPerUnit, sellingPrice).toStringAsFixed(1)} percent',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel,
      child: Container(
        padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusS,
                    ),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingS),
                Expanded(
                  child: Text(
                    title,
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: InventoryDesignConfig.spacingM),
            Text(
              value,
              style: InventoryDesignConfig.headlineMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingXS),
            Text(
              subtitle,
              style: InventoryDesignConfig.bodySmall.copyWith(
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationSection() {
    final isFabric = widget.inventoryType == 'fabric';

    return _buildSection(
      title: 'Basic Information',
      icon: PhosphorIcons.info(),
      children: [
        _buildDetailRow(
          'Item Code',
          widget.item[isFabric ? 'fabric_code' : 'accessory_code'],
          icon: PhosphorIcons.barcode(),
        ),
        _buildDetailRow(
          'Item Name',
          widget.item[isFabric ? 'fabric_item_name' : 'accessory_item_name'],
          icon: PhosphorIcons.tag(),
        ),
        _buildDetailRow(
          'Brand',
          widget.item['brand_name'],
          icon: PhosphorIcons.certificate(),
        ),
        _buildDetailRow(
          'Category',
          widget.item[isFabric ? 'fabric_type' : 'accessory_type'],
          icon: PhosphorIcons.folder(),
        ),
        if (widget.item[isFabric ? 'shade_color' : 'color'] != null)
          _buildColorDetailRow(
            'Color',
            widget.item[isFabric ? 'shade_color' : 'color'],
            widget.item['color_code'],
          ),
      ],
    );
  }

  Widget _buildInventorySection() {
    final quantityAvailable = widget.item['quantity_available'] ?? 0;
    final minimumStockLevel = widget.item['minimum_stock_level'] ?? 0;
    final isLowStock = quantityAvailable <= minimumStockLevel;

    return _buildSection(
      title: 'Inventory Details',
      icon: PhosphorIcons.warehouse(),
      children: [
        _buildDetailRow(
          'Available Quantity',
          '$quantityAvailable',
          icon: PhosphorIcons.package(),
          statusColor:
              isLowStock
                  ? InventoryDesignConfig.errorColor
                  : InventoryDesignConfig.successColor,
        ),
        _buildDetailRow(
          'Unit Type',
          widget.item['unit_type'],
          icon: PhosphorIcons.ruler(),
        ),
        _buildDetailRow(
          'Minimum Stock Level',
          '$minimumStockLevel',
          icon: PhosphorIcons.warning(),
        ),
        _buildDetailRow(
          'Stock Status',
          isLowStock ? 'Low Stock' : 'In Stock',
          icon:
              isLowStock
                  ? PhosphorIcons.warning()
                  : PhosphorIcons.checkCircle(),
          statusColor:
              isLowStock
                  ? InventoryDesignConfig.errorColor
                  : InventoryDesignConfig.successColor,
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    final costPerUnit = (widget.item['cost_per_unit'] ?? 0.0) as double;
    final sellingPrice =
        (widget.item['selling_price_per_unit'] ?? 0.0) as double;
    final profitMargin = _calculateProfitMargin(costPerUnit, sellingPrice);

    return _buildSection(
      title: 'Pricing Information',
      icon: PhosphorIcons.currencyDollar(),
      children: [
        _buildDetailRow(
          'Cost per Unit',
          '\$${costPerUnit.toStringAsFixed(2)}',
          icon: PhosphorIcons.coins(),
        ),
        _buildDetailRow(
          'Selling Price per Unit',
          '\$${sellingPrice.toStringAsFixed(2)}',
          icon: PhosphorIcons.tag(),
        ),
        _buildDetailRow(
          'Profit per Unit',
          '\$${(sellingPrice - costPerUnit).toStringAsFixed(2)}',
          icon: PhosphorIcons.trendUp(),
          statusColor:
              sellingPrice > costPerUnit
                  ? InventoryDesignConfig.successColor
                  : InventoryDesignConfig.errorColor,
        ),
        _buildDetailRow(
          'Profit Margin',
          '${profitMargin.toStringAsFixed(1)}%',
          icon: PhosphorIcons.percent(),
          statusColor:
              profitMargin > 0
                  ? InventoryDesignConfig.successColor
                  : InventoryDesignConfig.errorColor,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        InventoryDesignConfig.spacingXL,
        InventoryDesignConfig.spacingL,
        InventoryDesignConfig.spacingXL,
        InventoryDesignConfig.spacingXL + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        border: Border(
          top: BorderSide(
            color: InventoryDesignConfig.borderSecondary,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              label: 'Edit Item',
              icon: PhosphorIcons.pencilSimple(),
              color: InventoryDesignConfig.primaryColor,
              onTap: () {
                Navigator.of(context).pop();
                widget.onEdit?.call();
              },
            ),
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          Expanded(
            child: _buildActionButton(
              label: 'Delete Item',
              icon: PhosphorIcons.trash(),
              color: InventoryDesignConfig.errorColor,
              onTap: () {
                Navigator.of(context).pop();
                widget.onDelete?.call();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
              decoration: BoxDecoration(
                color: InventoryDesignConfig.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  InventoryDesignConfig.radiusS,
                ),
              ),
              child: Icon(
                icon,
                size: 16,
                color: InventoryDesignConfig.primaryColor,
              ),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
            Text(
              title,
              style: InventoryDesignConfig.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: InventoryDesignConfig.spacingL),
        Container(
          decoration: InventoryDesignConfig.cardDecoration,
          child: Column(
            children:
                children.asMap().entries.map((entry) {
                  final index = entry.key;
                  final child = entry.value;
                  return Column(
                    children: [
                      child,
                      if (index < children.length - 1)
                        Container(
                          height: 1,
                          color: InventoryDesignConfig.borderSecondary,
                        ),
                    ],
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String? value, {
    IconData? icon,
    Color? statusColor,
  }) {
    return Semantics(
      label: '$label: ${value ?? 'Not specified'}',
      child: Padding(
        padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: statusColor ?? InventoryDesignConfig.textSecondary,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingM),
            ],
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color: InventoryDesignConfig.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
            Expanded(
              flex: 3,
              child: Text(
                value ?? 'N/A',
                style: InventoryDesignConfig.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: statusColor ?? InventoryDesignConfig.textPrimary,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorDetailRow(
    String label,
    String? colorName,
    String? colorCode,
  ) {
    return Semantics(
      label: '$label: ${colorName ?? 'Not specified'}',
      child: Padding(
        padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
        child: Row(
          children: [
            Icon(
              PhosphorIcons.paintBrush(),
              size: 16,
              color: InventoryDesignConfig.textSecondary,
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color: InventoryDesignConfig.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: InventoryDesignConfig.spacingM),
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _parseColor(colorCode ?? ''),
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusS,
                      ),
                      border: Border.all(
                        color: InventoryDesignConfig.borderPrimary,
                        width: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: InventoryDesignConfig.spacingS),
                  Text(
                    colorName ?? 'N/A',
                    style: InventoryDesignConfig.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: InventoryDesignConfig.spacingL,
              horizontal: InventoryDesignConfig.spacingM,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusM,
              ),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: InventoryDesignConfig.spacingS),
                Text(
                  label,
                  style: InventoryDesignConfig.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods
  double _calculateProfitMargin(double cost, double selling) {
    if (cost <= 0) return 0;
    return ((selling - cost) / cost) * 100;
  }

  Color _parseColor(String colorCode) {
    if (colorCode.isEmpty) return InventoryDesignConfig.textTertiary;

    try {
      if (colorCode.startsWith('#')) {
        String hexCode = colorCode.substring(1);
        if (hexCode.length == 6) {
          return Color(int.parse('FF$hexCode', radix: 16));
        }
      }

      // Map common color names
      switch (colorCode.toLowerCase()) {
        case 'red':
          return Colors.red;
        case 'blue':
          return Colors.blue;
        case 'green':
          return Colors.green;
        case 'yellow':
          return Colors.yellow;
        case 'black':
          return Colors.black;
        case 'white':
          return Colors.grey[300]!;
        case 'purple':
          return Colors.purple;
        case 'pink':
          return Colors.pink;
        case 'orange':
          return Colors.orange;
        case 'brown':
          return Colors.brown;
        case 'grey':
        case 'gray':
          return Colors.grey;
        default:
          return InventoryDesignConfig.primaryColor;
      }
    } catch (e) {
      return InventoryDesignConfig.textTertiary;
    }
  }

  IconData _getAccessoryIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'button':
        return PhosphorIcons.circle();
      case 'zipper':
        return PhosphorIcons.arrowLineDown();
      case 'thread':
        return PhosphorIcons.spiral();
      case 'elastic':
        return PhosphorIcons.waveSine();
      case 'lace':
        return PhosphorIcons.flower();
      default:
        return PhosphorIcons.package();
    }
  }
}
