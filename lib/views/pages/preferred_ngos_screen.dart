import 'package:flutter/material.dart';

class PreferredNgosScreen extends StatefulWidget {
  const PreferredNgosScreen({super.key});

  @override
  _PreferredNgosScreenState createState() => _PreferredNgosScreenState();
}

class _PreferredNgosScreenState extends State<PreferredNgosScreen> {
  int _currentIndex = 3;

  final List<Map<String, dynamic>> _ngos = [
    {
      'id': '1',
      'name': 'Hope Foundation',
      'pickups': '15 successful pickups',
      'isPreferred': true,
      'phone': '+918978512345',
      'email': 'hope@foundation.org',
      'address': '123 Main Street, City',
    },
    {
      'id': '2',
      'name': 'Community Shelter',
      'pickups': '8 successful pickups',
      'isPreferred': false,
      'phone': '+919876543210',
      'email': 'contact@communityshelter.org',
      'address': '456 Oak Avenue, City',
    },
    {
      'id': '3',
      'name': 'Homeless Shelter',
      'pickups': '12 successful pickups',
      'isPreferred': true,
      'phone': '+917654321098',
      'email': 'info@homelessshelter.org',
      'address': '789 Pine Road, City',
    },
    {
      'id': '4',
      'name': 'Children Home',
      'pickups': '6 successful pickups',
      'isPreferred': false,
      'phone': '+916543210987',
      'email': 'care@childrenhome.org',
      'address': '321 Elm Street, City',
    },
  ];

  void _togglePreferred(int index) {
    setState(() {
      _ngos[index]['isPreferred'] = !_ngos[index]['isPreferred'];
    });
  }

  void _showNgoProfile(Map<String, dynamic> ngo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(ngo['name'], style: TextStyle(fontFamily: 'Poppins')),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildProfileDetail('Successful Pickups', ngo['pickups']),
                _buildProfileDetail('Phone', ngo['phone']),
                _buildProfileDetail('Email', ngo['email']),
                _buildProfileDetail('Address', ngo['address']),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'This NGO has received ${ngo['pickups']} from you.',
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileDetail(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontFamily: 'Poppins')),
        ],
      ),
    );
  }

  void _contactNgo(Map<String, dynamic> ngo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Contact ${ngo['name']}', style: TextStyle(fontFamily: 'Poppins')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(Icons.phone, color: Color(0xFF2E7D32)),
                title: Text('Call', style: TextStyle(fontFamily: 'Poppins')),
                subtitle: Text(ngo['phone'], style: TextStyle(fontFamily: 'Poppins')),
                onTap: () {
                  // TODO: Implement phone call
                  Navigator.of(context).pop();
                  _showMessage('Calling ${ngo['phone']}');
                },
              ),
              ListTile(
                leading: Icon(Icons.email, color: Color(0xFF2E7D32)),
                title: Text('Email', style: TextStyle(fontFamily: 'Poppins')),
                subtitle: Text(ngo['email'], style: TextStyle(fontFamily: 'Poppins')),
                onTap: () {
                  // TODO: Implement email
                  Navigator.of(context).pop();
                  _showMessage('Opening email to ${ngo['email']}');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: 'Poppins')),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Preferred NGOs',
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
            Text(
              'Mark NGOs as preferred to notify them first.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 24),

            // NGOs List
            _buildNgosList(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildNgosList() {
    return Column(
      children: _ngos.map((ngo) {
        return Column(
          children: [
            _buildNgoCard(ngo),
            SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildNgoCard(Map<String, dynamic> ngo) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NGO Name and Preferred Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ngo['name'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  final index = _ngos.indexWhere((n) => n['id'] == ngo['id']);
                  _togglePreferred(index);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ngo['isPreferred'] ? Color(0xFF2E7D32) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ngo['isPreferred'] ? 'PREFERRED' : 'MARK PREFERRED',
                    style: TextStyle(
                      color: ngo['isPreferred'] ? Colors.white : Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8),

          // Pickup stats
          Text(
            ngo['pickups'],
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontFamily: 'Poppins',
            ),
          ),

          SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showNgoProfile(ngo),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Color(0xFF2E7D32)),
                  ),
                  child: Text(
                    'View Profile',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _contactNgo(ngo),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2E7D32),
                  ),
                  child: Text(
                    'Contact',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
      // Already on preferred NGOs screen
        break;
    }
  }
}