import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

void main() {
  runApp(SaarthiApp());
}

class SaarthiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: OnboardingScreen(),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int currentIndex = 0;
  bool isFirstPage = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isFirstPage ? buildFirstPage(context) : buildOnboardingPages(context),
    );
  }

  Widget buildFirstPage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(),
          Image.asset('assets/images/logo.png'), 
          SizedBox(height: 30),
          Text(
            'Report Crime. Share Experience. Aware People.',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  isFirstPage = false;
                });
              },
              child: Text('Get Started', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF29ABE2),

                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: TextStyle(fontSize: 18 , fontWeight: FontWeight.bold),



                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget buildOnboardingPages(BuildContext context) {
    return Stack(
      children: [
        PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          children: [
            OnboardingPage(
              image: 'assets/images/report.png',
              title: 'Report with Confidence',
              description: 'You can now report incidents with confidence knowing that your data will be kept secure and confidential.',
            ),
            OnboardingPage(
              image: 'assets/images/crimemap.png', 
              title: 'Ensuring Safety and Security',
              description: 'Our platform ensures your safety and security by providing you with real-time data about your area.',
            ),
            OnboardingPage(
              image: 'assets/images/community.png', 
              title: 'Share Experience',
              description: 'Share your experience with the community, helping others to stay away from crimes in the city.',
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            children: [
              SmoothPageIndicator(
                controller: _pageController,
                count: 3,
                effect: WormEffect(
                  dotHeight: 9,
                  dotWidth: 9,
                  spacing: 12,
                  dotColor: Colors.grey,
                  activeDotColor: Colors.blue,
                ),
              ),
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login'); 
                    },
                    child: Text(
                      'Skip',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (currentIndex == 2) {
                        Navigator.pushReplacementNamed(context, '/login'); 
                      } else {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(currentIndex == 2 ? 'Get Started' : 'Next', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF29ABE2),
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      textStyle: TextStyle(fontSize: 18 , fontWeight: FontWeight.normal),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String image;
  final String title;
  final String description;

  OnboardingPage({
    required this.image,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200, 
            height: 200, 
            child: Image.asset(image),
          ),
          SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Text(
            description,
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
