import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_inventory_desktop_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'inventory_detail_dialog_desktop.dart';
import 'edit_inventory_desktop_dialog.dart';
import 'inventory_design_config.dart';

class InventoryDesktopView extends StatefulWidget {
  final String inventoryType; // 'fabric' or 'accessory'
  final Function(String)? onTypeChanged; // Callback for switching types

  const InventoryDesktopView({
    super.key,
    required this.inventoryType,
    this.onTypeChanged,
  });

  @override
  State<InventoryDesktopView> createState() => _InventoryDesktopViewState();
}

class _InventoryDesktopViewState extends State<InventoryDesktopView> {
  final _supabase = Supabase.instance.client;
  String _sortColumn = 'created_at';
  bool _sortAscending = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _inventoryItems = [];

  @override
  void initState() {
    super.initState();
    _loadInventoryItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInventoryItems() async {
    setState(() => _isLoading = true);

    try {
      final table =
          widget.inventoryType == 'fabric'
              ? 'fabric_inventory'
              : 'accessories_inventory';

      String selectQuery;
      if (widget.inventoryType == 'fabric') {
        selectQuery = '''
          id, fabric_code, fabric_item_name, shade_color, color_code, 
          unit_type, quantity_available, minimum_stock_level, 
          cost_per_unit, selling_price_per_unit, is_active, created_at,
          brands(id, name),
          inventory_categories(id, category_name)
        ''';
      } else {
        selectQuery = '''
          id, accessory_code, accessory_item_name, color, color_code,
          unit_type, quantity_available, minimum_stock_level,
          cost_per_unit, selling_price_per_unit, is_active, created_at,
          brands(id, name),
          inventory_categories(id, category_name)
        ''';
      }

      var query = _supabase
          .from(table)
          .select(selectQuery)
          .eq('is_active', true);

      if (_searchQuery.isNotEmpty) {
        if (widget.inventoryType == 'fabric') {
          query = query.or(
            'fabric_item_name.ilike.%${_searchQuery}%,shade_color.ilike.%${_searchQuery}%,fabric_code.ilike.%${_searchQuery}%',
          );
        } else {
          query = query.or(
            'accessory_item_name.ilike.%${_searchQuery}%,color.ilike.%${_searchQuery}%,accessory_code.ilike.%${_searchQuery}%',
          );
        }
      }

      final response = await query.order(
        _sortColumn,
        ascending: _sortAscending,
      );

      final processedItems =
          response.map<Map<String, dynamic>>((item) {
            final Map<String, dynamic> processedItem = Map.from(item);

            if (item['brands'] != null) {
              processedItem['brand_name'] =
                  item['brands']['name'] ?? 'No Brand';
              processedItem['brand_id'] = item['brands']['id'];
            } else {
              processedItem['brand_name'] = 'No Brand';
            }

            if (item['inventory_categories'] != null) {
              processedItem[widget.inventoryType == 'fabric'
                      ? 'fabric_type'
                      : 'accessory_type'] =
                  item['inventory_categories']['category_name'] ??
                  'Uncategorized';
              processedItem['category_id'] = item['inventory_categories']['id'];
            } else {
              processedItem[widget.inventoryType == 'fabric'
                      ? 'fabric_type'
                      : 'accessory_type'] =
                  'Uncategorized';
            }

            return processedItem;
          }).toList();

      setState(() {
        _inventoryItems = processedItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading inventory: ${e.toString()}'),
            backgroundColor: InventoryDesignConfig.errorColor,
          ),
        );
      }
    }
  }

