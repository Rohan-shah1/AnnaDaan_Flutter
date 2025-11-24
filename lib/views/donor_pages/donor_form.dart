import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../pages/location_picker.dart';

class DonorForm extends StatefulWidget {
  const DonorForm({super.key});

  @override
  _DonorFormState createState() => _DonorFormState();
}

class _DonorFormState extends State<DonorForm> {
  final _organizationNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  String? _selectedOrganizationType;
  bool _isLoading = false;

  // Map display names to backend enum values
  final Map<String, String> _organizationTypesMap = {
    'Restaurant': 'restaurant',
    'Large Vegetable Market': 'large_vegetable_market',
    'Party Palace': 'party_palace',
    'Event Venue': 'event_venue',
    'Catering Service': 'catering',
  };

  @override
  void dispose() {
    _organizationNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_organizationNameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _selectedOrganizationType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Convert display name to backend enum value
      final backendValue = _organizationTypesMap[_selectedOrganizationType];
      
      final result = await apiService.updateProfile({
        'userType': 'donor',
        'organizationName': _organizationNameController.text,
        'organizationType': backendValue, // Send backend-compatible value
        'phone': _phoneController.text,
        'city': _cityController.text,
      });

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        // Navigate to donor dashboard
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
            '/donor-dashboard',
            (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to complete profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/role-selection');
          },
        ),
        title: Text(
          'Donor Registration',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text(
                'Join us in reducing food waste',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade700,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 40),

              // Organization Name
              Text(
                'ORGANIZATION NAME',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _organizationNameController,
                decoration: InputDecoration(
                  hintText: 'Taj Restaurant',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              SizedBox(height: 30),

              // Organization Type
              Text(
                'ORGANIZATION TYPE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedOrganizationType,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                    hint: Text('Select type'),
                    items: _organizationTypesMap.keys.map((String displayName) {
                      return DropdownMenuItem<String>(
                        value: displayName,
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedOrganizationType = newValue;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 30),

              // Phone Number
              Text(
                'PHONE NUMBER',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '+918676543210',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              SizedBox(height: 30),

              // City
              Text(
                'CITY',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _cityController,
                decoration: InputDecoration(
                  hintText: 'Mumbai',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.map),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LocationPicker()),
                      );
                      
                      if (result != null && result is Map) {
                        setState(() {
                          if (result['address'] != null) {
                            _cityController.text = result['address'];
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: 50),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}