import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class IncidentService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  SharedPreferences? _prefs;

  bool _isOnLocationPreferencePage = false;
  bool _isViewingIncidentDetails = false;
  bool _isOnIncidentsSharedByMePage = false;

  IncidentService() {
    _initializeNotificationListener();
    _initializeSharedPreferences();
  }

  Future<void> _initializeSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void _initializeNotificationListener() async {
    String? email = await AuthService().getCurrentUserEmail();
    if (email == null) return;

    var preferences = await getUserLocationPreference(email);
    String? preferredCity = preferences['city'];

    if (preferredCity != null && preferredCity.isNotEmpty) {
      _firestore.collection('incidents').snapshots().listen((querySnapshot) {
        for (var change in querySnapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            var newIncident = change.doc.data();
            String incidentId = change.doc.id;

            if (newIncident?['city'] == preferredCity &&
                !_isOnLocationPreferencePage &&
                !_isViewingIncidentDetails &&
                !_isOnIncidentsSharedByMePage &&
                !_isNotified(incidentId)) {
              Timestamp? timestamp = newIncident?['crimeDateTime'];
              DateTime crimeDateTime = timestamp?.toDate() ?? DateTime.now();
              String formattedDate = "${crimeDateTime.day}/${crimeDateTime.month}/${crimeDateTime.year}";
              String formattedTime = "${crimeDateTime.hour}:${crimeDateTime.minute}";

              _sendNotification(
                  "Crime Reported",
                  "A new crime has been reported in your city, $preferredCity on $formattedDate at $formattedTime. Be Aware!"
              );

              _markAsNotified(incidentId);
            }
          }
        }
      });
    }
  }

  bool _isNotified(String incidentId) {
    return _prefs?.getStringList('notified_incidents')?.contains(incidentId) ?? false;
  }

  void _markAsNotified(String incidentId) {
    List<String>? notifiedIncidents = _prefs?.getStringList('notified_incidents') ?? [];
    notifiedIncidents.add(incidentId);
    _prefs?.setStringList('notified_incidents', notifiedIncidents);
  }

  Future<void> _sendNotification(String title, String body) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'Default_Sound',
    );
  }

  void setOnLocationPreferencePage(bool isOnPage) {
    _isOnLocationPreferencePage = isOnPage;
  }

  void setViewingIncidentDetails(bool isViewing) {
    _isViewingIncidentDetails = isViewing;
  }

  void setOnIncidentsSharedByMePage(bool isOnPage) {
    _isOnIncidentsSharedByMePage = isOnPage;
  }

  Future<void> reportIncident(
      String state,
      String city,
      String locationDetails,
      String crimeType,
      String description,
      File? photo,
      File? video,
      double latitude,
      double longitude,
      String countryPath,
      String statePath,
      String cityPath,
      DateTime crimeDate,
      TimeOfDay crimeTime,
      ) async {
    try {
      String? email = await AuthService().getCurrentUserEmail();
      if (email == null) {
        throw Exception("User is not logged in");
      }

      final photoUpload = _uploadFile(photo, 'photos');
      final videoUpload = _uploadFile(video, 'videos');

      final List<String?> uploadResults = await Future.wait([photoUpload, videoUpload]);
      final String? photoUrl = uploadResults[0];
      final String? videoUrl = uploadResults[1];

      DateTime crimeDateTime = DateTime(
        crimeDate.year,
        crimeDate.month,
        crimeDate.day,
        crimeTime.hour,
        crimeTime.minute,
      );

      await _firestore.collection('incidents').add({
        'state': state,
        'city': city,
        'locationDetails': locationDetails,
        'crimeType': crimeType,
        'description': description,
        'photoUrl': photoUrl,
        'videoUrl': videoUrl,
        'location': GeoPoint(latitude, longitude),
        'timestamp': DateTime.now(),
        'crimeDateTime': crimeDateTime,
        'country': countryPath,
        'stateInCountry': statePath,
        'cityInState': cityPath,
        'reportedBy': email,
      });

      notifyListeners();
    } catch (e) {
      print('Error reporting incident: $e');
      rethrow;
    }
  }

  Future<String?> _uploadFile(File? file, String folder) async {
    if (file == null) return null;
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      Reference reference = _storage.ref().child('$folder/$fileName');
      UploadTask uploadTask = reference.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  Future<File?> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  Future<File?> pickVideo() async {
    final pickedFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getIncidentsByCity(String state, String city) async {
    final querySnapshot = await _firestore.collection('incidents')
        .where('state', isEqualTo: state)
        .where('city', isEqualTo: city)
        .get();

    return querySnapshot.docs.map((doc) {
      return {
        'crimeType': doc['crimeType'],
        'description': doc['description'],
        'location': doc['location'],
        'timestamp': doc.id,
      };
    }).toList();
  }

  Future<void> saveUserLocationPreference({
    required String email,
    required String country,
    required String state,
    required String city,
  }) async {
    try {
      await _firestore.collection('user_preferences').doc(email).set({
        'country': country,
        'state': state,
        'city': city,
      });
      notifyListeners();
    } catch (e) {
      print('Error saving location preference: $e');
      rethrow;
    }
  }

  Future<Map<String, String>> getUserLocationPreference(String email) async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection('user_preferences').doc(email).get();
      if (snapshot.exists) {
        return {
          'country': snapshot['country'] ?? '',
          'state': snapshot['state'] ?? '',
          'city': snapshot['city'] ?? '',
        };
      }
    } catch (e) {
      print('Error fetching location preference: $e');
    }
    return {'country': '', 'state': '', 'city': ''};
  }

  Future<Map<String, dynamic>> getIncidentDetails(String incidentId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('incidents').doc(incidentId).get();
      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching incident details: $e');
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> getIncidentsByUser() async {
    String? email = await AuthService().getCurrentUserEmail();
    if (email == null) return [];

    final querySnapshot = await _firestore.collection('incidents')
        .where('reportedBy', isEqualTo: email)
        .get();

    return querySnapshot.docs.map((doc) {
      return {
        'crimeType': doc['crimeType'],
        'description': doc['description'],
        'location': doc['location'],
        'crimeDateTime': doc['crimeDateTime'],
        'city': doc['city'],
        'timestamp': doc.id,
      };
    }).toList();
  }



  Stream<Map<String, int>> getCrimeTypeCounts() {
    return _firestore.collection('incidents').snapshots().map((snapshot) {
      Map<String, int> crimeTypeCounts = {};

      // Loop through each document and increment the crime type count
      for (var doc in snapshot.docs) {
        String crimeType = doc['crimeType'] as String;
        crimeTypeCounts.update(crimeType, (value) => value + 1,
            ifAbsent: () => 1);
      }

      return crimeTypeCounts;
    });
  }

  Future<int> getCrimesReportedToday() async {
    try {
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      QuerySnapshot snapshot = await _firestore.collection('incidents')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error fetching crimes reported today: $e');
      return 0;
    }
  }

  Future<int> getActiveUserCount() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('user_preferences').get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error fetching active user count: $e');
      return 0;
    }
  }





}
