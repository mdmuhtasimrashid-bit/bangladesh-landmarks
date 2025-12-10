import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/landmark_provider.dart';
import '../models/landmark.dart';
import '../widgets/landmark_card.dart';
import 'landmark_detail_screen.dart';
import 'new_entry_screen.dart';

class RecordsListScreen extends StatefulWidget {
  @override
  _RecordsListScreenState createState() => _RecordsListScreenState();
}

class _RecordsListScreenState extends State<RecordsListScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search landmarks...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Landmarks list
          Expanded(
            child: Consumer<LandmarkProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.landmarks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading landmarks...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Show error message if there's an error
                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Error Loading Data',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.red[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            provider.error ?? 'Unknown error occurred',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            provider.refresh();
                          },
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                List<Landmark> landmarks = _searchQuery.isEmpty
                    ? provider.landmarks
                    : provider.searchLandmarks(_searchQuery);

                if (landmarks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No landmarks found'
                              : 'No landmarks match your search',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Add your first landmark using the New Entry tab'
                              : 'Try a different search term',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to New Entry tab - We'll handle this differently since we don't use TabController
                              Navigator.pop(context);
                            },
                            child: Text('Add Landmark'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: provider.refresh,
                  child: ListView.builder(
                    itemCount: landmarks.length,
                    padding: EdgeInsets.only(bottom: 80),
                    itemBuilder: (context, index) {
                      Landmark landmark = landmarks[index];

                      return Dismissible(
                        key: Key(landmark.id ?? landmark.title),
                        background: Container(
                          color: Colors.blue,
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(left: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit, color: Colors.white),
                              Text(
                                'Edit',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete, color: Colors.white),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        onDismissed: (direction) {
                          if (direction == DismissDirection.startToEnd) {
                            // Edit
                            _editLandmark(landmark);
                          } else if (direction == DismissDirection.endToStart) {
                            // Delete
                            _deleteLandmark(landmark, provider);
                          }
                        },
                        child: LandmarkCard(
                          landmark: landmark,
                          onTap: () => _showLandmarkDetails(landmark),
                          onEdit: () => _editLandmark(landmark),
                          onDelete: () => _deleteLandmark(landmark, provider),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewEntryScreen(),
            ),
          );
          // The provider automatically refreshes after adding
        },
        child: Icon(Icons.add),
        tooltip: 'Add New Landmark',
      ),
    );
  }

  void _showLandmarkDetails(Landmark landmark) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LandmarkDetailScreen(landmark: landmark),
      ),
    );
  }

  void _editLandmark(Landmark landmark) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewEntryScreen(landmark: landmark),
      ),
    );
    // Refresh the list after returning from edit screen
  }

  void _deleteLandmark(Landmark landmark, LandmarkProvider provider) {
    // Check if widget is still mounted before proceeding
    if (!mounted) return;

    // Get ScaffoldMessenger before showing dialog to avoid widget disposal issues
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete Landmark'),
        content: Text(
          'Are you sure you want to delete "${landmark.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              if (landmark.id != null) {
                bool success = await provider.deleteLandmark(landmark.id!);

                // Use the scaffoldMessenger reference we got earlier
                if (success) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Landmark deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
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
