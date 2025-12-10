// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/landmark.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiService {
  // API URL - needs CORS proxy for web browsers
  static const String directApiUrl = 'https://labs.anontech.info/cse489/t3/api.php';
  
  // Get base URL with CORS proxy for browser requests
  static String getUrlForMethod(String method) {
    // For web browsers, we need to use CORS proxy
    // The proxy URL format must include the full target URL with query params
    return 'https://corsproxy.io/?${Uri.encodeComponent(directApiUrl)}';
  }
  
  static String get baseUrl => getUrlForMethod('GET');

  static const Duration timeoutDuration = Duration(seconds: 30);

  // Headers for API requests - API expects form-urlencoded, not JSON
  static const Map<String, String> _formHeaders = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Accept': 'application/json',
  };
  
  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Helper to parse responses that sometimes wrap data in { success, data }
  static Landmark _parseSingleLandmark(dynamic jsonData) {
    if (jsonData is Map<String, dynamic>) {
      if (jsonData.containsKey('data')) {
        return Landmark.fromJson(jsonData['data'] as Map<String, dynamic>);
      } else {
        return Landmark.fromJson(jsonData);
      }
    }
    throw ApiException('Invalid API response format');
  }

  // GET: Retrieve all landmarks
  static Future<List<Landmark>> getAllLandmarks() async {
    try {
      // Try direct API first, fallback to CORS proxy on web if needed
      String url = baseUrl;
      final response = await http
          .get(Uri.parse(url), headers: _jsonHeaders)
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);

        if (jsonData is List) {
          return jsonData
              .map<Landmark>((item) => Landmark.fromJson(item))
              .toList();
        } else if (jsonData is Map && jsonData.containsKey('data')) {
          final List<dynamic> list = jsonData['data'];
          return list.map((item) => Landmark.fromJson(item)).toList();
        } else {
          throw ApiException('Unexpected response format from server');
        }
      } else {
        throw ApiException(
          'Failed to load landmarks: ${response.reasonPhrase}',
          response.statusCode,
        );
      }
    } on FormatException {
      throw ApiException('Invalid response format');
    } catch (e) {
      if (e is ApiException) rethrow;
      // Handle network errors (including CORS)
      if (e.toString().contains('Failed to fetch') ||
          e.toString().contains('XMLHttpRequest') ||
          e.toString().contains('CORS')) {
        throw ApiException(
            'Network error: Unable to reach server. Please check CORS settings.');
      }
      throw ApiException('Unexpected error: $e');
    }
  }

  // POST: Create a new landmark
  // Uses form-urlencoded. API expects lat/lon, not latitude/longitude.
  static Future<Landmark> createLandmark(Landmark landmark) async {
    try {
      // Convert to form data with correct field names (lat/lon)
      final Map<String, String> formData = {
        'title': landmark.title,
        'lat': landmark.latitude.toString(),
        'lon': landmark.longitude.toString(),
      };
      
      // Add image if present
      if (landmark.imageBase64 != null && landmark.imageBase64!.isNotEmpty) {
        formData['image'] = landmark.imageBase64!;
      }

      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: _formHeaders,
            body: formData,
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic jsonData = json.decode(response.body);

        // If API returns just an ID like {"id":"414"}, create landmark with original data + new ID
        if (jsonData is Map<String, dynamic> &&
            jsonData.containsKey('id') &&
            jsonData.length <= 2) {
          // Preserve the original imageBase64 since the API doesn't return it
          return landmark.copyWith(
            id: jsonData['id'].toString(),
            imageBase64: landmark.imageBase64, // Keep the original base64
          );
        }

        // If API returns full landmark data, parse it but preserve imageBase64 if missing in response
        final parsedLandmark = _parseSingleLandmark(jsonData);
        if (parsedLandmark.imageBase64 == null &&
            landmark.imageBase64 != null) {
          return parsedLandmark.copyWith(imageBase64: landmark.imageBase64);
        }
        return parsedLandmark;
      } else {
        // Try to parse error message
        try {
          final err = json.decode(response.body);
          final msg = err['message'] ?? err['error'] ?? 'Failed to create';
          throw ApiException(msg.toString(), response.statusCode);
        } catch (_) {
          throw ApiException('Failed to create landmark', response.statusCode);
        }
      }
    } on FormatException {
      throw ApiException('Invalid response format');
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e.toString().contains('Failed to fetch') ||
          e.toString().contains('XMLHttpRequest') ||
          e.toString().contains('CORS')) {
        throw ApiException(
            'Network error: Unable to reach server. Please check CORS settings.');
      }
      throw ApiException('Unexpected error: $e');
    }
  }

  // PUT: Update an existing landmark
  // Uses PUT method with id in body. API expects form-urlencoded with lat/lon fields.
  static Future<Landmark> updateLandmark(String id, Landmark landmark) async {
    try {
      // Convert to form data with correct field names (lat/lon) and include id
      final Map<String, String> formData = {
        'id': id,
        'title': landmark.title,
        'lat': landmark.latitude.toString(),
        'lon': landmark.longitude.toString(),
      };
      
      // Add image if present
      if (landmark.imageBase64 != null && landmark.imageBase64!.isNotEmpty) {
        formData['image'] = landmark.imageBase64!;
      }

      final response = await http
          .put(
            Uri.parse(baseUrl),
            headers: _formHeaders,
            body: formData,
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic jsonData = json.decode(response.body);

        // API returns {"status":"success","message":"Entity updated"}
        if (jsonData is Map<String, dynamic>) {
          if (jsonData.containsKey('status') && jsonData['status'] == 'success') {
            // Return the landmark with updated data and original id
            return landmark.copyWith(id: id);
          }
          if (jsonData.containsKey('success') ||
              (jsonData.containsKey('id') && jsonData['id'].toString() == id)) {
            // Return the landmark with updated data
            return landmark.copyWith(id: id);
          }
        }

        return _parseSingleLandmark(jsonData);
      } else {
        try {
          final err = json.decode(response.body);
          final msg = err['message'] ?? err['error'] ?? 'Failed to update';
          throw ApiException(msg.toString(), response.statusCode);
        } catch (_) {
          throw ApiException('Failed to update landmark', response.statusCode);
        }
      }
    } on FormatException {
      throw ApiException('Invalid response format');
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e.toString().contains('Failed to fetch') ||
          e.toString().contains('XMLHttpRequest') ||
          e.toString().contains('CORS')) {
        throw ApiException(
            'Network error: Unable to reach server. Please check CORS settings.');
      }
      throw ApiException('Unexpected error: $e');
    }
  }

  // DELETE: Remove a landmark
  static Future<bool> deleteLandmark(String id) async {
    try {
      // For web, use CORS proxy with the full URL including query parameter
      final apiUrlWithId = 'https://labs.anontech.info/cse489/t3/api.php?id=$id';
      final corsUrl = 'https://corsproxy.io/?${Uri.encodeComponent(apiUrlWithId)}';
      final uri = Uri.parse(corsUrl);

      final response = await http
          .delete(uri)
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);
        if (jsonData is Map && jsonData.containsKey('success')) {
          return jsonData['success'] == true;
        }
        // If server returns nothing structured, assume success for 200
        return true;
      } else {
        try {
          final err = json.decode(response.body);
          final msg = err['message'] ?? err['error'] ?? 'Failed to delete';
          throw ApiException(msg.toString(), response.statusCode);
        } catch (_) {
          throw ApiException('Failed to delete landmark', response.statusCode);
        }
      }
    } on FormatException {
      throw ApiException('Invalid response format');
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e.toString().contains('Failed to fetch') ||
          e.toString().contains('XMLHttpRequest') ||
          e.toString().contains('CORS')) {
        throw ApiException(
            'Network error: Unable to reach server. Please check CORS settings.');
      }
      throw ApiException('Unexpected error: $e');
    }
  }

  // Helper method to check API connectivity quickly
  static Future<bool> checkConnectivity() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl), headers: _jsonHeaders)
          .timeout(Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
