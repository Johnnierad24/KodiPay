import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_config.dart';

class ApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;
  final _storage = const FlutterSecureStorage();

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<Map<String, String>> _getHeaders({bool jsonBody = true}) async {
    final token = await getToken();
    return {
      if (jsonBody) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _buildUri(String endpoint, [Map<String, dynamic>? query]) {
    final base = Uri.parse('$baseUrl$endpoint');
    if (query == null || query.isEmpty) return base;
    final filtered = <String, String>{};
    query.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.isEmpty) return;
      filtered[key] = value.toString();
    });
    return base.replace(queryParameters: {...base.queryParameters, ...filtered});
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    return http.post(_buildUri(endpoint), headers: await _getHeaders(), body: jsonEncode(data));
  }

  Future<http.Response> put(String endpoint, [Map<String, dynamic>? data]) async {
    return http.put(_buildUri(endpoint),
        headers: await _getHeaders(), body: jsonEncode(data ?? const {}));
  }

  Future<http.Response> delete(String endpoint) async {
    return http.delete(_buildUri(endpoint), headers: await _getHeaders(jsonBody: false));
  }

  Future<http.Response> get(String endpoint, {Map<String, dynamic>? query}) async {
    return http.get(_buildUri(endpoint, query), headers: await _getHeaders(jsonBody: false));
  }

  Future<http.StreamedResponse> uploadMultipart(
    String endpoint, {
    required List<int> fileBytes,
    required String fileName,
    required String fieldName,
    Map<String, String> fields = const {},
    String? mimeType,
  }) async {
    final request = http.MultipartRequest('POST', _buildUri(endpoint));
    final token = await getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(fields);
    request.files.add(http.MultipartFile.fromBytes(
      fieldName,
      fileBytes,
      filename: fileName,
    ));
    return request.send();
  }
}
