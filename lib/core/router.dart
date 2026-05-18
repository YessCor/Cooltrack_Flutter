import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'core/constants.dart';

// Auth screens
import 'features/auth/views/login_screen.dart';
import 'features/auth/views/forgot_password_screen.dart';

// Admin screens
import 'features/admin/views/admin_layout.dart';
import 'features/admin/views/admin_dashboard_screen.dart';
import 'features/admin/views/admin_clients_screen.dart';
import 'features/admin/views/admin_client_new_screen.dart';
import 'features/admin/views/admin_client_detail_screen.dart';
import 'features/admin/views/admin_technicians_screen.dart';
import 'features/admin/views/admin_create_technician_screen.dart';
import 'features/admin/views/admin_orders_screen.dart';
import 'features/admin/views/admin_order_detail_screen.dart';
import 'features/admin/views/admin_quotes_screen.dart';
import 'features/admin/views/admin_quote_new_screen.dart';
import 'features/admin/views/admin_equipment_screen.dart';
import 'features/admin/views/admin_equipment_new_screen.dart';
import 'features/admin/views/admin_equipment_detail_screen.dart';

// Tech screens
import 'features/tech/views/tech_layout.dart';
import 'features/tech/views/tech_jobs_screen.dart';
import 'features/tech/views/tech_job_detail_screen.dart';
import 'features/tech/views/tech_quote_detail_screen.dart';
import 'features/tech/views/tech_profile_screen.dart';

// Client screens
import 'features/client/views/client_layout.dart';
import 'features/client/views/client_home_screen.dart';
import 'features/client/views/client_equipment_screen.dart';
import 'features/client/views/client_equipment_detail_screen.dart';
import 'features/client/views/client_equipment_new_screen.dart';
import 'features/client/views/client_new_request_screen.dart';
import 'features/client/views/client_service_detail_screen.dart';
import 'features/client/views/client_quote_detail_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

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

      // Admin routes
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminLayout(),
        routes: [
          GoRoute(
            path: '',
            name: 'admin-dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: 'clients',
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
            path: 'technicians',
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
            path: 'orders',
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
            path: 'quotes',
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
            path: 'equipment',
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
        ],
      ),

      // Technician routes
      GoRoute(
        path: '/technician',
        name: 'technician',
        builder: (context, state) => const TechLayout(),
        routes: [
          GoRoute(
            path: '',
            name: 'technician-jobs',
            builder: (context, state) => const TechJobsScreen(),
          ),
          GoRoute(
            path: 'job/:id',
            name: 'technician-job-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TechJobDetailScreen(jobId: id);
            },
          ),
          GoRoute(
            path: 'quote/:id',
            name: 'technician-quote-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TechQuoteDetailScreen(quoteId: id);
            },
          ),
          GoRoute(
            path: 'profile',
            name: 'technician-profile',
            builder: (context, state) => const TechProfileScreen(),
          ),
        ],
      ),

      // Client routes
      GoRoute(
        path: '/client',
        name: 'client',
        builder: (context, state) => const ClientLayout(),
        routes: [
          GoRoute(
            path: '',
            name: 'client-home',
            builder: (context, state) => const ClientHomeScreen(),
          ),
          GoRoute(
            path: 'equipment',
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
            path: 'new-request',
            name: 'client-new-request',
            builder: (context, state) => const ClientNewRequestScreen(),
          ),
          GoRoute(
            path: 'service/:id',
            name: 'client-service-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ClientServiceDetailScreen(serviceId: id);
            },
          ),
          GoRoute(
            path: 'quote/:id',
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



