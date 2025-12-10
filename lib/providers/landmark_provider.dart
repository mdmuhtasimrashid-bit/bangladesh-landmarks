// lib/providers/landmark_provider.dart

import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../models/landmark.dart';
import '../services/api_service.dart';

class LandmarkProvider with ChangeNotifier {
  List<Landmark> _landmarks = [];
  bool _isLoading = false;
  String? _error;
  Landmark? _selectedLandmark;

  // Getters
  List<Landmark> get landmarks => _landmarks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get errorMessage => _error;
  Landmark? get selectedLandmark => _selectedLandmark;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _setError(null);
  }

  // Set selected landmark
  void setSelectedLandmark(Landmark? landmark) {
    _selectedLandmark = landmark;
    notifyListeners();
  }

  // Load all landmarks
  Future<void> loadLandmarks() async {
    _setLoading(true);
    _setError(null);

    try {
      _landmarks = await ApiService.getAllLandmarks();
      _setLoading(false);
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load landmarks: $e');
      _setLoading(false);
    }
  }

  // Add a new landmark
  Future<bool> addLandmark(Landmark landmark) async {
    _setLoading(true);
    _setError(null);

    try {
      await ApiService.createLandmark(landmark);

      // Reload all landmarks to ensure sync with server
      await loadLandmarks();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to add landmark: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update an existing landmark
  Future<bool> updateLandmark(String id, Landmark landmark) async {
    _setLoading(true);
    _setError(null);

    try {
      await ApiService.updateLandmark(id, landmark);

      // Reload all landmarks to ensure sync with server
      await loadLandmarks();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to update landmark: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete a landmark
  Future<bool> deleteLandmark(String id) async {
    _setLoading(true);
    _setError(null);

    try {
      final bool success = await ApiService.deleteLandmark(id);
      if (success) {
        _landmarks.removeWhere((l) => l.id == id);
        if (_selectedLandmark?.id == id) {
          _selectedLandmark = null;
        }
      }
      _setLoading(false);
      return success;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to delete landmark: $e');
      _setLoading(false);
      return false;
    }
  }

  // Search landmarks by title (case-insensitive & trimmed)
  List<Landmark> searchLandmarks(String query) {
    final q = query.trim();
    if (q.isEmpty) return _landmarks;
    return _landmarks
        .where((landmark) =>
            landmark.title.toLowerCase().contains(q.toLowerCase()))
        .toList();
  }

  // Get landmarks within a radius (in meters)
  List<Landmark> getLandmarksNearby(
    double latitude,
    double longitude,
    double radiusInMeters,
  ) {
    return _landmarks.where((landmark) {
      final double distance = _calculateDistance(
        latitude,
        longitude,
        landmark.latitude,
        landmark.longitude,
      );
      return distance <= radiusInMeters;
    }).toList();
  }

  // Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth radius in meters

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180);

  // Refresh landmarks
  Future<void> refresh() async {
    await loadLandmarks();
  }

  // Get landmark by ID
  Landmark? getLandmarkById(String id) {
    try {
      return _landmarks.firstWhere((landmark) => landmark.id == id);
    } catch (e) {
      return null;
    }
  }
}
