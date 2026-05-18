import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import 'constants.dart';

// Auth screens
import '../features/auth/views/login_screen.dart';
import '../features/auth/views/forgot_password_screen.dart';

// Admin screens
import '../features/admin/views/admin_layout.dart';
import '../features/admin/views/admin_dashboard_screen.dart';
import '../features/admin/views/admin_clients_screen.dart';
import '../features/admin/views/admin_client_new_screen.dart';
import '../features/admin/views/admin_client_detail_screen.dart';
import '../features/admin/views/admin_technicians_screen.dart';
import '../features/admin/views/admin_create_technician_screen.dart';
import '../features/admin/views/admin_orders_screen.dart';
import '../features/admin/views/admin_order_detail_screen.dart';
import '../features/admin/views/admin_quotes_screen.dart';
import '../features/admin/views/admin_quote_new_screen.dart';
import '../features/admin/views/admin_equipment_screen.dart';
import '../features/admin/views/admin_equipment_new_screen.dart';
import '../features/admin/views/admin_equipment_detail_screen.dart';
import '../features/admin/views/admin_service_catalog_screen.dart';
import '../features/admin/views/admin_tech_tracking_screen.dart';
import '../features/admin/views/admin_reports_screen.dart';
import '../features/notifications/views/notifications_screen.dart';

// Tech screens
import '../features/tech/views/tech_layout.dart';
import '../features/tech/views/tech_jobs_screen.dart';
import '../features/tech/views/tech_job_detail_screen.dart';
import '../features/tech/views/tech_quote_detail_screen.dart';
import '../features/tech/views/tech_profile_screen.dart';

// Client screens
import '../features/client/views/client_layout.dart';
import '../features/client/views/client_home_screen.dart';
import '../features/client/views/client_equipment_screen.dart';
import '../features/client/views/client_equipment_detail_screen.dart';
import '../features/client/views/client_equipment_new_screen.dart';
import '../features/client/views/client_new_request_screen.dart';
import '../features/client/views/client_service_detail_screen.dart';
import '../features/client/views/client_quote_detail_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isInitialized = authState.isInitialized;
      final isAuthRoute = state.matchedLocation == '/login' || 
                          state.matchedLocation == '/forgot-password';

      if (!isInitialized) return null;

      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      if (isAuthenticated && isAuthRoute) {
        final role = authState.role;
        if (role == UserRole.admin) return '/admin';
        if (role == UserRole.technician) return '/technician';
        return '/client';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Admin Shell
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AdminLayout(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            name: 'admin-dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/clients',
            name: 'admin-clients',
            builder: (context, state) => const AdminClientsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'admin-client-new',
                builder: (context, state) => const AdminClientNewScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'admin-client-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return AdminClientDetailScreen(clientId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/admin/technicians',
            name: 'admin-technicians',
            builder: (context, state) => const AdminTechniciansScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'admin-technician-new',
                builder: (context, state) => const AdminCreateTechnicianScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/admin/orders',
            name: 'admin-orders',
            builder: (context, state) => const AdminOrdersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'admin-order-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return AdminOrderDetailScreen(orderId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/admin/quotes',
            name: 'admin-quotes',
            builder: (context, state) => const AdminQuotesScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'admin-quote-new',
                builder: (context, state) => const AdminQuoteNewScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/admin/equipment',
            name: 'admin-equipment',
            builder: (context, state) => const AdminEquipmentScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'admin-equipment-new',
                builder: (context, state) {
                  final clientId = state.uri.queryParameters['client_id'];
                  return AdminEquipmentNewScreen(clientId: clientId);
                },
              ),
              GoRoute(
                path: ':id',
                name: 'admin-equipment-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return AdminEquipmentDetailScreen(equipmentId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/admin/catalog',
            name: 'admin-catalog',
            builder: (context, state) => const AdminServiceCatalogScreen(),
          ),
          GoRoute(
            path: '/admin/tracking',
            name: 'admin-tracking',
            builder: (context, state) => const AdminTechTrackingScreen(),
          ),
          GoRoute(
            path: '/admin/reports',
            name: 'admin-reports',
            builder: (context, state) => const AdminReportsScreen(),
          ),
        ],
      ),

      // Technician Shell
      ShellRoute(
        builder: (context, state, child) => TechLayout(child: child),
        routes: [
          GoRoute(
            path: '/technician',
            name: 'technician-jobs',
            builder: (context, state) => const TechJobsScreen(),
          ),
          GoRoute(
            path: '/technician/job/:id',
            name: 'technician-job-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TechJobDetailScreen(jobId: id);
            },
          ),
          GoRoute(
            path: '/technician/quote/:id',
            name: 'technician-quote-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TechQuoteDetailScreen(quoteId: id);
            },
          ),
          GoRoute(
            path: '/technician/profile',
            name: 'technician-profile',
            builder: (context, state) => const TechProfileScreen(),
          ),
        ],
      ),

      // Client Shell
      ShellRoute(
        builder: (context, state, child) => ClientLayout(child: child),
        routes: [
          GoRoute(
            path: '/client',
            name: 'client-home',
            builder: (context, state) => const ClientHomeScreen(),
          ),
          GoRoute(
            path: '/client/equipment',
            name: 'client-equipment',
            builder: (context, state) => const ClientEquipmentScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'client-equipment-new',
                builder: (context, state) => const ClientEquipmentNewScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'client-equipment-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ClientEquipmentDetailScreen(equipmentId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/client/new-request',
            name: 'client-new-request',
            builder: (context, state) => const ClientNewRequestScreen(),
          ),
          GoRoute(
            path: '/client/service/:id',
            name: 'client-service-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ClientServiceDetailScreen(serviceId: id);
            },
          ),
          GoRoute(
            path: '/client/quote/:id',
            name: 'client-quote-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ClientQuoteDetailScreen(quoteId: id);
            },
          ),
        ],
      ),
    ],
  );
});
