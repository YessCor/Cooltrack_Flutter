import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../core/constants.dart';
import '../core/api_client.dart'; // Will create next

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final User? user;
  final UserRole? role;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.role,
    this.isLoading
