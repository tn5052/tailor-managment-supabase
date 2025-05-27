import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabasetest/widgets/inventory/inventory_detail_dialog_mobile.dart';
import 'add_inventory_mobile_sheet.dart';

class InventoryMobileView extends StatefulWidget {
  final String inventoryType; // 'fabric' or 'accessory'
  final Function(String)? onTypeChanged;

  const InventoryMobileView({
    super.key,
    required this.inventoryType,
    this.onTypeChanged,
  });

  @override
  State<InventoryMobileView> createState() => _InventoryMobileViewState();
}

class _InventoryMobileViewState extends State<InventoryMobileView>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  String _sortBy = 'created_at';
  bool _isLoading = false;
  List<Map<String, dynamic>> _inventoryItems = [];

  TabController? _tabController;
  final List<String> _inventoryTypes = ['fabric', 'accessory'];

  String? _selectedFilter;
  final List<String> _filterOptions = [
    'All',
    'Low Stock',
    'New Items',
    'Expensive',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.inventoryType == 'fabric' ? 0 : 1,
    );
    _tabController!.addListener(_handleTabChange);
    _loadInventoryItems();
  }

  void _handleTabChange() {
    if (_tabController!.indexIsChanging) return;
    final newType = _inventoryTypes[_tabController!.index];
    if (newType != widget.inventoryType) {
      widget.onTypeChanged?.call(newType);
    }
  }

  @override
  void didUpdateWidget(InventoryMobileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update tab controller when inventory type changes externally
    if (oldWidget.inventoryType != widget.inventoryType) {
      _tabController?.animateTo(_inventoryTypes.indexOf(widget.inventoryType));

      // Reset state and reload
      _searchController.clear();
      _searchQuery = '';
      _selectedFilter = null;
      _sortBy = 'created_at';
      _inventoryItems.clear();
      _loadInventoryItems();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadInventoryItems() async {
    setState(() => _isLoading = true);

    try {
      final table =
          widget.inventoryType == 'fabric'
              ? 'fabric_inventory'
              : 'accessories_inventory';

      // Define select query with proper joins
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

      // Start building the query
      var query = _supabase
          .from(table)
          .select(selectQuery)
          .eq('is_active', true);

      // Add search filter if query exists
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

      // Apply additional filters
      if (_selectedFilter == 'Low Stock') {
        query = query.lt('quantity_available', 10);
      } else if (_selectedFilter == 'New Items') {
        final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
        query = query.gte('created_at', cutoffDate.toIso8601String());
      } else if (_selectedFilter == 'Expensive') {
        query = query.gte('selling_price_per_unit', 50);
      }

      // Apply order after all filters
      final response = await query.order(_sortBy, ascending: false);

      // Process the response to extract nested brand and category data
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
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading items: ${e.toString()}')),
        );
      }
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.3,
              maxChildSize: 0.8,
              expand: false,
              builder:
                  (context, scrollController) => Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Filter Items',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            _buildFilterSection('Sort By', [
                              'Newest First',
                              'Oldest First',
                              'Name (A-Z)',
                              'Name (Z-A)',
                              'Price (High-Low)',
                              'Price (Low-High)',
                            ]),
                            const Divider(),
                            _buildFilterSection('Filter By', _filterOptions),
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedFilter = null;
                                          _sortBy = 'created_at';
                                        });
                                        Navigator.pop(context);
                                        _loadInventoryItems();
                                      },
                                      child: const Text('Reset'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _loadInventoryItems();
                                      },
                                      child: const Text('Apply'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
            ),
          ),
    );
  }

  Widget _buildFilterSection(String title, List<String> options) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                options.map((option) {
                  final isSelected =
                      _selectedFilter == option ||
                      (title == 'Sort By' &&
                          ((option == 'Newest First' &&
                                  _sortBy == 'created_at') ||
                              (option == 'Oldest First' &&
                                  _sortBy == 'created_at') ||
                              (option == 'Name (A-Z)' &&
                                  _sortBy == 'fabric_name') ||
                              (option == 'Name (Z-A)' &&
                                  _sortBy == 'fabric_name') ||
                              (option == 'Price (High-Low)' &&
                                  _sortBy == 'selling_price_per_unit') ||
                              (option == 'Price (Low-High)' &&
                                  _sortBy == 'selling_price_per_unit')));

                  return FilterChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (title == 'Sort By') {
                          switch (option) {
                            case 'Newest First':
                              _sortBy = 'created_at';
                              break;
                            case 'Oldest First':
                              _sortBy = 'created_at';
                              break;
                            case 'Name (A-Z)':
                              _sortBy =
                                  widget.inventoryType == 'fabric'
                                      ? 'fabric_name'
                                      : 'accessory_name';
                              break;
                            case 'Name (Z-A)':
                              _sortBy =
                                  widget.inventoryType == 'fabric'
                                      ? 'fabric_name'
                                      : 'accessory_name';
                              break;
                            case 'Price (High-Low)':
                              _sortBy = 'selling_price_per_unit';
                              break;
                            case 'Price (Low-High)':
                              _sortBy = 'selling_price_per_unit';
                              break;
                          }
                        } else {
                          _selectedFilter = selected ? option : null;
                        }
                      });
                    },
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  void _showItemDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder:
                  (context, scrollController) => CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Handle bar
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 16,
                                ),
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),

                            // Header
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Color swatch or icon
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: _parseColor(
                                      widget.inventoryType == 'fabric'
                                          ? item['color_code'] ?? ''
                                          : item['color'] ?? '',
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline.withOpacity(0.5),
                                    ),
                                  ),
                                  child:
                                      widget.inventoryType == 'fabric'
                                          ? Icon(
                                            PhosphorIcons.scissors(),
                                            color: Colors.white,
                                            size: 32,
                                          )
                                          : Icon(
                                            PhosphorIcons.package(),
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                ),
                                const SizedBox(width: 16),

                                // Title and subtitle
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.inventoryType == 'fabric'
                                            ? item['fabric_item_name'] ??
                                                'Unknown Fabric'
                                            : item['accessory_item_name'] ??
                                                'Unknown Accessory',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.inventoryType == 'fabric'
                                            ? '${item['brand_name'] ?? 'No Brand'} · ${widget.inventoryType == 'fabric' ? item['fabric_type'] : item['accessory_type']}'
                                            : '${item['brand_name'] ?? 'No Brand'} · ${item['accessory_type'] ?? 'Unknown Type'}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.copyWith(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          widget.inventoryType == 'fabric'
                                              ? item['fabric_code'] ?? 'No Code'
                                              : item['accessory_code'] ??
                                                  'No Code',
                                          style: TextStyle(
                                            color:
                                                Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Close button
                                IconButton(
                                  icon: Icon(PhosphorIcons.x()),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Inventory stats cards
                            Row(
                              children: [
                                _buildDetailStatCard(
                                  'Available',
                                  '${item['quantity_available'] ?? 0}',
                                  '${item['unit_type'] ?? 'units'}',
                                  PhosphorIcons.stack(),
                                  Theme.of(context).colorScheme.primary,
                                ),
                                _buildDetailStatCard(
                                  'Cost',
                                  NumberFormat.currency(
                                    symbol: '\$',
                                  ).format(item['cost_per_unit'] ?? 0),
                                  'per ${item['unit_type'] ?? 'unit'}',
                                  PhosphorIcons.currencyDollar(),
                                  Theme.of(context).colorScheme.tertiary,
                                ),
                                _buildDetailStatCard(
                                  'Selling Price',
                                  NumberFormat.currency(
                                    symbol: '\$',
                                  ).format(item['selling_price_per_unit'] ?? 0),
                                  'per ${item['unit_type'] ?? 'unit'}',
                                  PhosphorIcons.tag(),
                                  Theme.of(context).colorScheme.secondary,
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Item details
                            _buildDetailSection('Details', [
                              _buildDetailRow(
                                'Item Code',
                                widget.inventoryType == 'fabric'
                                    ? item['fabric_code']
                                    : item['accessory_code'],
                              ),
                              _buildDetailRow('Brand', item['brand_name']),
                              _buildDetailRow(
                                'Name',
                                widget.inventoryType == 'fabric'
                                    ? item['fabric_item_name']
                                    : item['accessory_item_name'],
                              ),
                              _buildDetailRow(
                                'Type',
                                widget.inventoryType == 'fabric'
                                    ? item['fabric_type']
                                    : item['accessory_type'],
                              ),
                              _buildDetailRow(
                                'Color',
                                widget.inventoryType == 'fabric'
                                    ? item['shade_color']
                                    : item['color'],
                              ),
                              if (widget.inventoryType == 'fabric') ...[
                                _buildDetailRow(
                                  'Width',
                                  '${item['fabric_width'] ?? 'N/A'} cm',
                                ),
                                _buildDetailRow(
                                  'Weight',
                                  '${item['fabric_weight'] ?? 'N/A'} g',
                                ),
                              ] else ...[
                                _buildDetailRow(
                                  'Size',
                                  item['size_specification'] ?? 'N/A',
                                ),
                              ],
                              _buildDetailRow('Unit Type', item['unit_type']),
                              _buildDetailRow(
                                'Min. Stock Level',
                                '${item['minimum_stock_level']}',
                              ),
                            ]),

                            const SizedBox(height: 16),

                            // Supplier information
                            _buildDetailSection('Supplier Information', [
                              _buildDetailRow(
                                'Supplier',
                                item['supplier_name'] ?? 'N/A',
                              ),
                              _buildDetailRow(
                                'Contact',
                                item['supplier_contact'] ?? 'N/A',
                              ),
                              _buildDetailRow(
                                'Purchase Date',
                                item['purchase_date'] != null
                                    ? DateFormat('MMM d, yyyy').format(
                                      DateTime.parse(item['purchase_date']),
                                    )
                                    : 'N/A',
                              ),
                              _buildDetailRow(
                                'Location',
                                item['storage_location'] ?? 'N/A',
                              ),
                            ]),

                            const SizedBox(height: 16),

                            // Notes
                            _buildDetailSection('Notes', [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item['notes'] ?? 'No notes available',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ]),

                            const SizedBox(height: 24),

                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      // Update stock
                                      Navigator.pop(context);
                                    },
                                    icon: Icon(PhosphorIcons.arrowsClockwise()),
                                    label: const Text('Update Stock'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () {
                                      // Edit item
                                      Navigator.pop(context);
                                    },
                                    icon: Icon(PhosphorIcons.pencilSimple()),
                                    label: const Text('Edit Item'),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
            ),
          ),
    );
  }

  Widget _buildDetailStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withAlpha((255 * 0.1).round()),
        margin: const EdgeInsets.only(right: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withAlpha((255 * 0.8).round()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withAlpha((255 * 0.8).round()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use colors inspired from desktop inventory
    final backgroundColor =
        isDark ? const Color(0xFF1A1C1E) : theme.scaffoldBackgroundColor;
    final cardColor = isDark ? const Color(0xFF2D2F31) : theme.cardColor;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Inventory Management',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.funnel()),
            onPressed: _showFilterBottomSheet,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: Icon(PhosphorIcons.plus()),
            onPressed: () {
              AddInventoryMobileSheet.show(
                context,
                inventoryType: widget.inventoryType,
                onItemAdded: _loadInventoryItems,
              );
            },
            tooltip: 'Add Item',
          ),
        ],
        backgroundColor: backgroundColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            onTap: (index) {
              final newType = _inventoryTypes[index];
              widget.onTypeChanged?.call(newType);
            },
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIcons.scissors()),
                    const SizedBox(width: 8),
                    Text('Fabrics', style: GoogleFonts.inter()),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIcons.package()),
                    const SizedBox(width: 8),
                    Text('Accessories', style: GoogleFonts.inter()),
                  ],
                ),
              ),
            ],
            labelColor: primaryColor,
            unselectedLabelColor:
                isDark
                    ? Colors.white70
                    : theme.colorScheme.onSurface.withOpacity(0.7),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 3,
            indicatorColor: primaryColor,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar - modern and compact
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.inter(),
              decoration: InputDecoration(
                hintText:
                    'Search ${widget.inventoryType == 'fabric' ? 'fabrics' : 'accessories'}...',
                hintStyle: GoogleFonts.inter(color: theme.hintColor),
                prefixIcon: Icon(PhosphorIcons.magnifyingGlass(), size: 20),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: Icon(PhosphorIcons.x(), size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _loadInventoryItems();
                          },
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _loadInventoryItems();
              },
            ),
          ),

          // Filter chips - horizontal and compact
          Container(
            height: 40,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // "All" filter
                _buildFilterChip('All', _selectedFilter == null),
                ...['Low Stock', 'New Items', 'Expensive']
                    .map(
                      (filter) =>
                          _buildFilterChip(filter, _selectedFilter == filter),
                    )
                    .toList(),
              ],
            ),
          ),

          // Inventory list - with modern cards
          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                    : _inventoryItems.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                      color: primaryColor,
                      onRefresh: _loadInventoryItems,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _inventoryItems.length,
                        itemBuilder: (context, index) {
                          final item = _inventoryItems[index];
                          return _buildInventoryCard(item);
                        },
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          AddInventoryMobileSheet.show(
            context,
            inventoryType: widget.inventoryType,
            onItemAdded: _loadInventoryItems,
          );
        },
        backgroundColor: primaryColor,
        child: Icon(PhosphorIcons.plus(), color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: RawChip(
        label: Text(
          label,
          style: GoogleFonts.inter(
            color:
                isSelected
                    ? (isDark ? Colors.white : theme.colorScheme.onPrimary)
                    : theme.colorScheme.onSurface.withOpacity(0.8),
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        selected: isSelected,
        showCheckmark: false,
        avatar:
            isSelected
                ? Icon(
                  PhosphorIcons.check(),
                  size: 14,
                  color: isDark ? Colors.white : theme.colorScheme.onPrimary,
                )
                : null,
        backgroundColor:
            isDark
                ? const Color(0xFF2D2F31)
                : theme.colorScheme.surfaceVariant.withOpacity(0.7),
        selectedColor: theme.colorScheme.primary.withOpacity(
          isDark ? 0.3 : 0.2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onSelected: (selected) {
          setState(() {
            _selectedFilter =
                selected
                    ? label == 'All'
                        ? null
                        : label
                    : null;
          });
          _loadInventoryItems();
        },
      ),
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2D2F31) : theme.cardColor;
    final isFabric = widget.inventoryType == 'fabric';

    final isLowStock =
        (item['quantity_available'] ?? 0) <= (item['minimum_stock_level'] ?? 0);
    final itemName =
        isFabric ? item['fabric_item_name'] : item['accessory_item_name'];
    final itemCode = isFabric ? item['fabric_code'] : item['accessory_code'];
    final itemType = isFabric ? item['fabric_type'] : item['accessory_type'];
    final itemColor = isFabric ? item['shade_color'] : item['color'];
    final colorCode = item['color_code'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            // Show the detail dialog when card is tapped
            InventoryDetailDialogMobile.show(
              context,
              item: item,
              inventoryType: widget.inventoryType,
              onEdit: () {
                // Implement edit functionality
                Navigator.of(context).pop();
                // Open edit sheet
              },
              onDelete: () {
                // Implement delete functionality
                Navigator.of(context).pop();
                // Show delete confirmation
              },
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with color swatch, name, and price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Color swatch or item icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            isFabric
                                ? _parseColor(colorCode)
                                : _parseColor(
                                  colorCode.isNotEmpty
                                      ? colorCode
                                      : itemColor ?? '',
                                ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          isFabric
                              ? PhosphorIcons.scissors()
                              : _getAccessoryIcon(itemType),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Name, type, and brand info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itemName ?? 'Unknown Item',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              // Type badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: (isFabric
                                          ? theme.colorScheme.primaryContainer
                                          : theme.colorScheme.tertiaryContainer)
                                      .withOpacity(isDark ? 0.3 : 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  itemType ?? 'Unknown',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        isFabric
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.tertiary,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 6),

                              // Brand info
                              Expanded(
                                child: Text(
                                  item['brand_name'] ?? 'No Brand',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Price badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(
                          isDark ? 0.15 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            NumberFormat.currency(
                              symbol: '\$',
                              decimalDigits: 2,
                            ).format(item['selling_price_per_unit'] ?? 0),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            'per ${item['unit_type'] ?? 'unit'}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Divider - subtle
                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.dividerColor.withOpacity(0.1),
                ),

                const SizedBox(height: 10),

                // Bottom row with code and stock info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Code badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIcons.barcode(),
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            itemCode ?? 'No Code',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Stock info with warning for low stock
                    Row(
                      children: [
                        Text(
                          'In Stock: ',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isLowStock
                                    ? theme.colorScheme.error.withOpacity(0.1)
                                    : theme.colorScheme.primary.withOpacity(
                                      0.1,
                                    ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${item['quantity_available'] ?? 0} ${item['unit_type'] ?? ''}',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color:
                                      isLowStock
                                          ? theme.colorScheme.error
                                          : theme.colorScheme.primary,
                                ),
                              ),
                              if (isLowStock) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  PhosphorIcons.warning(),
                                  size: 12,
                                  color: theme.colorScheme.error,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.inventoryType == 'fabric'
                ? PhosphorIcons.scissors()
                : PhosphorIcons.package(),
            size: 60,
            color: isDark ? Colors.white30 : theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Add some items to your inventory',
            style: GoogleFonts.inter(
              fontSize: 14,
              color:
                  isDark ? Colors.white30 : theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_searchQuery.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
                _loadInventoryItems();
              },
              icon: Icon(PhosphorIcons.arrowClockwise()),
              label: const Text('Clear Search'),
            )
          else
            FilledButton.icon(
              onPressed: () {
                AddInventoryMobileSheet.show(
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

  Color _parseColor(String colorCode) {
    if (colorCode.isEmpty) return Colors.grey;

    try {
      if (colorCode.startsWith('#')) {
        return Color(
          int.parse(colorCode.substring(1, 7), radix: 16) + 0xFF000000,
        );
      }

      // Map common color names to colors
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
          return Colors.white;
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
          return Colors.teal;
      }
    } catch (e) {
      return Colors.grey;
    }
  }
}
