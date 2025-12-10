import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/landmark.dart';
import '../services/image_service.dart';

class LandmarkCard extends StatelessWidget {
  final Landmark landmark;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const LandmarkCard({
    Key? key,
    required this.landmark,
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImage(),
                ),
              ),

              SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      landmark.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 4),

                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            landmark.locationString,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8),

                    // Action buttons
                    Row(
                      children: [
                        if (onEdit != null)
                          TextButton.icon(
                            onPressed: onEdit,
                            icon: Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.blue,
                            ),
                            label: Text(
                              'Edit',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              minimumSize: Size(0, 32),
                              padding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        SizedBox(width: 8),
                        if (onDelete != null)
                          TextButton.icon(
                            onPressed: onDelete,
                            icon: Icon(
                              Icons.delete,
                              size: 16,
                              color: Colors.red,
                            ),
                            label: Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              minimumSize: Size(0, 32),
                              padding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    // First try base64 image (for newly added images)
    if (landmark.imageBase64 != null && landmark.imageBase64!.isNotEmpty) {
      try {
        final imageBytes =
            ImageService.decodeBase64Image(landmark.imageBase64!);
        if (imageBytes != null && imageBytes.isNotEmpty) {
          return Image.memory(
            imageBytes,
            fit: BoxFit.cover,
            width: 80,
            height: 80,
            errorBuilder: (context, error, stackTrace) {
              // If base64 fails, try imageUrl if available
              if (landmark.imageUrl != null && landmark.imageUrl!.isNotEmpty) {
                return _buildNetworkImage();
              }
              return _buildPlaceholder(Icons.broken_image);
            },
          );
        }
      } catch (e) {
        // Fall through to try imageUrl
      }
    }

    // Then try imageUrl (from API response)
    if (landmark.imageUrl != null && landmark.imageUrl!.isNotEmpty) {
      return _buildNetworkImage();
    }

    // Placeholder image
    return _buildPlaceholder(Icons.landscape);
  }

  Widget _buildPlaceholder(IconData icon) {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        icon,
        size: 32,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildNetworkImage() {
    String imageUrl =
        landmark.imageUrl!.replaceAll(r'\/', '/'); // Fix escaped slashes

    // If it's a relative path, make it absolute
    if (!imageUrl.startsWith('http')) {
      // Remove leading slash if present
      if (imageUrl.startsWith('/')) {
        imageUrl = imageUrl.substring(1);
      }
      imageUrl = 'https://labs.anontech.info/cse489/t3/$imageUrl';
    }

    // Use CORS proxy for web to bypass CORS restrictions
    if (kIsWeb) {
      imageUrl = 'https://corsproxy.io/?${Uri.encodeComponent(imageUrl)}';
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: 80,
      height: 80,
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder(Icons.broken_image);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }
}
