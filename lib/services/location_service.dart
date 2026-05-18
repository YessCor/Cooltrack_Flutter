import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  final _supabase = Supabase.instance.client;

  Future<bool> handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  void startTrackingTechnician() async {
    final hasPermission = await handlePermission();
    if (!hasPermission) return;

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50, // Actualizar cada 50 metros
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) async {
        final userId = _supabase.auth.currentUser?.id;
        if (userId == null) return;

        try {
          await _supabase.from('technician_locations').insert({
            'technician_id': userId,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'accuracy': position.accuracy,
            'heading': position.heading,
            'speed': position.speed,
            'recorded_at': DateTime.now().toIso8601String(),
          });
          
          if (kDebugMode) print('Location updated: ${position.latitude}, ${position.longitude}');
        } catch (e) {
          if (kDebugMode) print('Error updating location: $e');
        }
      },
    );
  }

  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }
}
