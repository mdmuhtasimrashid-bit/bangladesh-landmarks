# Bangladesh Landmarks

A comprehensive Flutter web application for managing and visualizing landmark records in Bangladesh. The app allows users to create, view, update, and delete landmarks with location data and images, all integrated with a REST API backend.



## 🎯 Project Overview
This project demonstrates full-stack development skills including:
- Frontend development with Flutter for web
- REST API integration with proper CORS handling
- State management using Provider pattern
- Geolocation and mapping capabilities
- Image processing and base64 encoding
- CRUD operations with real-time updates

## 🏛️ Features

### Core Functionality
- **Interactive Map View**: Displays landmarks on a Google Maps interface centered on Bangladesh
- **Records Management**: Complete CRUD operations for landmark records
- **GPS Integration**: Automatic location detection for new landmarks
- **Image Handling**: Camera and gallery integration with automatic image processing (800x600)
- **Search & Filter**: Real-time search functionality across all landmarks
- **Offline-Ready**: Caches data for improved performance

### User Interface
- **Bottom Navigation**: Three main tabs - Overview (Map), Records (List), New Entry (Form)
- **Material Design**: Bangladesh-themed color scheme with green and red accents
- **Responsive Layout**: Optimized for various screen sizes
- **Interactive Elements**: Swipe actions, bottom sheets, and contextual menus

## 🗂️ Project Structure

```
lib/
├── main.dart                 # Application entry point
├── models/
│   └── landmark.dart         # Landmark data model
├── services/
│   ├── api_service.dart      # REST API communication
│   ├── location_service.dart # GPS and location utilities
│   └── image_service.dart    # Image processing and encoding
├── providers/
│   └── landmark_provider.dart # State management with Provider
├── screens/
│   ├── main_screen.dart      # Main navigation container
│   ├── map_view_screen.dart  # Interactive map view
│   ├── records_list_screen.dart # Landmark list view
│   ├── new_entry_screen.dart # Add/edit landmark form
│   └── landmark_detail_screen.dart # Detailed landmark view
└── widgets/
    ├── landmark_card.dart    # List item component
    └── landmark_bottom_sheet.dart # Map marker popup
```

## 🛠️ Implementation Details

### API Integration
The application connects to a REST API with the following implementation:

**Base URL**: `https://labs.anontech.info/cse489/t3/api.php`

**CORS Proxy**: For web deployment, requests are routed through `https://corsproxy.io/` to handle Cross-Origin Resource Sharing restrictions in browsers.

**Content Type**: The API requires `application/x-www-form-urlencoded` format (not JSON) for POST/PUT requests.

**Field Names**: The API uses `lat`/`lon` field names (not `latitude`/`longitude`).

### API Endpoints

#### 1. GET - Retrieve All Landmarks
```dart
GET https://labs.anontech.info/cse489/t3/api.php
```
Returns array of landmarks with fields: `id`, `title`, `lat`, `lon`, `image`

#### 2. POST - Create New Landmark
```dart
POST https://labs.anontech.info/cse489/t3/api.php
Content-Type: application/x-www-form-urlencoded

Body: title=MyLandmark&lat=23.8103&lon=90.4125&image=base64string
```
Returns: `{"id": "123"}`

#### 3. PUT - Update Existing Landmark
```dart
PUT https://labs.anontech.info/cse489/t3/api.php
Content-Type: application/x-www-form-urlencoded

Body: id=123&title=Updated&lat=23.8104&lon=90.4126&image=base64string
```
Returns: `{"status":"success","message":"Entity updated"}`

#### 4. DELETE - Remove Landmark
```dart
DELETE https://labs.anontech.info/cse489/t3/api.php?id=123
```
Returns: `{"status":"success","message":"Entity deleted"}`

### Key Implementation Features

#### 1. State Management
- **Provider Pattern**: Used for reactive state management across the app
- **ChangeNotifier**: Landmark provider notifies listeners on data changes
- **Consumer Widgets**: Automatically rebuild UI when data updates

#### 2. Location Services
- **Geolocator Package**: GPS location detection
- **Permission Handling**: Requests location permissions gracefully
- **Fallback**: Defaults to Bangladesh center (23.6850, 90.3563) if permission denied

#### 3. Image Processing
- **Image Picker**: Supports both camera and gallery
- **Base64 Encoding**: Images converted to base64 for API transmission
- **Automatic Resizing**: Images resized to 800x600 for optimal performance
- **Web Compatibility**: Uses `Uint8List` for web platform

#### 4. Error Handling
- **Try-Catch Blocks**: All API calls wrapped with error handling
- **User Feedback**: SnackBars show success/error messages
- **Network Error Detection**: Specific messages for CORS and network issues
- **Validation**: Form validation before submission

