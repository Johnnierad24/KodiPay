import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class PasswordResetRequestResult {
  final bool success;
  final String message;
  final String? resetToken;

  const PasswordResetRequestResult({
    required this.success,
    required this.message,
    this.resetToken,
  });
}

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  User? get user => _user;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/register', {
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'email': email.trim(),
        'password': password,
        'phone': phone?.trim(),
        'role': role,
      });

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _user = User.fromJson(data['user']);
        await _storage.write(key: 'jwt_token', value: _token);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Registration error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _user = User.fromJson(data['user']);
        await _storage.write(key: 'jwt_token', value: _token);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<PasswordResetRequestResult> requestPasswordReset(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/forgot-password', {
        'email': email.trim(),
      });
      final data = jsonDecode(response.body);

      _isLoading = false;
      notifyListeners();

      return PasswordResetRequestResult(
        success: response.statusCode == 200,
        message: data['message'] ?? 'Password reset request processed.',
        resetToken: data['reset_token'],
      );
    } catch (e) {
      debugPrint('Password reset request error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return const PasswordResetRequestResult(
      success: false,
      message: 'Failed to request password reset.',
    );
  }

  Future<bool> resetPassword({
    required String token,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/reset-password', {
        'token': token.trim(),
        'password': password,
      });

      _isLoading = false;
      notifyListeners();
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Password reset error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    try {
      await _storage.delete(key: 'jwt_token');
    } catch (e) {
      debugPrint('Token cleanup error: $e');
    }
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    try {
      _token = await _storage.read(key: 'jwt_token');
      if (_token != null) {
        final response = await _apiService.get('/auth/me');
        if (response.statusCode == 200) {
          _user = User.fromJson(jsonDecode(response.body));
        } else {
          await logout();
        }
      }
    } catch (e) {
      _user = null;
      _token = null;
      debugPrint('Auto-login error: $e');
    }
    notifyListeners();
  }
}
