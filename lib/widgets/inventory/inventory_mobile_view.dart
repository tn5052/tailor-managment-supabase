import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_inventory_mobile_sheet.dart';
import 'edit_inventory_mobile_sheet.dart';
import 'inventory_design_config.dart';
import 'inventory_detail_dialog_mobile.dart';

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
    with TickerProviderStateMixin {
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

  // Add search expansion state
  bool _isSearchExpanded = false;
  AnimationController? _searchAnimationController;
  Animation<double>? _searchAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.inventoryType == 'fabric' ? 0 : 1,
    );
    _tabController!.addListener(_handleTabChange);

    // Initialize search animation
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController!,
      curve: Curves.easeInOut,
    );

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
    _searchAnimationController?.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
    });

    if (_isSearchExpanded) {
      _searchAnimationController!.forward();
      // Focus the search field after animation
      Future.delayed(const Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(FocusNode());
      });
    } else {
      _searchAnimationController!.reverse();
      _searchController.clear();
      setState(() => _searchQuery = '');
      _loadInventoryItems();
      FocusScope.of(context).unfocus();
    }
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
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: InventoryDesignConfig.surfaceColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(InventoryDesignConfig.radiusXL),
              ),
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.8,
              expand: false,
              builder:
                  (context, scrollController) => Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: InventoryDesignConfig.borderSecondary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Header
                      Padding(
                        padding: const EdgeInsets.all(
                          InventoryDesignConfig.spacingL,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              PhosphorIcons.funnel(),
                              color: InventoryDesignConfig.primaryColor,
                            ),
                            const SizedBox(
                              width: InventoryDesignConfig.spacingM,
                            ),
                            Text(
                              'Filter & Search',
                              style: InventoryDesignConfig.titleLarge,
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: InventoryDesignConfig.spacingL,
                          ),
                          children: [
                            // Search Section
                            Text(
                              'Search',
                              style: InventoryDesignConfig.titleMedium,
                            ),
                            const SizedBox(
                              height: InventoryDesignConfig.spacingM,
                            ),
                            Container(
                              decoration: InventoryDesignConfig.inputDecoration,
                              child: TextField(
                                controller: _searchController,
                                style: InventoryDesignConfig.bodyLarge,
                                decoration: InputDecoration(
                                  hintText:
                                      'Search ${widget.inventoryType == 'fabric' ? 'fabrics' : 'accessories'}...',
                                  hintStyle: InventoryDesignConfig.bodyMedium
                                      .copyWith(
                                        color:
                                            InventoryDesignConfig.textTertiary,
                                      ),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.all(
                                      InventoryDesignConfig.spacingM,
                                    ),
                                    child: Icon(
                                      PhosphorIcons.magnifyingGlass(),
                                      size: 18,
                                      color:
                                          InventoryDesignConfig.textSecondary,
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: InventoryDesignConfig.spacingM,
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() => _searchQuery = value);
                                  _loadInventoryItems();
                                },
                              ),
                            ),

                            const SizedBox(
                              height: InventoryDesignConfig.spacingXL,
                            ),

                            // Filter Section
                            _buildFilterSection('Filter By', _filterOptions),

                            const SizedBox(
                              height: InventoryDesignConfig.spacingL,
                            ),

                            // Sort Section
                            _buildFilterSection('Sort By', [
                              'Newest First',
                              'Oldest First',
                              'Name (A-Z)',
                              'Name (Z-A)',
                              'Price (High-Low)',
                              'Price (Low-High)',
                            ]),

                            const SizedBox(
                              height: InventoryDesignConfig.spacingXL,
                            ),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(
                                      InventoryDesignConfig.radiusM,
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedFilter = null;
                                          _sortBy = 'created_at';
                                          _searchController.clear();
                                          _searchQuery = '';
                                        });
                                        Navigator.pop(context);
                                        _loadInventoryItems();
                                      },
                                      borderRadius: BorderRadius.circular(
                                        InventoryDesignConfig.radiusM,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical:
                                              InventoryDesignConfig.spacingM,
                                        ),
                                        decoration:
                                            InventoryDesignConfig
                                                .buttonSecondaryDecoration,
                                        child: Center(
                                          child: Text(
                                            'Reset',
                                            style: InventoryDesignConfig
                                                .bodyMedium
                                                .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: InventoryDesignConfig.spacingM,
                                ),
                                Expanded(
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(
                                      InventoryDesignConfig.radiusM,
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.pop(context);
                                        _loadInventoryItems();
                                      },
                                      borderRadius: BorderRadius.circular(
                                        InventoryDesignConfig.radiusM,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical:
                                              InventoryDesignConfig.spacingM,
                                        ),
                                        decoration:
                                            InventoryDesignConfig
                                                .buttonPrimaryDecoration,
                                        child: Center(
                                          child: Text(
                                            'Apply',
                                            style: InventoryDesignConfig
                                                .bodyMedium
                                                .copyWith(
                                                  color:
                                                      InventoryDesignConfig
                                                          .surfaceColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: InventoryDesignConfig.spacingXL,
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
                                  _sortBy ==
                                      (widget.inventoryType == 'fabric'
                                          ? 'fabric_item_name'
                                          : 'accessory_item_name')) ||
                              (option == 'Name (Z-A)' &&
                                  _sortBy ==
                                      (widget.inventoryType == 'fabric'
                                          ? 'fabric_item_name'
                                          : 'accessory_item_name')) ||
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
                                      ? 'fabric_item_name'
                                      : 'accessory_item_name';
                              break;
                            case 'Name (Z-A)':
                              _sortBy =
                                  widget.inventoryType == 'fabric'
                                      ? 'fabric_item_name'
                                      : 'accessory_item_name';
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
                      _loadInventoryItems();
                    },
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEditItem(Map<String, dynamic> item) async {
    await EditInventoryMobileSheet.show(
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

  void _showItemDetails(Map<String, dynamic> item) {
    InventoryDetailDialogMobile.show(
      context,
      item: item,
      inventoryType: widget.inventoryType,
      onEdit: () => _handleEditItem(item),
      onDelete: () => _handleDeleteItem(item),
    );
  }

  void _showActionBottomSheet(Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final isFabric = widget.inventoryType == 'fabric';
    final itemName =
        isFabric ? item['fabric_item_name'] : item['accessory_item_name'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withAlpha(100),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        isFabric
                            ? PhosphorIcons.scissors()
                            : PhosphorIcons.package(),
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          itemName ?? 'Item Actions',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action buttons
                ListTile(
                  leading: Icon(PhosphorIcons.eye()),
                  title: const Text('View Details'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showItemDetails(item);
                  },
                ),
                ListTile(
                  leading: Icon(PhosphorIcons.pencilSimple()),
                  title: const Text('Edit Item'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _handleEditItem(item);
                  },
                ),
                ListTile(
                  leading: Icon(
                    PhosphorIcons.trash(),
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Delete Item',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _handleDeleteItem(item);
                  },
                ),
                const SizedBox(height: 16),
              ],
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
    return Container(
      color: InventoryDesignConfig.backgroundColor,
      child: Column(
        children: [
          // Modern App Bar with Expandable Search
          _buildModernAppBar(),

          // Type Selector Tabs
          _buildTypeSelector(),

          // Expandable Search Section
          _buildExpandableSearchSection(),

          // Quick Stats Bar
          _buildQuickStatsBar(),

          // Inventory List
          Expanded(child: _buildInventoryList()),
        ],
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top:
            MediaQuery.of(context).padding.top + InventoryDesignConfig.spacingS,
        left: InventoryDesignConfig.spacingL,
        right: InventoryDesignConfig.spacingL,
        bottom: InventoryDesignConfig.spacingM,
      ),
      decoration: const BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: InventoryDesignConfig.borderSecondary,
            width: 1,
          ),
        ),
      ),
      child: AnimatedBuilder(
        animation: _searchAnimation!,
        builder: (context, child) {
          return Row(
            children: [
              // Title Section - Animated
              Expanded(
                flex: _isSearchExpanded ? 0 : 1,
                child: AnimatedOpacity(
                  opacity: _isSearchExpanded ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child:
                      _isSearchExpanded
                          ? const SizedBox.shrink()
                          : Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(
                                  InventoryDesignConfig.spacingS,
                                ),
                                decoration: BoxDecoration(
                                  color: InventoryDesignConfig.primaryColor
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    InventoryDesignConfig.radiusS,
                                  ),
                                ),
                                child: Icon(
                                  PhosphorIcons.warehouse(),
                                  size: 18,
                                  color: InventoryDesignConfig.primaryColor,
                                ),
                              ),
                              const SizedBox(
                                width: InventoryDesignConfig.spacingM,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Inventory',
                                      style:
                                          InventoryDesignConfig.headlineMedium,
                                    ),
                                    Text(
                                      'Manage items',
                                      style: InventoryDesignConfig.bodySmall
                                          .copyWith(
                                            color:
                                                InventoryDesignConfig
                                                    .textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                ),
              ),

              // Expandable Search Field
              if (_isSearchExpanded)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: InventoryDesignConfig.surfaceLight,
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusM,
                        ),
                        border: Border.all(
                          color: InventoryDesignConfig.borderPrimary,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: InventoryDesignConfig.bodyLarge,
                        decoration: InputDecoration(
                          hintText:
                              'Search ${widget.inventoryType == 'fabric' ? 'fabrics' : 'accessories'}...',
                          hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
                            color: InventoryDesignConfig.textTertiary,
                          ),
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(
                              InventoryDesignConfig.spacingM,
                            ),
                            child: Icon(
                              PhosphorIcons.magnifyingGlass(),
                              size: 18,
                              color: InventoryDesignConfig.textSecondary,
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: InventoryDesignConfig.spacingM,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                          _loadInventoryItems();
                        },
                      ),
                    ),
                  ),
                ),

              // Action Buttons
              Row(
                children: [
                  if (_isSearchExpanded) ...[
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    // Close Search Button
                    _buildHeaderIconButton(
                      icon: PhosphorIcons.x(),
                      onTap: _toggleSearch,
                    ),
                  ] else ...[
                    // Search Button
                    _buildHeaderIconButton(
                      icon: PhosphorIcons.magnifyingGlass(),
                      onTap: _toggleSearch,
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    // Filter Button
                    _buildHeaderIconButton(
                      icon: PhosphorIcons.funnel(),
                      onTap: _showFilterBottomSheet,
                    ),
                    const SizedBox(width: InventoryDesignConfig.spacingS),
                    // Add Button
                    _buildHeaderIconButton(
                      icon: PhosphorIcons.plus(),
                      onTap:
                          () => AddInventoryMobileSheet.show(
                            context,
                            inventoryType: widget.inventoryType,
                            onItemAdded: _loadInventoryItems,
                          ),
                      isPrimary: true,
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExpandableSearchSection() {
    // Only show filter chips when search is expanded and there are active filters
    if (!_isSearchExpanded || _selectedFilter == null) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Container(
        color: InventoryDesignConfig.surfaceColor,
        padding: const EdgeInsets.fromLTRB(
          InventoryDesignConfig.spacingL,
          0,
          InventoryDesignConfig.spacingL,
          InventoryDesignConfig.spacingM,
        ),
        child: _buildActiveFilters(),
      ),
    );
  }

  Widget _buildQuickStatsBar() {
    final totalItems = _inventoryItems.length;
    final lowStockItems =
        _inventoryItems
            .where(
              (item) =>
                  (item['quantity_available'] ?? 0) <=
                  (item['minimum_stock_level'] ?? 0),
            )
            .length;
    final totalValue = _inventoryItems.fold<double>(
      0.0,
      (sum, item) =>
          sum +
          ((item['quantity_available'] ?? 0) *
              (item['selling_price_per_unit'] ?? 0.0)),
    );

    return Container(
      color: InventoryDesignConfig.surfaceColor,
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingL,
        vertical: InventoryDesignConfig.spacingM,
      ),
      child: Row(
        children: [
          _buildStatItem(
            icon: PhosphorIcons.package(),
            label: 'Total Items',
            value: '$totalItems',
            color: InventoryDesignConfig.primaryColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          _buildStatItem(
            icon: PhosphorIcons.warning(),
            label: 'Low Stock',
            value: '$lowStockItems',
            color:
                lowStockItems > 0
                    ? InventoryDesignConfig.errorColor
                    : InventoryDesignConfig.successColor,
          ),
          const SizedBox(width: InventoryDesignConfig.spacingM),
          _buildStatItem(
            icon: PhosphorIcons.currencyDollar(),
            label: 'Total Value',
            value: '\$${totalValue.toStringAsFixed(0)}',
            color: InventoryDesignConfig.successColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: InventoryDesignConfig.spacingXS),
                Expanded(
                  child: Text(
                    label,
                    style: InventoryDesignConfig.bodySmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: InventoryDesignConfig.spacingXS),
            Text(
              value,
              style: InventoryDesignConfig.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    if (_selectedFilter == null) return const SizedBox.shrink();

    return Row(
      children: [
        Text(
          'Filtered by:',
          style: InventoryDesignConfig.bodySmall.copyWith(
            color: InventoryDesignConfig.textSecondary,
          ),
        ),
        const SizedBox(width: InventoryDesignConfig.spacingS),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: InventoryDesignConfig.spacingM,
            vertical: InventoryDesignConfig.spacingXS,
          ),
          decoration: BoxDecoration(
            color: InventoryDesignConfig.primaryColor,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedFilter!,
                style: InventoryDesignConfig.bodySmall.copyWith(
                  color: InventoryDesignConfig.surfaceColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: InventoryDesignConfig.spacingXS),
              GestureDetector(
                onTap: () {
                  setState(() => _selectedFilter = null);
                  _loadInventoryItems();
                },
                child: Icon(
                  PhosphorIcons.x(),
                  size: 12,
                  color: InventoryDesignConfig.surfaceColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                isPrimary
                    ? InventoryDesignConfig.primaryColor
                    : InventoryDesignConfig.surfaceLight,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            border: Border.all(
              color:
                  isPrimary
                      ? InventoryDesignConfig.primaryColor
                      : InventoryDesignConfig.borderPrimary,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color:
                isPrimary
                    ? InventoryDesignConfig.surfaceColor
                    : InventoryDesignConfig.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      color: InventoryDesignConfig.surfaceColor,
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingL,
        vertical: InventoryDesignConfig.spacingS,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: InventoryDesignConfig.surfaceLight,
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
          border: Border.all(color: InventoryDesignConfig.borderPrimary),
        ),
        child: TabBar(
          controller: _tabController,
          onTap: (index) {
            final newType = _inventoryTypes[index];
            widget.onTypeChanged?.call(newType);
          },
          indicator: BoxDecoration(
            color: InventoryDesignConfig.primaryColor,
            borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusS),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(2),
          labelColor: InventoryDesignConfig.surfaceColor,
          unselectedLabelColor: InventoryDesignConfig.textSecondary,
          labelStyle: InventoryDesignConfig.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: InventoryDesignConfig.bodyMedium,
          dividerColor: Colors.transparent,
          tabs: [
            Tab(
              height: 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIcons.scissors(), size: 16),
                  const SizedBox(width: InventoryDesignConfig.spacingS),
                  const Text('Fabrics'),
                ],
              ),
            ),
            Tab(
              height: 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIcons.package(), size: 16),
                  const SizedBox(width: InventoryDesignConfig.spacingS),
                  const Text('Accessories'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: InventoryDesignConfig.primaryColor,
        ),
      );
    }

    if (_inventoryItems.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: InventoryDesignConfig.primaryColor,
      onRefresh: _loadInventoryItems,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          InventoryDesignConfig.spacingL,
          InventoryDesignConfig.spacingS,
          InventoryDesignConfig.spacingL,
          InventoryDesignConfig.spacingXL,
        ),
        itemCount: _inventoryItems.length,
        itemBuilder: (context, index) {
          final item = _inventoryItems[index];
          return _buildInventoryCard(item);
        },
      ),
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> item) {
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
      margin: const EdgeInsets.only(bottom: InventoryDesignConfig.spacingM),
      decoration: InventoryDesignConfig.cardDecoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        child: InkWell(
          onTap: () => _showItemDetails(item),
          onLongPress: () => _showActionBottomSheet(item),
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Color Swatch
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _parseColor(colorCode),
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusS,
                        ),
                        border: Border.all(
                          color: InventoryDesignConfig.borderPrimary,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          isFabric
                              ? PhosphorIcons.scissors()
                              : _getAccessoryIcon(itemType),
                          color: InventoryDesignConfig.surfaceColor,
                          size: 16,
                        ),
                      ),
                    ),

                    const SizedBox(width: InventoryDesignConfig.spacingM),

                    // Item Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itemName ?? 'Unknown Item',
                            style: InventoryDesignConfig.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(
                            height: InventoryDesignConfig.spacingXS,
                          ),
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
                                  itemType ?? 'Uncategorized',
                                  style: InventoryDesignConfig.bodySmall
                                      .copyWith(
                                        color:
                                            InventoryDesignConfig.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              const SizedBox(
                                width: InventoryDesignConfig.spacingS,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: InventoryDesignConfig.spacingS,
                                  vertical: InventoryDesignConfig.spacingXS,
                                ),
                                decoration: BoxDecoration(
                                  color: InventoryDesignConfig.surfaceAccent,
                                  borderRadius: BorderRadius.circular(
                                    InventoryDesignConfig.radiusS,
                                  ),
                                ),
                                child: Text(
                                  itemCode ?? 'No Code',
                                  style: InventoryDesignConfig.code.copyWith(
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${(item['selling_price_per_unit'] ?? 0).toStringAsFixed(2)}',
                          style: InventoryDesignConfig.titleMedium.copyWith(
                            color: InventoryDesignConfig.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'per ${item['unit_type'] ?? 'unit'}',
                          style: InventoryDesignConfig.bodySmall.copyWith(
                            color: InventoryDesignConfig.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: InventoryDesignConfig.spacingM),

                // Bottom Row
                Row(
                  children: [
                    // Stock Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: InventoryDesignConfig.spacingS,
                        vertical: InventoryDesignConfig.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isLowStock
                                ? InventoryDesignConfig.errorColor.withOpacity(
                                  0.1,
                                )
                                : InventoryDesignConfig.successColor
                                    .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusS,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLowStock
                                ? PhosphorIcons.warning()
                                : PhosphorIcons.checkCircle(),
                            size: 12,
                            color:
                                isLowStock
                                    ? InventoryDesignConfig.errorColor
                                    : InventoryDesignConfig.successColor,
                          ),
                          const SizedBox(
                            width: InventoryDesignConfig.spacingXS,
                          ),
                          Text(
                            '${item['quantity_available'] ?? 0} in stock',
                            style: InventoryDesignConfig.bodySmall.copyWith(
                              color:
                                  isLowStock
                                      ? InventoryDesignConfig.errorColor
                                      : InventoryDesignConfig.successColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Action Button
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        InventoryDesignConfig.radiusS,
                      ),
                      child: InkWell(
                        onTap: () => _showActionBottomSheet(item),
                        borderRadius: BorderRadius.circular(
                          InventoryDesignConfig.radiusS,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(
                            InventoryDesignConfig.spacingS,
                          ),
                          decoration: BoxDecoration(
                            color: InventoryDesignConfig.surfaceLight,
                            borderRadius: BorderRadius.circular(
                              InventoryDesignConfig.radiusS,
                            ),
                            border: Border.all(
                              color: InventoryDesignConfig.borderPrimary,
                            ),
                          ),
                          child: Icon(
                            PhosphorIcons.dotsThreeVertical(),
                            size: 16,
                            color: InventoryDesignConfig.textSecondary,
                          ),
                        ),
                      ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(InventoryDesignConfig.spacingXXL),
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
            const SizedBox(height: InventoryDesignConfig.spacingXL),
            Text('No items found', style: InventoryDesignConfig.headlineMedium),
            const SizedBox(height: InventoryDesignConfig.spacingS),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Add some items to your inventory',
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: InventoryDesignConfig.spacingXL),
            if (_searchQuery.isNotEmpty)
              _buildEmptyStateButton(
                icon: PhosphorIcons.arrowClockwise(),
                label: 'Clear Search',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                  _loadInventoryItems();
                },
                isPrimary: false,
              )
            else
              _buildEmptyStateButton(
                icon: PhosphorIcons.plus(),
                label: 'Add New Item',
                onPressed:
                    () => AddInventoryMobileSheet.show(
                      context,
                      inventoryType: widget.inventoryType,
                      onItemAdded: _loadInventoryItems,
                    ),
                isPrimary: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: InventoryDesignConfig.spacingXL,
            vertical: InventoryDesignConfig.spacingM,
          ),
          decoration:
              isPrimary
                  ? InventoryDesignConfig.buttonPrimaryDecoration
                  : InventoryDesignConfig.buttonSecondaryDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color:
                    isPrimary
                        ? InventoryDesignConfig.surfaceColor
                        : InventoryDesignConfig.textSecondary,
              ),
              const SizedBox(width: InventoryDesignConfig.spacingS),
              Text(
                label,
                style: InventoryDesignConfig.bodyMedium.copyWith(
                  color:
                      isPrimary
                          ? InventoryDesignConfig.surfaceColor
                          : InventoryDesignConfig.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
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
