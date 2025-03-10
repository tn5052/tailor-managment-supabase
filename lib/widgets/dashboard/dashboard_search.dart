import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';
import '../customer/customer_detail_dialog.dart';

class DashboardSearch extends StatefulWidget {
  final VoidCallback? onClose;

  const DashboardSearch({
    super.key,
    this.onClose,
  });

  static Future<void> show(BuildContext context) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 640;

    if (isMobile) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true, 
        backgroundColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        builder: (context) => const DynamicSearchInterface(),
      );
    } else {
      // Enhanced desktop dialog
      await showGeneralDialog(
        context: context,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 250),
        barrierDismissible: true, // Allow closing on outside click
        barrierLabel: 'Close Search',
        pageBuilder: (context, animation, secondaryAnimation) {
          return GestureDetector(
            onTap: () {
              // Close the dialog if tapped outside
              Navigator.pop(context);
            },
            behavior: HitTestBehavior.opaque,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutExpo),
                ),
                child: FadeTransition(
                  opacity: animation,
                  child: const Dialog(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    insetPadding: EdgeInsets.all(0),
                    child: Center(
                      child: DynamicSearchInterface(isDesktop: true),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
  }

  @override
  State<DashboardSearch> createState() => _DashboardSearchState();
}

/// A unified search interface that adapts to mobile or desktop
class DynamicSearchInterface extends StatefulWidget {
  final bool isDesktop;

  const DynamicSearchInterface({
    super.key,
    this.isDesktop = false,
  });

  @override
  State<DynamicSearchInterface> createState() => _DynamicSearchInterfaceState();
}

class _DynamicSearchInterfaceState extends State<DynamicSearchInterface> 
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _customerService = CustomerService(Supabase.instance.client);
  final _debouncer = Debouncer(milliseconds: 250);
  final _scrollController = ScrollController();
  
  late AnimationController _animationController;
  
  List<Customer> _searchResults = [];
  bool _isLoading = false;
  String _searchQuery = '';
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 300),
    );

    _searchController.addListener(_onSearchChanged);
    
    // Set up keyboard shortcuts for desktop
    if (widget.isDesktop) {
      _setupKeyboardShortcuts();
    }
    
    // Focus the search field automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _setupKeyboardShortcuts() {
    _searchFocusNode.onKeyEvent = (focusNode, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.pop(context);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _selectNextResult();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _selectPreviousResult();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.enter && _selectedIndex >= 0) {
          _openSelectedResult();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
  }

  void _selectNextResult() {
    if (_searchResults.isEmpty) return;
    
    setState(() {
      if (_selectedIndex < _searchResults.length - 1) {
        _selectedIndex++;
      } else {
        _selectedIndex = 0; // Loop back to the first item
      }
    });
    
    if (_scrollController.hasClients) {
      _ensureItemVisible(_selectedIndex);
    }
  }

  void _selectPreviousResult() {
    if (_searchResults.isEmpty) return;
    
    setState(() {
      if (_selectedIndex > 0) {
        _selectedIndex--;
      } else {
        _selectedIndex = _searchResults.length - 1; // Loop back to the last item
      }
    });
    
    if (_scrollController.hasClients) {
      _ensureItemVisible(_selectedIndex);
    }
  }

  void _ensureItemVisible(int index) {
    if (index < 0 || _scrollController.positions.isEmpty) return;
    
    // Approximate item height with padding
    const itemHeight = 72.0;
    final visibleHeight = _scrollController.position.viewportDimension;
    final offset = index * itemHeight;
    
    // Check if the item is already visible
    if (offset < _scrollController.offset ||
        offset > _scrollController.offset + visibleHeight - itemHeight) {
      // Scroll to make item visible with animation
      _scrollController.animateTo(
        offset - (visibleHeight / 2) + (itemHeight / 2),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _openSelectedResult() {
    if (_selectedIndex >= 0 && _selectedIndex < _searchResults.length) {
      _selectCustomer(_searchResults[_selectedIndex]);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query == _searchQuery) return;
    
    setState(() {
      _searchQuery = query;
      _isLoading = query.isNotEmpty;
      _selectedIndex = -1; // Reset selection on new search
    });

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    _debouncer.run(() async {
      try {
        final results = await _customerService.searchCustomers(query);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isLoading = false;
            // Auto-select first result on desktop
            if (widget.isDesktop && results.isNotEmpty) {
              _selectedIndex = 0;
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  void _selectCustomer(Customer customer) {
    Navigator.pop(context);
    CustomerDetailDialog.show(context, customer);
  }

  @override
  Widget build(BuildContext context) {
    return widget.isDesktop 
        ? _buildDesktopSearch(context)
        : _buildMobileSearch(context);
  }

  Widget _buildMobileSearch(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Container(
      height: size.height * 0.9,
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(32), // Increased radius for more modern look
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pull handle with improved styling
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Search header with refined design
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.03),
                    offset: const Offset(0, 1),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Search',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Enhanced search field design
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      letterSpacing: 0.1,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by name or bill number...',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.outline.withOpacity(0.8),
                        fontWeight: FontWeight.normal,
                        fontSize: 16,
                      ),
                      prefixIcon: Container(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.search_rounded,
                          color: theme.colorScheme.outline,
                          size: 24,
                        ),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _searchController.clear(),
                            tooltip: 'Clear search',
                          )
                        : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                          width: 1.5, // Slightly thicker border
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _selectedIndex >= 0 ? _openSelectedResult() : null,
                  ),
                ],
              ),
            ),
            
            // Improved search state indicator
            if (_isLoading)
              LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: theme.colorScheme.primary,
                minHeight: 3,
              ).animate().fadeIn(duration: 200.ms),
            
            // Results area with enhanced styling
            Expanded(
              child: _buildResultsArea(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSearch(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: 720,
      constraints: const BoxConstraints(maxHeight: 680),
      child: Card(
        elevation: 24,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Redesigned search header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 28,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.1),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search field container with updated suffixIcon
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withOpacity(0.2),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.3,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search by name or bill number...',
                          hintStyle: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.outline.withOpacity(0.5),
                            fontWeight: FontWeight.normal,
                            letterSpacing: -0.3,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Icon(
                              Icons.search_rounded,
                              size: 28,
                              color: theme.colorScheme.primary.withOpacity(0.8),
                            ),
                          ),
                          // Only show clear button when there's text
                          suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(
                    duration: 400.ms,
                    curve: Curves.easeOutCubic,
                  ),
                ],
              ),
            ),

            // ...existing results area code...
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.2),
                    ),
                  ),
                ),
                child: _buildResultsArea(theme),
              ),
            ),

            // Enhanced keyboard shortcuts help
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildKeyboardShortcutHint(theme, '↑↓', 'Navigate'),
                  const SizedBox(width: 24),
                  _buildKeyboardShortcutHint(theme, '↵', 'Select'),
                  const SizedBox(width: 24),
                  _buildKeyboardShortcutHint(theme, 'ESC', 'Close'),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuint,
      begin: const Offset(0.95, 0.95),
      end: const Offset(1.0, 1.0),
    );
  }

  Widget _buildKeyboardShortcutHint(ThemeData theme, String key, String action) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Text(
            key,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          action,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildResultsArea(ThemeData theme) {
    if (_searchQuery.isEmpty) {
      return _buildInitialSearchState(theme);
    }

    if (_isLoading && _searchResults.isEmpty) {
      return _buildLoadingState(theme);
    }

    if (_searchResults.isEmpty) {
      return _buildNoResultsState(theme);
    }

    return ListView.separated(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(), // Smoother scrolling physics
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        indent: 72, // Left indent to align with the content
        color: theme.colorScheme.outlineVariant.withOpacity(0.1),
      ),
      itemBuilder: (context, index) {
        return _buildResultItem(
          theme,
          _searchResults[index],
          isSelected: index == _selectedIndex,
          onTap: () => _selectCustomer(_searchResults[index]),
        );
      },
    ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Searching...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms, curve: Curves.easeOut);
  }

  Widget _buildInitialSearchState(ThemeData theme) {
    final bool isDesktop = widget.isDesktop;
    final searchHints = ['Try searching by name', 'Enter customer bill number', 'Quick access to customer data'];
    
    return ListView(
      physics: const BouncingScrollPhysics(), // Smoother scrolling
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 20,
        vertical: isDesktop ? 32 : 24,
      ),
      children: [
        // Calculate more space on desktop
        SizedBox(height: isDesktop ? 16 : 8),
        
        // Centered icon with improved styling
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.manage_search_rounded,
              size: 44,
              color: theme.colorScheme.primary.withOpacity(0.8),
            ),
          ),
        ).animate().scale(
          duration: 600.ms,
          delay: 100.ms,
          curve: Curves.elasticOut,
          begin: const Offset(0.7, 0.7),
          end: const Offset(1.0, 1.0),
        ),
        
        const SizedBox(height: 24),
        
        // Text with improved typography
        Text(
          'Start typing to search',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3, // Tighter letter spacing for modern look
          ),
        ).animate().fadeIn(
          duration: 400.ms,
          delay: 200.ms,
        ).moveY(
          begin: 10,
          end: 0,
          curve: Curves.easeOutCubic,
          duration: 500.ms,
          delay: 200.ms,
        ),
        
        const SizedBox(height: 12),
        
        Text(
          'Find customers quickly by name or bill number',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4, // Better line height
            letterSpacing: 0.1,
          ),
        ).animate().fadeIn(
          duration: 400.ms,
          delay: 300.ms,
        ).moveY(
          begin: 10,
          end: 0,
          curve: Curves.easeOutCubic,
          duration: 500.ms,
          delay: 300.ms,
        ),
        
        SizedBox(height: isDesktop ? 40 : 32),
        
        // Tips section with refined animations
        ...searchHints.asMap().entries.map((entry) {
          final index = entry.key;
          final hint = entry.value;
          
          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: isDesktop ? 10 : 8,
              horizontal: isDesktop ? 16 : 12,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.tips_and_updates_outlined,
                    size: isDesktop ? 20 : 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    hint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(
            duration: 400.ms,
            delay: Duration(milliseconds: 400 + (index * 100)),
          ).moveX(
            begin: -10,
            end: 0,
            duration: 500.ms,
            delay: Duration(milliseconds: 400 + (index * 100)),
            curve: Curves.easeOutCubic,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildNoResultsState(ThemeData theme) {
    final bool isDesktop = widget.isDesktop;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 24,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.search_off_rounded,
                size: 40,
                color: theme.colorScheme.error,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'No results found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Try a different search term or check the spelling',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 28),
            
            // Enhanced button with better spacing
            FilledButton.tonal(
              onPressed: () => _searchController.clear(),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                textStyle: TextStyle(fontWeight: FontWeight.w500),
              ),
              child: const Text('Clear Search'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildResultItem(
    ThemeData theme,
    Customer customer, {
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    final searchPattern = RegExp(_searchQuery, caseSensitive: false);
    final nameMatches = searchPattern.allMatches(customer.name);
    final billMatches = searchPattern.allMatches(customer.billNumber);
    
    // Enhanced hover effect with Material animations
    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withOpacity(0.25)
          : theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        splashColor: theme.colorScheme.primary.withOpacity(0.1),
        hoverColor: theme.colorScheme.primaryContainer.withOpacity(0.15),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          child: Row(
            children: [
              // Enhanced avatar with proper Hero animation
              Hero(
                tag: 'avatar_${customer.id}',
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    width: 44, 
                    height: 44, // Slightly larger for better visibility
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? theme.colorScheme.primary.withOpacity(0.2)
                          : theme.colorScheme.primary.withOpacity(0.1),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary.withOpacity(0.3)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        customer.name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        children: _buildHighlightedText(
                          customer.name,
                          nameMatches,
                          theme.colorScheme.primary,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            children: [
                              const TextSpan(text: 'Bill # '),
                              ..._buildHighlightedText(
                                customer.billNumber,
                                billMatches,
                                theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            customer.phone,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
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
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<TextSpan> _buildHighlightedText(
    String text,
    Iterable<RegExpMatch> matches,
    Color highlightColor,
  ) {
    if (_searchQuery.isEmpty) return [TextSpan(text: text)];

    final spans = <TextSpan>[];
    int currentPos = 0;

    for (final match in matches) {
      if (match.start > currentPos) {
        spans.add(TextSpan(text: text.substring(currentPos, match.start)));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: TextStyle(
          color: highlightColor,
          fontWeight: FontWeight.bold,
        ),
      ));
      currentPos = match.end;
    }

    if (currentPos < text.length) {
      spans.add(TextSpan(text: text.substring(currentPos)));
    }

    return spans;
  }
}

// Original implementation (can be removed now)
class _DashboardSearchState extends State<DashboardSearch> {
  @override
  Widget build(BuildContext context) {
    // Placeholder - we're replacing this with the DynamicSearchInterface
    return const SizedBox();
  }
}

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
