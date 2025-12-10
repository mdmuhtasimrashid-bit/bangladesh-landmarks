// lib/services/image_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Image helper: process, resize (preserve aspect ratio), encode to base64, validate.
class ImageService {
  /// Resize and encode image bytes to base64 (for web platform).
  static Future<String> processAndEncodeImageBytes(Uint8List bytes,
      {int targetWidth = 800, int jpegQuality = 85}) async {
    try {
      final img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Preserve aspect ratio: resize by width only
      final img.Image resized = img.copyResize(
        image,
        width: targetWidth,
      );

      final Uint8List encoded =
          Uint8List.fromList(img.encodeJpg(resized, quality: jpegQuality));

      return base64Encode(encoded);
    } catch (e) {
      throw Exception('Failed to process image: $e');
    }
  }

  /// Resize and encode image to base64.
  /// This preserves aspect ratio by specifying only width (or only height).
  /// Default target width is 800 px.
  static Future<String> processAndEncodeImage(File imageFile,
      {int targetWidth = 800, int jpegQuality = 85}) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      return processAndEncodeImageBytes(bytes,
          targetWidth: targetWidth, jpegQuality: jpegQuality);
    } catch (e) {
      throw Exception('Failed to process image: $e');
    }
  }

  // Validate image file extension
  static bool isValidImageFile(File file) {
    try {
      final ext = file.path.toLowerCase().split('.').last;
      final supported = ['jpg', 'jpeg', 'png', 'bmp', 'gif', 'webp'];
      return supported.contains(ext);
    } catch (e) {
      return false;
    }
  }

  // Get image dimensions (width/height)
  static Future<Map<String, int>?> getImageDimensions(File imageFile) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;
      return {'width': image.width, 'height': image.height};
    } catch (_) {
      return null;
    }
  }

  // Decode base64 string to bytes for display
  static Uint8List? decodeBase64Image(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  // Compute file size in KB
  static double getFileSizeInKB(File file) {
    try {
      final int bytes = file.lengthSync();
      return bytes / 1024;
    } catch (e) {
      return 0.0;
    }
  }

  // Generate a square thumbnail from base64 image (returns base64)
  static String generateThumbnail(String base64Image, {int size = 150}) {
    try {
      final Uint8List bytes = base64Decode(base64Image);
      final img.Image? image = img.decodeImage(bytes);
      if (image == null) return base64Image;

      final int minDim =
          image.width < image.height ? image.width : image.height;
      final img.Image cropped = img.copyCrop(
        image,
        x: (image.width - minDim) ~/ 2,
        y: (image.height - minDim) ~/ 2,
        width: minDim,
        height: minDim,
      );

      final img.Image thumb =
          img.copyResize(cropped, width: size, height: size);
      final Uint8List out =
          Uint8List.fromList(img.encodeJpg(thumb, quality: 70));
      return base64Encode(out);
    } catch (e) {
      return base64Image;
    }
  }
}
