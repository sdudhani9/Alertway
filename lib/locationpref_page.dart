import 'package:flutter/material.dart';
import 'package:csc_picker/csc_picker.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'incident_service.dart';

class LocationprefPage extends StatefulWidget {
  @override
  _LocationprefPageState createState() => _LocationprefPageState();
}

class _LocationprefPageState extends State<LocationprefPage> {
  String? countryValue;
  String? stateValue;
  String? cityValue;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Notify IncidentService that user is on the location preference page
    Provider.of<IncidentService>(context, listen: false).setOnLocationPreferencePage(true);
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final incidentService = Provider.of<IncidentService>(context, listen: false);

    if (authService.user != null) {
      var preferences = await incidentService.getUserLocationPreference(authService.user!.email!);
      setState(() {
        countryValue = preferences['country'];
        stateValue = preferences['state'];
        cityValue = preferences['city'];
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Notify IncidentService that user is leaving the location preference page
    Provider.of<IncidentService>(context, listen: false).setOnLocationPreferencePage(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final incidentService = Provider.of<IncidentService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Location Preference',
          style: TextStyle(fontSize: 18), 
        ),

      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CSCPicker(
              showStates: true,
              showCities: true,
              flagState: CountryFlag.DISABLE,
              dropdownDecoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
              ),
              disabledDropdownDecoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                color: Colors.grey.shade200,
                border: Border.all(color: Colors.grey.shade200),
              ),
              onCountryChanged: (value) {
                setState(() {
                  countryValue = value;
                  stateValue = null; 
                  cityValue = null;
                });
              },
              onStateChanged: (value) {
                setState(() {
                  stateValue = value;
                  cityValue = null; 
                });
              },
              onCityChanged: (value) {
                setState(() {
                  cityValue = value;
                });
              },
              countryDropdownLabel: countryValue ?? "Select Country",
              stateDropdownLabel: stateValue ?? "Select State",
              cityDropdownLabel: cityValue ?? "Select City",
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (countryValue != null && stateValue != null && cityValue != null) {
                  if (authService.user != null) {
                    await incidentService.saveUserLocationPreference(
                      email: authService.user!.email!,
                      country: countryValue!,
                      state: stateValue!,
                      city: cityValue!,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Location preference saved successfully!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('User not signed in!')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select a country, state, and city!')),
                  );
                }
              },
              child: Text('Save Location Preference', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF29ABE2),

                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: TextStyle(fontSize: 18 , fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
