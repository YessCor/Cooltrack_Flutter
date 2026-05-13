import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../core/constants.dart';
import '../core/api_client.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  bool get isAuthenticated => user != null;
  UserRole? get role => user?.role;
  bool get isAdmin => user?.isAdmin ?? false;
  bool get isTechnician => user?.isTechnician ?? false;
  bool get isClient => user?.isClient ?? false;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    await _loadStoredAuth();
    state = state.copyWith(isInitialized: true);
  }

  Future<void> _loadStoredAuth() async {
    try {
      final token = await _storage.read(key: tokenKey);
      final userJson = await _storage.read(key: userKey);

      if (token != null && userJson != null) {
        _api.setAuthToken(token);
        final user = User.fromJson(jsonDecode(userJson));
        state = state.copyWith(user: user);
      }
    } catch (e) {
      await _clearStorage();
    }
  }

  Future<void> _clearStorage() async {
    await _storage.delete(key: tokenKey);
    await _storage.delete(key: userKey);
    _api.setAuthToken(null);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _api.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final token = response['token'] as String?;
      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Token no recibido',
        );
        return false;
      }

      final userData = response['user'];
      final user = User.fromJson(userData);

      await _storage.write(key: tokenKey, value: token);
      await _storage.write(key: userKey, value: jsonEncode(userData));
      _api.setAuthToken(token);

      state = state.copyWith(
        user: user,
        isLoading: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error de conexión',
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      await _api.post('/auth/logout');
    } catch (_) {}

    await _clearStorage();
    state = const AuthState(isInitialized: true);
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _api.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
        'phone': phone,
      });

      final token = response['token'] as String?;
      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Token no recibido',
        );
        return false;
      }

      final userData = response['user'];
      final user = User.fromJson(userData);

      await _storage.write(key: tokenKey, value: token);
      await _storage.write(key: userKey, value: jsonEncode(userData));
      _api.setAuthToken(token);

      state = state.copyWith(
        user: user,
        isLoading: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error de conexión',
      );
      return false;
    }
  }

  Future<bool> refreshUser() async {
    try {
      final response = await _api.get('/users/me');
      final userData = response['data'] as Map<String, dynamic>;
      final user = User.fromJson(userData);

      await _storage.write(key: userKey, value: jsonEncode(userData));
      state = state.copyWith(user: user);
      return true;
    } catch (e) {
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}