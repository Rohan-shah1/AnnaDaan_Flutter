import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _currentIndex = 3;

  // Notification settings
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsAlerts = false;

  // Preference settings
  bool _autoNotifyNGOs = true;
  bool _allowQuantitySplitting = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notifications Section
            _buildSectionHeader('Notifications'),
            SizedBox(height: 16),
            _buildNotificationSettings(),
            SizedBox(height: 32),

            // Preferences Section
            _buildSectionHeader('Preferences'),
            SizedBox(height: 16),
            _buildPreferenceSettings(),
            SizedBox(height: 32),

            // App Version
            _buildAppVersion(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        fontFamily: 'Poppins',
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSettingSwitch(
              title: 'Push Notifications',
              subtitle: 'Receive app notifications for donations and requests',
              value: _pushNotifications,
              onChanged: (value) {
                setState(() {
                  _pushNotifications = value;
                });
              },
            ),
            Divider(height: 24),
            _buildSettingSwitch(
              title: 'Email Notifications',
              subtitle: 'Get email updates about your donation activities',
              value: _emailNotifications,
              onChanged: (value) {
                setState(() {
                  _emailNotifications = value;
                });
              },
            ),
            Divider(height: 24),
            _buildSettingSwitch(
              title: 'SMS Alerts',
              subtitle: 'Receive text messages for urgent updates',
              value: _smsAlerts,
              onChanged: (value) {
                setState(() {
                  _smsAlerts = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceSettings() {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSettingSwitch(
              title: 'Auto-notify Preferred NGOs',
              subtitle: 'Automatically notify your preferred NGOs about new donations',
              value: _autoNotifyNGOs,
              onChanged: (value) {
                setState(() {
                  _autoNotifyNGOs = value;
                });
              },
            ),
            Divider(height: 24),
            _buildSettingSwitch(
              title: 'Allow Quantity Splitting',
              subtitle: 'Allow NGOs to request partial quantities of your donations',
              value: _allowQuantitySplitting,
              onChanged: (value) {
                setState(() {
                  _allowQuantitySplitting = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Color(0xFF2E7D32),
        ),
      ],
    );
  }

  Widget _buildAppVersion() {
    return Center(
      child: Text(
        'AnnaDaan v1.0.0',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade500,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
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
        selectedItemColor: Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
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
        Navigator.pushReplacementNamed(context, '/profile-screen');
        break;
    }
  }
}