// lib/models/landmark.dart

class Landmark {
  final String? id;
  final String title;
  final double latitude;
  final double longitude;
  final String? imageUrl; // e.g., a URL string returned by server
  final String?
      imageBase64; // base64 encoded image to send to server (optional)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Landmark({
    this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.imageBase64,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor for creating Landmark from JSON
  factory Landmark.fromJson(Map<String, dynamic> json) {
    // Handle image field - could be URL or base64
    String? imageUrl;
    String? imageBase64;

    final imageField = json['image_url'] ?? json['imageUrl'] ?? json['image'];
    if (imageField != null && imageField is String && imageField.isNotEmpty) {
      // If it starts with http, it's a URL
      if (imageField.startsWith('http://') ||
          imageField.startsWith('https://')) {
        imageUrl = imageField;
      }
      // If it looks like a relative path (contains / or .), treat as URL path
      else if (imageField.contains('/') || imageField.contains('.')) {
        imageUrl = imageField;
      }
      // Otherwise, treat as base64 - store in both for compatibility
      else {
        imageBase64 = imageField;
        // Also try as URL in case it's a filename
        imageUrl = imageField;
      }
    }

    return Landmark(
      id: json['id']?.toString(),
      title: (json['title'] ?? '') as String,
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ??
          (json['lat'] != null
              ? double.tryParse(json['lat'].toString()) ?? 0.0
              : 0.0),
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ??
          (json['lon'] != null
              ? double.tryParse(json['lon'].toString()) ?? 0.0
              : 0.0),
      imageUrl: imageUrl,
      imageBase64: imageBase64,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  // Convert Landmark to JSON for API requests
  // Note: API service converts this to form-urlencoded with lat/lon field names
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'title': title,
      'latitude': latitude,
      'longitude': longitude,
    };

    if (id != null) data['id'] = id;
    // Prefer sending imageBase64 if present (server accepts a base64 'image' field)
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      data['image'] = imageBase64;
    }
    // Do not send imageUrl when creating/updating; server usually returns it.
    return data;
  }

  // Create a copy with updated values
  Landmark copyWith({
    String? id,
    String? title,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? imageBase64,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Landmark(
      id: id ?? this.id,
      title: title ?? this.title,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBase64: imageBase64 ?? this.imageBase64,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get formatted location string
  String get locationString {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  // Check if landmark has an image
  bool get hasImage {
    return (imageUrl != null && imageUrl!.isNotEmpty) ||
        (imageBase64 != null && imageBase64!.isNotEmpty);
  }

  @override
  String toString() {
    return 'Landmark(id: $id, title: $title, lat: $latitude, lng: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Landmark &&
        other.id == id &&
        other.title == title &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode =>
      (id?.hashCode ?? 0) ^
      title.hashCode ^
      latitude.hashCode ^
      longitude.hashCode;
}
