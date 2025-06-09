import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_inventory_desktop_dialog.dart';
import 'fabric_color_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'inventory_detail_dialog_desktop.dart';
import 'edit_inventory_desktop_dialog.dart';

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

  // Modern minimalistic color palette
  static const _backgroundColor = Color(0xFFFAFAFA);
  static const _surfaceColor = Color(0xFFFFFFFF);
  static const _primaryColor = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _borderColor = Color(0xFFE5E7EB);
  static const _successColor = Color(0xFF059669);
  static const _warningColor = Color(0xFFD97706);
  static const _errorColor = Color(0xFFDC2626);

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
            backgroundColor: _errorColor,
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
      decoration: const BoxDecoration(color: _backgroundColor),
      child: Column(
        children: [
          // Compact header section with title and controls
          Container(
            decoration: const BoxDecoration(color: _backgroundColor),
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
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            PhosphorIcons.warehouse(),
                            size: 22,
                            color: _primaryColor,
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
                                color: _textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Manage fabrics and accessories',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: _textSecondary,
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
                        _buildFilterButton(),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          icon: PhosphorIcons.plus(),
                          label: 'Add Item',
                          isPrimary: true,
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
                _buildStatsRow(),
              ],
            ),
          ),

          // Table container with matching background
          Expanded(
            child: Container(
              decoration: const BoxDecoration(color: _backgroundColor),
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Container(
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  border: Border.all(color: _borderColor),
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
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor.withOpacity(0.3)),
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
            color: isSelected ? _surfaceColor : Colors.transparent,
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
                color: isSelected ? _primaryColor : _textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? _textPrimary : _textSecondary,
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
      height: 36,
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(fontSize: 14, color: _textPrimary),
        decoration: InputDecoration(
          hintText: 'Search inventory...',
          hintStyle: GoogleFonts.inter(
            color: _textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              PhosphorIcons.magnifyingGlass(),
              size: 16,
              color: _textSecondary,
            ),
          ),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: Icon(
                      PhosphorIcons.x(),
                      size: 14,
                      color: _textSecondary,
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

  Widget _buildFilterButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Filter functionality coming soon!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _surfaceColor,
            border: Border.all(color: _borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIcons.funnel(), size: 16, color: _textSecondary),
              const SizedBox(width: 6),
              Text(
                'Filter',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
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
          _buildStatCard(
            title: 'Total Items',
            value: totalItems.toString(),
            icon: PhosphorIcons.stack(),
            color: _primaryColor,
          ),
          const SizedBox(width: 24),
          _buildStatCard(
            title: 'Low Stock',
            value: lowStockItems.toString(),
            icon: PhosphorIcons.warning(),
            color: _warningColor,
          ),
          const SizedBox(width: 24),
          _buildStatCard(
            title: 'Total Value',
            value: NumberFormat.currency(symbol: '\$').format(totalValue),
            icon: PhosphorIcons.currencyDollar(),
            color: _successColor,
          ),
          const Spacer(),
          // Current inventory type indicator - smaller and more subtle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.inventoryType == 'fabric'
                      ? PhosphorIcons.scissors()
                      : PhosphorIcons.package(),
                  size: 14,
                  color: _primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.inventoryType == 'fabric' ? 'Fabric' : 'Accessory'} Inventory',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _primaryColor,
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator(color: _primaryColor));
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
        const DataColumn(label: Text('')), // Actions
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
        const DataColumn(label: Text('')), // Actions
      ];
    }

    return Theme(
      data: Theme.of(context).copyWith(
        dataTableTheme: DataTableThemeData(
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF9FAFB)),
          dataRowColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.hovered)) {
              return const Color(0xFFF9FAFB);
            }
            return Colors.white;
          }),
          headingTextStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _textSecondary,
            letterSpacing: 0.5,
          ),
          dataTextStyle: GoogleFonts.inter(fontSize: 14, color: _textPrimary),
        ),
      ),
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          child: DataTable(
            columnSpacing: 32,
            horizontalMargin: 24,
            headingRowHeight: 48,
            dataRowMaxHeight: 56,
            dataRowMinHeight: 56,
            showCheckboxColumn: false,
            dividerThickness: 1,
            border: TableBorder(
              horizontalInside: BorderSide(
                color: _borderColor.withOpacity(0.5),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.inventoryType == 'fabric'
                  ? PhosphorIcons.scissors()
                  : PhosphorIcons.package(),
              size: 32,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some items to your inventory to get started',
            style: GoogleFonts.inter(fontSize: 14, color: _textSecondary),
          ),
          const SizedBox(height: 24),
          _buildActionButton(
            icon: PhosphorIcons.plus(),
            label: 'Add New Item',
            isPrimary: true,
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
            const SizedBox(width: 4),
            Icon(
              _sortAscending
                  ? PhosphorIcons.caretUp()
                  : PhosphorIcons.caretDown(),
              size: 12,
              color: _primaryColor,
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
        DataCell(_buildTypeCell(fabric['fabric_type'], _primaryColor)),
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
        DataCell(_buildTypeCell(accessory['accessory_type'], _successColor)),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        code ?? '',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _textSecondary,
        ),
      ),
    );
  }

  Widget _buildNameCell(String? name) {
    return Text(
      name ?? '',
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _textPrimary,
      ),
    );
  }

  Widget _buildTypeCell(String? type, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type ?? '',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTextCell(String? text) {
    return Text(
      text ?? '',
      style: GoogleFonts.inter(fontSize: 14, color: _textPrimary),
    );
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
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: _borderColor),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          colorName ?? '',
          style: GoogleFonts.inter(fontSize: 14, color: _textPrimary),
        ),
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
            color: isLowStock ? _errorColor : _successColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$quantity',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isLowStock ? _errorColor : _textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceCell(dynamic price) {
    final numericPrice = _toDouble(price);
    return Text(
      NumberFormat.currency(symbol: '\$').format(numericPrice),
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _textPrimary,
      ),
    );
  }

  Widget _buildActionsCell(Map<String, dynamic> item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionIcon(
          icon: PhosphorIcons.pencilSimple(),
          onTap: () => _handleEditItem(item),
          color: _primaryColor,
        ),
        const SizedBox(width: 8),
        _buildActionIcon(
          icon: PhosphorIcons.trash(),
          onTap: () => _handleDeleteItem(item),
          color: _errorColor,
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(6),
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
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _loadInventoryItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting item: ${e.toString()}'),
          backgroundColor: Colors.red,
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
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  PhosphorIcons.warning(PhosphorIconsStyle.fill),
                  color: theme.colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text('Confirm Deletion'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete this ${isFabric ? 'fabric' : 'accessory'}?',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isFabric
                            ? PhosphorIcons.scissors()
                            : PhosphorIcons.package(),
                        color: theme.colorScheme.error,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          itemName ?? 'Unknown Item',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: Icon(PhosphorIcons.trash()),
                label: const Text('Delete'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
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
    if (colorCode.isEmpty) return Colors.grey;

    try {
      if (colorCode.startsWith('#')) {
        String hexCode = colorCode.substring(1);
        if (hexCode.length == 6) {
          return Color(int.parse('FF$hexCode', radix: 16));
        }
      }
      return Colors.grey;
    } catch (e) {
      return Colors.grey;
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isPrimary ? _primaryColor : _surfaceColor,
            border: Border.all(color: isPrimary ? _primaryColor : _borderColor),
            borderRadius: BorderRadius.circular(8),
            boxShadow:
                isPrimary
                    ? [
                      BoxShadow(
                        color: _primaryColor.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
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
                color: isPrimary ? Colors.white : _textPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : _textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
