import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:controlzukis/core/models/license_status.dart';
import 'package:controlzukis/app/router/routing_snapshot.dart';
import 'package:controlzukis/core/theme/app_theme.dart';
import 'package:controlzukis/core/providers/maintenance_provider.dart';
import 'package:controlzukis/features/bootstrap/presentation/controllers/bootstrap_controller.dart';
import 'package:controlzukis/features/settings/presentation/controllers/theme_controller.dart';

class SaaSScaffold extends ConsumerWidget {
  const SaaSScaffold({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.child,
  });

  final String currentRoute;
  final String title;
  final Widget child;

  static const _items = <_NavItem>[
    _NavItem('/dashboard', 'Dashboard', Icons.dashboard_outlined),
    _NavItem('/products', 'Productos', Icons.inventory_2_outlined),
    _NavItem('/categories', 'Categorías', Icons.category_outlined),
    _NavItem('/sales', 'Ventas', Icons.point_of_sale_outlined),
    _NavItem('/expenses', 'Gastos', Icons.receipt_long_outlined),
    _NavItem('/customers', 'Clientes', Icons.groups_outlined),
    _NavItem('/reports', 'Reportes', Icons.assessment_outlined),
    _NavItem('/settings', 'Settings', Icons.settings_outlined),
    _NavItem('/superadmin', 'SuperAdmin', Icons.admin_panel_settings_outlined),
  ];

  int get _selectedIndex => _items
      .indexWhere((i) => i.route == currentRoute)
      .clamp(0, _items.length - 1);

  String _licenseLabel(RoutingSnapshot? snapshot) {
    if (snapshot == null) return 'Licencia: ...';
    return switch (snapshot.licenseStatus) {
      LicenseStatus.active => 'Activo',
      LicenseStatus.trial => 'Trial (${snapshot.daysRemaining} días)',
      LicenseStatus.expired => 'Expirado',
      LicenseStatus.tamper => 'Tamper',
    };
  }

  Color _licenseBgColor(BuildContext context, RoutingSnapshot? snapshot) {
    final scheme = Theme.of(context).colorScheme;
    if (snapshot == null) return scheme.surfaceContainerHighest;
    return switch (snapshot.licenseStatus) {
      LicenseStatus.active => Colors.green.withValues(alpha: 0.15),
      LicenseStatus.trial => Colors.blue.withValues(alpha: 0.15),
      LicenseStatus.expired => Colors.orange.withValues(alpha: 0.18),
      LicenseStatus.tamper => Colors.red.withValues(alpha: 0.18),
    };
  }

  Color _licenseTextColor(BuildContext context, RoutingSnapshot? snapshot) {
    final scheme = Theme.of(context).colorScheme;
    if (snapshot == null) return scheme.onSurfaceVariant;
    return switch (snapshot.licenseStatus) {
      LicenseStatus.active => Colors.green.shade800,
      LicenseStatus.trial => Colors.blue.shade800,
      LicenseStatus.expired => Colors.orange.shade900,
      LicenseStatus.tamper => Colors.red.shade900,
    };
  }

  Widget _licenseBadge(BuildContext context, RoutingSnapshot? snapshot) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _licenseBgColor(context, snapshot),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _licenseLabel(snapshot),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: _licenseTextColor(context, snapshot),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _statusBanner(BuildContext context, RoutingSnapshot? snapshot) {
    if (snapshot == null) return const SizedBox.shrink();
    if (!snapshot.isReadOnly) return const SizedBox.shrink();

    final isTamper = snapshot.licenseStatus == LicenseStatus.tamper;
    final text = isTamper
        ? 'Se detectó alteración de reloj del sistema. Activación obligatoria.'
        : 'Licencia expirada: modo solo lectura activo. Las escrituras están bloqueadas.';
    final ctaText = isTamper ? 'Activar' : 'Ver diagnóstico';

    return Container(
      width: double.infinity,
      color: isTamper
          ? Colors.red.withValues(alpha: 0.12)
          : Colors.orange.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(
            isTamper ? Icons.gpp_bad_outlined : Icons.lock_outline,
            size: 18,
            color: isTamper ? Colors.red.shade900 : Colors.orange.shade900,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isTamper ? Colors.red.shade900 : Colors.orange.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                context.go(isTamper ? '/activation' : '/superadmin'),
            child: Text(ctaText),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    RoutingSnapshot? snapshot,
  ) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                Text(
                  currentRoute.replaceFirst('/', '').toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 280,
            child: TextField(
              readOnly: true,
              decoration: const InputDecoration(
                hintText: 'Búsqueda global (próximamente)',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _licenseBadge(context, snapshot),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            tooltip: 'Cambiar tema',
            onPressed: () {
              final notifier = ref.read(themeModeProvider.notifier);
              final next = switch (themeMode) {
                ThemeMode.system => isDark ? ThemeMode.light : ThemeMode.dark,
                ThemeMode.light => ThemeMode.dark,
                ThemeMode.dark => ThemeMode.light,
              };
              notifier.setThemeMode(next);
            },
            icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) {
              if (value == 'settings') context.go('/settings');
              if (value == 'license') context.go('/activation');
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'settings', child: Text('Mi configuración')),
              PopupMenuItem(value: 'license', child: Text('Licencia')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _maintenanceOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withValues(alpha: 0.40),
          alignment: Alignment.center,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Modo mantenimiento activo',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text('Restauración en curso. No cierres la app.'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref
        .watch(bootstrapControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final maintenance = ref
        .watch(maintenanceModeProvider)
        .maybeWhen(data: (v) => v, orElse: () => false);

    if (snapshot?.licenseStatus == LicenseStatus.tamper &&
        currentRoute != '/activation') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/activation');
        }
      });
    }

    final content = Column(
      children: [
        _statusBanner(context, snapshot),
        Expanded(
          child: Stack(
            children: [
              child,
              if (snapshot?.isReadOnly ?? false)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Card(
                    color: Colors.orange.withValues(alpha: 0.12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text('Solo lectura activo'),
                    ),
                  ),
                ),
              if (maintenance) _maintenanceOverlay(),
            ],
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 980;
        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  useIndicator: true,
                  minExtendedWidth: 220,
                  extended: constraints.maxWidth >= 1280,
                  labelType: constraints.maxWidth >= 1280
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  onDestinationSelected: (index) {
                    context.go(_items[index].route);
                  },
                  destinations: [
                    for (final i in _items)
                      NavigationRailDestination(
                        icon: Icon(i.icon),
                        label: Text(i.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopBar(context, ref, snapshot),
                      const Divider(height: 1),
                      Expanded(child: content),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              IconButton(
                tooltip: 'Tema',
                onPressed: () {
                  final notifier = ref.read(themeModeProvider.notifier);
                  final dark = Theme.of(context).brightness == Brightness.dark;
                  notifier.setThemeMode(
                    dark ? ThemeMode.light : ThemeMode.dark,
                  );
                },
                icon: const Icon(Icons.brightness_6_outlined),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(child: _licenseBadge(context, snapshot)),
              ),
            ],
          ),
          body: content,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              context.go(_items[index].route);
            },
            destinations: [
              for (final i in _items)
                NavigationDestination(icon: Icon(i.icon), label: i.label),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem {
  const _NavItem(this.route, this.label, this.icon);

  final String route;
  final String label;
  final IconData icon;
}
