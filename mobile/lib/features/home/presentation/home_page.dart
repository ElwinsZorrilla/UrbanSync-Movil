import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/domain/app_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../incidents/presentation/incidents_providers.dart';
import '../../incidents/presentation/widgets/incident_list_section.dart';
import '../../profile/presentation/profile_page.dart';
import '../../reports/presentation/dashboard_page.dart';

class _HomeTab {
  const _HomeTab({
    required this.icon,
    required this.label,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String label;
  final String title;
  final Widget body;
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tabs = _tabsFor(user.roleGroup);
    final safeIndex = _index.clamp(0, tabs.length - 1);
    final showReportFab = user.isCitizen && safeIndex == 0;

    return Scaffold(
      appBar: AppBar(title: Text(tabs[safeIndex].title)),
      body: IndexedStack(
        index: safeIndex,
        children: tabs.map((tab) => tab.body).toList(),
      ),
      floatingActionButton: showReportFab
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/report'),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Reportar'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: tabs
            .map(
              (tab) =>
                  NavigationDestination(icon: Icon(tab.icon), label: tab.label),
            )
            .toList(),
      ),
    );
  }

  List<_HomeTab> _tabsFor(RoleGroup role) {
    switch (role) {
      case RoleGroup.manager:
        return [
          _HomeTab(
            icon: Icons.assignment_outlined,
            label: 'Triage',
            title: 'Cola de análisis',
            body: IncidentListSection(
              provider: triageQueueProvider,
              emptyTitle: 'No hay incidencias nuevas',
              emptyMessage:
                  'Las incidencias registradas aparecerán aquí para su análisis.',
              routePrefix: '/triage',
            ),
          ),
          _HomeTab(
            icon: Icons.dashboard_outlined,
            label: 'Panel',
            title: 'Panel de gestión',
            body: IncidentListSection(
              provider: allIncidentsProvider,
              emptyTitle: 'Sin incidencias',
            ),
          ),
          _HomeTab(
            icon: Icons.insights_outlined,
            label: 'Indicadores',
            title: 'Indicadores',
            body: DashboardPage(),
          ),
          _HomeTab(
            icon: Icons.person_outline,
            label: 'Perfil',
            title: 'Mi perfil',
            body: ProfilePage(),
          ),
        ];
      case RoleGroup.technician:
        return [
          _HomeTab(
            icon: Icons.build_outlined,
            label: 'Trabajos',
            title: 'Trabajos asignados',
            body: IncidentListSection(
              provider: technicianJobsProvider,
              emptyTitle: 'Sin trabajos asignados',
              emptyMessage: 'Cuando te asignen una incidencia aparecerá aquí.',
            ),
          ),
          _HomeTab(
            icon: Icons.person_outline,
            label: 'Perfil',
            title: 'Mi perfil',
            body: ProfilePage(),
          ),
        ];
      case RoleGroup.citizen:
        return [
          _HomeTab(
            icon: Icons.list_alt_outlined,
            label: 'Reportes',
            title: 'Mis reportes',
            body: IncidentListSection(
              provider: myIncidentsProvider,
              emptyTitle: 'Aún no has reportado incidencias',
              emptyMessage:
                  'Usa el botón "Reportar" para crear tu primer reporte.',
            ),
          ),
          _HomeTab(
            icon: Icons.person_outline,
            label: 'Perfil',
            title: 'Mi perfil',
            body: ProfilePage(),
          ),
        ];
    }
  }
}
