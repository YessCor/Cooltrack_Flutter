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
import 'features/admin/views/admin_technicians_screen.dart';
import 'features/admin/views/admin_orders_screen.dart';
import 'features/admin/views/admin_quotes_screen.dart';
import 'features/admin/views/admin_equipment_screen.dart';

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
                  return AdminClientDetailScreenPlaceholder(clientId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'technicians',
            name: 'admin-technicians',
            builder: (context, state) => const AdminTechniciansScreen(),
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
                  return AdminOrderDetailScreenPlaceholder(orderId: id);
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
                builder: (context, state) => const AdminQuoteNewScreenPlaceholder(),
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
                builder: (context, state) => const AdminEquipmentNewScreenPlaceholder(),
              ),
              GoRoute(
                path: ':id',
                name: 'admin-equipment-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return AdminEquipmentDetailScreenPlaceholder(equipmentId: id);
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
        builder: (context, state) => const TechnicianLayoutPlaceholder(),
        routes: [
          GoRoute(
            path: '',
            name: 'technician-jobs',
            builder: (context, state) => const TechnicianJobsScreenPlaceholder(),
          ),
          GoRoute(
            path: 'job/:id',
            name: 'technician-job-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TechnicianJobDetailScreenPlaceholder(jobId: id);
            },
          ),
          GoRoute(
            path: 'quote/:id',
            name: 'technician-quote-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TechnicianQuoteDetailScreenPlaceholder(quoteId: id);
            },
          ),
          GoRoute(
            path: 'profile',
            name: 'technician-profile',
            builder: (context, state) => const TechnicianProfileScreenPlaceholder(),
          ),
        ],
      ),

      // Client routes
      GoRoute(
        path: '/client',
        name: 'client',
        builder: (context, state) => const ClientLayoutPlaceholder(),
        routes: [
          GoRoute(
            path: '',
            name: 'client-home',
            builder: (context, state) => const ClientHomeScreenPlaceholder(),
          ),
          GoRoute(
            path: 'equipment',
            name: 'client-equipment',
            builder: (context, state) => const ClientEquipmentScreenPlaceholder(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'client-equipment-new',
                builder: (context, state) => const ClientEquipmentNewScreenPlaceholder(),
              ),
            ],
          ),
          GoRoute(
            path: 'new-request',
            name: 'client-new-request',
            builder: (context, state) => const ClientNewRequestScreenPlaceholder(),
          ),
          GoRoute(
            path: 'service/:id',
            name: 'client-service-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ClientServiceDetailScreenPlaceholder(serviceId: id);
            },
          ),
          GoRoute(
            path: 'quote/:id',
            name: 'client-quote-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ClientQuoteDetailScreenPlaceholder(quoteId: id);
            },
          ),
        ],
      ),
    ],
  );
});

// Placeholder screens for detail views
class AdminClientDetailScreenPlaceholder extends StatelessWidget {
  final String clientId;
  const AdminClientDetailScreenPlaceholder({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Cliente $clientId')),
    body: const Center(child: Text('Detalle de cliente')),
  );
}

class AdminOrderDetailScreenPlaceholder extends StatelessWidget {
  final String orderId;
  const AdminOrderDetailScreenPlaceholder({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Orden $orderId')),
    body: const Center(child: Text('Detalle de orden')),
  );
}

class AdminQuoteNewScreenPlaceholder extends StatelessWidget {
  const AdminQuoteNewScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nueva Cotización')),
    body: const Center(child: Text('Nueva cotización')),
  );
}

class AdminEquipmentNewScreenPlaceholder extends StatelessWidget {
  const AdminEquipmentNewScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nuevo Equipo')),
    body: const Center(child: Text('Nuevo equipo')),
  );
}

class AdminEquipmentDetailScreenPlaceholder extends StatelessWidget {
  final String equipmentId;
  const AdminEquipmentDetailScreenPlaceholder({super.key, required this.equipmentId});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Equipo $equipmentId')),
    body: const Center(child: Text('Detalle de equipo')),
  );
}

// Placeholder screens - Technician
class TechnicianLayoutPlaceholder extends StatelessWidget {
  const TechnicianLayoutPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: const Center(child: Text('Technician Layout')),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: 0,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    ),
  );
}

class TechnicianJobsScreenPlaceholder extends StatelessWidget {
  const TechnicianJobsScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mis Trabajos')),
    body: const Center(child: Text('Lista de trabajos')),
  );
}

class TechnicianJobDetailScreenPlaceholder extends StatelessWidget {
  final String jobId;
  const TechnicianJobDetailScreenPlaceholder({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Trabajo $jobId')),
    body: const Center(child: Text('Detalle del trabajo')),
  );
}

class TechnicianQuoteDetailScreenPlaceholder extends StatelessWidget {
  final String quoteId;
  const TechnicianQuoteDetailScreenPlaceholder({super.key, required this.quoteId});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Cotización $quoteId')),
    body: const Center(child: Text('Detalle de cotización')),
  );
}

class TechnicianProfileScreenPlaceholder extends StatelessWidget {
  const TechnicianProfileScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Perfil')),
    body: const Center(child: Text('Perfil del técnico')),
  );
}

// Placeholder screens - Client
class ClientLayoutPlaceholder extends StatelessWidget {
  const ClientLayoutPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: const Center(child: Text('Client Layout')),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: 0,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.hvac), label: 'Equipos'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Servicios'),
      ],
    ),
  );
}

class ClientHomeScreenPlaceholder extends StatelessWidget {
  const ClientHomeScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mi Casa')),
    body: const Center(child: Text('Pantalla de inicio del cliente')),
  );
}

class ClientEquipmentScreenPlaceholder extends StatelessWidget {
  const ClientEquipmentScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mis Equipos')),
    body: const Center(child: Text('Equipos del cliente')),
  );
}

class ClientEquipmentNewScreenPlaceholder extends StatelessWidget {
  const ClientEquipmentNewScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nuevo Equipo')),
    body: const Center(child: Text('Agregar equipo')),
  );
}

class ClientNewRequestScreenPlaceholder extends StatelessWidget {
  const ClientNewRequestScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nueva Solicitud')),
    body: const Center(child: Text('Nueva solicitud de servicio')),
  );
}

class ClientServiceDetailScreenPlaceholder extends StatelessWidget {
  final String serviceId;
  const ClientServiceDetailScreenPlaceholder({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Servicio $serviceId')),
    body: const Center(child: Text('Detalle del servicio')),
  );
}

class ClientQuoteDetailScreenPlaceholder extends StatelessWidget {
  final String quoteId;
  const ClientQuoteDetailScreenPlaceholder({super.key, required this.quoteId});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Cotización $quoteId')),
    body: const Center(child: Text('Detalle de cotización')),
  );
}