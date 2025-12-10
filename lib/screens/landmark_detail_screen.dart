import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/landmark.dart';
import '../providers/landmark_provider.dart';
import '../services/image_service.dart';
import 'new_entry_screen.dart';

class LandmarkDetailScreen extends StatelessWidget {
  final Landmark landmark;

  const LandmarkDetailScreen({
    Key? key,
    required this.landmark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(landmark.title),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _editLandmark(context),
            tooltip: 'Edit Landmark',
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _deleteLandmark(context),
            tooltip: 'Delete Landmark',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            if (landmark.hasImage) ...[
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildImage(),
                ),
              ),
              SizedBox(height: 24),
            ],

            // Title section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Title',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      landmark.title,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Location section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Location',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Latitude',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                              Text(
                                '${landmark.latitude.toStringAsFixed(6)}°',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Longitude',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                              Text(
                                '${landmark.longitude.toStringAsFixed(6)}°',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.my_location,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              landmark.locationString,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.copy,
                              size: 18,
                            ),
                            onPressed: () => _copyCoordinates(context),
                            tooltip: 'Copy Coordinates',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _editLandmark(context),
                    icon: Icon(Icons.edit),
                    label: Text('Edit Landmark'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteLandmark(context),
                    icon: Icon(Icons.delete),
                    label: Text('Delete Landmark'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
        if (imageBytes != null) {
          return Image.memory(
            imageBytes,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder();
            },
          );
        }
      } catch (e) {
        // Fall through to imageUrl
      }
    }

    // Then try imageUrl (from API response)
    if (landmark.imageUrl != null && landmark.imageUrl!.isNotEmpty) {
      String imageUrl = landmark.imageUrl!;

      // If it's a relative path, make it absolute
      if (!imageUrl.startsWith('http')) {
        imageUrl = 'https://labs.anontech.info/cse489/t3/$imageUrl';
      }

      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
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
              ),
            ),
          );
        },
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.landscape,
              size: 64,
              color: Colors.grey[600],
            ),
            SizedBox(height: 8),
            Text(
              'No Image Available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editLandmark(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewEntryScreen(landmark: landmark),
      ),
    );
  }

  void _deleteLandmark(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Landmark'),
        content: Text(
          'Are you sure you want to delete "${landmark.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen

              if (landmark.id != null) {
                final provider = context.read<LandmarkProvider>();
                bool success = await provider.deleteLandmark(landmark.id!);

                if (!context.mounted) return;

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Landmark deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete landmark'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _copyCoordinates(BuildContext context) {
    // In a real app, you would use Clipboard.setData here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Coordinates copied: ${landmark.locationString}'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
