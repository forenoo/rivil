import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapLocationPicker extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng) onLocationSelected;

  const MapLocationPicker({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(-7.9666,
      112.6326); // Fallback location if user location cannot be determined
  Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
      _updateMarker();
      _isLoading = false;
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, use fallback location
      setState(() {
        _isLoading = false;
        _updateMarker();
      });
      return;
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, use fallback location
        setState(() {
          _isLoading = false;
          _updateMarker();
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied, use fallback location
      setState(() {
        _isLoading = false;
        _updateMarker();
      });
      return;
    }

    // Get current position
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
        _updateMarker();
        widget.onLocationSelected(_selectedLocation);
      });

      // Move camera to user location if map controller is available
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _selectedLocation,
            zoom: 14,
          ),
        ),
      );
    } catch (e) {
      // Error getting location, use fallback location
      setState(() {
        _isLoading = false;
        _updateMarker();
      });
    }
  }

  void _updateMarker() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation,
          infoWindow: const InfoWindow(title: 'Selected Location'),
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 215,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation,
                      zoom: 14,
                    ),
                    markers: _markers,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      // If we already have a location but the controller just got created,
                      // we might want to move the camera
                      if (!_isLoading && widget.initialLocation == null) {
                        controller.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: _selectedLocation,
                              zoom: 14,
                            ),
                          ),
                        );
                      }
                    },
                    onTap: (location) {
                      setState(() {
                        _selectedLocation = location;
                        _updateMarker();
                        widget.onLocationSelected(location);
                      });
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                  ),
                  if (_isLoading)
                    Container(
                      color: Colors.white.withOpacity(0.7),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            'Tekan pada peta untuk memilih lokasi',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            ),
            const SizedBox(width: 8),
            Text(
              'Long: ${_selectedLocation.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}
