import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../pages/location_picker.dart';

class PostDonationScreen extends StatefulWidget {
  final Map<String, dynamic>? donation;

  const PostDonationScreen({super.key, this.donation});

  @override
  _PostDonationScreenState createState() => _PostDonationScreenState();
}

class _PostDonationScreenState extends State<PostDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Controllers for form fields
  final TextEditingController _foodDescriptionController = TextEditingController();
  final TextEditingController _quantityValueController = TextEditingController();
  DateTime? _pickupStartTime;
  DateTime? _pickupEndTime;
  final TextEditingController _additionalNotesController = TextEditingController();
  // Location controllers
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _latController = TextEditingController(text: '27.7172'); // Default Kathmandu
  final TextEditingController _lngController = TextEditingController(text: '85.3240');

  // Selections
  String? _selectedFoodType;
  String _selectedQuantityUnit = 'kg';
  String? _selectedDietaryInfo;
  
  // Image selection
  File? _selectedImage;
  String? _existingImageId;

  // Map display names to backend enum values
  final Map<String, String> _foodTypesMap = {
    'Cooked Vegetarian': 'cooked_meals_veg',
    'Cooked Non-Vegetarian': 'cooked_meals_nonveg',
    'Fruits':'fruits',
    'Vegetables':'vegetables',
    'Bakery':'bakery',
    'Dairy':'dairy',
  };



  // Safety checklist
  final Map<String, bool> _foodSafetyChecklist = {
    'Stored at safe temperature': false,
    'Properly packaged/covered': false,
    'Fresh and good quality': false,
    'Labeled with prep time': false,
  };

  @override
  void initState() {
    super.initState();
    if (widget.donation != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final d = widget.donation!;
    
    // Food Description
    _foodDescriptionController.text = d['foodDescription'] ?? '';
    
    // Quantity
    if (d['quantity'] != null) {
      _quantityValueController.text = d['quantity']['value']?.toString() ?? '';
      _selectedQuantityUnit = d['quantity']['unit'] ?? 'kg';
    }

    // Food Type (Reverse lookup)
    final backendType = d['foodType'];
    _selectedFoodType = _foodTypesMap.entries
        .firstWhere((entry) => entry.value == backendType, orElse: () => const MapEntry('', ''))
        .key;
    if (_selectedFoodType == '') _selectedFoodType = null;

    // Existing food image
    _existingImageId = d['foodImage'];

    // Location
    if (d['location'] != null) {
      _addressController.text = d['location']['address'] ?? '';
      _cityController.text = d['location']['city'] ?? '';
      if (d['location']['coordinates'] != null) {
        _latController.text = d['location']['coordinates']['lat']?.toString() ?? '';
        _lngController.text = d['location']['coordinates']['lng']?.toString() ?? '';
      }
    }

    // Timing
    if (d['pickupWindow'] != null) {
      if (d['pickupWindow']['start'] != null) {
        _pickupStartTime = DateTime.parse(d['pickupWindow']['start']);
      }
      if (d['pickupWindow']['end'] != null) {
        _pickupEndTime = DateTime.parse(d['pickupWindow']['end']);
      }
    }

    // Safety Checklist
    if (d['safetyChecklist'] != null) {
      _foodSafetyChecklist['Stored at safe temperature'] = d['safetyChecklist']['temperatureChecked'] ?? false;
      _foodSafetyChecklist['Properly packaged/covered'] = d['safetyChecklist']['properlyPackaged'] ?? false;
      _foodSafetyChecklist['Fresh and good quality'] = true;
      _foodSafetyChecklist['Labeled with prep time'] = d['safetyChecklist']['labeled'] ?? false;
    }

    // Additional Notes
    _additionalNotesController.text = d['additionalNotes'] ?? '';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source', style: TextStyle(fontFamily: 'Poppins')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
              title: const Text('Camera', style: TextStyle(fontFamily: 'Poppins')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF2E7D32)),
              title: const Text('Gallery', style: TextStyle(fontFamily: 'Poppins')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _foodDescriptionController.dispose();
    _quantityValueController.dispose();
    _additionalNotesController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  // Helper to build section titles
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Poppins'),
    );
  }

  // Image selection section
  Widget _imageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedImage != null || _existingImageId != null) ...[
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              image: _selectedImage != null
                  ? DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    )
                  : _existingImageId != null
                      ? DecorationImage(
                          image: NetworkImage('${ApiService.baseUrl}/api/upload/$_existingImageId'),
                          fit: BoxFit.cover,
                        )
                      : null,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showImageSourceDialog,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text(_selectedImage != null || _existingImageId != null ? 'Change Photo' : 'Add Food Photo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_selectedImage != null || _existingImageId != null) ...[
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                    _existingImageId = null;
                  });
                },
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // Food type selector
  Widget _foodTypeSection() {
    return Column(
      children: _foodTypesMap.keys.map((displayName) {
        return RadioListTile<String>(
          title: Text(displayName, style: const TextStyle(fontFamily: 'Poppins')),
          value: displayName,
          groupValue: _selectedFoodType,
          onChanged: (value) => setState(() => _selectedFoodType = value),
        );
      }).toList(),
    );
  }

  // Food details fields
  Widget _foodDetailsSection() {
    return Column(
      children: [
        TextFormField(
          controller: _foodDescriptionController,
          decoration: const InputDecoration(
            labelText: 'FOOD DESCRIPTION',
            hintText: 'e.g. Rice, Dal, Vegetables',
            border: OutlineInputBorder(),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Enter food description' : null,
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _quantityValueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'QUANTITY',
                  hintText: '20',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter quantity' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: _selectedQuantityUnit,
                decoration: const InputDecoration(
                  labelText: 'UNIT',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                ),
                isExpanded: true,
                items: ['kg', 'portions', 'boxes', 'crates'].map((unit) {
                  return DropdownMenuItem(value: unit, child: Text(unit, overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: (value) => setState(() => _selectedQuantityUnit = value!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Timing fields with date-time picker
  Widget _timingSection() {
    return Column(
      children: [
        ListTile(
          title: const Text('Pickup Start Time', style: TextStyle(fontFamily: 'Poppins')),
          subtitle: Text(
            _pickupStartTime != null 
                ? '${_pickupStartTime!.toLocal()}'.split('.')[0]
                : 'Select start time',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final now = DateTime.now();
            final dateTime = await showDatePicker(
              context: context,
              initialDate: _pickupStartTime ?? now,
              firstDate: now.subtract(const Duration(seconds: 1)), // Allow today
              lastDate: now.add(const Duration(days: 7)),
            );
            if (dateTime != null) {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_pickupStartTime ?? now),
                builder: (BuildContext context, Widget? child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  );
                },
              );
              if (time != null) {
                final selectedDateTime = DateTime(
                  dateTime.year,
                  dateTime.month,
                  dateTime.day,
                  time.hour,
                  time.minute,
                );
                
                // Validate that the selected time hasn't passed
                if (selectedDateTime.isBefore(now)) {
                  final formattedDateTime = '${dateTime.day}/${dateTime.month}/${dateTime.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Selected time ($formattedDateTime) has already passed. Please select a future time.'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                  return;
                }
                
                setState(() {
                  _pickupStartTime = selectedDateTime;
                });
              }
            }
          },
        ),
        const SizedBox(height: 10),
        ListTile(
          title: const Text('Pickup End Time', style: TextStyle(fontFamily: 'Poppins')),
          subtitle: Text(
            _pickupEndTime != null 
                ? '${_pickupEndTime!.toLocal()}'.split('.')[0]
                : 'Select end time',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final now = DateTime.now();
            final dateTime = await showDatePicker(
              context: context,
              initialDate: _pickupEndTime ?? _pickupStartTime ?? now,
              firstDate: _pickupStartTime ?? now.subtract(const Duration(seconds: 1)), // Allow today
              lastDate: now.add(const Duration(days: 7)),
            );
            if (dateTime != null) {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_pickupEndTime ?? now),
                builder: (BuildContext context, Widget? child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  );
                },
              );
              if (time != null) {
                final selectedDateTime = DateTime(
                  dateTime.year,
                  dateTime.month,
                  dateTime.day,
                  time.hour,
                  time.minute,
                );
                
                // Validate that the selected time hasn't passed
                if (selectedDateTime.isBefore(now)) {
                  final formattedDateTime = '${dateTime.day}/${dateTime.month}/${dateTime.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Selected time ($formattedDateTime) has already passed. Please select a future time.'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                  return;
                }
                
                // Validate that end time is after start time
                if (_pickupStartTime != null && selectedDateTime.isBefore(_pickupStartTime!)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('End time must be after start time'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                setState(() {
                  _pickupEndTime = selectedDateTime;
                });
              }
            }
          },
        ),
      ],
    );
  }

  // Location section
  Widget _locationSection() {
    return Column(
      children: [
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'ADDRESS',
            hintText: 'Street address',
            border: OutlineInputBorder(),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Enter address' : null,
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LocationPicker()),
              );
              
              if (result != null && result is Map) {
                setState(() {
                  if (result['address'] != null) {
                    _addressController.text = result['address'];
                    final parts = result['address'].toString().split(', ');
                    if (parts.length >= 3) {
                      _cityController.text = parts[2];
                    }
                  }
                  if (result['location'] != null && result['location'] is LatLng) {
                    _latController.text = (result['location'] as LatLng).latitude.toString();
                    _lngController.text = (result['location'] as LatLng).longitude.toString();
                  }
                });
              }
            },
            icon: const Icon(Icons.map, color: Color(0xFF2E7D32)),
            label: const Text('Pick on Map', style: TextStyle(color: Color(0xFF2E7D32), fontFamily: 'Poppins')),
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: _cityController,
          decoration: const InputDecoration(
            labelText: 'CITY',
            hintText: 'Kathmandu',
            border: OutlineInputBorder(),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Enter city' : null,
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _latController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'LATITUDE',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter latitude' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _lngController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'LONGITUDE',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter longitude' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Safety checklist
  Widget _safetyChecklist() {
    return Column(
      children: _foodSafetyChecklist.keys.map((item) {
        return CheckboxListTile(
          title: Text(item, style: const TextStyle(fontFamily: 'Poppins')),
          value: _foodSafetyChecklist[item],
          onChanged: (value) => setState(() => _foodSafetyChecklist[item] = value ?? false),
        );
      }).toList(),
    );
  }

  // Dietary info selector
  Widget _dietaryInfoSection() {
    const options = ['Vegetarian', 'Non-Veg', 'Vegan', 'Mixed'];
    return Column(
      children: options.map((option) {
        return RadioListTile<String>(
          title: Text(option, style: const TextStyle(fontFamily: 'Poppins')),
          value: option,
          groupValue: _selectedDietaryInfo,
          onChanged: (value) => setState(() => _selectedDietaryInfo = value),
        );
      }).toList(),
    );
  }

  // Additional notes
  Widget _additionalNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ADDITIONAL NOTES (OPTIONAL)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey, fontFamily: 'Poppins')),
        const SizedBox(height: 8),
        const Text('Any special instructions, allergen info, etc.', style: TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Poppins')),
        const SizedBox(height: 10),
        TextFormField(
          controller: _additionalNotesController,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter any additional notes...',
          ),
        ),
      ],
    );
  }

  // Post/Update button
  Widget _postButton() {
    final isEditing = widget.donation != null;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () async {
          if (_formKey.currentState!.validate() && 
              _selectedFoodType != null && 
              (_selectedDietaryInfo != null || isEditing) &&
              _pickupStartTime != null &&
              _pickupEndTime != null) {
            
            final api = Provider.of<ApiService>(context, listen: false);
            
            // Convert display name to backend enum value
            final backendFoodType = _foodTypesMap[_selectedFoodType];
            
            // Upload image if selected
            String? foodImageId = _existingImageId;
            if (_selectedImage != null) {
              final uploadResult = await api.uploadFile(_selectedImage!);
              if (uploadResult['success'] == true) {
                foodImageId = uploadResult['file']['_id'];
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Image upload failed: ${uploadResult['message']}'), backgroundColor: Colors.red),
                );
                return;
              }
            }
            
            final payload = {
              'foodType': backendFoodType,
              'foodDescription': _foodDescriptionController.text,
              'quantity': {
                'value': int.parse(_quantityValueController.text),
                'unit': _selectedQuantityUnit,
              },
              'location': {
                'address': _addressController.text,
                'city': _cityController.text,
                'coordinates': {
                  'lat': double.parse(_latController.text),
                  'lng': double.parse(_lngController.text),
                },
              },
              'pickupWindow': {
                'start': _pickupStartTime!.toIso8601String(),
                'end': _pickupEndTime!.toIso8601String(),
              },
              'safetyChecklist': {
                'temperatureChecked': _foodSafetyChecklist['Stored at safe temperature'] ?? false,
                'properlyPackaged': _foodSafetyChecklist['Properly packaged/covered'] ?? false,
                'labeled': _foodSafetyChecklist['Labeled with prep time'] ?? false,
                'timestamp': DateTime.now().toIso8601String(),
              },
            };
            
            if (foodImageId != null) {
              payload['foodImage'] = foodImageId;
            }
            
            if (_additionalNotesController.text.isNotEmpty) {
              payload['additionalNotes'] = _additionalNotesController.text;
            }
            
            Map<String, dynamic> result;
            if (isEditing) {
              result = await api.updateDonation(widget.donation!['_id'], payload);
            } else {
              result = await api.createDonation(payload);
            }

            if (result['success'] == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEditing ? 'Donation updated successfully!' : 'Donation posted successfully!'), 
                  backgroundColor: Colors.green
                ),
              );
              Navigator.of(context).pop(true);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result['message'] ?? 'Operation failed'), backgroundColor: Colors.red),
              );
            }
          } else {
            String errorMessage = 'Please complete all required fields';
            if (_selectedFoodType == null) errorMessage = 'Please select a food type';
            else if (_selectedDietaryInfo == null && !isEditing) errorMessage = 'Please select dietary information';
            else if (_pickupStartTime == null) errorMessage = 'Please select pickup start time';
            else if (_pickupEndTime == null) errorMessage = 'Please select pickup end time';
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
            );
          }
        },
        child: Text(
          isEditing ? 'Update Donation' : 'Post Donation', 
          style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.bold)
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.donation != null ? 'Edit Donation' : 'Post New Donation', 
          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Food Photo'),
                const SizedBox(height: 8),
                _imageSection(),
                const SizedBox(height: 20),
                _sectionTitle('Food Type'),
                _foodTypeSection(),
                const SizedBox(height: 20),
                _sectionTitle('Food Details'),
                _foodDetailsSection(),
                const SizedBox(height: 20),
                _sectionTitle('Timing'),
                _timingSection(),
                const SizedBox(height: 20),
                _sectionTitle('Location'),
                _locationSection(),
                const SizedBox(height: 20),
                _sectionTitle('Food Safety Checklist'),
                _safetyChecklist(),
                const SizedBox(height: 20),
                _sectionTitle('Dietary Information'),
                _dietaryInfoSection(),
                const SizedBox(height: 20),
                _additionalNotesSection(),
                const SizedBox(height: 30),
                _postButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
