import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';
import '../donor_pages/donor_dashboard.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBottomNav;
  
  const ProfileScreen({super.key, this.showBottomNav = true});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 3;
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      setState(() {
        _userProfile = apiService.userProfile;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: widget.showBottomNav ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DonorDashboard()),
            );
          },
        ) : null,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(),
            const SizedBox(height: 32),

            // Menu Items
            _buildMenuItems(),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav ? _buildBottomNavigationBar() : null,
    );
  }

  Widget _buildProfileHeader() {
    final name = _userProfile?['name'] ?? 'User';
    final email = _userProfile?['email'] ?? '';
    final userType = _userProfile?['userType'] ?? 'donor';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Profile Picture
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF2E7D32),
            backgroundImage: _userProfile?['profilePicture'] != null
                ? NetworkImage('${ApiService.baseUrl}/api/upload/${_userProfile!['profilePicture']}')
                : null,
            child: _userProfile?['profilePicture'] == null
                ? Icon(
                    userType == 'donor' ? Icons.restaurant : Icons.business,
                    size: 40,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(height: 16),

          // User/Organization Name
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),

          // Email
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),

          // Verification Badge - Dynamic based on status
          _buildVerificationBadge(userType),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge(String userType) {
    final verificationStatus = _userProfile?['verificationStatus'];
    
    // Determine badge color, icon, and text based on status
    Color badgeColor;
    Color backgroundColor;
    IconData icon;
    String text;

    switch (verificationStatus) {
      case 'approved':
      case 'verified':
        // Verified status - green
        badgeColor = const Color(0xFF2E7D32);
        backgroundColor = const Color(0xFFE8F5E9);
        icon = Icons.verified;
        text = 'Verified ${userType == 'donor' ? 'Donor' : 'Receiver'}';
        break;
      case 'pending':
        // Pending status - orange/amber
        badgeColor = const Color(0xFFF57C00);
        backgroundColor = const Color(0xFFFFF3E0);
        icon = Icons.hourglass_empty;
        text = 'Verification Pending';
        break;
      case 'rejected':
        // Rejected status - red
        badgeColor = const Color(0xFFD32F2F);
        backgroundColor = const Color(0xFFFFEBEE);
        icon = Icons.cancel;
        text = 'Verification Required';
        break;
      default:
        // No verification document or null status - grey
        badgeColor = Colors.grey.shade600;
        backgroundColor = Colors.grey.shade100;
        icon = Icons.info_outline;
        text = 'Not Verified';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: badgeColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    return Column(
      children: [
        _buildMenuItem(
          Icons.edit,
          'Edit Profile',
          Colors.grey.shade700,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditProfileScreen()),
            );
          },
        ),
        _buildMenuItem(
          Icons.settings,
          'Settings',
          Colors.grey.shade700,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        _buildMenuItem(
          Icons.help,
          'Help & Support',
          Colors.grey.shade700,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
            );
          },
        ),
        _buildMenuItem(
          Icons.info,
          'About AnnaDaan',
          Colors.grey.shade700,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutScreen()),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildMenuItem(
          Icons.logout,
          'Logout',
          Colors.red,
          () async {
            // Show confirmation dialog
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout', style: TextStyle(fontFamily: 'Poppins')),
                content: const Text('Are you sure you want to logout?', style: TextStyle(fontFamily: 'Poppins')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Logout', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );

            if (shouldLogout == true) {
              final apiService = Provider.of<ApiService>(context, listen: false);
              await apiService.logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: color,
                  fontWeight: title == 'Logout' ? FontWeight.w600 : FontWeight.normal,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x33AAAAAA),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => _handleNavigation(index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.diamond), label: 'Active'),
          BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Impact'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/donor-dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/active-donations');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/impact-screen');
        break;
      case 3:
        // Already on profile
        break;
    }
  }
}