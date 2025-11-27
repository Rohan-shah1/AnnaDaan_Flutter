import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    'Vegetables',
    'Fruits',
    'Bakery',
    'Dairy'
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
      
      // Fetch nearby donations (10km radius)
      final nearby = await apiService.getNearbyDonations(maxDistance: 10000);
      
      // Fetch all donations (no distance limit)
      final all = await apiService.getNearbyDonations();

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

  @override
  Widget build(BuildContext context) {
    // Filter logic
    List<dynamic> filteredDonations;
    if (_selectedCategory == 'Nearby') {
      filteredDonations = _nearbyDonations;
    } else if (_selectedCategory == 'All') {
      filteredDonations = _allDonations;
    } else {
      filteredDonations = _allDonations.where((donation) => 
        donation['category'] == _selectedCategory || 
        donation['foodType'] == _selectedCategory
      ).toList();
    }

    return Column(
      children: [
        // Dark Blue Header Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                              'Welcome Back',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
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
                      IconButton(
                        icon: const Icon(Icons.account_circle, color: Colors.white, size: 32),
                        onPressed: () {
                          // Navigate to profile will be handled by parent
                        },
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
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation['foodDescription'] ?? 'Food Donation',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${donation['foodType']} • ${donation['dietaryInformation'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF81C784),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'AVAILABLE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.scale, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                donation['quantity'] ?? 'N/A',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Expires: ${donation['expiryDate'] ?? 'N/A'}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  donation['location']?['address'] ?? 'N/A',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showDonationDetails(donation);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1565C0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(
                      color: Color(0xFF1565C0),
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _reservePickup(donation);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Reserve Pickup',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
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

  void _showDonationDetails(dynamic donation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation['foodDescription'] ?? 'Food Donation',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow(Icons.restaurant, 'Food Type', donation['foodType']),
                    _buildDetailRow(Icons.scale, 'Quantity', donation['quantity']),
                    _buildDetailRow(Icons.calendar_today, 'Expiry Date', donation['expiryDate']),
                    _buildDetailRow(Icons.local_dining, 'Dietary Info', donation['dietaryInformation']),
                    _buildDetailRow(Icons.location_on, 'Location', donation['location']?['address']),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF1565C0)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Close', style: TextStyle(fontFamily: 'Poppins')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _reservePickup(donation);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Reserve', style: TextStyle(fontFamily: 'Poppins')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1565C0)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value?.toString() ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _reservePickup(dynamic donation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Reserve Pickup',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to reserve ${donation['foodDescription']}?',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins')),
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
                    SnackBar(
                      content: Text(
                          'Successfully reserved ${donation['foodDescription']}',
                          style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  // Refresh list
                  _fetchDonations();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Reservation failed: ${result['message']}',
                          style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error: $e',
                      style: const TextStyle(fontFamily: 'Poppins'),
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
            ),
            child: const Text('Confirm', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }
}