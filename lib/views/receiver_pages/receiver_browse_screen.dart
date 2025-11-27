import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';

class ReceiverBrowseScreen extends StatefulWidget {
  const ReceiverBrowseScreen({super.key});

  @override
  _ReceiverBrowseScreenState createState() => _ReceiverBrowseScreenState();
}

class _ReceiverBrowseScreenState extends State<ReceiverBrowseScreen> {
  String _selectedCategory = 'Nearby'; // Default to Nearby
  
  final List<String> _categories = [
    'Nearby',
    'All',
    'Cooked Meals',
    'Fruits & Veg',
    'Bakery & Dairy'
  ];

  List<dynamic> _allDonations = [];
  List<dynamic> _nearbyDonations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDonations();
  }

  Future<void> _fetchDonations() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Get current location
      Position? position;
      try {
        position = await _determinePosition();
      } catch (e) {
        print('Error getting location: $e');
      }

      // Fetch nearby donations (10km radius) if location available
      List<dynamic> nearby = [];
      if (position != null) {
        nearby = await apiService.getNearbyDonations(
          lat: position.latitude, 
          lng: position.longitude,
          maxDistance: 10000
        );
      }
      
      // Fetch all donations (using search endpoint)
      final all = await apiService.searchDonations(
        lat: position?.latitude,
        lng: position?.longitude
      );

      if (mounted) {
        setState(() {
          _nearbyDonations = nearby;
          _allDonations = all;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching donations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    } 

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    // Filter logic
    List<dynamic> filteredDonations;
    if (_selectedCategory == 'Nearby') {
      filteredDonations = _nearbyDonations;
    } else if (_selectedCategory == 'All') {
      filteredDonations = _allDonations;
    } else {
      filteredDonations = _allDonations.where((donation) {
        final foodType = donation['foodType']?.toString().toLowerCase() ?? '';
        switch (_selectedCategory) {
          case 'Cooked Meals':
            return foodType.contains('cooked');
          case 'Fruits & Veg':
            return foodType == 'fruits' || foodType == 'vegetables';
          case 'Bakery & Dairy':
            return foodType == 'bakery' || foodType == 'dairy';
          default:
            return true;
        }
      }).toList();
    }

    return Column(
      children: [
        // Dark Blue Header Section
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 24),
          decoration: const BoxDecoration(
            color: Color(0xFF1565C0),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<ApiService>(
                builder: (context, apiService, child) {
                  final organizationName = apiService.userProfile?['organizationName'] ?? 'Receiver';
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome Back,',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              organizationName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          // Notification Bell
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, '/notifications');
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Profile Picture
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            backgroundImage: apiService.userProfile?['profilePicture'] != null
                                ? NetworkImage('${ApiService.baseUrl}/api/upload/${apiService.userProfile!['profilePicture']}')
                                : null,
                            child: apiService.userProfile?['profilePicture'] == null
                                ? const Icon(Icons.person, color: Color(0xFF1565C0))
                                : null,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              // Stats Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard('${filteredDonations.length}', 'Available', const Color(0xFF1976D2)),
                  _buildStatCard('0', 'Reserved', const Color(0xFF1976D2)),
                  _buildStatCard('0', 'Completed', const Color(0xFF1976D2)),
                ],
              ),
            ],
          ),
        ),
        // Content Section
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Filter Section
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1565C0) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF1565C0) : Colors.grey[300]!,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                // Dynamic Heading
                Text(
                  _selectedCategory == 'Nearby' 
                    ? 'Nearby Donations (within 10km)'
                    : _selectedCategory == 'All'
                      ? 'All Available Donations'
                      : '$_selectedCategory Donations',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 16),
                // Donation List
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (filteredDonations.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        _selectedCategory == 'Nearby'
                          ? 'No donations found within 10km.'
                          : 'No donations available in this category.',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  )
                else
                  ...filteredDonations.map((donation) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildDonationCard(donation),
                    );
                  }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1976D2).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationCard(dynamic donation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                donation['foodDescription'] ?? 'Food Donation',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getFoodTypeLabel(donation['foodType'] ?? ''),
                  style: TextStyle(
                    color: _getFoodTypeColor(donation['foodType'] ?? ''),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  donation['location']?['address'] ?? 'Unknown Location',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Pickup by: ${donation['pickupWindow']?['end'] ?? 'N/A'}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Reserve functionality
                _showReserveDialog(donation);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Reserve',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReserveDialog(dynamic donation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Reservation', style: TextStyle(fontFamily: 'Poppins')),
        content: Text(
          'Do you want to reserve ${donation['foodDescription']}?',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Call API to reserve
              try {
                final apiService = Provider.of<ApiService>(context, listen: false);
                final result = await apiService.createReservation(donation['_id']);
                
                if (result['success']) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Donation reserved successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Refresh list
                  _fetchDonations();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Failed to reserve'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String _getFoodTypeLabel(String foodType) {
    final typeLower = foodType.toLowerCase();
    if (typeLower == 'cooked_meals_veg') return 'COOKED VEG';
    if (typeLower == 'cooked_meals_nonveg') return 'COOKED NON-VEG';
    if (typeLower == 'fruits') return 'FRUITS';
    if (typeLower == 'vegetables') return 'VEGETABLES';
    if (typeLower == 'bakery') return 'BAKERY';
    if (typeLower == 'dairy') return 'DAIRY';
    return foodType.toUpperCase().replaceAll('_', ' ');
  }

  Color _getFoodTypeColor(String foodType) {
    final typeLower = foodType.toLowerCase();
    if (typeLower == 'cooked_meals_veg') return const Color(0xFF4CAF50);
    if (typeLower == 'cooked_meals_nonveg') return const Color(0xFFFF5722);
    if (typeLower == 'fruits') return const Color(0xFFFF9800);
    if (typeLower == 'vegetables') return const Color(0xFF8BC34A);
    if (typeLower == 'bakery') return const Color(0xFF795548);
    if (typeLower == 'dairy') return const Color(0xFF2196F3);
    return const Color(0xFF1565C0);
  }
}