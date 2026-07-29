import 'package:flutter/material.dart';

/// A shell that provides the primary navigation shared across Stride screens.
class StrideNavigationScaffold extends StatefulWidget {
  const StrideNavigationScaffold({
    super.key,
    required this.destinations,
  }) : assert(destinations.length > 1);

  final List<StrideNavigationDestination> destinations;

  @override
  State<StrideNavigationScaffold> createState() =>
      _StrideNavigationScaffoldState();
}

class _StrideNavigationScaffoldState extends State<StrideNavigationScaffold> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: widget.destinations.map((destination) => destination.screen).toList(),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFFE5E7EB)
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: widget.destinations
              .map(
                (destination) => NavigationDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(
                    destination.selectedIcon ?? destination.icon,
                  ),
                  label: destination.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

/// Describes one tab in [StrideNavigationScaffold].
class StrideNavigationDestination {
  const StrideNavigationDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
    required this.screen,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final Widget screen;
}
