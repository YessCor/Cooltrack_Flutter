import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/offline_repository.dart';
import 'services/photo_upload_service.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Cargar variables de entorno
  await dotenv.load(fileName: ".env.local");

  // 2. Inicializar Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabasePublishableKey,
  );

  // 3. Inicializar Hive y Offline Repository
  await OfflineRepository().init();
  
  // 4. Configurar Cloudinary
  PhotoUploadService().configure(
    cloudName: cloudinaryCloudName,
    uploadPreset: cloudinaryUploadPreset,
  );
  
  runApp(
    const ProviderScope(
      child: CoolTrackApp(),
    ),
  );
}

class CoolTrackApp extends ConsumerWidget {
  const CoolTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'CoolTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
