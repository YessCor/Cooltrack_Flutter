import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../providers/admin_provider.dart';

class AdminTechTrackingScreen extends ConsumerStatefulWidget {
  const AdminTechTrackingScreen({super.key});

  @override
  ConsumerState<AdminTechTrackingScreen> createState() => _AdminTechTrackingScreenState();
}

class _AdminTechTrackingScreenState extends ConsumerState<AdminTechTrackingScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  final Map<MarkerId, Marker> _markers = {};
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _startListeningLocations();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _startListeningLocations() {
    // Escuchar cambios en tiempo real en la tabla technician_locations de Supabase
    _subscription = Supabase.instance.client
        .from('technician_locations')
        .stream(primaryKey: ['id'])
        .order('recorded_at')
        .listen((List<Map<String, dynamic>> data) {
          _updateMarkers(data);
        });
  }

  void _updateMarkers(List<Map<String, dynamic>> data) {
    // Agrupar por técnico y obtener la última ubicación de cada uno
    final Map<String, Map<String, dynamic>> latestLocations = {};
    for (var loc in data) {
      latestLocations[loc['technician_id']] = loc;
    }

    setState(() {
      _markers.clear();
      latestLocations.forEach((techId, loc) {
        final markerId = MarkerId(techId);
        final marker = Marker(
          markerId: markerId,
          position: LatLng(loc['latitude'], loc['longitude']),
          infoWindow: InfoInformation(title: 'Técnico', snippet: 'Última actualización: ${loc['recorded_at']}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        );
        _markers[markerId] = marker;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rastreo de Técnicos'),
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: const CameraPosition(
          target: LatLng(4.6097, -74.0817), // Bogotá por defecto
          zoom: 12,
        ),
        markers: Set<Marker>.of(_markers.values),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}

// Helper para InfoWindow (corrección de nombre si es necesario)
class InfoInformation extends InfoWindow {
  const InfoInformation({required super.title, required super.snippet});
}
