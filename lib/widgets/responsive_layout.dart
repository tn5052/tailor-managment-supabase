import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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

class MobileBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const MobileBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    // Calculate font size based on screen width, with min and max constraints
    final fontSize = (width * 0.03).clamp(11.0, 14.0);
    final iconSize = (width * 0.055).clamp(20.0, 24.0);
    
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      height: 60,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        _buildDestination(
          icon: PhosphorIcons.squaresFour(),
          selectedIcon: PhosphorIcons.squaresFour(PhosphorIconsStyle.fill),
          label: 'Dashboard',
          fontSize: fontSize,
          iconSize: iconSize,
          theme: theme,
        ),
        _buildDestination(
          icon: PhosphorIcons.users(),
          selectedIcon: PhosphorIcons.users(PhosphorIconsStyle.fill),
          label: 'Customers',
          fontSize: fontSize,
          iconSize: iconSize,
          theme: theme,
        ),
        _buildDestination(
          icon: PhosphorIcons.ruler(),
          selectedIcon: PhosphorIcons.ruler(PhosphorIconsStyle.fill),
          label: 'Measures',
          fontSize: fontSize,
          iconSize: iconSize,
          theme: theme,
        ),
        _buildDestination(
          icon: PhosphorIcons.receipt(),
          selectedIcon: PhosphorIcons.receipt(PhosphorIconsStyle.fill),
          label: 'Invoices',
          fontSize: fontSize,
          iconSize: iconSize,
          theme: theme,
        ),
        _buildDestination(
          icon: PhosphorIcons.warning(),
          selectedIcon: PhosphorIcons.warning(PhosphorIconsStyle.fill),
          label: 'Issues',
          fontSize: fontSize,
          iconSize: iconSize,
          theme: theme,
        ),
      ],
    );
  }

  NavigationDestination _buildDestination({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required double fontSize,
    required double iconSize,
    required ThemeData theme,
  }) {
    return NavigationDestination(
      icon: PhosphorIcon(
        icon,
        size: iconSize,
      ),
      selectedIcon: PhosphorIcon(
        selectedIcon,
        size: iconSize,
      ),
      label: label,
    );
  }
}
