import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  
  // State
  File? _selectedProfileImage;
  File? _selectedVerificationDoc;
  String? _existingProfilePic;
  String? _existingVerificationDoc;
  String? _verificationStatus;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _documentDeleted = false; // Track if user explicitly deleted document

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final profile = apiService.userProfile;
    
    if (profile != null) {
      setState(() {
        _nameController.text = profile['name'] ?? '';
        _phoneController.text = profile['phone'] ?? '';
        _addressController.text = profile['address'] ?? '';
        _cityController.text = profile['city'] ?? '';
        _existingProfilePic = profile['profilePicture'];
        _existingVerificationDoc = profile['verificationDocument'];
        _verificationStatus = profile['verificationStatus'];
        _isLoading = false;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedProfileImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickVerificationDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'docx'],
      );

      if (result != null) {
        setState(() {
          _selectedVerificationDoc = File(result.files.single.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking document: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _openDocumentPreview() async {
    if (_existingVerificationDoc == null) return;
    
    final url = '${ApiService.baseUrl}/api/upload/$_existingVerificationDoc';
    final uri = Uri.parse(url);
    
    try {
      // Open in external browser
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to open document: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Upload profile image if selected
      String? profilePicId = _existingProfilePic;
      if (_selectedProfileImage != null) {
        final uploadResult = await apiService.uploadFile(_selectedProfileImage!);
        if (uploadResult['success'] == true) {
          profilePicId = uploadResult['file']['_id'];
        }
      }

      // Upload verification document if selected
      String? verificationDocId = _existingVerificationDoc;
      if (_selectedVerificationDoc != null) {
        final uploadResult = await apiService.uploadFile(_selectedVerificationDoc!);
        if (uploadResult['success'] == true) {
          verificationDocId = uploadResult['file']['_id'];
        }
      }

      // Update profile
      final Map<String, dynamic> payload = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'city': _cityController.text,
      };

      if (profilePicId != null) {
        payload['profilePicture'] = profilePicId;
      }

      // Handle verification document
      if (_documentDeleted) {
        // User deleted the document - explicitly set to null
        payload['verificationDocument'] = null;
        payload['verificationStatus'] = null;
      } else if (verificationDocId != null) {
        // Document exists (either new or existing)
        payload['verificationDocument'] = verificationDocId;
        // Set status to pending when new document is uploaded
        if (_selectedVerificationDoc != null) {
          payload['verificationStatus'] = 'pending';
        }
      }

      final result = await apiService.updateProfile(payload);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to update profile'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              _buildProfilePictureSection(),
              const SizedBox(height: 24),
              
              // Basic Information
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Verification Document Section
              _buildVerificationSection(),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins'),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
    );
  }

  Widget _buildProfilePictureSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickProfileImage,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[300],
              backgroundImage: _selectedProfileImage != null
                  ? FileImage(_selectedProfileImage!)
                  : _existingProfilePic != null
                      ? NetworkImage('${ApiService.baseUrl}/api/upload/$_existingProfilePic')
                      : null,
              child: _selectedProfileImage == null && _existingProfilePic == null
                  ? const Icon(Icons.person, size: 60, color: Colors.grey)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _pickProfileImage,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Change Photo'),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionTitle('Verification Document'),
            const SizedBox(width: 8),
            if (_verificationStatus != null) _buildVerificationBadge(),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Upload ID, license, or official documents for verification',
          style: TextStyle(fontSize: 14, color: Colors.grey[600], fontFamily: 'Poppins'),
        ),
        const SizedBox(height: 12),
        
        if (_selectedVerificationDoc != null || _existingVerificationDoc != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _selectedVerificationDoc != null
                          ? Icons.insert_drive_file
                          : Icons.cloud_done,
                      color: const Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedVerificationDoc != null
                            ? _selectedVerificationDoc!.path.split('/').last
                            : 'Document uploaded',
                        style: const TextStyle(fontFamily: 'Poppins'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _selectedVerificationDoc = null;
                          _existingVerificationDoc = null;
                          _documentDeleted = true; // Mark as deleted
                        });
                      },
                    ),
                  ],
                ),
                if (_existingVerificationDoc != null && _selectedVerificationDoc == null) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _openDocumentPreview(),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            '${ApiService.baseUrl}/api/upload/$_existingVerificationDoc',
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 100,
                                width: double.infinity,
                                color: Colors.grey[200],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.description, size: 40, color: Colors.grey),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to view document',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Tap to preview',
                                  style: TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_selectedVerificationDoc != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedVerificationDoc!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 100,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.description, size: 40, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text(
                                'Preview Unavailable',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        
        const SizedBox(height: 12),
        
        OutlinedButton.icon(
          onPressed: _pickVerificationDocument,
          icon: const Icon(Icons.upload_file),
          label: Text(_selectedVerificationDoc != null || _existingVerificationDoc != null
              ? 'Change Document'
              : 'Upload Document'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2E7D32),
            side: const BorderSide(color: Color(0xFF2E7D32)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Supported formats: JPG, PNG, PDF, DOCX',
          style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'Poppins'),
        ),
      ],
    );
  }

  Widget _buildVerificationBadge() {
    Color color;
    String text;
    IconData icon;

    switch (_verificationStatus) {
      case 'pending':
        color = Colors.orange;
        text = 'PENDING';
        icon = Icons.schedule;
        break;
      case 'verified':
        color = Colors.green;
        text = 'VERIFIED';
        icon = Icons.verified;
        break;
      case 'rejected':
        color = Colors.red;
        text = 'REJECTED';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        text = 'NOT VERIFIED';
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }
}
