import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // ⚠️ REPLACE WITH YOUR ACTUAL WEB CLIENT ID FROM GOOGLE CLOUD CONSOLE
    serverClientId: '305271525087-dm6gs10ekd35usvf4k6keoadub38nqln.apps.googleusercontent.com',
  );

  static Future<Map<String, dynamic>?> signIn() async {
    try {
      print('🔵 Starting Google Sign-In...');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('🔵 Google Sign-In cancelled by user');
        return null;
      }

      print('🔵 Google user selected: ${googleUser.email}');

      // Get authentication
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      print('🔵 Google authentication obtained');

      return {
        'id': googleUser.id,
        'email': googleUser.email,
        'name': googleUser.displayName,
        'photoUrl': googleUser.photoUrl,
        'idToken': googleAuth.idToken,
        'accessToken': googleAuth.accessToken,
      };
    } catch (e) {
      print('❌ Google Sign-In error: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      print('🔵 Google Sign-Out successful');
    } catch (e) {
      print('❌ Google Sign-Out error: $e');
      rethrow;
    }
  }

  static Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  static Future<GoogleSignInAccount?> getCurrentUser() async {
    return _googleSignIn.currentUser;
  }
}