import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'dart:typed_data';
import '../providers/landmark_provider.dart';
import '../models/landmark.dart';
import '../services/location_service.dart';
import '../services/image_service.dart';

class NewEntryScreen extends StatefulWidget {
  final Landmark? landmark; // For editing existing landmarks

  NewEntryScreen({this.landmark});

  @override
  _NewEntryScreenState createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  File? _selectedImage;
  Uint8List? _webImageBytes; // For web platform
  String? _imageBase64;
  bool _isLoading = false;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.landmark != null) {
      // Editing existing landmark
      _titleController.text = widget.landmark!.title;
      _latitudeController.text = widget.landmark!.latitude.toString();
      _longitudeController.text = widget.landmark!.longitude.toString();
      _imageBase64 = widget.landmark!.imageBase64;
      // Note: imageUrl will be handled in _buildImageWidget
    } else {
      // Creating new landmark - auto-detect location
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.landmark != null ? 'Edit Landmark' : 'New Landmark'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveLandmark,
            child: Text(
              widget.landmark != null ? 'Update' : 'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Landmark Title *',
                  hintText: 'Enter a descriptive title',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.trim().length < 3) {
                    return 'Title must be at least 3 characters long';
                  }
                  return null;
                },
              ),

              SizedBox(height: 20),

              // Location section
              Text(
                'Location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 8),

              // Latitude field
              TextFormField(
                controller: _latitudeController,
                decoration: InputDecoration(
                  labelText: 'Latitude *',
                  hintText: '23.6850',
                  prefixIcon: Icon(Icons.my_location),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter latitude';
                  }
                  double? lat = double.tryParse(value);
                  if (lat == null) {
                    return 'Please enter a valid latitude';
                  }
                  if (lat < -90 || lat > 90) {
                    return 'Latitude must be between -90 and 90';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Longitude field
              TextFormField(
                controller: _longitudeController,
                decoration: InputDecoration(
                  labelText: 'Longitude *',
                  hintText: '90.3563',
                  prefixIcon: Icon(Icons.location_on),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter longitude';
                  }
                  double? lng = double.tryParse(value);
                  if (lng == null) {
                    return 'Please enter a valid longitude';
                  }
                  if (lng < -180 || lng > 180) {
                    return 'Longitude must be between -180 and 180';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Location buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _isGettingLocation ? null : _getCurrentLocation,
                      icon: _isGettingLocation
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.gps_fixed),
                      label: Text('Get Current Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _setDefaultLocation,
                    icon: Icon(Icons.flag),
                    label: Text('Bangladesh Center'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Image section
              Text(
                'Image',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 8),

              // Image display
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildImageWidget(),
              ),

              SizedBox(height: 16),

              // Image buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: Icon(Icons.camera_alt),
                      label: Text('Take Photo'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: Icon(Icons.photo_library),
                      label: Text('Choose from Gallery'),
                    ),
                  ),
                ],
              ),

              if (_selectedImage != null ||
                  _webImageBytes != null ||
                  _imageBase64 != null) ...[
                SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _removeImage,
                  icon: Icon(Icons.delete),
                  label: Text('Remove Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],

              SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveLandmark,
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(widget.landmark != null
                                ? 'Updating...'
                                : 'Saving...'),
                          ],
                        )
                      : Text(
                          widget.landmark != null
                              ? 'Update Landmark'
                              : 'Save Landmark',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    // Display web image bytes if available
    if (_webImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          _webImageBytes!,
          fit: BoxFit.cover,
        ),
      );
    }
    // Display selected file image (for mobile/desktop)
    if (_selectedImage != null && !kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _selectedImage!,
          fit: BoxFit.cover,
        ),
      );
    } else if (widget.landmark?.imageUrl != null &&
        widget.landmark!.imageUrl!.isNotEmpty) {
      // Display existing image URL from server
      String imageUrl = widget.landmark!.imageUrl!;
      if (!imageUrl.startsWith('http')) {
        imageUrl = 'https://labs.anontech.info/cse489/t3/$imageUrl';
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: Icon(
                Icons.broken_image,
                size: 48,
                color: Colors.grey[600],
              ),
            );
          },
        ),
      );
    } else if (_imageBase64 != null) {
      try {
        final imageBytes = ImageService.decodeBase64Image(_imageBase64!);
        if (imageBytes != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              imageBytes,
              fit: BoxFit.cover,
            ),
          );
        }
      } catch (e) {
        // Fall through to placeholder
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo,
          size: 48,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 8),
        Text(
          'Add an image',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();

      // On web, camera source is not supported, use gallery instead
      final actualSource =
          kIsWeb && source == ImageSource.camera ? ImageSource.gallery : source;

      final XFile? image = await picker.pickImage(
        source: actualSource,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          // For web: read bytes directly from XFile
          final bytes = await image.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            _selectedImage = null;
            _imageBase64 = null;
          });
        } else {
          // For mobile/desktop: use File
          File imageFile = File(image.path);

          // Validate image file
          if (!ImageService.isValidImageFile(imageFile)) {
            _showErrorSnackBar('Please select a valid image file');
            return;
          }

          setState(() {
            _selectedImage = imageFile;
            _webImageBytes = null;
            _imageBase64 = null;
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _webImageBytes = null;
      _imageBase64 = null;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      Position position =
          await LocationService.getCurrentLocationWithFallback();

      setState(() {
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
        _isGettingLocation = false;
      });

      if (position.latitude == LocationService.bangladeshLatitude &&
          position.longitude == LocationService.bangladeshLongitude) {
        _showInfoSnackBar(
            'Location permission denied. Using Bangladesh center as fallback.');
      } else {
        _showSuccessSnackBar('Location detected successfully');
      }
    } catch (e) {
      setState(() {
        _isGettingLocation = false;
      });
      _showErrorSnackBar('Failed to get location: $e');
    }
  }

  void _setDefaultLocation() {
    setState(() {
      _latitudeController.text = LocationService.bangladeshLatitude.toString();
      _longitudeController.text =
          LocationService.bangladeshLongitude.toString();
    });
    _showInfoSnackBar('Set to Bangladesh center coordinates');
  }

  Future<void> _saveLandmark() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? processedImageBase64;

      // Process image if selected
      if (_webImageBytes != null) {
        // Web platform: process bytes directly
        processedImageBase64 =
            await ImageService.processAndEncodeImageBytes(_webImageBytes!);
      } else if (_selectedImage != null) {
        // Mobile/Desktop: process file
        processedImageBase64 =
            await ImageService.processAndEncodeImage(_selectedImage!);
      } else if (_imageBase64 != null) {
        processedImageBase64 = _imageBase64;
      }

      Landmark landmark = Landmark(
        id: widget.landmark?.id,
        title: _titleController.text.trim(),
        latitude: double.parse(_latitudeController.text),
        longitude: double.parse(_longitudeController.text),
        imageBase64: processedImageBase64,
      );

      if (!mounted) return;
      final provider = context.read<LandmarkProvider>();
      bool success;

      if (widget.landmark != null) {
        // Update existing landmark
        success = await provider.updateLandmark(widget.landmark!.id!, landmark);
      } else {
        // Create new landmark
        success = await provider.addLandmark(landmark);
      }

      setState(() {
        _isLoading = false;
      });

      if (success) {
        _showSuccessSnackBar(
          widget.landmark != null
              ? 'Landmark updated successfully'
              : 'Landmark added successfully',
        );

        // If this is a modal (has landmark for editing), pop to go back
        // Otherwise, clear form and stay on page (tab navigation)
        if (widget.landmark != null && Navigator.canPop(context)) {
          await Future.delayed(Duration(milliseconds: 500));
          if (!mounted) return;
          Navigator.pop(context, true);
        } else {
          // Clear form for new entry
          _titleController.clear();
          setState(() {
            _selectedImage = null;
            _webImageBytes = null;
            _imageBase64 = null;
          });
          // Set default location
          _setDefaultLocation();
        }
      } else {
        // Show specific error from provider if available
        final errorMsg = provider.errorMessage ??
            (widget.landmark != null
                ? 'Failed to update landmark'
                : 'Failed to add landmark');
        _showErrorSnackBar(errorMsg);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error processing landmark: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
