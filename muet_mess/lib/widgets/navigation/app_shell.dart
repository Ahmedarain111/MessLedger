import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/route_names.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/responsive_utils.dart';
import '../../models/user_model.dart';
import '../../providers/theme_provider.dart';
import '../common/user_avatar.dart';

class Destination {
  const Destination({required this.label, required this.icon, required this.route});

  final String label;
  final IconData icon;
  final String route;
}

/// Adaptive shell: bottom nav on mobile, rail on tablet, side pane on desktop.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.destinations, required this.currentRoute, required this.onGo, required this.user});

  final Widget child;
  final List<Destination> destinations;
  final String currentRoute;
  final ValueChanged<String> onGo;
  final AppUser user;

  int get _index {
    final i = destinations.indexWhere((d) => currentRoute.startsWith(d.route));
    return i < 0 ? 0 : i;
  }

  bool get _isManager => user.role == UserRole.manager;

  @override
  Widget build(BuildContext context) {
    switch (ResponsiveUtils.of(context)) {
      case ScreenSize.desktop:
        return Scaffold(
          body: Row(children: [
            _Sidebar(
              destinations: destinations,
              selectedIndex: _index,
              onGo: onGo,
              user: user,
              profileRoute: _isManager ? RouteNames.managerProfile : RouteNames.studentProfile,
            ),
            Expanded(child: child),
          ]),
        );
      case ScreenSize.tablet:
        return Scaffold(
          body: Row(children: [
            LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: NavigationRail(
                      selectedIndex: _index,
                      onDestinationSelected: (i) => onGo(destinations[i].route),
                      labelType: NavigationRailLabelType.all,
                      leading: const Padding(
                        padding: EdgeInsets.only(top: 12, bottom: 16),
                        child: _BrandMark(size: 44),
                      ),
                      trailing: const Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(padding: EdgeInsets.only(bottom: 16), child: _ThemeToggleButton()),
                        ),
                      ),
                      destinations: destinations
                          .map((d) => NavigationRailDestination(
                                icon: Icon(d.icon),
                                label: Text(d.label),
                                padding: const EdgeInsets.symmetric(vertical: 2),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              );
            }),
            VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
            Expanded(child: child),
          ]),
        );
      case ScreenSize.mobile:
        return Scaffold(
          body: child,
          bottomNavigationBar: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: NavigationBar(
              selectedIndex: _index,
              labelBehavior: destinations.length > 5
                  ? NavigationDestinationLabelBehavior.onlyShowSelected
                  : NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (i) => onGo(destinations[i].route),
              destinations: destinations
                  .map((d) => NavigationDestination(icon: Icon(d.icon), label: d.label, tooltip: d.label))
                  .toList(),
            ),
          ),
        );
    }
  }
}

/// Gradient app mark.
class _BrandMark extends StatelessWidget {
  const _BrandMark({this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: tokens.heroGradient),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [BoxShadow(color: tokens.heroGradient.first.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Icon(Icons.restaurant_menu, color: tokens.onHero, size: size * 0.52),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final dark = theme.mode == ThemeMode.dark;
    return IconButton(
      tooltip: dark ? 'Switch to light mode' : 'Switch to dark mode',
      onPressed: () => theme.toggle(),
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.onGo,
    required this.user,
    required this.profileRoute,
  });

  final List<Destination> destinations;
  final int selectedIndex;
  final ValueChanged<String> onGo;
  final AppUser user;
  final String profileRoute;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final theme = context.watch<ThemeProvider>();
    final dark = theme.mode == ThemeMode.dark;
    final isManager = user.role == UserRole.manager;
    return Material(
      color: scheme.surface,
      child: Container(
        width: 264,
        decoration: BoxDecoration(border: Border(right: BorderSide(color: Theme.of(context).dividerColor))),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Row(children: [
                const _BrandMark(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(AppConstants.appName, style: text.titleMedium),
                    const SizedBox(height: 2),
                    Text(isManager ? 'Manager console' : 'Student portal', style: text.bodySmall),
                  ]),
                ),
              ]),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: destinations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, i) {
                  final d = destinations[i];
                  final selected = i == selectedIndex;
                  return Material(
                    color: selected ? scheme.primaryContainer : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onGo(d.route),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        child: Row(children: [
                          Icon(d.icon, size: 22, color: selected ? scheme.primary : scheme.onSurfaceVariant),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              d.label,
                              style: text.labelLarge?.copyWith(
                                color: selected ? scheme.primary : scheme.onSurface,
                                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (selected) Container(width: 6, height: 6, decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle)),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => theme.toggle(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Row(children: [
                    Icon(dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined, size: 20, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 14),
                    Expanded(child: Text('Dark mode', style: text.labelLarge?.copyWith(fontWeight: FontWeight.w600))),
                    IgnorePointer(child: Switch(value: dark, onChanged: (_) {})),
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onGo(profileRoute),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(children: [
                    UserAvatar(name: user.name, radius: 19),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(user.name, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(user.role == UserRole.manager ? 'Manager' : 'Student', style: text.bodySmall),
                      ]),
                    ),
                    Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
