import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/inventory_design_config.dart';
import '../../../models/customer.dart';

class CustomerSelectorSheet extends StatefulWidget {
  final Function(Customer) onCustomerSelected;

  const CustomerSelectorSheet({
    Key? key,
    required this.onCustomerSelected,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required Function(Customer) onCustomerSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: false,
      useSafeArea: true,
      builder: (context) => CustomerSelectorSheet(
        onCustomerSelected: onCustomerSelected,
      ),
    );
  }

  @override
  _CustomerSelectorSheetState createState() => _CustomerSelectorSheetState();
}

class _CustomerSelectorSheetState extends State<CustomerSelectorSheet>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Timer? _debounceTimer;

  // Animation controllers
  late AnimationController _sheetAnimationController;
  late Animation<double> _sheetAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchCustomers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sheetAnimationController.forward();
    });
  }

  void _initializeAnimations() {
    _sheetAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _sheetAnimation = CurvedAnimation(
      parent: _sheetAnimationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _sheetAnimationController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('customers')
          .select()
          .order('name', ascending: true)
          .limit(100);
      
      final customers = response.map((data) => Customer.fromMap(data)).toList();
      
      setState(() {
        _customers = customers;
        _filteredCustomers = customers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading customers: ${e.toString()}'),
            backgroundColor: InventoryDesignConfig.errorColor,
          ),
        );
      }
    }
  }

  void _filterCustomers(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      setState(() {
        _searchQuery = query.toLowerCase();
        if (_searchQuery.isEmpty) {
          _filteredCustomers = _customers;
        } else {
          _filteredCustomers = _customers.where((customer) {
            return customer.name.toLowerCase().contains(_searchQuery) ||
                   customer.phone.toLowerCase().contains(_searchQuery) ||
                   customer.whatsapp.toLowerCase().contains(_searchQuery) ||
                   customer.address.toLowerCase().contains(_searchQuery);
          }).toList();
        }
      });
    });
  }

  Future<void> _handleClose() async {
    HapticFeedback.lightImpact();
    await _sheetAnimationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final safeAreaTop = mediaQuery.padding.top;

    return AnimatedBuilder(
      animation: _sheetAnimation,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.4 * _sheetAnimation.value),
          resizeToAvoidBottomInset: true,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: safeAreaTop + 40,
                  bottom: 0,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      (screenHeight - safeAreaTop - 40) * (1 - _sheetAnimation.value),
                    ),
                    child: _buildSheetContent(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetContent() {
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
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(child: _buildCustomerList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(InventoryDesignConfig.radiusXL),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
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
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        InventoryDesignConfig.primaryColor,
                        InventoryDesignConfig.primaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
                    boxShadow: [
                      BoxShadow(
                        color: InventoryDesignConfig.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    PhosphorIcons.users(),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: InventoryDesignConfig.spacingL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Customer',
                        style: InventoryDesignConfig.headlineMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: InventoryDesignConfig.spacingXS),
                      Text(
                        '${_filteredCustomers.length} customers available',
                        style: InventoryDesignConfig.bodyMedium.copyWith(
                          color: InventoryDesignConfig.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildHeaderActionButton(
                  icon: PhosphorIcons.x(),
                  onTap: _handleClose,
                  semanticLabel: 'Close customer selector',
                ),
              ],
            ),
          ),

          Container(height: 1, color: InventoryDesignConfig.borderSecondary),
        ],
      ),
    );
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required VoidCallback onTap,
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
              color: InventoryDesignConfig.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusM),
            ),
            child: Icon(
              icon,
              size: 18,
              color: InventoryDesignConfig.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(InventoryDesignConfig.spacingXL),
      child: Container(
        decoration: BoxDecoration(
          color: InventoryDesignConfig.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: InventoryDesignConfig.borderPrimary),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: InventoryDesignConfig.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Search customers by name, phone, or address...',
            hintStyle: InventoryDesignConfig.bodyMedium.copyWith(
              color: InventoryDesignConfig.textTertiary,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(InventoryDesignConfig.spacingM),
              child: Icon(
                PhosphorIcons.magnifyingGlass(),
                size: 20,
                color: InventoryDesignConfig.primaryColor,
              ),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      PhosphorIcons.x(),
                      size: 18,
                      color: InventoryDesignConfig.textSecondary,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _filterCustomers('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: InventoryDesignConfig.spacingL,
            ),
          ),
          onChanged: _filterCustomers,
        ),
      ),
    );
  }

  Widget _buildCustomerList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: InventoryDesignConfig.primaryColor,
            ),
            const SizedBox(height: InventoryDesignConfig.spacingL),
            Text(
              'Loading customers...',
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredCustomers.isEmpty) {
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
                _searchQuery.isNotEmpty 
                    ? PhosphorIcons.magnifyingGlass()
                    : PhosphorIcons.userPlus(),
                size: 48,
                color: InventoryDesignConfig.textTertiary,
              ),
            ),
            const SizedBox(height: InventoryDesignConfig.spacingXL),
            Text(
              _searchQuery.isNotEmpty ? 'No customers found' : 'No customers available',
              style: InventoryDesignConfig.headlineMedium,
            ),
            const SizedBox(height: InventoryDesignConfig.spacingS),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Try searching with different keywords'
                  : 'Add customers to get started',
              style: InventoryDesignConfig.bodyMedium.copyWith(
                color: InventoryDesignConfig.textSecondary,
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: InventoryDesignConfig.spacingXL),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _filterCustomers('');
                },
                icon: Icon(PhosphorIcons.arrowCounterClockwise()),
                label: const Text('Clear search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: InventoryDesignConfig.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: InventoryDesignConfig.spacingXL,
      ),
      itemCount: _filteredCustomers.length,
      itemBuilder: (context, index) => _buildCustomerCard(_filteredCustomers[index]),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Container(
      margin: const EdgeInsets.only(bottom: InventoryDesignConfig.spacingM),
      decoration: BoxDecoration(
        color: InventoryDesignConfig.surfaceColor,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        border: Border.all(
          color: InventoryDesignConfig.borderSecondary,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onCustomerSelected(customer);
            _handleClose();
          },
          borderRadius: BorderRadius.circular(InventoryDesignConfig.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(InventoryDesignConfig.spacingL),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getColorFromName(customer.name),
                        _getColorFromName(customer.name).withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _getColorFromName(customer.name).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      customer.name.isNotEmpty 
                          ? customer.name[0].toUpperCase()
                          : '?',
                      style: InventoryDesignConfig.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: InventoryDesignConfig.spacingL),

                // Customer info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: InventoryDesignConfig.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: InventoryDesignConfig.spacingXS),
                      if (customer.phone.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              PhosphorIcons.phone(),
                              size: 16,
                              color: InventoryDesignConfig.textSecondary,
                            ),
                            const SizedBox(width: InventoryDesignConfig.spacingXS),
                            Expanded(
                              child: Text(
                                customer.phone,
                                style: InventoryDesignConfig.bodyMedium.copyWith(
                                  color: InventoryDesignConfig.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      if (customer.whatsapp.isNotEmpty) ...[
                        const SizedBox(height: InventoryDesignConfig.spacingXS),
                        Row(
                          children: [
                            Icon(
                              PhosphorIcons.whatsappLogo(),
                              size: 16,
                              color: InventoryDesignConfig.textSecondary,
                            ),
                            const SizedBox(width: InventoryDesignConfig.spacingXS),
                            Expanded(
                              child: Text(
                                customer.whatsapp,
                                style: InventoryDesignConfig.bodyMedium.copyWith(
                                  color: InventoryDesignConfig.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  PhosphorIcons.caretRight(),
                  size: 20,
                  color: InventoryDesignConfig.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorFromName(String name) {
    if (name.isEmpty) return InventoryDesignConfig.primaryColor;
    
    // Generate consistent color based on name hash
    final hash = name.hashCode;
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEC4899), // Pink
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFEF4444), // Red
      const Color(0xFF8B5A2B), // Brown
      const Color(0xFF059669), // Teal
      const Color(0xFF7C3AED), // Purple
    ];
    
    return colors[hash.abs() % colors.length];
  }
}
