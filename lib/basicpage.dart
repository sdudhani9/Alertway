import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:provider/provider.dart';
import 'package:suraksha3/CrimeInformationPage.dart';
import 'package:suraksha3/NotificationPage.dart';
import 'package:suraksha3/crime_map_screen.dart';
import 'package:suraksha3/incident_report_form_screen.dart';
import 'package:suraksha3/incident_service.dart';
import 'package:suraksha3/locationpref_page.dart';
import 'auth_service.dart'; 
import 'package:suraksha3/AnimatedStatsCard.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<IncidentService>(
          create: (_) => IncidentService(),
        ),
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 1;
  List<String> _notifications = [];

  List<Widget> _pages = []; 

  @override
  void initState() {
    super.initState();

  
    _pages = [
      IncidentReportFormScreen(),
      HomePage(notifications: _notifications),
      CrimeMapScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

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
      body: _pages[_selectedIndex],
      drawer: _buildDrawer(context, authService),

      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        height: 55.0,
        items: <Widget>[
          Icon(Icons.report, size: 25, color: Colors.white),
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.warning, size: 25, color: Colors.white),
        ],
        color: Color(0xFF29ABE2),
        buttonBackgroundColor: Color(0xFF29ABE2),
        backgroundColor: Colors.white,
        animationCurve: Curves.easeInOut,
        animationDuration: Duration(milliseconds: 300),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),

    );
  }

  Widget _buildDrawer(BuildContext context, AuthService authService) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png', height: 72),
                SizedBox(height: 10),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.account_circle),
            title: Text(authService.user?.email ?? 'No Email'),
          ),
          Divider(), 
          SizedBox(height: 10), 
          ListTile(
            leading: Icon(Icons.report),
            title: Text('Incidents shared by me'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => IncidentsSharedByMePage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LocationSettingsPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('Terms and Conditions'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TermsAndConditionsPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.support),
            title: Text('Support and FAQ'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SupportFAQPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.group),
            title: Text('About us'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutUsPage()),
              );
            },
          ),
          SizedBox(height: 70),
          Divider(), // Horizontal line
          SizedBox(height: 20),
           ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () async {
              await authService.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  void _onNewNotification(String notification) {
    setState(() {
      _notifications.add(notification);
    });
  }
}

class HomePage extends StatelessWidget {
  final List<String> notifications;

  HomePage({required this.notifications});

  @override
  Widget build(BuildContext context) {
    return GridViewMenu();
  }
}

class GridViewMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final incidentService = Provider.of<IncidentService>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/samplemap.png'),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 8.0,
              crossAxisSpacing: 8.0,
              children: <Widget>[
                _buildGridItem(
                    Icons.report, "Want to report\na crime ?", context,
                    IncidentReportFormScreen()),
                _buildGridItem(Icons.warning, "Incidents\nGoing on", context,
                    CrimeMapScreen()),
                _buildGridItem(Icons.bar_chart, "Crime Statistics", context,
                    CaseHistoryPage()),
              ],
            ),
          ),
        ),
        SizedBox(height: 5),
        FutureBuilder<int>(
          future: incidentService.getCrimesReportedToday(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final crimeCount = snapshot.data ?? 0;

            return FutureBuilder<int>(
              future: incidentService.getActiveUserCount(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final userCount = userSnapshot.data ?? 0;

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
                  padding: EdgeInsets.all(3.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: MediaQuery
                            .of(context)
                            .size
                            .width,
                        height: MediaQuery
                            .of(context)
                            .size
                            .height * 0.10, 
                        margin: const EdgeInsets.symmetric(vertical: 2.0),
                        child: AnimatedStatsCard(
                          title: "Crimes Reported Today",
                          count: crimeCount,

                          color: Colors.red,
                        ),
                      ),
                      Container(
                        width: MediaQuery
                            .of(context)
                            .size
                            .width,
                        height: MediaQuery
                            .of(context)
                            .size
                            .height * 0.10,
                        margin: const EdgeInsets.symmetric(vertical: 2.0),
                        child: AnimatedStatsCard(
                          title: "Active Users",
                          count: userCount,

                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 5),
                     
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Container(
                          padding: EdgeInsets.all(9.0),

                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildActionButton(
                                  context, "About Us", AboutUsPage()),
                              SizedBox(width: 10),
                              _buildActionButton(
                                  context, "FAQ", SupportFAQPage()),
                              SizedBox(width: 10),
                              _buildActionButton(
                                  context, "Terms", TermsAndConditionsPage()),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildGridItem(IconData icon, String label, BuildContext context,
      Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blueGrey, width: 0.7),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.4),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF29ABE2),
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(6.0),
              child: Icon(icon, size: 40, color: Color(0xFFffffff)),
            ),
            SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String title, Widget page) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white, 
        foregroundColor: Colors.black, 
        padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0), 
          side: BorderSide(color: Colors.blueGrey,
          width: 0.7),
        ),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Text(
        title,
        style: TextStyle(fontSize: 12),
      ),
    );
  }
}



