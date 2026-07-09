import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/auth/presentation/splash_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/incidents/presentation/incident_detail_page.dart';
import '../features/incidents/presentation/report_incident_page.dart';
import '../features/triage/presentation/triage_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final location = state.matchedLocation;
      final onSplash = location == '/splash';
      final onAuthPage = location == '/login' || location == '/register';

      if (status == AuthStatus.unknown) {
        return onSplash ? null : '/splash';
      }

      if (status == AuthStatus.unauthenticated) {
        return onAuthPage ? null : '/login';
      }

      if (onSplash || onAuthPage) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/report',
        builder: (context, state) => const ReportIncidentPage(),
      ),
      GoRoute(
        path: '/incidents/:id',
        builder: (context, state) => IncidentDetailPage(
          incidentId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/triage/:id',
        builder: (context, state) =>
            TriagePage(incidentId: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );
});
