import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:phoenix/phoenix.dart';

class DebugOverlay extends StatefulWidget {
  final Widget child;
  
  const DebugOverlay({super.key, required this.child});

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  bool _showPerformanceOverlay = false;
  bool _showBaselines = false;
  bool _showGuidelines = false;
  bool _slowAnimations = false;
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            color: Colors.black54,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.speed, 
                    color: _showPerformanceOverlay ? Colors.green : Colors.white),
                  onPressed: () {
                    setState(() {
                      _showPerformanceOverlay = !_showPerformanceOverlay;
                      // Store the setting in shared preferences
                      SharedPreferences.getInstance().then((prefs) {
                        prefs.setBool('show_performance_overlay', _showPerformanceOverlay);
                      });
                      // Force app rebuild
                      // Phoenix.rebirth(context); // Uncomment when phoenix is fixed
                    });
                  },
                  tooltip: 'Toggle Performance Overlay',
                ),
                IconButton(
                  icon: Icon(Icons.border_bottom, 
                    color: _showBaselines ? Colors.green : Colors.white),
                  onPressed: () {
                    setState(() {
                      _showBaselines = !_showBaselines;
                      debugPaintBaselinesEnabled = _showBaselines;
                    });
                  },
                  tooltip: 'Show Baselines',
                ),
                IconButton(
                  icon: Icon(Icons.grid_on, 
                    color: _showGuidelines ? Colors.green : Colors.white),
                  onPressed: () {
                    setState(() {
                      _showGuidelines = !_showGuidelines;
                      debugPaintSizeEnabled = _showGuidelines;
                    });
                  },
                  tooltip: 'Show Guidelines',
                ),
                IconButton(
                  icon: Icon(Icons.slow_motion_video, 
                    color: _slowAnimations ? Colors.green : Colors.white),
                  onPressed: () {
                    setState(() {
                      _slowAnimations = !_slowAnimations;
                      timeDilation = _slowAnimations ? 5.0 : 1.0;
                    });
                  },
                  tooltip: 'Slow Animations',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
