import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/location_service.dart';

enum LocationStatus { unknown, enabled, disabled, denied }

class LocationState {
  final LocationData? currentLocation;
  final LocationStatus status;
  final bool isTracking;
  final String? error;

  const LocationState({
    this.currentLocation,
    this.status = LocationStatus.unknown,
    this.isTracking = false,
    this.error,
  });

  LocationState copyWith({
    LocationData? currentLocation,
    LocationStatus? status,
    bool? isTracking,
    String? error,
  }) {
    return LocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      status: status ?? this.status,
      isTracking: isTracking ?? this.isTracking,
      error: error,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService = LocationService();
  StreamSubscription? _subscription;

  LocationNotifier() : super(const LocationState());

  Future<void> init() async {
    final hasPermission = await _locationService.checkPermission();
    if (hasPermission) {
      state = state.copyWith(status: LocationStatus.enabled);
      await getCurrentLocation();
    } else {
      state = state.copyWith(status: LocationStatus.denied);
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        final locationData = LocationData.fromPosition(position);
        state = state.copyWith(
          currentLocation: locationData,
          status: LocationStatus.enabled,
          error: null,
        );
      } else {
        state = state.copyWith(error: 'No se pudo obtener la ubicación');
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> startTracking() async {
    final hasPermission = await _locationService.checkPermission();
    if (!hasPermission) {
      state = state.copyWith(status: LocationStatus.denied);
      return;
    }

    await _locationService.startTracking();
    _subscription = _locationService.positionStream.listen((position) {
      final locationData = LocationData.fromPosition(position);
      state = state.copyWith(currentLocation: locationData);
    });

    state = state.copyWith(isTracking: true, status: LocationStatus.enabled);
  }

  void stopTracking() {
    _locationService.stopTracking();
    _subscription?.cancel();
    _subscription = null;
    state = state.copyWith(isTracking: false);
  }

  Future<bool> isWithinRadius(double lat, double lon, double radiusMeters) async {
    final current = state.currentLocation;
    if (current == null) return false;
    
    return await _locationService.isWithinRadius(
      current.latitude,
      current.longitude,
      lat,
      lon,
      radiusMeters,
    );
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});