//crime Statistics
class CaseHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Crime Statistics',
          style: TextStyle(fontSize: 18), 
        ),

      ),
      body: StreamBuilder<Map<String, int>>(
        stream: Provider.of<IncidentService>(context).getCrimeTypeCounts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available'));
          }

          Map<String, int> crimeTypeCounts = snapshot.data!;

          List<String> allowedCrimeTypes = [
            'Touching / Groping',
            'Sexual Assault',
            'Vandalism',
            'Stalking',
            'Ogling / Staring',
            'Commenting / Sexual Invites',
            'Catcalling',
            'Eve-teasing',
            'Theft',
            'Kidnapping / Abduction'
            'Other',
          ];

          crimeTypeCounts.removeWhere((key, value) => !allowedCrimeTypes.contains(key));

          List<PieSeries<MapEntry<String, int>, String>> pieChartSeries = [
            PieSeries<MapEntry<String, int>, String>(
              dataSource: crimeTypeCounts.entries.toList(),
              xValueMapper: (MapEntry<String, int> entry, _) => entry.key,
              yValueMapper: (MapEntry<String, int> entry, _) => entry.value,
              dataLabelMapper: (MapEntry<String, int> entry, _) =>
              '${entry.key}: ${entry.value}',
              dataLabelSettings: DataLabelSettings(
                isVisible: true,
                labelIntersectAction: LabelIntersectAction.shift,
                labelPosition: ChartDataLabelPosition.outside,
              ),
              pointColorMapper: (MapEntry<String, int> entry, _) =>
                  _getColorForCrimeType(entry.key),
            ),
          ];

          List<BarSeries<MapEntry<String, int>, String>> barChartSeries = [
            BarSeries<MapEntry<String, int>, String>(
              dataSource: crimeTypeCounts.entries.toList(),
              xValueMapper: (MapEntry<String, int> entry, _) => entry.key,
              yValueMapper: (MapEntry<String, int> entry, _) => entry.value,
              pointColorMapper: (MapEntry<String, int> entry, _) =>
                  _getColorForCrimeType(entry.key),
            ),
          ];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: SfCircularChart(
                    title: ChartTitle(text: 'Crime Distribution by Type'),
                    legend: Legend(isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
                    series: pieChartSeries,
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: SfCartesianChart(
                    title: ChartTitle(text: 'Crime Counts by Type'),
                    primaryXAxis: CategoryAxis(),
                    series: barChartSeries,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getColorForCrimeType(String crimeType) {
    const colors = {
      'Touching / Groping': Colors.red,
      'Sexual Assault': Colors.orange,
      'Vandalism': Colors.yellow,
      'Stalking': Colors.green,
      'Ogling / Staring': Colors.blue,
      'Commenting / Sexual Invites': Colors.purple,
      'Catcalling': Colors.pink,
      'Eve-teasing': Colors.brown,
      'Theft': Colors.cyan,
      'Other': Colors.teal,
      'Kidnapping / Abduction': Colors.grey,
    };
    return colors[crimeType] ?? Colors.black;
  }
}




//incident shared by me 
class IncidentsSharedByMePage extends StatefulWidget {
  @override
  _IncidentsSharedByMePageState createState() => _IncidentsSharedByMePageState();
}

class _IncidentsSharedByMePageState extends State<IncidentsSharedByMePage> {
  late final IncidentService _incidentService;

  @override
  void initState() {
    super.initState();
    _incidentService = Provider.of<IncidentService>(context, listen: false);

    // Set the flag to true when this page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _incidentService.setOnIncidentsSharedByMePage(true);
    });
  }

  @override
  void dispose() {
       _incidentService.setOnIncidentsSharedByMePage(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Incidents Shared by Me',
          style: TextStyle(fontSize: 18), 
        ),

      ),
      body: Consumer<IncidentService>(
        builder: (context, incidentService, child) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: incidentService.getIncidentsByUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error loading incidents'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No incidents found'));
              } else {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var incident = snapshot.data![index];

                    // Fetch the crimeDateTime and city values from the incident data
                    DateTime? crimeDateTime = incident['crimeDateTime']?.toDate();
                    String? city = incident['city'];

                    return Card(
                      elevation: 1.0,
                      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0.0), 
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16.0),
                        title: Text(
                          incident['crimeType'] ?? 'Unknown Crime Type',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4.0),
                            Text(
                              'Date: ${crimeDateTime != null ? "${crimeDateTime.toLocal().day}/${crimeDateTime.toLocal().month}/${crimeDateTime.toLocal().year}" : 'Unknown Date'}',
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Colors.grey[700], 
                              ),
                            ),
                            SizedBox(height: 4.0),
                            Text(
                              'City: ${city ?? 'Unknown City'}',
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          incidentService.setViewingIncidentDetails(true);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CrimeInformationPage(incidentId: incident['timestamp']),
                            ),
                          ).then((_) {
                            incidentService.setViewingIncidentDetails(false);
                          });
                        },
                      ),
                    );

                  },

                );
              }
            },
          );
        },
      ),
    );
  }
}


