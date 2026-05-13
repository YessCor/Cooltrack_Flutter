import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';

class AdminLayout extends StatelessWidget {
  const AdminLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const _AdminBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: AppColors.textMuted,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Clientes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.engineering_outlined),
            activeIcon: Icon(Icons.engineering),
            label: 'Técnicos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Órdenes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Cotizaciones',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/admin/clients')) return 1;
    if (location.startsWith('/admin/technicians')) return 2;
    if (location.startsWith('/admin/orders')) return 3;
    if (location.startsWith('/admin/quotes')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/admin');
        break;
      case 1:
        context.go('/admin/clients');
        break;
      case 2:
        context.go('/admin/technicians');
        break;
      case 3:
        context.go('/admin/orders');
        break;
      case 4:
        context.go('/admin/quotes');
        break;
    }
  }
}

class _AdminBody extends StatelessWidget {
  const _AdminBody();

  @override
  Widget build(BuildContext context) {
    return const AutoRouter();
  }
}