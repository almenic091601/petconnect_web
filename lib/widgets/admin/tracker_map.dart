import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class TrackerMapScreen extends StatefulWidget {
  const TrackerMapScreen({super.key});

  @override
  State<TrackerMapScreen> createState() => _TrackerMapScreenState();
}

class _TrackerMapScreenState extends State<TrackerMapScreen> {
  LatLng? _userLocation;
  final LatLng _defaultCenter =
      const LatLng(14.6091, 121.0223); // Example: Manila
  
  BitmapDescriptor? _petIcon;

  // get from database here
  final List<Map<String, dynamic>> _petLocations = [
    {
      'name': 'Buddy',
      'breed': 'Golden Retriever',
      'sex': 'Male',
      'location': LatLng(14.6251, 121.0523),
    },
    {
      'name': 'Luna',
      'breed': 'Siberian Husky',
      'sex': 'Female',
      'location': LatLng(14.6135, 121.0359),
    },
    {
      'name': 'Max',
      'breed': 'Beagle',
      'sex': 'Male',
      'location': LatLng(14.6018, 121.0172),
    },
  ];

  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadPetIcon();
    _determinePosition();
  }

  Future<void> _loadPetIcon() async {
  final icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(32, 32)),
      'assets/images/pin-point.png',
    );
    setState(() {
      _petIcon = icon;
    });
  }

  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _userLocation = _defaultCenter;
        });
        print('Location permission denied');
        return;
      }
      Position position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
      print('User location: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _userLocation = _defaultCenter;
      });
      print('Error getting location: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Auto-fit all pet markers
    if (_userLocation != null) {
      final allLatLngs = [
        _userLocation!,
      ];
      double minLat = allLatLngs.first.latitude;
      double maxLat = allLatLngs.first.latitude;
      double minLng = allLatLngs.first.longitude;
      double maxLng = allLatLngs.first.longitude;
      for (final latLng in allLatLngs) {
        if (latLng.latitude < minLat) minLat = latLng.latitude;
        if (latLng.latitude > maxLat) maxLat = latLng.latitude;
        if (latLng.longitude < minLng) minLng = latLng.longitude;
        if (latLng.longitude > maxLng) maxLng = latLng.longitude;
      }
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      Future.delayed(const Duration(milliseconds: 300), () {
        _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Map and Filters
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stylish header
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    children: [
                      Icon(Icons.map, color: Colors.blue, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Pet Tracker Map',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                // Stylish filter bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                  ),
                  child: _buildFilters(),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _userLocation == null
                          ? const Center(child: CircularProgressIndicator())
                          : Builder(
                              builder: (context) {
                                final Set<Marker> userMarker = {
                                  Marker(
                                    markerId: const MarkerId('user_location'),
                                    position: _userLocation!,
                                    infoWindow: const InfoWindow(title: 'Admin'),
                                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                                  ),
                                    ..._petLocations.map(
                                    (pet) => Marker(
                                      markerId: MarkerId(pet['name']),
                                      position: pet['location'],
                                      icon: _petIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                                      infoWindow: InfoWindow(
                                        title: pet['name'],
                                        snippet: 'Breed: ${pet['breed']} | Sex: ${pet['sex']}',
                                      ),
                                    ),
                                  ),
                                };
                                return Stack(
                                  children: [
                                    GoogleMap(
                                      onMapCreated: _onMapCreated,
                                      initialCameraPosition: CameraPosition(
                                        target: _userLocation!,
                                        zoom: 12,
                                      ),
                                      markers: userMarker,
                                    ),
                                    Positioned(
                                      top: 16,
                                      right: 16,
                                      child: FloatingActionButton(
                                        mini: true,
                                        backgroundColor: Colors.white,
                                        onPressed: () {
                                          if (!mounted) return;
                                          setState(() {});
                                          if (_mapController != null) {
                                            _mapController?.animateCamera(
                                              CameraUpdate.newLatLng(
                                                  _userLocation!),
                                            );
                                          }
                                        },
                                        tooltip: 'Show My Location',
                                        child: const Icon(Icons.my_location,
                                            color: Colors.blue),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right side - Tracked Pets List
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tracked Pets',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildTrackedPetsList(),
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

  Widget _buildFilters() {
    return Row(
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment<String>(
              value: 'All',
              label: Text('All'),
            ),
            ButtonSegment<String>(
              value: 'Active',
              label: Text('Active'),
            ),
            ButtonSegment<String>(
              value: 'Inactive',
              label: Text('Inactive'),
            ),
          ],
          selected: const {'All'}, // You can implement filter logic if needed
          onSelectionChanged: (Set<String> newSelection) {
            // Implement filter logic if needed
          },
        ),
        const SizedBox(width: 16),
        FilterChip(
          label: const Text('Show Offline'),
          selected: true,
          onSelected: (bool selected) {
            // Implement show/hide offline pets logic if needed
          },
        ),
      ],
    );
  }

  Widget _buildTrackedPetsList() {
    return const Text('No pets to display');
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'lost':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getBatteryColor(int level) {
    if (level > 60) return Colors.green;
    if (level > 20) return Colors.orange;
    return Colors.red;
  }
}
