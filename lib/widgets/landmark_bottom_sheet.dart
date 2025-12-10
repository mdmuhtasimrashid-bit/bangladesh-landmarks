import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/landmark.dart';
import '../providers/landmark_provider.dart';
import '../services/image_service.dart';
import '../screens/new_entry_screen.dart';

class LandmarkBottomSheet extends StatelessWidget {
  final Landmark landmark;

  const LandmarkBottomSheet({
    Key? key,
    required this.landmark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                if (landmark.hasImage) ...[
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildImage(),
                    ),
                  ),
                  SizedBox(height: 16),
                ],

                // Title
                Text(
                  landmark.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                SizedBox(height: 12),

                // Location info
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coordinates',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                          Text(
                            landmark.locationString,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _editLandmark(context),
                        icon: Icon(Icons.edit),
                        label: Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _deleteLandmark(context),
                        icon: Icon(Icons.delete),
                        label: Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (landmark.imageBase64 != null) {
      try {
        final imageBytes =
            ImageService.decodeBase64Image(landmark.imageBase64!);
        if (imageBytes != null) {
          return Image.memory(
            imageBytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
          );
        }
      } catch (e) {
        // Fall through to placeholder
      }
    }

    // Placeholder image
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.landscape,
              size: 48,
              color: Colors.grey[600],
            ),
            SizedBox(height: 8),
            Text(
              'No Image',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editLandmark(BuildContext context) {
    Navigator.pop(context); // Close bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewEntryScreen(landmark: landmark),
      ),
    );
  }

  void _deleteLandmark(BuildContext context) {
    Navigator.pop(context); // Close bottom sheet

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
              Navigator.pop(context);

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
}