  void _onSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
    _loadInventoryItems();
  }

  @override
  void didUpdateWidget(InventoryDesktopView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inventoryType != widget.inventoryType) {
      _searchController.clear();
      _searchQuery = '';
      _sortColumn = 'created_at';
      _sortAscending = false;
      _inventoryItems.clear();
      _loadInventoryItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: InventoryDesignConfig.backgroundColor,
      ),
      child: Column(
        children: [
          // Compact header section with title and controls
          Container(
            decoration: const BoxDecoration(
              color: InventoryDesignConfig.backgroundColor,
            ),
            padding: const EdgeInsets.fromLTRB(32, 20, 32, 16),
            child: Column(
              children: [
                // Main header row - compact design
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title section
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: InventoryDesignConfig.primaryColor
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            PhosphorIcons.warehouse(),
                            size: 22,
                            color: InventoryDesignConfig.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inventory Management',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: InventoryDesignConfig.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Manage fabrics and accessories',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: InventoryDesignConfig.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Right side controls - in a single row
                    Row(
                      children: [
                        _buildTypeSelector(),
                        const SizedBox(width: 16),
                        _buildSearchField(),
                        const SizedBox(width: 12),
                        _buildModernFilterButton(),
                        const SizedBox(width: 12),
                        _buildModernPrimaryButton(
                          icon: PhosphorIcons.plus(),
                          label: 'Add Item',
                          onPressed: () {
                            AddInventoryDesktopDialog.show(
                              context,
                              inventoryType: widget.inventoryType,
                              onItemAdded: _loadInventoryItems,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Stats row - more compact
                _buildModernStatsRow(),
              ],
            ),
          ),

          // Table container with matching background
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: InventoryDesignConfig.backgroundColor,
              ),
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Container(
                decoration: BoxDecoration(
                  color: InventoryDesignConfig.surfaceColor,
                  border: Border.all(
                    color: InventoryDesignConfig.borderPrimary,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child:
                    _isLoading ? _buildLoadingState() : _buildInventoryTable(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      height: 40, // Match button height
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: InventoryDesignConfig.borderPrimary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTypeSelectorButton(
            label: 'Fabrics',
            icon: PhosphorIcons.scissors(),
            isSelected: widget.inventoryType == 'fabric',
            onTap: () => widget.onTypeChanged?.call('fabric'),
          ),
          _buildTypeSelectorButton(
            label: 'Accessories',
            icon: PhosphorIcons.package(),
            isSelected: widget.inventoryType == 'accessory',
            onTap: () => widget.onTypeChanged?.call('accessory'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelectorButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? InventoryDesignConfig.surfaceColor
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color:
                    isSelected
                        ? InventoryDesignConfig.primaryColor
                        : InventoryDesignConfig.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      isSelected
                          ? InventoryDesignConfig.textPrimary
                          : InventoryDesignConfig.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      width: 280,
      height: 40, // Match button height
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        border: Border.all(color: InventoryDesignConfig.borderPrimary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: InventoryDesignConfig.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search inventory...',
          hintStyle: GoogleFonts.inter(
            color: InventoryDesignConfig.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              PhosphorIcons.magnifyingGlass(),
              size: 16,
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: Icon(
                      PhosphorIcons.x(),
                      size: 14,
                      color: InventoryDesignConfig.textSecondary,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _loadInventoryItems();
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _loadInventoryItems();
        },
      ),
    );
  }

  Widget _buildModernFilterButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Filter functionality coming soon!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          height: 40, // Match other elements height
          padding: const EdgeInsets.symmetric(
            horizontal: InventoryDesignConfig.spacingL,
            vertical: InventoryDesignConfig.spacingM,
          ),
          decoration: InventoryDesignConfig.buttonSecondaryDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.funnel(),
                size: 16,
                color: InventoryDesignConfig.textSecondary,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingXS),
              Text('Filter', style: InventoryDesignConfig.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernPrimaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          height: 40, // Match other elements height
          padding: const EdgeInsets.symmetric(
            horizontal: InventoryDesignConfig.spacingL,
            vertical: InventoryDesignConfig.spacingM,
          ),
          decoration: InventoryDesignConfig.buttonPrimaryDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: InventoryDesignConfig.spacingXS),
              Text(
                label,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernStatsRow() {
    final totalItems = _inventoryItems.length;
    final lowStockItems =
        _inventoryItems.where((item) {
          final quantityAvailable = _toInt(item['quantity_available']);
          final minimumStockLevel = _toInt(item['minimum_stock_level']);
          return quantityAvailable <= minimumStockLevel;
        }).length;

    final totalValue = _inventoryItems.fold<double>(0, (sum, item) {
      final quantity = _toDouble(item['quantity_available']);
      final cost = _toDouble(item['cost_per_unit']);
      return sum + (quantity * cost);
    });

    return Container(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
      decoration: InventoryDesignConfig.cardDecoration,
      child: Row(
        children: [
          _buildModernStatCard(
            title: 'Total Items',
            value: totalItems.toString(),
            icon: PhosphorIcons.stack(),
            color: InventoryDesignConfig.primaryAccent,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingXXL),
          _buildModernStatCard(
            title: 'Low Stock',
            value: lowStockItems.toString(),
            icon: PhosphorIcons.warning(),
            color: InventoryDesignConfig.warningColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingXXL),
          _buildModernStatCard(
            title: 'Total Value',
            value: NumberFormat.currency(symbol: '\$').format(totalValue),
            icon: PhosphorIcons.currencyDollar(),
            color: InventoryDesignConfig.successColor,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: InventoryDesignConfig.spacingM,
              vertical: InventoryDesignConfig.spacingXS,
            ),
            decoration: BoxDecoration(
              color: InventoryDesignConfig.primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusS,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.inventoryType == 'fabric'
                      ? PhosphorIcons.scissors()
                      : PhosphorIcons.package(),
                  size: 14,
                  color: InventoryDesignConfig.primaryColor,
                ),
                const SizedBox(width: InventoryDesignConfig.spacingXS),
                Text(
                  '${widget.inventoryType == 'fabric' ? 'Fabric' : 'Accessory'} Inventory',
                  style: InventoryDesignConfig.bodySmall.copyWith(
                    color: InventoryDesignConfig.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: InventoryDesignConfig.spacingM),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: InventoryDesignConfig.headlineMedium),
            Text(title, style: InventoryDesignConfig.bodySmall),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: InventoryDesignConfig.primaryAccent,
      ),
    );
  }

  Widget _buildInventoryTable() {
    if (_inventoryItems.isEmpty) {
      return _buildEmptyState();
    }

    List<DataColumn> columns = [];
    if (widget.inventoryType == 'fabric') {
      columns = [
        _buildDataColumn('Code', 'fabric_code'),
        _buildDataColumn('Name', 'fabric_item_name'),
        _buildDataColumn('Type', 'fabric_type'),
        _buildDataColumn('Brand', 'brand_name'),
        _buildDataColumn('Color', 'shade_color'),
        _buildDataColumn('Stock', 'quantity_available'),
        _buildDataColumn('Unit', 'unit_type'),
        _buildDataColumn('Cost', 'cost_per_unit'),
        _buildDataColumn('Price', 'selling_price_per_unit'),
        const DataColumn(label: Text('')),
      ];
    } else {
      columns = [
        _buildDataColumn('Code', 'accessory_code'),
        _buildDataColumn('Name', 'accessory_item_name'),
        _buildDataColumn('Type', 'accessory_type'),
        _buildDataColumn('Brand', 'brand_name'),
        _buildDataColumn('Color', 'color'),
        _buildDataColumn('Stock', 'quantity_available'),
        _buildDataColumn('Unit', 'unit_type'),
        _buildDataColumn('Cost', 'cost_per_unit'),
        _buildDataColumn('Price', 'selling_price_per_unit'),
        const DataColumn(label: Text('')),
      ];
    }

    return Theme(
      data: Theme.of(context).copyWith(
        dataTableTheme: DataTableThemeData(
          headingRowColor: MaterialStateProperty.all(
            InventoryDesignConfig.surfaceAccent,
          ),
          dataRowColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.hovered)) {
              return InventoryDesignConfig.surfaceLight;
            }
            return InventoryDesignConfig.surfaceColor;
          }),
          headingTextStyle: InventoryDesignConfig.labelLarge,
          dataTextStyle: InventoryDesignConfig.bodyLarge,
        ),
      ),
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          child: DataTable(
            columnSpacing: InventoryDesignConfig.spacingXXXL,
            horizontalMargin: InventoryDesignConfig.spacingXXL,
            headingRowHeight: 52,
            dataRowMaxHeight: 60,
            dataRowMinHeight: 60,
            showCheckboxColumn: false,
            dividerThickness: 1,
            border: TableBorder(
              horizontalInside: BorderSide(
                color: InventoryDesignConfig.borderSecondary,
              ),
            ),
            columns: columns,
            rows:
                _inventoryItems.map((item) {
                  return widget.inventoryType == 'fabric'
                      ? _buildFabricRow(item)
                      : _buildAccessoryRow(item);
                }).toList(),
          ),
        ),
      ),
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
              widget.inventoryType == 'fabric'
                  ? PhosphorIcons.scissors()
                  : PhosphorIcons.package(),
              size: 48,
              color: InventoryDesignConfig.textTertiary,
            ),
          ),
          const SizedBox(height: InventoryDesignConfig.spacingXXL),
          Text('No items found', style: InventoryDesignConfig.headlineMedium),
          const SizedBox(height: InventoryDesignConfig.spacingS),
          Text(
            'Add some items to your inventory to get started',
            style: InventoryDesignConfig.bodyMedium,
          ),
          const SizedBox(height: InventoryDesignConfig.spacingXXL),
          _buildModernPrimaryButton(
            icon: PhosphorIcons.plus(),
            label: 'Add New Item',
            onPressed: () {
              AddInventoryDesktopDialog.show(
                context,
                inventoryType: widget.inventoryType,
                onItemAdded: _loadInventoryItems,
              );
            },
          ),
        ],
      ),
    );
  }

  DataColumn _buildDataColumn(String label, String column) {
    final isSorted = _sortColumn == column;

    return DataColumn(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase()),
          if (isSorted) ...[
            const SizedBox(width: InventoryDesignConfig.spacingXS),
            Icon(
              _sortAscending
                  ? PhosphorIcons.caretUp()
                  : PhosphorIcons.caretDown(),
              size: 12,
              color: InventoryDesignConfig.primaryAccent,
            ),
          ],
        ],
      ),
      onSort: (_, __) => _onSort(column),
    );
  }

  DataRow _buildFabricRow(Map<String, dynamic> fabric) {
    final quantityAvailable = _toInt(fabric['quantity_available']);
    final minimumStockLevel = _toInt(fabric['minimum_stock_level']);
    final isLowStock = quantityAvailable <= minimumStockLevel;

    return DataRow(
      cells: [
        DataCell(_buildCodeCell(fabric['fabric_code'])),
        DataCell(_buildNameCell(fabric['fabric_item_name'])),
        DataCell(
          _buildTypeCell(
            fabric['fabric_type'],
            InventoryDesignConfig.primaryAccent,
          ),
        ),
        DataCell(_buildTextCell(fabric['brand_name'])),
        DataCell(_buildColorCell(fabric['shade_color'], fabric['color_code'])),
        DataCell(_buildStockCell(quantityAvailable, isLowStock)),
        DataCell(_buildTextCell(fabric['unit_type'])),
        DataCell(_buildPriceCell(fabric['cost_per_unit'])),
        DataCell(_buildPriceCell(fabric['selling_price_per_unit'])),
        DataCell(_buildActionsCell(fabric)),
      ],
      onSelectChanged: (selected) {
        if (selected == true) {
          InventoryDetailDialogDesktop.show(
            context,
            item: fabric,
            inventoryType: 'fabric',
            onEdit: _loadInventoryItems,
            onDelete: _loadInventoryItems,
          );
        }
      },
    );
  }

  DataRow _buildAccessoryRow(Map<String, dynamic> accessory) {
    final quantityAvailable = _toInt(accessory['quantity_available']);
    final minimumStockLevel = _toInt(accessory['minimum_stock_level']);
    final isLowStock = quantityAvailable <= minimumStockLevel;

    return DataRow(
      cells: [
        DataCell(_buildCodeCell(accessory['accessory_code'])),
        DataCell(_buildNameCell(accessory['accessory_item_name'])),
        DataCell(
          _buildTypeCell(
            accessory['accessory_type'],
            InventoryDesignConfig.successColor,
          ),
        ),
        DataCell(_buildTextCell(accessory['brand_name'])),
        DataCell(_buildTextCell(accessory['color'])),
        DataCell(_buildStockCell(quantityAvailable, isLowStock)),
        DataCell(_buildTextCell(accessory['unit_type'])),
        DataCell(_buildPriceCell(accessory['cost_per_unit'])),
        DataCell(_buildPriceCell(accessory['selling_price_per_unit'])),
        DataCell(_buildActionsCell(accessory)),
      ],
      onSelectChanged: (selected) {
        if (selected == true) {
          InventoryDetailDialogDesktop.show(
            context,
            item: accessory,
            inventoryType: 'accessory',
            onEdit: _loadInventoryItems,
            onDelete: _loadInventoryItems,
          );
        }
      },
    );
  }

  Widget _buildCodeCell(String? code) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingS,
        vertical: InventoryDesignConfig.spacingXS,
      ),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceAccent,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
      ),
      child: Text(code ?? '', style: InventoryDesignConfig.code),
    );
  }

  Widget _buildNameCell(String? name) {
    return Text(name ?? '', style: InventoryDesignConfig.titleMedium);
  }

  Widget _buildTypeCell(String? type, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingS,
        vertical: InventoryDesignConfig.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
      ),
      child: Text(
        type ?? '',
        style: InventoryDesignConfig.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextCell(String? text) {
    return Text(text ?? '', style: InventoryDesignConfig.bodyLarge);
  }

  Widget _buildColorCell(String? colorName, String? colorCode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: _parseColor(colorCode ?? ''),
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
            border: Border.all(color: InventoryDesignConfig.borderPrimary),
          ),
        ),
        const SizedBox(width: InventoryDesignConfig.spacingS),
        Text(colorName ?? '', style: InventoryDesignConfig.bodyLarge),
      ],
    );
  }

  Widget _buildStockCell(int quantity, bool isLowStock) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color:
                isLowStock
                    ? InventoryDesignConfig.errorColor
                    : InventoryDesignConfig.successColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: InventoryDesignConfig.spacingS),
        Text(
          '$quantity',
          style: InventoryDesignConfig.titleMedium.copyWith(
            color:
                isLowStock
                    ? InventoryDesignConfig.errorColor
                    : InventoryDesignConfig.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceCell(dynamic price) {
    final numericPrice = _toDouble(price);
    return Text(
      NumberFormat.currency(symbol: '\$').format(numericPrice),
      style: InventoryDesignConfig.titleMedium,
    );
  }

  Widget _buildActionsCell(Map<String, dynamic> item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionIcon(
          icon: PhosphorIcons.pencilSimple(),
          onTap: () => _handleEditItem(item),
          color: InventoryDesignConfig.primaryAccent,
        ),
        const SizedBox(width: InventoryDesignConfig.spacingS),
        _buildActionIcon(
          icon: PhosphorIcons.trash(),
          onTap: () => _handleDeleteItem(item),
          color: InventoryDesignConfig.errorColor,
        ),
      ],
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
        child: Container(
          padding: const EdgeInsets.all(InventoryDesignConfig.spacingS),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Future<void> _handleEditItem(Map<String, dynamic> item) async {
    await EditInventoryDesktopDialog.show(
      context,
      item: item,
      inventoryType: widget.inventoryType,
      onItemUpdated: _loadInventoryItems,
    );
  }

  Future<void> _handleDeleteItem(Map<String, dynamic> item) async {
    final confirm = await _showDeleteConfirmationDialog(item);
    if (confirm != true) return;

    try {
      final table =
          widget.inventoryType == 'fabric'
              ? 'fabric_inventory'
              : 'accessories_inventory';

      await _supabase
          .from(table)
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', item['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.inventoryType == 'fabric' ? 'Fabric' : 'Accessory'} deleted successfully',
          ),
          backgroundColor: InventoryDesignConfig.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _loadInventoryItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting item: ${e.toString()}'),
          backgroundColor: InventoryDesignConfig.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final isFabric = widget.inventoryType == 'fabric';
    final itemName =
        item[isFabric ? 'fabric_item_name' : 'accessory_item_name'];

    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                InventoryDesignConfig.radiusL,
              ),
            ),
            title: Row(
              children: [
                Icon(
                  PhosphorIcons.warning(PhosphorIconsStyle.fill),
                  color: InventoryDesignConfig.errorColor,
                  size: 24,
                ),
                const SizedBox(width: InventoryDesignConfig.spacingM),
                Text(
                  'Confirm Deletion',
                  style: InventoryDesignConfig.titleLarge,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete this ${isFabric ? 'fabric' : 'accessory'}?',
                  style: InventoryDesignConfig.bodyLarge,
                ),
                const SizedBox(height: InventoryDesignConfig.spacingM),
                Container(
                  padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
                  decoration: BoxDecoration(
                    color: InventoryDesignConfig.errorColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(
                      InventoryDesignConfig.radiusM,
                    ),
                    border: Border.all(
                      color: InventoryDesignConfig.errorColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isFabric
                            ? PhosphorIcons.scissors()
                            : PhosphorIcons.package(),
                        color: InventoryDesignConfig.errorColor,
                        size: 16,
                      ),
                      const SizedBox(width: InventoryDesignConfig.spacingS),
                      Expanded(
                        child: Text(
                          itemName ?? 'Unknown Item',
                          style: InventoryDesignConfig.titleMedium.copyWith(
                            color: InventoryDesignConfig.errorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: InventoryDesignConfig.spacingM),
                Text(
                  'This action cannot be undone.',
                  style: InventoryDesignConfig.bodyMedium,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: InventoryDesignConfig.bodyMedium),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: Icon(PhosphorIcons.trash()),
                label: const Text('Delete'),
                style: FilledButton.styleFrom(
                  backgroundColor: InventoryDesignConfig.errorColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
    );
  }

  // Helper methods for type conversion
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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
      return InventoryDesignConfig.textTertiary;
    } catch (e) {
      return InventoryDesignConfig.textTertiary;
    }
  }
}
