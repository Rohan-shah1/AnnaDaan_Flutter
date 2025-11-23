import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import 'location_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PostDonationScreen extends StatefulWidget {
  const PostDonationScreen({super.key});

  @override
  _PostDonationScreenState createState() => _PostDonationScreenState();
}

class _PostDonationScreenState extends State<PostDonationScreen> {
  final _formKey = GlobalKey<FormState>();

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

  // Map display names to backend enum values
  final Map<String, String> _foodTypesMap = {
    'Cooked Vegetarian': 'cooked_veg',
    'Cooked Non-Vegetarian': 'cooked_non_veg',
   'Packaged Meals': 'packaged_meals',
    'Raw Vegetables/Fruits': 'raw_vegetables',
  };

  // Safety checklist
  final Map<String, bool> _foodSafetyChecklist = {
    'Stored at safe temperature': false,
    'Properly packaged/covered': false,
    'Fresh and good quality': false,
    'Labeled with prep time': false,
  };

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
            final dateTime = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 7)),
            );
            if (dateTime != null) {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                setState(() {
                  _pickupStartTime = DateTime(
                    dateTime.year,
                    dateTime.month,
                    dateTime.day,
                    time.hour,
                    time.minute,
                  );
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
            final dateTime = await showDatePicker(
              context: context,
              initialDate: _pickupStartTime ?? DateTime.now(),
              firstDate: _pickupStartTime ?? DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 7)),
            );
            if (dateTime != null) {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                setState(() {
                  _pickupEndTime = DateTime(
                    dateTime.year,
                    dateTime.month,
                    dateTime.day,
                    time.hour,
                    time.minute,
                  );
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
                    // Extract city if possible, or just leave it for user to edit
                    // Simple heuristic: split by comma and take the 3rd last or so?
                    // For now, let's just populate address.
                    // If the address format is "Street, SubLocality, Locality, Postal, Country"
                    // Locality is likely the city.
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
        Text('ADDITIONAL NOTES (OPTIONAL)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey, fontFamily: 'Poppins')),
        SizedBox(height: 8),
        Text('Any special instructions, allergen info, etc.', style: TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Poppins')),
        SizedBox(height: 10),
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

  // Post donation button
  Widget _postButton() {
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
              _selectedDietaryInfo != null &&
              _pickupStartTime != null &&
              _pickupEndTime != null) {
            
            final api = Provider.of<ApiService>(context, listen: false);
            
            // Convert display name to backend enum value
            final backendFoodType = _foodTypesMap[_selectedFoodType];
            
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
            
            if (_additionalNotesController.text.isNotEmpty) {
              payload['additionalNotes'] = _additionalNotesController.text;
            }
            
            final result = await api.createDonation(payload);
            if (result['success'] == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Donation posted successfully!'), backgroundColor: Colors.green),
              );
              Navigator.of(context).pushNamedAndRemoveUntil('/donor-dashboard', (route) => false);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result['message'] ?? 'Failed to post donation'), backgroundColor: Colors.red),
              );
            }
          } else {
            String errorMessage = 'Please complete all required fields';
            if (_selectedFoodType == null) errorMessage = 'Please select a food type';
            else if (_selectedDietaryInfo == null) errorMessage = 'Please select dietary information';
            else if (_pickupStartTime == null) errorMessage = 'Please select pickup start time';
            else if (_pickupEndTime == null) errorMessage = 'Please select pickup end time';
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
            );
          }
        },
        child: const Text('Post Donation', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post New Donation', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
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
