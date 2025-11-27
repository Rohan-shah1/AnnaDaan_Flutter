import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'google_signin_service.dart';

class ApiService with ChangeNotifier {
  // Production backend URL
  static const String baseUrl = 'https://annadaan-backend.onrender.com';

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;
  Map<String, dynamic>? _userProfile;
  bool _isLoggedIn = false;
  bool _isInitialized = false;

  // Getters
  String? get token => _token;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;

  // Location
  Map<String, double>? _currentLocation;
  Map<String, double>? get currentLocation => _currentLocation;

  void setCurrentLocation(double lat, double lng) {
    _currentLocation = {'lat': lat, 'lng': lng};
    notifyListeners();
    print('📍 Location updated in ApiService: $_currentLocation');
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');

      if (_token != null) {
        _isLoggedIn = true;
        // Try to get user profile
        await _getUserProfile();
      }

      _isInitialized = true;
      notifyListeners();

      print('🔵 ApiService initialized - loggedIn: $_isLoggedIn');
    } catch (e) {
      print('❌ Error initializing ApiService: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Email registration
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        _handleAuthSuccess(data);
        return {'success': true, 'message': 'Registration successful'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Email login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _handleAuthSuccess(data);
        return {'success': true, 'message': 'Login successful'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Google authentication
  Future<Map<String, dynamic>> googleAuth(String idToken, String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'idToken': idToken,
          'accessToken': accessToken,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _handleAuthSuccess(data);
        return {'success': true, 'message': 'Google authentication successful'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Google authentication failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Handle successful authentication
  void _handleAuthSuccess(Map<String, dynamic> data) async {
    _token = data['token'];
    _userProfile = data['user'];
    _isLoggedIn = true;

    // Save token to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);

    notifyListeners();
    print('✅ Authentication successful - token saved');
  }

  // Get user profile
  Future<void> _getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _userProfile = data['user'];
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error getting user profile: $e');
    }
  }

  // ⭐ FIXED: Update Profile for EDITING (uses PATCH, no userType required)
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      // Use PATCH method for editing existing profiles
      final response = await http.patch(
        Uri.parse('$baseUrl/api/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: json.encode(profileData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Update local user profile
        _userProfile = data['user'];
        
        // Save to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile', json.encode(_userProfile));
        
        notifyListeners();
        return {
          'success': true,
          'message': data['message'] ?? 'Profile updated successfully',
          'user': data['user']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Profile update failed'
        };
      }
    } catch (e) {
      print('❌ Error updating profile: $e');
      return {
        'success': false,
        'message': 'Network error: $e'
      };
    }
  }

  // Complete Profile (for initial profile setup with userType - uses PUT)
  Future<Map<String, dynamic>> completeProfile(Map<String, dynamic> profileData) async {
    try {
      // Use PUT method for completing profile (includes userType)
      final response = await http.put(
        Uri.parse('$baseUrl/api/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: json.encode(profileData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _userProfile = data['user'];
        
        // Save to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile', json.encode(_userProfile));
        
        notifyListeners();
        return {
          'success': true,
          'message': 'Profile completed successfully',
          'user': data['user']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Profile completion failed'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e'
      };
    }
  }

  // Logout
  Future<void> logout() async {
    // Sign out from Google if signed in
    try {
      await GoogleSignInService.signOut();
    } catch (e) {
      print('⚠️ Error signing out from Google: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_profile');

    _token = null;
    _userProfile = null;
    _isLoggedIn = false;

    notifyListeners();
    print('✅ Logged out successfully');
  }

  // File Upload
  Future<Map<String, dynamic>> uploadFile(File file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/upload'));

      // Add authorization header if token exists
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      // Get file extension to determine content type
      String fileName = file.path.split('/').last;
      String extension = fileName.split('.').last.toLowerCase();
      
      MediaType mediaType;
      if (extension == 'jpg' || extension == 'jpeg') {
        mediaType = MediaType('image', 'jpeg');
      } else if (extension == 'png') {
        mediaType = MediaType('image', 'png');
      } else if (extension == 'gif') {
        mediaType = MediaType('image', 'gif');
      } else if (extension == 'pdf') {
        mediaType = MediaType('application', 'pdf');
      } else if (extension == 'docx') {
        mediaType = MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document');
      } else if (extension == 'doc') {
        mediaType = MediaType('application', 'msword');
      } else {
        mediaType = MediaType('application', 'octet-stream');
      }

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: mediaType,
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'file': data['file']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Upload failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ----------------- DONATIONS -----------------

  // Create Donation
  Future<Map<String, dynamic>> createDonation(Map<String, dynamic> donationData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/donations'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: json.encode(donationData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return {'success': true, 'message': 'Donation posted successfully', 'data': data['donation']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to post donation'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get My Donations (Donor)
  Future<List<dynamic>> getMyDonations({String? status, String? startDate, String? endDate}) async {
    try {
      String url = '$baseUrl/api/donations/my-donations';
      List<String> queryParams = [];
      
      if (status != null) queryParams.add('status=$status');
      if (startDate != null) queryParams.add('startDate=$startDate');
      if (endDate != null) queryParams.add('endDate=$endDate');
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['donations'] ?? [];
      } else {
        print('Failed to fetch my donations: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching my donations: $e');
      return [];
    }
  }

  // Get Nearby Donations (Receiver)
  Future<List<dynamic>> getNearbyDonations({double? lat, double? lng, double? maxDistance}) async {
    try {
      // Use stored location if not provided
      lat ??= _currentLocation?['lat'];
      lng ??= _currentLocation?['lng'];

      String url = '$baseUrl/api/donations/nearby/available';
      List<String> queryParams = [];
      
      if (lat != null) queryParams.add('lat=$lat');
      if (lng != null) queryParams.add('lng=$lng');
      if (maxDistance != null) queryParams.add('maxDistance=$maxDistance');
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['donations'] ?? [];
      } else {
        print('Failed to fetch nearby donations: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching nearby donations: $e');
      return [];
    }
  }

  // Get Single Donation
  Future<Map<String, dynamic>?> getDonation(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/donations/$id'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['donation'];
      } else {
        print('Failed to fetch donation: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching donation: $e');
      return null;
    }
  }

  // Update Donation
  Future<Map<String, dynamic>> updateDonation(String id, Map<String, dynamic> updateData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/donations/$id'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: json.encode(updateData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        notifyListeners();
        return {'success': true, 'message': 'Donation updated successfully', 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Update failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Delete Donation
  Future<Map<String, dynamic>> deleteDonation(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/donations/$id'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        notifyListeners();
        return {'success': true, 'message': 'Donation deleted successfully'};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Delete failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ----------------- RESERVATIONS -----------------

  // Create Reservation
  Future<Map<String, dynamic>> createReservation(String donationId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/reservations'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: json.encode({'donationId': donationId}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return {'success': true, 'message': 'Reservation successful', 'data': data['reservation']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Reservation failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get My Reservations (Receiver)
  Future<List<dynamic>> getMyReservations({String? status}) async {
    try {
      String url = '$baseUrl/api/reservations/my-reservations';
      if (status != null) {
        url += '?status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['reservations'] ?? [];
      } else {
        print('Failed to fetch my reservations: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching my reservations: $e');
      return [];
    }
  }

  // Get Reservations for a Donation (Donor)
  Future<List<dynamic>> getDonationReservations(String donationId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/reservations?donationId=$donationId'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        print('Failed to fetch donation reservations: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching donation reservations: $e');
      return [];
    }
  }

  // Update Reservation Status
  Future<Map<String, dynamic>> updateReservationStatus(String id, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/reservations/$id/status'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: json.encode({'status': status}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        notifyListeners();
        return {'success': true, 'message': 'Status updated successfully', 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Status update failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Upload Pickup Proof
  Future<Map<String, dynamic>> uploadPickupProof(String reservationId, File proofFile) async {
    try {
      // First upload the file
      final uploadResult = await uploadFile(proofFile);
      
      if (!uploadResult['success']) {
        return uploadResult;
      }

      // Then update the reservation with the file ID
      final response = await http.patch(
        Uri.parse('$baseUrl/api/reservations/$reservationId/pickup-proof'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: json.encode({'proofOfPickup': uploadResult['file']['_id']}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        notifyListeners();
        return {'success': true, 'message': 'Pickup proof uploaded successfully', 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Upload failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ----------------- NOTIFICATIONS -----------------

  // Get Notifications
  Future<List<dynamic>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        print('Failed to fetch notifications: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  // Mark Notification as Read
  Future<bool> markNotificationRead(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/notifications/$id/read'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notification read: $e');
      return false;
    }
  }

  // Register FCM Token
  Future<Map<String, dynamic>> registerFCMToken(String fcmToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications/register-token'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: json.encode({'fcmToken': fcmToken}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'FCM token registered'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Token registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ----------------- STATS -----------------

  // Get Impact Metrics
  Future<Map<String, dynamic>> getImpactMetrics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/stats/impact'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data['data']};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch impact metrics'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get Dashboard Stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/stats/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      } else {
        print('Failed to fetch dashboard stats: ${response.body}');
        return {};
      }
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      return {};
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
