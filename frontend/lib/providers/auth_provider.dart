import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/app_config.dart';

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

  /// Signs in (or signs up) with Google for the given [role]. The role is only
  /// used by the backend when creating a brand-new account; existing users keep
  /// their stored role. Returns whether it succeeded plus a message to surface.
  Future<({bool success, String message})> loginWithGoogle({
    required String role,
  }) async {
    if (AppConfig.googleServerClientId.isEmpty) {
      return (
        success: false,
        message: 'Google sign-in isn\'t configured yet.',
      );
    }
    if (kIsWeb) {
      return (
        success: false,
        message: 'Use Google sign-in from the mobile app.',
      );
    }

    _isLoading = true;
    notifyListeners();

    try {
      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: AppConfig.googleServerClientId,
      );
      // Start from a clean slate so the account chooser always shows.
      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      if (account == null) {
        _isLoading = false;
        notifyListeners();
        return (success: false, message: 'Sign-in cancelled.');
      }

      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        _isLoading = false;
        notifyListeners();
        return (success: false, message: 'Could not get a Google token.');
      }

      final response = await _apiService.post('/auth/google', {
        'id_token': idToken,
        'role': role,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _user = User.fromJson(data['user']);
        await _storage.write(key: 'jwt_token', value: _token);
        _isLoading = false;
        notifyListeners();
        return (success: true, message: 'Signed in with Google.');
      }

      String message = 'Google sign-in failed.';
      try {
        message = (jsonDecode(response.body)['error'] ?? message).toString();
      } catch (_) {/* keep default */}
      _isLoading = false;
      notifyListeners();
      return (success: false, message: message);
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      _isLoading = false;
      notifyListeners();
      return (success: false, message: 'Google sign-in failed.');
    }
  }

  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/login', {
        'email': identifier,
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

  Future<Map<String, dynamic>> sendOtp({
    required String identifier,
    required String method,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/send-otp', {
        'identifier': identifier.trim(),
        'method': method,
      });

      final data = jsonDecode(response.body);
      _isLoading = false;
      notifyListeners();

      return {
        'success': response.statusCode < 400,
        'message': data['message'] ?? 'OTP sent.',
        if (data['dev_otp'] != null) 'dev_otp': data['dev_otp'].toString(),
      };
    } catch (e) {
      debugPrint('Send OTP error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return {'success': false, 'message': 'Failed to send OTP.'};
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String identifier,
    required String otp,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/verify-otp', {
        'identifier': identifier.trim(),
        'otp': otp,
      });

      final data = jsonDecode(response.body);
      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP verified.',
          'reset_token': data['reset_token'] ?? '',
        };
      }
      return {'success': false, 'message': data['error'] ?? 'OTP verification failed.'};
    } catch (e) {
      debugPrint('Verify OTP error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return {'success': false, 'message': 'Failed to verify OTP.'};
  }

  Future<Map<String, dynamic>> resetPasswordWithOtp({
    required String identifier,
    required String otp,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/reset-password-with-otp', {
        'identifier': identifier.trim(),
        'otp': otp,
        'password': password,
      });

      final data = jsonDecode(response.body);
      _isLoading = false;
      notifyListeners();

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Password reset.',
      };
    } catch (e) {
      debugPrint('Reset password with OTP error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return {'success': false, 'message': 'Failed to reset password.'};
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final body = <String, dynamic>{};
      if (firstName != null) body['first_name'] = firstName.trim();
      if (lastName != null) body['last_name'] = lastName.trim();
      if (email != null) body['email'] = email.trim();
      if (phone != null) body['phone'] = phone.trim();

      final response = await _apiService.put('/auth/profile', body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
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
