import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../widgets/customer/add_customer_dialog.dart';
import '../widgets/measurement/add_measurement_dialog.dart'; // added import for measurement dialog
import '../widgets/invoice/add_invoice_dailog.dart'; // added import for invoice dialog
import '../widgets/complaint/complaint_dialog.dart'; // added import for complaint dialog
import 'package:supabase_flutter/supabase_flutter.dart';

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

class _SideMenuState extends State<SideMenu>
    with SingleTickerProviderStateMixin {
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
                padding: EdgeInsets.symmetric(horizontal: isExpanded ? 8 : 12),
                child: ListView(
                  children: [
                    _buildNavItem(
                      index: 0,
                      icon: PhosphorIcon(PhosphorIcons.squaresFour()),
                      selectedIcon: PhosphorIcon(
                        PhosphorIcons.squaresFour(PhosphorIconsStyle.fill),
                      ),
                      label: 'Dashboard',
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: PhosphorIcon(PhosphorIcons.users()),
                      selectedIcon: PhosphorIcon(
                        PhosphorIcons.users(PhosphorIconsStyle.fill),
                      ),
                      label: 'Customers',
                    ),
                    _buildNavItem(
                      index: 2,
                      icon: PhosphorIcon(PhosphorIcons.ruler()),
                      selectedIcon: PhosphorIcon(
                        PhosphorIcons.ruler(PhosphorIconsStyle.fill),
                      ),
                      label: 'Measurements',
                    ),
                    _buildNavItem(
                      index: 3,
                      icon: PhosphorIcon(PhosphorIcons.receipt()),
                      selectedIcon: PhosphorIcon(
                        PhosphorIcons.receipt(PhosphorIconsStyle.fill),
                      ),
                      label: 'Invoices',
                    ),
                    _buildNavItem(
                      index: 4,
                      icon: PhosphorIcon(PhosphorIcons.warning()),
                      selectedIcon: PhosphorIcon(
                        PhosphorIcons.warning(PhosphorIconsStyle.fill),
                      ),
                      label: 'Complaints',
                    ),
                    _buildNavItem(
                      index: 5,
                      icon: PhosphorIcon(PhosphorIcons.package()),
                      selectedIcon: PhosphorIcon(
                        PhosphorIcons.package(PhosphorIconsStyle.fill),
                      ),
                      label: 'Inventory',
                    ),
                    _buildNavItem(
                      index: 6,
                      icon: PhosphorIcon(PhosphorIcons.gear()),
                      selectedIcon: PhosphorIcon(
                        PhosphorIcons.gear(PhosphorIconsStyle.fill),
                      ),
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
        mainAxisAlignment:
            isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
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
                  color:
                      isHovering
                          ? theme.colorScheme.surfaceContainerHighest.withAlpha(
                            100,
                          )
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
          color:
              isSelected
                  ? theme.colorScheme.primaryContainer
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onDestinationSelected(index),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 40,
              padding: EdgeInsets.symmetric(horizontal: isExpanded ? 12 : 0),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                alignment: isExpanded ? Alignment.centerLeft : Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconTheme(
                      data: IconThemeData(
                        color:
                            isSelected
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
                                color:
                                    isSelected
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
          color:
              isFooterHovered
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
                      boxShadow:
                          isFooterHovered
                              ? [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withAlpha(
                                    40,
                                  ),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                              : [],
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
                    onTap: () => _handleSignOut(context),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: PhosphorIcon(
                        PhosphorIcons.signOut(),
                        size: 20,
                        color: theme.colorScheme.error,
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

  Future<void> _handleSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await Supabase.instance.client.auth.signOut();
    }
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

class _MobileBottomNavState extends State<MobileBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _menuController;
  OverlayEntry? _overlayEntry;
  OverlayEntry? _fabPopoverEntry;

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

  /* Commenting out circular menu code temporarily
  double get _menuRadius => MediaQuery.of(context).size.width * 0.25;
  final double _arcSpan = 130.0;
  
  List<_MenuItem> get menuItems {
    // Calculate even spacing between items
    final itemCount = 4;
    final angleStep = _arcSpan / (itemCount - 1);
    final startAngle = -180 + (180 - _arcSpan) / 2;

    return [
      _MenuItem(
        angleDeg: startAngle,
        icon: PhosphorIcons.userPlus(),
        label: 'Add Customer',
        onTapMessage: 'Add New Customer',
      ),
      // ...rest of the menu items...
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
  */

  void _toggleFabPopover() {
    if (_fabPopoverEntry == null) {
      _showFabPopover();
    } else {
      _removeFabPopover();
    }
  }

  void _showFabPopover() {
    final overlay = Overlay.of(context);
    _fabPopoverEntry = OverlayEntry(
      builder:
          (context) => TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0.0, end: 1.0),
            builder:
                (context, value, child) => GestureDetector(
                  onTap: _removeFabPopover,
                  behavior: HitTestBehavior.translucent,
                  child: Stack(
                    children: [
                      // Backdrop with fade animation
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.1 * value),
                        ),
                      ),
                      // Animated popover
                      Positioned(
                        left: MediaQuery.of(context).size.width / 2 - 100,
                        bottom: 120 + (1 - value) * 20, // Slide up effect
                        child: Transform.scale(
                          scale: 0.2 + value * 0.8, // Scale up from 0.2 to 1.0
                          alignment: Alignment.bottomCenter,
                          child: Opacity(
                            opacity: value,
                            child: _FabPopover(
                              onOptionSelected: (option) {
                                _removeFabPopover();
                                if (option == "Add Customer") {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => const AddCustomerDialog(),
                                  );
                                } else if (option == "Add Measures") {
                                  AddMeasurementDialog.show(context);
                                } else if (option == "Add Invoice") {
                                  InvoiceScreen.show(context);
                                } else if (option == "Add Complaint") {
                                  ComplaintDialog.show(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(option)),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
    overlay.insert(_fabPopoverEntry!);
  }

  void _removeFabPopover() {
    _fabPopoverEntry?.remove();
    _fabPopoverEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
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
              height: 65, // Increased height to match FAB spacing
              padding: EdgeInsets.zero,
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly, // Changed to spaceEvenly
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDestination(
                          icon: PhosphorIcons.squaresFour(),
                          selectedIcon: PhosphorIcons.squaresFour(
                            PhosphorIconsStyle.fill,
                          ),
                          label: 'Dashboard',
                          fontSize: fontSize,
                          iconSize: iconSize,
                          theme: theme,
                          isSelected: widget.selectedIndex == 0,
                          onTap: () => widget.onDestinationSelected(0),
                        ),
                        _buildDestination(
                          icon: PhosphorIcons.users(),
                          selectedIcon: PhosphorIcons.users(
                            PhosphorIconsStyle.fill,
                          ),
                          label: 'Customers',
                          fontSize: fontSize,
                          iconSize: iconSize,
                          theme: theme,
                          isSelected: widget.selectedIndex == 1,
                          onTap: () => widget.onDestinationSelected(1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 70), // Increased space for FAB
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDestination(
                          icon: PhosphorIcons.ruler(),
                          selectedIcon: PhosphorIcons.ruler(
                            PhosphorIconsStyle.fill,
                          ),
                          label: 'Measures',
                          fontSize: fontSize,
                          iconSize: iconSize,
                          theme: theme,
                          isSelected: widget.selectedIndex == 2,
                          onTap: () => widget.onDestinationSelected(2),
                        ),
                        _buildDestination(
                          icon: PhosphorIcons.receipt(),
                          selectedIcon: PhosphorIcons.receipt(
                            PhosphorIconsStyle.fill,
                          ),
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
                ],
              ),
            ),
          ),
        ),
        // FAB positioning updated
        Positioned(
          left: 0,
          right: 0,
          bottom: 32, // Adjusted to align with nav buttons
          child: Center(
            child: Material(
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              elevation: 4,
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _toggleFabPopover,
                child: Ink(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        blurRadius: 16,
                        spreadRadius: -2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: 56,
                    width: 56,
                    child: Center(
                      child: PhosphorIcon(
                        PhosphorIcons.plus(),
                        size: 24,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
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
    return Material(
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
                color:
                    isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  color:
                      isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Enhance _FabPopover with staggered item animations
class _FabPopover extends StatelessWidget {
  final void Function(String option) onOptionSelected;
  const _FabPopover({required this.onOptionSelected});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ClipPath(
        clipper: _PopoverClipper(),
        child: Container(
          width: 200,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAnimatedItem("Add Customer", PhosphorIcons.userPlus(), 0),
              _buildAnimatedItem("Add Measures", PhosphorIcons.ruler(), 1),
              _buildAnimatedItem("Add Invoice", PhosphorIcons.receipt(), 2),
              _buildAnimatedItem("Add Complaint", PhosphorIcons.warning(), 3),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedItem(String text, IconData icon, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index * 40)),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder:
          (context, value, child) => Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: TextButton(
                onPressed: () => onOptionSelected(text),
                child: Row(
                  children: [Icon(icon), const SizedBox(width: 8), Text(text)],
                ),
              ),
            ),
          ),
    );
  }
}

// Custom clipper for popover shape with bottom arrow.
class _PopoverClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const arrowHeight = 20.0;
    const cornerRadius = 30.0; // updated corner radius
    final path = Path();

    // Top-left corner
    path.moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);
    // Top line
    path.lineTo(size.width - cornerRadius, 0);
    // Top-right corner
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);
    // Right side
    path.lineTo(size.width, size.height - arrowHeight - cornerRadius);
    // Bottom-right corner
    path.quadraticBezierTo(
      size.width,
      size.height - arrowHeight,
      size.width - cornerRadius,
      size.height - arrowHeight,
    );
    // Bottom line to right arrow base
    const arrowWidth = 40.0; // increased arrow width
    final arrowXEnd = (size.width + arrowWidth) / 2;
    path.lineTo(arrowXEnd, size.height - arrowHeight);
    // Arrow tip
    final arrowXMid = size.width / 2;
    path.lineTo(arrowXMid, size.height);
    // Arrow left base
    final arrowXStart = (size.width - arrowWidth) / 2;
    path.lineTo(arrowXStart, size.height - arrowHeight);
    // Bottom line left
    path.lineTo(cornerRadius, size.height - arrowHeight);
    // Bottom-left corner
    path.quadraticBezierTo(
      0,
      size.height - arrowHeight,
      0,
      size.height - arrowHeight - cornerRadius,
    );
    // Left side
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
