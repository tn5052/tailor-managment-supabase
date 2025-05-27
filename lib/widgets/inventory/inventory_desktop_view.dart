import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_inventory_desktop_dialog.dart';
import 'fabric_color_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'inventory_detail_dialog_desktop.dart';

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

      // Updated query to join with brands and categories tables
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

      // Process the response and enhance it with brand and category info
      final processedItems =
          response.map<Map<String, dynamic>>((item) {
            final Map<String, dynamic> processedItem = Map.from(item);

            // Extract brand info
            if (item['brands'] != null) {
              processedItem['brand_name'] =
                  item['brands']['name'] ?? 'No Brand';
              processedItem['brand_id'] = item['brands']['id'];
            } else {
              processedItem['brand_name'] = 'No Brand';
            }

            // Extract category info
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
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading inventory: ${e.toString()}'),
            backgroundColor: Colors.red,
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
    // Refresh data when inventory type changes
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: Color(0xFF1A1C1E), // Dark background
      child: Column(
        children: [
          // Top Header with simplified layout and switcher
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Type Switcher
                Row(
                  children: [
                    // Type Switcher - Clean, minimal toggle buttons
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Color(0xFF2D2F31),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTypeSwitcherButton(
                            title: 'Fabrics',
                            icon: PhosphorIcons.scissors(),
                            isSelected: widget.inventoryType == 'fabric',
                            onTap: () => widget.onTypeChanged?.call('fabric'),
                          ),
                          _buildTypeSwitcherButton(
                            title: 'Accessories',
                            icon: PhosphorIcons.package(),
                            isSelected: widget.inventoryType == 'accessory',
                            onTap:
                                () => widget.onTypeChanged?.call('accessory'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Subtitle text
                    Text(
                      'Manage your ${widget.inventoryType} inventory',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    // Search Field with Modern Design
                    Container(
                      width: 300,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Color(0xFF2D2F31),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search inventory...',
                          hintStyle: GoogleFonts.inter(color: Colors.white54),
                          prefixIcon: Icon(
                            PhosphorIcons.magnifyingGlass(),
                            color: Colors.white54,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                          _loadInventoryItems();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Filter button
                    _buildActionButton(
                      icon: PhosphorIcons.funnelSimple(),
                      label: 'Filter',
                      onPressed: () {
                        /* Show filter */
                      },
                      bgColor: Color(0xFF2D2F31),
                      textColor: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    // Add New button
                    _buildActionButton(
                      icon: PhosphorIcons.plus(),
                      label: 'Add New',
                      onPressed: () {
                        AddInventoryDesktopDialog.show(
                          context,
                          inventoryType: widget.inventoryType,
                          onItemAdded: _loadInventoryItems,
                        );
                      },
                      bgColor: Color(0xFF2B5EE3), // Accent blue
                      textColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Stats Cards Row
                Row(
                  children: [
                    _buildStatCard(
                      icon: PhosphorIcons.stack(),
                      title: 'Total Items',
                      value: _inventoryItems.length.toString(),
                      trend: '+5% from last month',
                      trendUp: true,
                    ),
                    _buildStatCard(
                      icon: PhosphorIcons.warning(),
                      title: 'Low Stock Items',
                      value:
                          _inventoryItems
                              .where(
                                (item) =>
                                    (item['quantity_available'] ?? 0) <=
                                    (item['minimum_stock_level'] ?? 0),
                              )
                              .length
                              .toString(),
                      trend: '2 items need attention',
                      trendUp: false,
                      isWarning: true,
                    ),
                    _buildStatCard(
                      icon: PhosphorIcons.currencyDollar(),
                      title: 'Total Value',
                      value: NumberFormat.currency(symbol: '\$').format(
                        _inventoryItems.fold<double>(
                          0,
                          (sum, item) =>
                              sum +
                              ((item['quantity_available'] ?? 0) *
                                  (item['cost_per_unit'] ?? 0)),
                        ),
                      ),
                      trend: '+12% from last month',
                      trendUp: true,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Table Container
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              decoration: BoxDecoration(
                color: Color(0xFF2D2F31),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child:
                    _isLoading
                        ? Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF2B5EE3),
                          ),
                        )
                        : _buildInventoryTable(theme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Type switcher button widget
  Widget _buildTypeSwitcherButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF2B5EE3) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String trend,
    required bool trendUp,
    bool isWarning = false,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF2D2F31),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isWarning ? Color(0xFF392E2E) : Color(0xFF2B3147),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isWarning ? Color(0xFFE57373) : Color(0xFF64B5F6),
                    size: 20,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      trendUp
                          ? PhosphorIcons.arrowUp()
                          : PhosphorIcons.arrowDown(),
                      color: trendUp ? Color(0xFF81C784) : Color(0xFFE57373),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trend,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: trendUp ? Color(0xFF81C784) : Color(0xFFE57373),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color bgColor,
    required Color textColor,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Update _buildInventoryTable method to match the new design and make the table full width
  Widget _buildInventoryTable(ThemeData theme) {
    if (_inventoryItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.inventoryType == 'fabric'
                  ? PhosphorIcons.scissors()
                  : PhosphorIcons.package(),
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No items found',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some items to your inventory',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                AddInventoryDesktopDialog.show(
                  context,
                  inventoryType: widget.inventoryType,
                  onItemAdded: _loadInventoryItems,
                );
              },
              icon: Icon(PhosphorIcons.plus()),
              label: const Text('Add New Item'),
            ),
          ],
        ),
      );
    }

    // Determine columns based on inventory type - UPDATED
    List<DataColumn> columns = [];
    if (widget.inventoryType == 'fabric') {
      columns = [
        _buildDataColumn('Code', 'fabric_code'),
        _buildDataColumn('Brand', 'brand_name'),
        _buildDataColumn('Fabric Name', 'fabric_item_name'),
        _buildDataColumn('Type', 'fabric_type'),
        _buildDataColumn('Color', 'shade_color'),
        _buildDataColumn('Available', 'quantity_available'),
        _buildDataColumn('Unit', 'unit_type'),
        _buildDataColumn('Cost', 'cost_per_unit'),
        _buildDataColumn('Price', 'selling_price_per_unit'),
        const DataColumn(label: Text('Actions')),
      ];
    } else {
      columns = [
        _buildDataColumn('Code', 'accessory_code'),
        _buildDataColumn('Name', 'accessory_item_name'),
        _buildDataColumn('Type', 'accessory_type'),
        _buildDataColumn('Brand', 'brand_name'),
        _buildDataColumn('Color', 'color'),
        _buildDataColumn('Available', 'quantity_available'),
        _buildDataColumn('Unit', 'unit_type'),
        _buildDataColumn('Cost', 'cost_per_unit'),
        _buildDataColumn('Price', 'selling_price_per_unit'),
        const DataColumn(label: Text('Actions')),
      ];
    }

    return Scrollbar(
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Theme(
          data: theme.copyWith(
            cardTheme: CardTheme(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            dividerTheme: const DividerThemeData(thickness: 0.3),
            // Add hover styling to the data table theme
            dataTableTheme: DataTableThemeData(
              dataRowColor: MaterialStateProperty.resolveWith<Color?>((
                Set<MaterialState> states,
              ) {
                if (states.contains(MaterialState.hovered)) {
                  return theme.colorScheme.primary.withOpacity(0.05);
                }
                if (states.contains(MaterialState.selected)) {
                  return theme.colorScheme.primary.withOpacity(0.08);
                }
                return Colors.transparent;
              }),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                width: constraints.maxWidth,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Color(0xFF21252A)),
                  dataRowColor: MaterialStateProperty.resolveWith<Color>((
                    Set<MaterialState> states,
                  ) {
                    if (states.contains(MaterialState.hovered)) {
                      return theme.colorScheme.primary.withOpacity(0.05);
                    }
                    if (states.contains(MaterialState.selected)) {
                      return theme.colorScheme.primary.withOpacity(0.08);
                    }
                    return Colors.transparent;
                  }),
                  headingTextStyle: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  dataRowMaxHeight: 64,
                  dataRowMinHeight: 64,
                  columnSpacing: 24,
                  horizontalMargin: 16,
                  showCheckboxColumn: false,
                  dividerThickness: 0.3,
                  columns: columns,
                  rows:
                      _inventoryItems.map((item) {
                        if (widget.inventoryType == 'fabric') {
                          return _buildFabricRow(item, theme);
                        } else {
                          return _buildAccessoryRow(item, theme);
                        }
                      }).toList(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  DataColumn _buildDataColumn(String label, String column) {
    final isSorted = _sortColumn == column;

    return DataColumn(
      label: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isSorted ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          if (isSorted)
            Icon(
              _sortAscending
                  ? PhosphorIcons.arrowUp()
                  : PhosphorIcons.arrowDown(),
              size: 16,
            ),
        ],
      ),
      onSort: (_, __) => _onSort(column),
    );
  }

  DataRow _buildFabricRow(Map<String, dynamic> fabric, ThemeData theme) {
    final isLowStock =
        (fabric['quantity_available'] ?? 0) <=
        (fabric['minimum_stock_level'] ?? 0);

    return DataRow(
      cells: [
        DataCell(Text(fabric['fabric_code'] ?? '')),
        DataCell(Text(fabric['brand_name'] ?? 'No Brand')),
        DataCell(Text(fabric['fabric_item_name'] ?? '')),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              fabric['fabric_type'] ?? 'Uncategorized',
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _parseColor(fabric['color_code'] ?? ''),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.5),
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fabric['shade_color'] ?? 'No color',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isLowStock
                          ? theme.colorScheme.error.withOpacity(0.1)
                          : theme.colorScheme.primaryContainer.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${fabric['quantity_available'] ?? 0}',
                  style: TextStyle(
                    color:
                        isLowStock
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isLowStock) ...[
                const SizedBox(width: 4),
                Icon(
                  PhosphorIcons.warning(),
                  color: theme.colorScheme.error,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
        DataCell(Text(fabric['unit_type'] ?? '')),
        DataCell(
          Text(
            NumberFormat.currency(
              symbol: '\$',
            ).format(fabric['cost_per_unit'] ?? 0),
          ),
        ),
        DataCell(
          Text(
            NumberFormat.currency(
              symbol: '\$',
            ).format(fabric['selling_price_per_unit'] ?? 0),
          ),
        ),
        DataCell(
          Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Tooltip(
                  message: 'Edit',
                  child: IconButton(
                    icon: Icon(
                      PhosphorIcons.pencilSimple(),
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () {
                      // Edit item
                    },
                    splashRadius: 20,
                    hoverColor: theme.colorScheme.primary.withOpacity(0.1),
                  ),
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Tooltip(
                  message: 'Delete',
                  child: IconButton(
                    icon: Icon(
                      PhosphorIcons.trash(),
                      color: theme.colorScheme.error,
                    ),
                    onPressed: () {
                      // Delete item
                    },
                    splashRadius: 20,
                    hoverColor: theme.colorScheme.error.withOpacity(0.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      onSelectChanged: (selected) {
        if (selected == true) {
          // Show the detail dialog when row is clicked
          InventoryDetailDialogDesktop.show(
            context,
            item: fabric,
            inventoryType: 'fabric',
            onEdit: () {
              // Implement edit functionality
              Navigator.of(context).pop();
              // Open edit dialog
            },
            onDelete: () {
              // Implement delete functionality
              Navigator.of(context).pop();
              // Show delete confirmation
            },
          );
        }
      },
    );
  }

  // Add this method to open the color picker
  Future<void> _openColorPicker({required Map<String, dynamic> fabric}) async {
    Color? initialColor;
    if (fabric['color_code'] != null && fabric['color_code'].isNotEmpty) {
      try {
        initialColor = _parseColor(fabric['color_code']);
      } catch (e) {
        // Use default if parsing fails
        initialColor = Colors.white;
      }
    }

    final result = await FabricColorPicker.show(
      context,
      initialColor: initialColor,
      initialColorName: fabric['shade_color'],
    );

    if (result != null) {
      // Update the color in the database
      try {
        await _supabase
            .from('fabric_inventory')
            .update({
              'shade_color': result.colorName,
              'color_code': result.hexCode,
            })
            .eq('id', fabric['id']);

        // Refresh the list
        _loadInventoryItems();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Color updated to ${result.colorName}'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating color: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  DataRow _buildAccessoryRow(Map<String, dynamic> accessory, ThemeData theme) {
    final isLowStock =
        (accessory['quantity_available'] ?? 0) <=
        (accessory['minimum_stock_level'] ?? 0);

    return DataRow(
      cells: [
        DataCell(Text(accessory['accessory_code'] ?? '')),
        DataCell(Text(accessory['accessory_item_name'] ?? '')),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer.withOpacity(0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              accessory['accessory_type'] ?? 'Uncategorized',
              style: TextStyle(
                color: theme.colorScheme.onTertiaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        DataCell(Text(accessory['brand_name'] ?? 'No Brand')),
        DataCell(Text(accessory['color'] ?? 'N/A')),
        DataCell(
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isLowStock
                          ? theme.colorScheme.error.withOpacity(0.1)
                          : theme.colorScheme.primaryContainer.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${accessory['quantity_available'] ?? 0}',
                  style: TextStyle(
                    color:
                        isLowStock
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isLowStock) ...[
                const SizedBox(width: 4),
                Icon(
                  PhosphorIcons.warning(),
                  color: theme.colorScheme.error,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
        DataCell(Text(accessory['unit_type'] ?? '')),
        DataCell(
          Text(
            NumberFormat.currency(
              symbol: '\$',
            ).format(accessory['cost_per_unit'] ?? 0),
          ),
        ),
        DataCell(
          Text(
            NumberFormat.currency(
              symbol: '\$',
            ).format(accessory['selling_price_per_unit'] ?? 0),
          ),
        ),
        DataCell(
          Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Tooltip(
                  message: 'Edit',
                  child: IconButton(
                    icon: Icon(
                      PhosphorIcons.pencilSimple(),
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () {
                      // Edit item
                    },
                    splashRadius: 20,
                    hoverColor: theme.colorScheme.primary.withOpacity(0.1),
                  ),
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Tooltip(
                  message: 'Delete',
                  child: IconButton(
                    icon: Icon(
                      PhosphorIcons.trash(),
                      color: theme.colorScheme.error,
                    ),
                    onPressed: () {
                      // Delete item
                    },
                    splashRadius: 20,
                    hoverColor: theme.colorScheme.error.withOpacity(0.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      onSelectChanged: (selected) {
        if (selected == true) {
          // Show the detail dialog when row is clicked
          InventoryDetailDialogDesktop.show(
            context,
            item: accessory,
            inventoryType: 'accessory',
            onEdit: () {
              // Implement edit functionality
              Navigator.of(context).pop();
              // Open edit dialog
            },
            onDelete: () {
              // Implement delete functionality
              Navigator.of(context).pop();
              // Show delete confirmation
            },
          );
        }
      },
    );
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
}
