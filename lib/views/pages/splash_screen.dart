import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  void _navigateToLogin() async {
    // Wait for ApiService to initialize
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    // Wait a bit for splash effect and initialization
    await Future.delayed(Duration(seconds: 2));
    
    // Ensure ApiService is initialized
    int retries = 0;
    while (!apiService.isInitialized && retries < 5) {
      await Future.delayed(Duration(milliseconds: 500));
      retries++;
    }

    if (mounted) {
      if (apiService.isLoggedIn && apiService.userProfile != null) {
        _navigateBasedOnRole(apiService);
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  void _navigateBasedOnRole(ApiService apiService) {
    final userProfile = apiService.userProfile!;
    
    // Admin bypasses profile completion check
    if (userProfile['userType'] == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
      return;
    }

    if (userProfile['profileCompleted'] == true) {
      if (userProfile['userType'] == 'donor') {
        Navigator.pushReplacementNamed(context, '/donor-dashboard');
      } else if (userProfile['userType'] == 'receiver') {
        Navigator.pushReplacementNamed(context, '/receiver-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/role-selection');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/role-selection');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFE3F2FD)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.restaurant,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 40),
                Text(
                  'AnnaDaan',
                  style: _getTextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        blurRadius: 2,
                        color: Colors.black12,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Connecting Food • Feeding • Hope',
                  style: _getTextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Get text style with fallback
  TextStyle _getTextStyle({
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    List<Shadow>? shadows,
  }) {
    try {
      return GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        shadows: shadows,
      );
    } catch (e) {
      // Fallback to default style if Google Fonts fails
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        shadows: shadows,
      );
    }
  }
}

// Simple error screen as fallback
class _ErrorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Unable to load app'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}