#### 5. CORS Solution
- **Direct API calls fail in browsers** due to CORS policy
- **CORS Proxy**: All requests routed through `corsproxy.io`
- **URL Encoding**: Proper encoding of API URLs for proxy
- **Method Support**: GET, POST, PUT, DELETE all supported through proxy

### Technical Challenges & Solutions

#### Challenge 1: API Content-Type
**Problem**: API rejected JSON requests
**Solution**: Changed to `application/x-www-form-urlencoded` format

#### Challenge 2: Field Name Mismatch
**Problem**: API uses `lat`/`lon` but app used `latitude`/`longitude`
**Solution**: Field name mapping in API service layer

#### Challenge 3: UPDATE Creates Duplicates
**Problem**: POST with id in query created new records
**Solution**: Use PUT method with id in body for proper updates

#### Challenge 4: CORS Errors in Browser
**Problem**: Browser blocked direct API calls
**Solution**: Implemented CORS proxy for all web requests

#### Challenge 5: Blank Page After Save
**Problem**: Navigator.pop() exited app when used in tab navigation
**Solution**: Conditional navigation - pop only when used as modal, clear form when used as tab

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Chrome browser or other modern web browser
- Internet connection for API and maps
- Internet connection for API access

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd bangladesh_landmarks
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Google Maps API**
   - Get an API key from [Google Cloud Console](https://console.cloud.google.com/)
   - Replace `YOUR_GOOGLE_MAPS_API_KEY` in `android/app/src/main/AndroidManifest.xml`

4. **Run the application**
   ```bash
   flutter run
   ```

## 💾 Dependencies

### Core Packages
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP & Networking
  http: ^1.1.0                    # REST API communication
  dio: ^5.3.2                     # Alternative HTTP client
  
  # State Management
  provider: ^6.0.5                # Reactive state management
  
  # Maps & Location
  flutter_map: ^6.1.0             # Interactive maps
  latlong2: ^0.9.0                # Coordinate handling
  location: ^5.0.3                # Location services
  geolocator: ^10.1.0             # GPS positioning
  
  # Image Handling
  image_picker: ^1.0.4            # Camera/gallery access
  image: ^4.1.3                   # Image processing
  
  # Storage
  shared_preferences: ^2.2.2      # Local data persistence
  
  # UI Enhancements
  cached_network_image: ^3.3.0    # Image caching
  flutter_spinkit: ^5.2.0         # Loading indicators
  
  # Utilities
  intl: ^0.18.1                   # Date formatting
  permission_handler: ^11.0.1     # Runtime permissions
```

## 🎯 Key Features Implementation

### 1. Navigation & Layout
- **Bottom Navigation Bar**: Three main sections for easy access
- **Tab Persistence**: Uses `IndexedStack` to maintain state across tabs
- **Contextual Actions**: Floating action buttons and app bar actions

### 2. Map-Based Display
- **Bangladesh Focus**: Centered on Dhaka with appropriate zoom level
- **Custom Markers**: Green markers for Bangladesh theme consistency
- **Interactive Elements**: Tap markers to open bottom sheet with details
- **Map Controls**: Location button, zoom controls, and search overlay

### 3. List-Based Display
- **Card Layout**: Material Design cards with image thumbnails
- **Swipe Actions**: Left swipe to edit, right swipe to delete
- **Pull to Refresh**: Refresh landmark data from server
- **Empty State**: Helpful messages when no landmarks exist

### 4. Landmark Form
- **Auto-Location**: Automatically detects GPS coordinates
- **Input Validation**: Comprehensive form validation for all fields
- **Image Processing**: Automatic resize to 800x600 with quality optimization
- **Dual Mode**: Single form handles both create and edit operations

### 5. Error Handling
- **Network Errors**: Graceful handling of connectivity issues
- **User Feedback**: SnackBars for success/error states
- **Validation Messages**: Clear, actionable error messages
- **Retry Mechanisms**: Options to retry failed operations

## 🏗️ Architecture

### State Management
- **Provider Pattern**: Uses the Provider package for state management
- **Centralized Store**: Single `LandmarkProvider` manages all landmark data
- **Reactive UI**: Automatic UI updates when data changes

### Data Layer
- **API Service**: Centralized HTTP client with error handling
- **Model Classes**: Type-safe data models with JSON serialization
- **Service Layer**: Separate services for different concerns (API, Location, Images)

### UI Components
- **Reusable Widgets**: Modular components for consistent UI
- **Responsive Design**: Adapts to different screen sizes
- **Accessibility**: Semantic labels and proper navigation

## 🎨 Design System

### Color Palette
- **Primary Green**: `#006A4E` (Bangladesh flag green)
- **Secondary Red**: `#F42A41` (Bangladesh flag red)
- **Background**: Light grey (`#F5F5F5`)
- **Surface**: White with elevation shadows

### Typography
- **Headings**: Roboto Bold
- **Body Text**: Roboto Regular
- **Coordinates**: Monospace font for precision

### Iconography
- Material Design icons throughout
- Consistent size and color usage
- Contextual icons for each action type

## 🔧 Build & Deployment

### Building for Web
```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build for web
flutter build web

# Output will be in build/web directory
```

### Running Locally
```bash
# Run in Chrome
flutter run -d chrome

# Run in Edge
flutter run -d edge

# Run with hot reload
flutter run -d chrome --hot
```

### Deployment
The built web application can be deployed to:
- **GitHub Pages**: Static hosting
- **Firebase Hosting**: Google's hosting solution
- **Netlify**: Easy deployment with CI/CD
- **Vercel**: Modern web hosting platform

Deploy the contents of `build/web` directory to any static hosting service.

## 🐛 Troubleshooting

### Common Issues

1. **CORS Errors in Browser**
   - **Symptom**: "Access-Control-Allow-Origin" error in console
   - **Solution**: Ensure CORS proxy is active in `api_service.dart`
   - **Verification**: Check requests go through `corsproxy.io`

2. **Blank Page After Saving**
   - **Symptom**: White screen after clicking Save
   - **Solution**: Already fixed - uses conditional navigation
   - **Prevention**: Don't use Navigator.pop() in tab-based screens

3. **Landmarks Not Saving**
   - **Symptom**: Success message but data doesn't persist
   - **Cause**: Wrong content-type or field names
   - **Solution**: Use `application/x-www-form-urlencoded` with `lat`/`lon`

4. **Location Not Detected**
   - **Symptom**: Stays at default Bangladesh center
   - **Solution**: Grant location permissions in browser
   - **Fallback**: Manually enter coordinates or use "Bangladesh Center" button

5. **Images Not Uploading**
   - **Symptom**: Landmark saves but no image
   - **Solution**: Check image is properly converted to base64
   - **Limit**: Large images may fail, automatically resized to 800x600

6. **Update Creates Duplicate**
   - **Symptom**: Edit creates new record instead of updating
   - **Solution**: Use PUT method with id in body (already implemented)

### Debug Tips
- Open browser Developer Tools (F12) to see console errors
- Check Network tab to inspect API requests/responses
- Use the Refresh button in app to reload data from server
- Clear browser cache if seeing stale data

## 📱 Testing

### Manual Testing Checklist
- [ ] Map loads with Bangladesh center
- [ ] Landmarks display as markers
- [ ] Location detection works
- [ ] Image capture/selection functions
- [ ] CRUD operations complete successfully
- [ ] Search functionality works
- [ ] Error messages are clear
- [ ] Navigation is smooth

### Device Testing
- Test on various Android versions
- Verify performance on lower-end devices
- Check landscape/portrait orientations
- Test offline behavior

## 📊 Project Statistics

- **Total Lines of Code**: ~3,500+ lines
- **Number of Screens**: 5 main screens
- **API Endpoints Used**: 4 (GET, POST, PUT, DELETE)
- **Packages Integrated**: 15+ Flutter packages
- **Development Time**: [Your timeframe]
- **Platform Support**: Web (primary), Android, iOS (compatible)

## 🎓 Learning Outcomes

This project demonstrates proficiency in:
- ✅ Flutter framework and Dart programming
- ✅ REST API integration and HTTP communication
- ✅ State management patterns (Provider)
- ✅ Asynchronous programming (async/await, Futures)
- ✅ Geolocation and mapping services
- ✅ Form validation and user input handling
- ✅ Image processing and base64 encoding
- ✅ Error handling and user feedback
- ✅ Responsive UI design
- ✅ Cross-platform development considerations
- ✅ CORS handling for web applications
- ✅ Debugging and problem-solving

## 🔄 Future Enhancements

### Planned Features
- **Offline Mode**: IndexedDB for local storage with sync
- **User Authentication**: Login system with personal collections
- **Categories**: Group landmarks by type (historical, natural, modern)
- **Advanced Search**: Filter by distance radius, date added
- **Export/Import**: JSON export of landmark data
- **Bengali Language**: Localization support

### Technical Improvements
- **Unit Tests**: Test coverage for services and providers
- **Performance**: Image lazy loading and pagination
- **PWA Features**: Install prompt and offline capability
- **Analytics**: User interaction tracking

## 👨‍💻 Developer

**Course**: CSE489 - Computer Networks Lab  
**Institution**: [Your University]  
**Semester**: [Your Semester]  
**Year**: 2025

## 📄 License

This project is created for educational purposes.

## 🙏 Acknowledgments

- Flutter team for excellent documentation
- API provided by labs.anontech.info
- Open source packages from pub.dev community
- Course instructor and teaching assistants

For questions or issues:
- Create an issue in the repository
- Contact the development team
- Refer to Flutter documentation for framework-specific issues

---

**Note**: This application requires active internet connection for full functionality. Some features may be limited in offline mode.