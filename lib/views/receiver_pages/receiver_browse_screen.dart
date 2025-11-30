import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';

class ReceiverBrowseScreen extends StatefulWidget {
  final VoidCallback? onNotificationPressed;
  final int unreadNotifications;
  
  const ReceiverBrowseScreen({
    super.key,
    this.onNotificationPressed,
    this.unreadNotifications = 0,
  });

  @override
  _ReceiverBrowseScreenState createState() => _ReceiverBrowseScreenState();
}

class _ReceiverBrowseScreenState extends State<ReceiverBrowseScreen> {
  String _selectedCategory = 'All'; // Default to All
  
  final List<String> _categories = [
    'All',
    'Nearby',
    'Cooked Meals',
    'Fruits & Veg',
    'Bakery & Dairy'
  ];

  List<dynamic> _allDonations = [];
  List<dynamic> _nearbyDonations = [];
  bool _isLoading = true;

  int _reservedCount = 0;
  int _completedCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchDonations();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final stats = await apiService.getDashboardStats();
      
      if (mounted) {
        setState(() {
          _reservedCount = stats['activeReservations'] ?? 0;
          _completedCount = stats['completedReservations'] ?? 0;
        });
      }
    } catch (e) {
      print('Error fetching stats: $e');
    }
  }

  Future<void> _fetchDonations() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Only fetch all donations on initial load (no location needed)
      final all = await apiService.searchDonations();

      if (mounted) {
        setState(() {
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

  Future<void> _fetchNearbyDonations() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      setState(() {
        _isLoading = true;
      });

      // Get current location
      Position position = await _determinePosition();

      // Fetch nearby donations (10km radius)
      final nearby = await apiService.getNearbyDonations(
        lat: position.latitude, 
        lng: position.longitude,
        maxDistance: 10
      );

      if (mounted) {
        setState(() {
          _nearbyDonations = nearby;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching nearby donations: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required for nearby donations'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isLoading = false;
          _selectedCategory = 'All'; // Switch back to All
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
                          // Notification Bell with Badge
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  onPressed: widget.onNotificationPressed ?? () {
                                    Navigator.pushNamed(context, '/notifications');
                                  },
                                ),
                                if (widget.unreadNotifications > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
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
                  _buildStatCard('$_reservedCount', 'Reserved', const Color(0xFF1976D2)),
                  _buildStatCard('$_completedCount', 'Completed', const Color(0xFF1976D2)),
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
                          if (category == 'Nearby' && _nearbyDonations.isEmpty) {
                            // Fetch nearby donations when Nearby is clicked for the first time
                            _fetchNearbyDonations();
                          }
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
    final String? foodImageId = donation['foodImage'];
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 80,
              height: 80,
              color: Colors.grey[100],
              child: foodImageId != null && foodImageId.isNotEmpty
                  ? Image.network(
                      '${ApiService.baseUrl}/api/upload/$foodImageId',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.fastfood, color: Colors.grey);
                      },
                    )
                  : const Icon(Icons.fastfood, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        donation['foodDescription'] ?? 'Food Donation',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  donation['quantity'] is Map
                      ? '${donation['quantity']['value']} ${donation['quantity']['unit']}'
                      : '${donation['quantity'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'POSTED',
                        style: TextStyle(
                          color: Color(0xFFFF9800),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => _showReserveDialog(donation),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: Color(0xFF673AB7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReserveDialog(dynamic donation) {
    final scaffoldContext = context; // Capture the screen's context
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Reservation', style: TextStyle(fontFamily: 'Poppins')),
        content: Text(
          'Do you want to reserve ${donation['foodDescription']}?',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // Call API to reserve
              try {
                final apiService = Provider.of<ApiService>(scaffoldContext, listen: false);
                
                // Use the donation's pickup window end time as scheduled pickup time
                // If not available, use current time + 2 hours as default
                String scheduledPickup;
                if (donation['pickupWindow'] != null && donation['pickupWindow']['end'] != null) {
                  scheduledPickup = donation['pickupWindow']['end'];
                } else {
                  // Default: 2 hours from now
                  scheduledPickup = DateTime.now().add(Duration(hours: 2)).toIso8601String();
                }
                
                final result = await apiService.createReservation(
                  donation['_id'],
                  scheduledPickup,
                );
                
                if (!mounted) return;
                
                if (result['success']) {
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    const SnackBar(
                      content: Text('Donation reserved successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Refresh list and stats
                  _fetchDonations();
                  _fetchStats();
                } else {
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Failed to reserve'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
            child: const Text(
              'Confirm',
              style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: Colors.white,
              ),
            ),
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