//settings
class LocationSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(fontSize: 18), 
        ),

      ),

      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.location_on),
            title: Text('Edit Location'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LocationprefPage()),
              );
            },
          ),

        ],
      ),
    );
  }
}



//Anout us
class AboutUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About us',
          style: TextStyle(fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 20),
              Center(
                child: Text(
                  'Welcome to Alertway',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'At Alertway, we are committed to making communities safer by empowering citizens with the tools they need to report and stay informed about local incidents. Our mission is to provide a reliable platform that helps reduce crime and enhance public safety through real-time information sharing.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 30),
              Text(
                'Our Mission',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Our mission is to foster safer communities by enabling seamless communication between citizens and authorities. We believe that informed citizens can make a significant difference in preventing and responding to crime.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 30),
              Text(
                'Key Features',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              _buildFeature(
                icon: Icons.report,
                title: 'Incident Reporting',
                description:
                'Report crimes and suspicious activities directly through the app. Provide detailed descriptions, upload photos or videos, and select the exact location on the map to help authorities respond quickly.',
              ),
              _buildFeature(
                icon: Icons.map,
                title: 'Crime Mapping',
                description:
                'View real-time crime data on an interactive map. Filter incidents by type, city, or state to understand the crime landscape in your area.',
              ),
              _buildFeature(
                icon: Icons.notifications,
                title: 'Crime Alerts Notifications',
                description:
                'Stay informed with real-time crime alerts based on your preferred location. Customize your notification preferences to receive updates about incidents in your neighborhood or any location of your choice.',
              ),
              _buildFeature(
                icon: Icons.bar_chart,
                title: 'Crime Statistics',
                description:
                'Access detailed crime statistics to understand trends in your area. Visualize crime data through charts and graphs to stay informed and take necessary precautions.',
              ),
              _buildFeature(
                icon: Icons.history,
                title: 'Incidents Shared by Me',
                description:
                'Track the incidents you\'ve reported with ease. Review your submissions and check their status, ensuring that your contributions are making a difference.',
              ),
              SizedBox(height: 30),
              Text(
                'Our Vision',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'We envision a world where technology bridges the gap between citizens and authorities, creating a safer environment for everyone. By leveraging real-time data and community collaboration, Alertway strives to be the go-to platform for crime prevention and reporting.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature({required IconData icon, required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Color(0xFF29ABE2), size: 30),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


//FAQ
class SupportFAQPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FAQ',
          style: TextStyle(fontSize: 18), 
        ),

      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          FAQItem(
            question: "What is AlertWay?",
            answer: "AlertWay is a crime reporting app that allows users to report incidents, view crime maps, and get alerts based on their location. The app helps users stay informed about crime in their area and provides features like route-based crime statistics and emergency support.",
          ),
          FAQItem(
            question: "How do I report an incident?",
            answer: "To report an incident, go to the Incident Report Form screen. Fill in details like crime type, city, exact location, description, and upload any relevant photos or videos. Once you submit the form, the incident will be added to the database and displayed on the crime map.",
          ),
          FAQItem(
            question: "How can I view ongoing crimes a map?",
            answer: "Navigate to the Crime Map screen. Here, you can view a map with markers indicating reported incidents. You can filter incidents by state and city to see the crime statistics for specific areas.",
          ),
          FAQItem(
            question: "Can I search for specific locations on the map?",
            answer: "Yes, you can use the search bar in the map to search for specific locations within the selected city. This helps you find and view crime data for particular areas.",
          ),

          FAQItem(
            question: "How do I access the profile section?",
            answer: "Open the drawer menu, and you’ll see your profile section displaying your email ID, and at the bottom of the drawer, you'll find the logout button.",
          ),
          FAQItem(
            question: "What are the location setting?",
            answer: "The Location Settings Page allows you to adjust your location preferences settings. You can access this page from the Settings option in the drawer.",
          ),
          FAQItem(
            question: "Who can I contact for support?",
            answer: "If you need assistance or have any questions not covered in the FAQ, please contact through email at support@alertway.com.",
          ),
        ],
      ),
    );
  }
}

