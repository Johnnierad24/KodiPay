import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _token!);
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _token!);
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
    String? emergencyContactName,
    String? emergencyContactRelation,
    String? emergencyContactPhone,
    String? businessName,
    String? businessRegistration,
    String? businessKraPin,
    String? businessContactPerson,
    String? businessAddress,
    String? businessCity,
    String? businessCounty,
    String? businessPostalCode,
    String? businessPhone,
    String? businessEmail,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final body = <String, dynamic>{};
      if (firstName != null) body['first_name'] = firstName.trim();
      if (lastName != null) body['last_name'] = lastName.trim();
      if (email != null) body['email'] = email.trim();
      if (phone != null) body['phone'] = phone.trim();
      if (emergencyContactName != null) body['emergency_contact_name'] = emergencyContactName.trim();
      if (emergencyContactRelation != null) body['emergency_contact_relation'] = emergencyContactRelation.trim();
      if (emergencyContactPhone != null) body['emergency_contact_phone'] = emergencyContactPhone.trim();
      if (businessName != null) body['business_name'] = businessName.trim();
      if (businessRegistration != null) body['business_registration'] = businessRegistration.trim();
      if (businessKraPin != null) body['business_kra_pin'] = businessKraPin.trim();
      if (businessContactPerson != null) body['business_contact_person'] = businessContactPerson.trim();
      if (businessAddress != null) body['business_address'] = businessAddress.trim();
      if (businessCity != null) body['business_city'] = businessCity.trim();
      if (businessCounty != null) body['business_county'] = businessCounty.trim();
      if (businessPostalCode != null) body['business_postal_code'] = businessPostalCode.trim();
      if (businessPhone != null) body['business_phone'] = businessPhone.trim();
      if (businessEmail != null) body['business_email'] = businessEmail.trim();

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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
    } catch (e) {
      debugPrint('Token cleanup error: $e');
    }
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      final response = await _apiService.get('/auth/me');
      if (response.statusCode == 200) {
        _user = User.fromJson(jsonDecode(response.body));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Refresh profile error: $e');
    }
  }

  Future<void> tryAutoLogin() async {
    if (isAuthenticated) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('jwt_token');
      if (storedToken == null || isAuthenticated) {
        notifyListeners();
        return;
      }
      _token = storedToken;
      final response = await _apiService.get('/auth/me');
      if (_token != storedToken) {
        notifyListeners();
        return;
      }
      if (response.statusCode == 200) {
        _user = User.fromJson(jsonDecode(response.body));
      } else {
        await logout();
      }
    } catch (e) {
      _user = null;
      _token = null;
      debugPrint('Auto-login error: $e');
    }
    notifyListeners();
  }
}
