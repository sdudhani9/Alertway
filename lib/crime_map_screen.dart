import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:csc_picker/csc_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:suraksha3/CrimeDetail.dart';
import '../incident_service.dart';

class CrimeMapScreen extends StatefulWidget {
  @override
  _CrimeMapScreenState createState() => _CrimeMapScreenState();
}

class _CrimeMapScreenState extends State<CrimeMapScreen> {
  String? _selectedCountry = 'India';
  String? _selectedState;
  String? _selectedCity;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(20.5937, 78.9629), 
    zoom: 5,
  );

  @override
  Widget build(BuildContext context) {
    final incidentService = Provider.of<IncidentService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Crime Map',
          style: TextStyle(fontSize: 18),         ),

      ),
      body: Column(
        children: <Widget>[
          CSCPicker(
            defaultCountry: CscCountry.India,
            onCountryChanged: (value) {
              setState(() {
                _selectedCountry = value;
                _selectedState = null;
                _selectedCity = null;
                _markers = {};
              });
            },
            onStateChanged: (value) {
              setState(() {
                _selectedState = value;
                _selectedCity = null;
                _markers = {};
              });
            },
            onCityChanged: (value) async {
              setState(() {
                _selectedCity = value;
              });

              if (_selectedCity != null) {
                LatLng cityCoordinates = await _getCityCoordinates(_selectedCity!);
                _mapController?.animateCamera(CameraUpdate.newLatLngZoom(cityCoordinates, 12));

                List<Map<String, dynamic>> incidents = await incidentService.getIncidentsByCity(_selectedState!, _selectedCity!);

                Set<Marker> newMarkers = incidents.map((incident) {
                  return Marker(
                    markerId: MarkerId(incident['timestamp']),
                    position: LatLng(incident['location'].latitude, incident['location'].longitude),
                    infoWindow: InfoWindow(
                      title: incident['crimeType'],
                      snippet: incident['description'],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CrimeDetailScreen(incidentId: incident['timestamp']),
                          ),
                        );
                      },
                    ),
                  );
                }).toSet();

                setState(() {
                  _markers = newMarkers;
                });
              }
            },
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: _initialCameraPosition,
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<LatLng> _getCityCoordinates(String city) async {
    try {
      List<Location> locations = await locationFromAddress(city + ", " + _selectedState! + ", " + _selectedCountry!);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      print('Error fetching city coordinates: $e');
    }
        return LatLng(20.5937, 78.9629);
  }
}