class FAQItem extends StatelessWidget {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(answer),
          ),
        ],
      ),
    );
  }
}


//Tersms & conditiond
class TermsAndConditionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terms and Conditions',
          style: TextStyle(fontSize: 18),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),

              Text(
                'Terms and Conditions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              SizedBox(height: 20),
              Divider(color: Colors.grey.shade300),
              SizedBox(height: 10),
              Text(
                '1. Acceptance of Terms',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'By using our app, you agree to these terms and conditions. If you do not agree, please do not use the app.',
                style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black54),
              ),
              SizedBox(height: 20),
              Text(
                '2. Changes to Terms',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'We may update these terms from time to time. You are advised to review this page periodically for any changes.',
                style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black54),
              ),
              SizedBox(height: 20),
              Text(
                '3. User Responsibilities',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'You are responsible for any content you submit or report through the app. Ensure that all information is accurate and true.',
                style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black54),
              ),
              SizedBox(height: 20),
              Text(
                '4. Privacy',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Your privacy is important to us. Please review our Privacy Policy to understand how we collect, use, and protect your information.',
                style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black54),
              ),
              SizedBox(height: 20),
              Text(
                '5. Limitation of Liability',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Our app is provided “as is” and we do not warrant the accuracy or completeness of the information provided. We are not liable for any damages resulting from the use of the app.',
                style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black54),
              ),
              SizedBox(height: 20),
              Text(
                '6. Contact Us',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'If you have any questions about these terms, please contact us at support@alertway.com.',
                style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black54),
              ),
              SizedBox(height: 20),
              Text(
                '7. Governing Law',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'These terms are governed by the laws of the jurisdiction in which we operate.',
                style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black54),
              ),
              SizedBox(height: 20),
              Text(
                '8. Termination',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'We reserve the right to terminate or suspend access to our app at our sole discretion, without notice, for any reason.',
                style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black54),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );

  }

}
