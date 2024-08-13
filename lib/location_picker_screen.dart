import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng initialLocation;

  LocationPickerScreen({required this.initialLocation});

  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _selectedLocation;
  String? _selectedAddress;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _updateAddress(_selectedLocation!);
  }

  Future<void> _updateAddress(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty) {
        setState(() {
          _selectedAddress = "${placemarks.first.name}, ${placemarks.first.locality}, ${placemarks.first.country}";
        });
      }
    } catch (e) {
      print('Error fetching address: $e');
      setState(() {
        _selectedAddress = 'Unknown location';
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, {
                'location': _selectedLocation,
                'address': _selectedAddress,
              });
            },
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _selectedLocation!,
          zoom: 16,
        ),
        markers: {
          Marker(
            markerId: MarkerId('selected-location'),
            position: _selectedLocation!,
          ),
        },
        onTap: (LatLng position) {
          setState(() {
            _selectedLocation = position;
            _updateAddress(_selectedLocation!);
          });
        },
      ),
    );
  }
}
