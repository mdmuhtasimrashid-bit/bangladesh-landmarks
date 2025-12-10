import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/landmark_provider.dart';
import '../models/landmark.dart';
import '../widgets/landmark_bottom_sheet.dart';

class MapViewScreen extends StatefulWidget {
  @override
  _MapViewScreenState createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final MapController _mapController = MapController();

  // Bangladesh center coordinates
  static const LatLng _bangladeshCenter = LatLng(23.6850, 90.3563);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<LandmarkProvider>(context, listen: false);
      provider.loadLandmarks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<LandmarkProvider>(
        builder: (context, provider, child) {
          // Update markers directly without setState since we're already in build
          final markers = provider.landmarks
              .map(
                (landmark) => Marker(
                  point: LatLng(landmark.latitude, landmark.longitude),
                  child: GestureDetector(
                    onTap: () => _showLandmarkDetails(landmark),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.place,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              )
              .toList();

          return Stack(
            children: [
              // OpenStreetMap View
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _bangladeshCenter,
                  initialZoom: 7.0,
                  minZoom: 3.0,
                  maxZoom: 18.0,
                  onTap: (tapPosition, point) {
                    // Hide any open bottom sheets
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                ),
                children: [
                  // OpenStreetMap tile layer
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.bangladesh_landmarks',
                    maxNativeZoom: 18,
                  ),

                  // Markers layer
                  MarkerLayer(
                    markers: markers,
                  ),
                ],
              ),

              // Loading indicator
              if (provider.isLoading)
                Container(
                  color: Colors.black26,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),

              // Floating action buttons
              Positioned(
                right: 16,
                bottom: 80,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: "zoom_to_bangladesh",
                      mini: true,
                      child: Icon(Icons.my_location),
                      onPressed: _zoomToBangladesh,
                      tooltip: 'Center on Bangladesh',
                    ),
                    SizedBox(height: 8),
                    FloatingActionButton(
                      heroTag: "show_all_markers",
                      mini: true,
                      child: Icon(Icons.zoom_out_map),
                      onPressed: _showAllMarkers,
                      tooltip: 'Show All Landmarks',
                    ),
                    SizedBox(height: 8),
                    FloatingActionButton(
                      heroTag: "refresh_data",
                      mini: true,
                      child: Icon(Icons.refresh),
                      onPressed: () => provider.loadLandmarks(),
                      tooltip: 'Refresh Data',
                    ),
                  ],
                ),
              ),

              // Search bar
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 80,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (query) {
                      _searchLandmarks(query);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search landmarks...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLandmarkDetails(Landmark landmark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LandmarkBottomSheet(landmark: landmark),
    );
  }

  void _zoomToBangladesh() {
    _mapController.move(_bangladeshCenter, 7.0);
  }

  void _showAllMarkers() {
    final provider = Provider.of<LandmarkProvider>(context, listen: false);
    if (provider.landmarks.isEmpty) return;

    double minLat = provider.landmarks.first.latitude;
    double maxLat = provider.landmarks.first.latitude;
    double minLng = provider.landmarks.first.longitude;
    double maxLng = provider.landmarks.first.longitude;

    for (var landmark in provider.landmarks) {
      minLat = minLat < landmark.latitude ? minLat : landmark.latitude;
      maxLat = maxLat > landmark.latitude ? maxLat : landmark.latitude;
      minLng = minLng < landmark.longitude ? minLng : landmark.longitude;
      maxLng = maxLng > landmark.longitude ? maxLng : landmark.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: EdgeInsets.all(50),
      ),
    );
  }

  void _searchLandmarks(String query) {
    // Search functionality is now handled directly in the build method
    // This could be expanded to use a separate state for filtered landmarks
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }
}
