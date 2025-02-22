import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:math' as math;

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget desktopBody;

  const ResponsiveLayout({
    super.key,
    required this.mobileBody,
    required this.desktopBody,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return mobileBody;
        }
        return desktopBody;
      },
    );
  }
}

class SideMenu extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const SideMenu({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> with SingleTickerProviderStateMixin {
  bool isExpanded = true;
  bool isHovering = false;
  bool isFooterHovered = false;

  void toggleMenu() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        width: isExpanded ? 240 : 70,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          // Removed borderRadius
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(theme),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: isExpanded ? 8 : 12,
                ),
                child: ListView(
                  children: [
                    _buildNavItem(
                      index: 0,
                      icon: PhosphorIcon(PhosphorIcons.squaresFour()),
                      selectedIcon: PhosphorIcon(PhosphorIcons.squaresFour(PhosphorIconsStyle.fill)),
                      label: 'Dashboard',
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: PhosphorIcon(PhosphorIcons.users()),
                      selectedIcon: PhosphorIcon(PhosphorIcons.users(PhosphorIconsStyle.fill)),
                      label: 'Customers',
                    ),
                    _buildNavItem(
                      index: 2,
                      icon: PhosphorIcon(PhosphorIcons.ruler()),
                      selectedIcon: PhosphorIcon(PhosphorIcons.ruler(PhosphorIconsStyle.fill)),
                      label: 'Measurements',
                    ),
                    _buildNavItem(
                      index: 3,
                      icon: PhosphorIcon(PhosphorIcons.receipt()),
                      selectedIcon: PhosphorIcon(PhosphorIcons.receipt(PhosphorIconsStyle.fill)),
                      label: 'Invoices',
                    ),
                    _buildNavItem(
                      index: 4,
                      icon: PhosphorIcon(PhosphorIcons.warning()),
                      selectedIcon: PhosphorIcon(PhosphorIcons.warning(PhosphorIconsStyle.fill)),
                      label: 'Complaints',
                    ),
                    _buildNavItem(
                      index: 5,
                      icon: PhosphorIcon(PhosphorIcons.gear()),
                      selectedIcon: PhosphorIcon(PhosphorIcons.gear(PhosphorIconsStyle.fill)),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? 12 : 16,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          if (isExpanded) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(128),
                borderRadius: BorderRadius.circular(8),
              ),
              child: PhosphorIcon(
                PhosphorIcons.scissors(PhosphorIconsStyle.fill),
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Shabab Al Yola',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: toggleMenu,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isHovering 
                      ? theme.colorScheme.surfaceContainerHighest.withAlpha(100)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: isExpanded ? 0 : 0.5,
                  child: PhosphorIcon(
                    PhosphorIcons.caretLeft(),
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required Widget icon,
    required Widget selectedIcon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final isSelected = widget.selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onDestinationSelected(index),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 40,
              padding: EdgeInsets.symmetric(
                horizontal: isExpanded ? 12 : 0,
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                alignment: isExpanded ? Alignment.centerLeft : Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconTheme(
                      data: IconThemeData(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      child: isSelected ? selectedIcon : icon,
                    ),
                    if (isExpanded)
                      AnimatedSize(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOutCubic,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 12),
                            Text(
                              label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: isSelected ? FontWeight.w600 : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return MouseRegion(
      onEnter: (_) => setState(() => isFooterHovered = true),
      onExit: (_) => setState(() => isFooterHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.all(isExpanded ? 16 : 12),
        decoration: BoxDecoration(
          color: isFooterHovered 
              ? theme.colorScheme.surfaceContainerHighest.withAlpha(50)
              : Colors.transparent,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withAlpha(50),
              width: 0.5,
            ),
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          alignment: isExpanded ? Alignment.centerLeft : Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isFooterHovered ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withAlpha(40),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ] : [],
                    ),
                    child: PhosphorIcon(
                      PhosphorIcons.user(),
                      size: 20,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  if (isFooterHovered)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Admin',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'admin@shababalyola.ae',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      // Handle logout
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: PhosphorIcon(
                        PhosphorIcons.signOut(),
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class MobileBottomNav extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const MobileBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  State<MobileBottomNav> createState() => _MobileBottomNavState();
}

class _MobileBottomNavState extends State<MobileBottomNav> with SingleTickerProviderStateMixin {
  late AnimationController _menuController;
  bool get _isMenuOpen => _menuController.status == AnimationStatus.completed;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _menuController.dispose();
    super.dispose();
  }

  // Reduce radius for tighter menu
  double get _menuRadius => MediaQuery.of(context).size.width * 0.25;
  
  // Adjust arc span for better visual balance with reduced radius
  final double _arcSpan = 130.0; // degrees
  
  List<_MenuItem> get menuItems {
    // Calculate even spacing between items
    final itemCount = 4;
    final angleStep = _arcSpan / (itemCount - 1);
    final startAngle = -180 + (180 - _arcSpan) / 2; // Center the arc

    return [
      _MenuItem(
        angleDeg: startAngle,
        icon: PhosphorIcons.userPlus(),
        label: 'Add Customer',
        onTapMessage: 'Add New Customer',
      ),
      _MenuItem(
        angleDeg: startAngle + angleStep,
        icon: PhosphorIcons.ruler(),
        label: 'Add Measures',
        onTapMessage: 'Add New Measurement',
      ),
      _MenuItem(
        angleDeg: startAngle + (angleStep * 2),
        icon: PhosphorIcons.receipt(),
        label: 'Add Invoice',
        onTapMessage: 'Add New Invoice',
      ),
      _MenuItem(
        angleDeg: startAngle + (angleStep * 3),
        icon: PhosphorIcons.warning(),
        label: 'Add Complaint',
        onTapMessage: 'Add New Complaint',
      ),
    ];
  }

  void _toggleMenu() {
    if (_menuController.isCompleted) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    _menuController.forward();
    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeMenu,
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeMenu() {
    _menuController.reverse().then((_) {
      if (_overlayEntry != null) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final width  = MediaQuery.of(context).size.width;
    final fontSize = (width * 0.03).clamp(10.0, 12.0);
    final iconSize = (width * 0.055).clamp(22.0, 24.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: BottomAppBar(
              color: theme.colorScheme.surface,
              height: 60,
              padding: EdgeInsets.zero,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDestination(
                    icon: PhosphorIcons.squaresFour(),
                    selectedIcon: PhosphorIcons.squaresFour(PhosphorIconsStyle.fill),
                    label: 'Dashboard',
                    fontSize: fontSize,
                    iconSize: iconSize,
                    theme: theme,
                    isSelected: widget.selectedIndex == 0,
                    onTap: () => widget.onDestinationSelected(0),
                  ),
                  _buildDestination(
                    icon: PhosphorIcons.users(),
                    selectedIcon: PhosphorIcons.users(PhosphorIconsStyle.fill),
                    label: 'Customers',
                    fontSize: fontSize,
                    iconSize: iconSize,
                    theme: theme,
                    isSelected: widget.selectedIndex == 1,
                    onTap: () => widget.onDestinationSelected(1),
                  ),
                  const SizedBox(width: 56), // space for FAB
                  _buildDestination(
                    icon: PhosphorIcons.ruler(),
                    selectedIcon: PhosphorIcons.ruler(PhosphorIconsStyle.fill),
                    label: 'Measures',
                    fontSize: fontSize,
                    iconSize: iconSize,
                    theme: theme,
                    isSelected: widget.selectedIndex == 2,
                    onTap: () => widget.onDestinationSelected(2),
                  ),
                  _buildDestination(
                    icon: PhosphorIcons.receipt(),
                    selectedIcon: PhosphorIcons.receipt(PhosphorIconsStyle.fill),
                    label: 'Invoices',
                    fontSize: fontSize,
                    iconSize: iconSize,
                    theme: theme,
                    isSelected: widget.selectedIndex == 3,
                    onTap: () => widget.onDestinationSelected(3),
                  ),
                ],
              ),
            ),
          ),
        ),
        // FAB with circular animated menu.
        Positioned(
          left: 0,
          right: 0,
          bottom: 50, // Adjusted position
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none, // Ensure menu items are not clipped
              children: [
                // Circular Menu Items
                for (var item in menuItems)
                  AnimatedBuilder(
                    animation: _menuController,
                    builder: (context, child) {
                      final double angleRad = item.angleDeg * (math.pi / 180);
                      final double dx = _menuRadius * math.cos(angleRad) * _menuController.value;
                      final double dy = _menuRadius * math.sin(angleRad) * _menuController.value;
                      
                      return Transform.translate(
                        offset: Offset(dx, dy),
                        child: IgnorePointer(
                          ignoring: !_isMenuOpen,
                          child: Transform.scale(
                            scale: _menuController.value,
                            child: Opacity(
                              opacity: _menuController.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.shadow.withOpacity(0.2),
                                      blurRadius: 10,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  shape: const CircleBorder(),
                                  color: theme.brightness == Brightness.dark
                                      ? theme.colorScheme.surfaceContainerHighest
                                      : theme.colorScheme.surface,
                                  elevation: 0,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(item.onTapMessage),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: theme.colorScheme.outline.withOpacity(0.1),
                                          width: 1,
                                        ),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            theme.colorScheme.surfaceContainerHighest,
                                            theme.colorScheme.surface,
                                          ],
                                        ),
                                      ),
                                      child: Icon(
                                        item.icon,
                                        size: 24,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                // The Floating Action Button
                Material(
                  shape: const CircleBorder(),
                  elevation: 8,
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _toggleMenu,
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 24,
                            spreadRadius: -2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0, end: _isMenuOpen ? 1 : 0),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, double value, child) {
                            return Transform.rotate(
                              angle: value * 0.5 * math.pi,
                              child: child,
                            );
                          },
                          child: PhosphorIcon(
                            PhosphorIcons.plus(),
                            size: 28,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDestination({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required double fontSize,
    required double iconSize,
    required ThemeData theme,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PhosphorIcon(
                  isSelected ? selectedIcon : icon,
                  size: iconSize,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final double angleDeg;
  final IconData icon;
  final String label;
  final String onTapMessage;

  _MenuItem({
    required this.angleDeg,
    required this.icon,
    required this.label,
    required this.onTapMessage,
  });
}
