import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AnimatedStatsCard extends StatefulWidget {
  final String title;
  final int count;

  final Color color;

  AnimatedStatsCard({
    required this.title,
    required this.count,

    required this.color,
  });

  @override
  _AnimatedStatsCardState createState() => _AnimatedStatsCardState();
}

class _AnimatedStatsCardState extends State<AnimatedStatsCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: ScaleTransition(
        scale: _animation,
        child: Card(
          color: widget.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[

                SizedBox(height: 3),
                Text(
                  widget.title,
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
                SizedBox(height: 2),
                Text(
                  widget.count.toString(),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
