import 'package:flutter/material.dart';
import 'package:csc_picker/csc_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:suraksha3/basicpage.dart';
import 'package:suraksha3/incident_service.dart';
import 'package:suraksha3/location_picker_screen.dart';
import 'package:suraksha3/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';

class IncidentReportFormScreen extends StatefulWidget {
  @override
  _IncidentReportFormScreenState createState() => _IncidentReportFormScreenState();
}

class _IncidentReportFormScreenState extends State<IncidentReportFormScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _descriptionController = TextEditingController();
  UniqueKey _cscPickerKey = UniqueKey();

  String? _selectedCountry = 'India';
  String? _selectedState;
  String? _selectedCity;
  String? _selectedCrimeType;
  File? _photo;
  File? _video;
  LatLng? _selectedLocation;
  String? _selectedLocationName;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final List<String> _crimeTypes = [
    'Touching / Groping',
    'Sexual Assault',
    'Vandalism',
    'Stalking',
    'Ogling / Staring',
    'Commenting / Sexual Invites',
    'Catcalling',
    'Eve-teasing',
    'Kidnapping / Abduction',
    'Theft',
    'Other'
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int _currentPageIndex = 0;

  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
    });
  }

  String _getAppBarTitle() {
    switch (_currentPageIndex) {
      case 0:
        return 'Location Details';
      case 1:
        return 'Crime Information';
      case 2:
        return 'Evidence Submission';
      default:
        return 'Report Incident';
    }
  }

  @override
  Widget build(BuildContext context) {
    final incidentService = Provider.of<IncidentService>(
        context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: TextStyle(fontSize: 18),        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            SizedBox(height: 30), 
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                onPageChanged: _onPageChanged,
                children: [
                  _buildLocationDetailsPage(),
                  _buildIncidentDetailsPage(),
                  _buildMediaUploadPage(context, incidentService),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({required String text, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor:       Color(0xFF29ABE2),
      
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        elevation: 3,
        shadowColor: Colors.grey,
      ),
      child: Text(text),
    );
  }

  Widget _buildLocationDetailsPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              children: <Widget>[
                CSCPicker(
                  key: _cscPickerKey,
                  defaultCountry: CscCountry.India,
                  dropdownDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                  ),
                  disabledDropdownDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade200,
                    border: Border.all(color: Colors.grey),
                  ),
                  countrySearchPlaceholder: "Country",
                  stateSearchPlaceholder: "State",
                  citySearchPlaceholder: "City",
                  countryDropdownLabel: "Country",
                  stateDropdownLabel: "State",
                  cityDropdownLabel: "City",
                  onCountryChanged: (value) {
                    setState(() {
                      _selectedCountry = value;
                      _selectedState = null;
                      _selectedCity = null;
                    });
                  },
                  onStateChanged: (value) {
                    setState(() {
                      _selectedState = value;
                      _selectedCity = null;
                    });
                  },
                  onCityChanged: (value) {
                    setState(() {
                      _selectedCity = value;
                    });
                  },
                ),
                SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: ListTile(
                    title: Text(_selectedLocationName ?? 'Select Location'),
                    trailing: Icon(Icons.location_on),
                    onTap: () async {
                      if (_selectedCity != null) {
                        try {
                          List<Location> locations = await locationFromAddress(
                              _selectedCity!);
                          LatLng cityLocation = LatLng(locations.first.latitude,
                              locations.first.longitude);
                          print('City Location: $cityLocation');

                          final Map<String, dynamic>? result = await Navigator
                              .push(
                            context,
                            MaterialPageRoute(builder: (context) =>
                                LocationPickerScreen(
                                    initialLocation: cityLocation)),
                          );

                          if (result != null && result.containsKey(
                              'location') && result.containsKey('address')) {
                            LatLng? pickedLocation = result['location'];
                            String? pickedAddress = result['address'];

                            setState(() {
                              _selectedLocation = pickedLocation;
                              _selectedLocationName = pickedAddress;
                            });
                          }
                        } catch (e) {
                          print('Error fetching city location: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error fetching city location')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please select a city first')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10), 
          _buildButton(
            text: 'Next',
            onPressed: () {
              _pageController.nextPage(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentDetailsPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: ListTile(
                    title: Text(_selectedDate == null
                        ? 'Select Date'
                        : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: ListTile(
                    title: Text(_selectedTime == null
                        ? 'Select Time'
                        : _selectedTime!.format(context)),
                    trailing: Icon(Icons.access_time),
                    onTap: () async {
                      TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedTime = picked;
                        });
                      }
                    },
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCrimeType,
                    items: _crimeTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCrimeType = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Crime Type',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    validator: (value) =>
                    value == null
                        ? 'Please select a crime type'
                        : null,
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    hintText: 'Enter a description',
                  ),
                  maxLines: 2,
                  validator: (value) =>
                  value!.isEmpty
                      ? 'Please enter a description'
                      : null,
                ),
              ],
            ),
          ),
          SizedBox(height: 10), 
          _buildButton(
            text: 'Next',
            onPressed: () {
              _pageController.nextPage(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
        ],
      ),
    );
  }










  Widget _buildMediaUploadPage(BuildContext context, IncidentService incidentService) {
    // Variables to store filenames of selected photo and video
    String? _photoFilename;
    String? _videoFilename;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      labelText: 'Upload Evidence',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: 'Upload Photo',
                        child: Text('Upload Photo'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Upload Video',
                        child: Text('Upload Video'),
                      ),
                    ],
                    onChanged: (value) async {
                      if (value == 'Upload Photo') {
                        File? pickedFile = await incidentService.pickImage();
                        if (pickedFile != null) {
                          setState(() {
                            _photo = pickedFile;
                            _photoFilename = pickedFile.path.split('/').last;
                          });
                          // Show the filename first
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Photo uploaded successfully')),
                          );
                        }
                      } else if (value == 'Upload Video') {
                        File? pickedFile = await incidentService.pickVideo();
                        if (pickedFile != null) {
                          setState(() {
                            _video = pickedFile;
                            _videoFilename = pickedFile.path.split('/').last;
                          });
                          // Show the filename first
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Video uploaded successfully')),
                          );
                        }
                      }
                    },
                  ),
                ),
                SizedBox(height: 20), // Added space between dropdown and filename
                if (_photoFilename != null)
                  Text(
                    'Selected Photo: $_photoFilename',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                if (_videoFilename != null)
                  Text(
                    'Selected Video: $_videoFilename',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
              ],
            ),
          ),
          SizedBox(height: 10), 
          _buildButton(
            text: 'Submit',
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  await incidentService.reportIncident(
                    _selectedState!,
                    _selectedCity!,
                    _selectedLocationName ?? '',
                    _selectedCrimeType!,
                    _descriptionController.text,
                    _photo,
                    _video,
                    _selectedLocation!.latitude,
                    _selectedLocation!.longitude,
                    _selectedCountry!,
                    _selectedState!,
                    _selectedCity!,
                    _selectedDate!,
                    _selectedTime!,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Incident reported successfully')),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  print('Error reporting incident: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error reporting incident')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

}
