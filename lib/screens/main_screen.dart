import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/landmark_provider.dart';
import 'map_view_screen.dart';
import 'records_list_screen.dart';
import 'new_entry_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    MapViewScreen(),
    RecordsListScreen(),
    NewEntryScreen(),
  ];

  final List<String> _titles = [
    'Overview',
    'Records',
    'New Entry',
  ];

  @override
  void initState() {
    super.initState();
    // Load landmarks when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LandmarkProvider>().loadLandmarks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              context.read<LandmarkProvider>().refresh();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Records',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_location),
            label: 'New Entry',
          ),
        ],
      ),
    );
  }
}
