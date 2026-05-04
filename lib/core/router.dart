import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

// Placeholder imports (screens to be created)
import '../features/auth/views/login_screen.dart' as authViews;
import '../features/admin/views/dashboard_screen.dart' as adminViews;
import '../features/technician/views/jobs_screen.dart' as techViews;
import '../features/client/views/equipment_screen.dart' as clientViews;

final _rootNavigatorKey
