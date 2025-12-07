import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';

class ReceiverForm extends StatefulWidget {
  const ReceiverForm({super.key});

  @override
  _ReceiverFormState createState() => _ReceiverFormState();
}

class _ReceiverFormState extends State<ReceiverForm> {
  final _organizationNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _organizationNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _registrationNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_organizationNameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _registrationNumberController.text.isEmpty) {
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
      final result = await apiService.updateProfile({
        'userType': 'receiver',
        'organizationName': _organizationNameController.text,
        'registrationNumber': _registrationNumberController.text,
        'phone': _phoneController.text,
        'city': _cityController.text,
      });

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        // Navigate to receiver dashboard
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
            '/receiver-dashboard',
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
          'Receiver Registration',
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
                  hintText: 'Hope Foundation',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              SizedBox(height: 30),

              // Registration Number
              Text(
                'REGISTRATION NUMBER',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _registrationNumberController,
                decoration: InputDecoration(
                  hintText: 'NGO123456',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  hintText: '+9779800000000',
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
                  hintText: 'Kathmandu',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    backgroundColor: Colors.orange,
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