import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CrimeDetailScreen extends StatefulWidget {
  final String incidentId;

  CrimeDetailScreen({required this.incidentId});

  @override
  _CrimeDetailScreenState createState() => _CrimeDetailScreenState();
}

class _CrimeDetailScreenState extends State<CrimeDetailScreen> {
  VideoPlayerController? _videoPlayerController;
  Future<void>? _initializeVideoPlayerFuture;
  String? _videoThumbnailPath;
  bool _isVideoPlayerInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    FirebaseFirestore.instance.collection('incidents').doc(widget.incidentId).get().then((documentSnapshot) {
      if (documentSnapshot.exists) {
        var data = documentSnapshot.data() as Map<String, dynamic>;
        if (data['videoUrl'] != null) {
          _generateThumbnail(data['videoUrl']);
          _videoPlayerController = VideoPlayerController.network(data['videoUrl']);
          _initializeVideoPlayerFuture = _videoPlayerController!.initialize().then((_) {
            setState(() {
              _isVideoPlayerInitialized = true;
              _videoPlayerController!.setLooping(true);
            });
          }).catchError((error) {
            print('Error initializing video player: $error');
          });
        }
      }
    }).catchError((error) {
      print('Error fetching incident data: $error');
    });
  }

  Future<void> _generateThumbnail(String videoUrl) async {
    final directory = await getApplicationDocumentsDirectory();
    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: videoUrl,
      thumbnailPath: directory.path,
      imageFormat: ImageFormat.PNG,
      maxHeight: 200,
      quality: 75,
    );
    setState(() {
      _videoThumbnailPath = thumbnailPath;
    });
  }

  Future<String> _getAddress(GeoPoint location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      }
    } catch (e) {
      print('Error fetching address: $e');
    }
    return "Unknown location";
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }

  void _showFullScreenVideo(String videoUrl) {
    VideoPlayerController controller = VideoPlayerController.network(videoUrl);
    controller.initialize().then((_) {
      controller.play();
      controller.addListener(() {
        if (controller.value.position >= controller.value.duration) {
          Navigator.of(context).pop(); 
          controller.dispose();
        }
      });
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
      ).then((_) {
        controller.dispose();
      });
    });
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              height: 72,
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('incidents').doc(widget.incidentId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('No data found'));
          } else {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            return FutureBuilder<String>(
              future: _getAddress(data['location']),
              builder: (context, locationSnapshot) {
                if (locationSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (locationSnapshot.hasError) {
                  return Center(child: Text('Error: ${locationSnapshot.error}'));
                } else {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView(
                      children: [
                        Text(
                          '${data['crimeType']}',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple),
                        ),
                        SizedBox(height: 20),
                        Text(
                          '${data['description']}',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_pin, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${locationSnapshot.data}',
                                style: TextStyle(fontSize: 16),
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              'Around ${DateFormat('dd MMM yyyy').format(data['crimeDateTime'].toDate())}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Between ${TimeOfDay.fromDateTime(data['crimeDateTime'].toDate()).format(context)}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Evidence',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              SizedBox(height: 10),
                              if (data['photoUrl'] != null)
                                Card(
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: InkWell(
                                    onTap: () => _showFullScreenImage(data['photoUrl']),
                                    child: Container(
                                      height: 200,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        image: DecorationImage(
                                          image: NetworkImage(data['photoUrl']),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (data['photoUrl'] != null && data['videoUrl'] != null)
                                SizedBox(height: 10),
                              if (data['videoUrl'] != null)
                                Card(
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: InkWell(
                                    onTap: () => _showFullScreenVideo(data['videoUrl']),
                                    child: Container(
                                      height: 200,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        image: _videoThumbnailPath != null
                                            ? DecorationImage(
                                          image: FileImage(File(_videoThumbnailPath!)),
                                          fit: BoxFit.cover,
                                        )
                                            : null,
                                      ),
                                      child: _videoThumbnailPath == null
                                          ? Center(child: CircularProgressIndicator())
                                          : Center(
                                        child: Icon(
                                          Icons.play_circle_outline,
                                          color: Colors.white,
                                          size: 50,
                                        ),
                                      ),
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
              },
            );
          }
        },
      ),
    );
  }
}
