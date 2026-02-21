import 'package:controlzukis/features/bootstrap/presentation/screens/splash_screen.dart';
import 'package:controlzukis/features/bootstrap/presentation/controllers/bootstrap_controller.dart';
import 'package:controlzukis/app/router/routing_snapshot.dart';
import 'package:controlzukis/features/auth/presentation/screens/login_screen.dart';
import 'package:controlzukis/features/categories/presentation/screens/categories_screen.dart';
import 'package:controlzukis/features/customers/presentation/screens/customers_screen.dart';
import 'package:controlzukis/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:controlzukis/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:controlzukis/features/license/presentation/screens/activation_screen.dart';
import 'package:controlzukis/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:controlzukis/features/products/presentation/screens/products_screen.dart';
import 'package:controlzukis/features/reports/presentation/screens/reports_screen.dart';
import 'package:controlzukis/features/sales/presentation/screens/sales_screen.dart';
import 'package:controlzukis/features/settings/presentation/screens/settings_screen.dart';
import 'package:controlzukis/features/superadmin/presentation/screens/superadmin_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final snapshotAsync = ref.watch(bootstrapControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final path = state.uri.path;

      return snapshotAsync.maybeWhen(
        data: (snapshot) {
          final isSplash = path == '/splash';
          final isActivation = path == '/activation';
          final isOnboarding = path == '/onboarding';
          final isLogin = path == '/login';

          if (snapshot.maintenanceMode &&
              !isSplash &&
              !isActivation &&
              !isLogin) {
            return '/splash';
          }

          switch (snapshot.phase) {
            case AppRoutePhase.unknown:
              return isSplash ? null : '/splash';
            case AppRoutePhase.activation:
              return isActivation ? null : '/activation';
            case AppRoutePhase.onboarding:
              return isOnboarding ? null : '/onboarding';
            case AppRoutePhase.ready:
              if (!snapshot.hasSession) {
                return isLogin ? null : '/login';
              }
              if (isSplash || isOnboarding || isLogin) {
                return '/dashboard';
              }
              return null;
          }
        },
        orElse: () {
          return path == '/splash' ? null : '/splash';
        },
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/activation',
        builder: (context, state) => const ActivationScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductsScreen(),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(path: '/sales', builder: (context, state) => const SalesScreen()),
      GoRoute(
        path: '/expenses',
        builder: (context, state) => const ExpensesScreen(),
      ),
      GoRoute(
        path: '/customers',
        builder: (context, state) => const CustomersScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/superadmin',
        builder: (context, state) => const SuperAdminScreen(),
      ),
    ],
  );
});
