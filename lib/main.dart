import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Service
import 'package:annadaan/services/api_service.dart';

// Screens
import 'package:annadaan/views/pages/splash_screen.dart';
import 'package:annadaan/views/pages/login_screen.dart';
import 'package:annadaan/views/pages/signup_page.dart';
import 'package:annadaan/views/pages/role_selection_screen.dart';
import 'package:annadaan/views/donor_pages/donor_form.dart';
import 'package:annadaan/views/receiver_pages/receiver_form.dart';
import 'package:annadaan/views/donor_pages/donor_dashboard.dart';
import 'package:annadaan/views/receiver_pages/receiver_dashboard.dart';
import 'package:annadaan/views/donor_pages/post_donation_screen.dart';
import 'package:annadaan/views/donor_pages/donation_history_screen.dart';
import 'package:annadaan/views/donor_pages/active_donations_screen.dart';
import 'package:annadaan/views/donor_pages/impact_screen.dart';
import 'package:annadaan/views/pages/notifications_screen.dart';
import 'package:annadaan/views/pages/profile_screen.dart';
import 'package:annadaan/views/pages/edit_profile_screen.dart';
import 'package:annadaan/views/pages/settings_screen.dart';
import 'package:annadaan/views/pages/help_support_screen.dart';
import 'package:annadaan/views/pages/about_screen.dart';
import 'package:annadaan/views/receiver_pages/receiver_browse_screen.dart';
import 'package:annadaan/views/pages/otp_verification_screen.dart';
import 'package:annadaan/views/pages/forgot_password_screen.dart';
import 'package:annadaan/views/pages/reset_password_screen.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    runApp(
      MultiProvider(
        providers: [
          /// ⭐ IMPORTANT: ApiService initializes before SplashScreen
          ChangeNotifierProvider(
            create: (_) => ApiService()..initialize(),
          ),
        ],
        child: const Annadaan(),
      ),
    );
  }, (error, stackTrace) {
    if (kDebugMode) {
      print('ZONE ERROR: $error');
    }
  });
}

class Annadaan extends StatelessWidget {
  const Annadaan({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AnnaDaan',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: _textTheme(),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/donor-form': (context) => const DonorForm(),
        '/receiver-form': (context) => const ReceiverForm(),
        '/donor-dashboard': (context) => const DonorDashboard(),
        '/receiver-dashboard': (context) => const ReceiverDashboard(),
        '/post-donation': (context) => const PostDonationScreen(),
        '/donation-history': (context) => const DonationHistoryScreen(),
        '/active-donations': (context) => const ActiveDonationsScreen(),
        '/impact-screen': (context) => const ImpactScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/profile-screen': (context) => const ProfileScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/help-support': (context) => const HelpSupportScreen(),
        '/about': (context) => const AboutScreen(),
        '/receiver_browse': (context) => const ReceiverBrowseScreen(),
        '/verify-otp': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return OtpVerificationScreen(
            email: args['email'],
            userId: args['userId'] ?? '',
            isPasswordReset: args['isPasswordReset'] ?? false,
          );
        },
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ResetPasswordScreen(
            email: args['email'],
            otp: args['otp'],
          );
        },
      },
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child ?? const Center(child: Text("Loading...")),
        );
      },
    );
  }

  static TextTheme _textTheme() {
    try {
      return GoogleFonts.poppinsTextTheme();
    } catch (e) {
      return Typography.material2018().englishLike;
    }
  }
}
