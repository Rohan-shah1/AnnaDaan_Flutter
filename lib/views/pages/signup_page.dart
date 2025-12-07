import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/google_signin_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signupWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.register(
        _fullNameController.text,
        _emailController.text,
        _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        if (result['requiresVerification'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please verify your email to continue.'),
              backgroundColor: Colors.blue,
            ),
          );
          
          Navigator.pushReplacementNamed(
            context, 
            '/verify-otp',
            arguments: {
              'email': _emailController.text,
              'userId': result['userId'] ?? '',
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign up successful! Please select your role.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacementNamed(context, '/role-selection');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Sign up failed'),
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
          content: Text('Sign up error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signupWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final googleData = await GoogleSignInService.signIn();

      if (googleData != null) {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final result = await apiService.googleAuth(
          googleData['idToken']!,
          googleData['accessToken']!,
        );

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google sign up successful! Please select your role.'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to role selection after successful Google signup
          Navigator.pushReplacementNamed(context, '/role-selection');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Google sign up failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      String errorMessage = 'Google Sign-In failed';
      if (e.toString().contains('network_error') || e.toString().contains('SocketException')) {
        errorMessage = 'Network error, check the internet';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGoogleLoading = false;
      });
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 40),
              
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Full name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your full name',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Work email',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Enter your work email',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Create a password',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signupWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              _buildGoogleButton(),
              const SizedBox(height: 30),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: _isGoogleLoading ? null : _signupWithGoogle,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isGoogleLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/google-logo.jpg',
                    height: 24,
                    width: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.g_mobiledata, color: Colors.grey[600]);
                    },
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sign up with Google',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}