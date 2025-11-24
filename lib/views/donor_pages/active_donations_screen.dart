import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import 'donor_dashboard.dart';
import 'impact_screen.dart';
import '../pages/profile_screen.dart';
import 'post_donation_screen.dart';

class ActiveDonationsScreen extends StatefulWidget {
  const ActiveDonationsScreen({super.key});

  @override
  _ActiveDonationsScreenState createState() => _ActiveDonationsScreenState();
}

class _ActiveDonationsScreenState extends State<ActiveDonationsScreen> {
  int _currentIndex = 1;
  String _selectedCategory = 'All';
  bool _isLoading = true;
  List<Map<String, dynamic>> _donations = [];

  @override
  void initState() {
    super.initState();
    _fetchDonations();
  }

  Future<void> _fetchDonations() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final data = await api.getMyDonations();
      setState(() {
        _donations = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching donations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredDonations {
    if (_selectedCategory == 'All') return _donations;
    
    return _donations.where((donation) {
      final foodType = donation['foodType']?.toString().toLowerCase() ?? '';
      switch (_selectedCategory) {
        case 'Cooked Food':
          return foodType.contains('cooked');
        case 'Raw/Produce':
          return foodType.contains('raw') || foodType.contains('vegetable');
        case 'Packaged Meals':
          return foodType.contains('packaged');
        default:
          return true;
      }
    }).toList();
  }

  void _setCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  Future<void> _handleEdit(Map<String, dynamic> donation) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDonationScreen(donation: donation),
      ),
    );

    if (result == true) {
      _fetchDonations();
    }
  }

  Future<void> _handleDelete(String donationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Donation', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this donation? This action cannot be undone.', style: TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(fontFamily: 'Poppins', color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final api = Provider.of<ApiService>(context, listen: false);
        final result = await api.deleteDonation(donationId);
        
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Donation deleted successfully'), backgroundColor: Colors.green),
          );
          _fetchDonations();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Failed to delete donation'), backgroundColor: Colors.red),
          );
          setState(() => _isLoading = false);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Active Donations',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDonations,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategoryFilter(),
                    const SizedBox(height: 24),
                    _buildDonationsList(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCategoryFilter() {
    const categories = ['All', 'Cooked Food', 'Raw/Produce', 'Packaged Meals'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter by Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((c) => _buildCategoryButton(c)).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryButton(String category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => _setCategory(category),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildDonationsList() {
    if (_filteredDonations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No donations found',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: _filteredDonations
          .map((don) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildDonationCard(don),
              ))
          .toList(),
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> donation) {
    final foodDescription = donation['foodDescription'] ?? 'Food Donation';
    final foodType = donation['foodType'] ?? '';
    final status = donation['status'] ?? 'pending';
    final quantity = donation['quantity'];
    final location = donation['location'];
    final rawFoodImage = donation['foodImage'];
    
    // Extract food image ID - handle string, object, or null
    String? foodImageId;
    if (rawFoodImage != null) {
      if (rawFoodImage is String && rawFoodImage.isNotEmpty) {
        foodImageId = rawFoodImage;
      } else if (rawFoodImage is Map && rawFoodImage['_id'] != null) {
        foodImageId = rawFoodImage['_id'].toString();
      }
    }
    
    String quantityText = '';
    if (quantity != null && quantity is Map) {
      quantityText = '${quantity['value']} ${quantity['unit'] ?? 'units'}';
    }
    
    String locationText = '';
    if (location != null && location is Map) {
      locationText = location['address'] ?? location['city'] ?? '';
    }


    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with food type and status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getFoodTypeColor(foodType).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getFoodTypeColor(foodType).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    image: foodImageId != null
                        ? DecorationImage(
                            image: NetworkImage('${ApiService.baseUrl}/api/upload/$foodImageId'),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: foodImageId == null
                      ? Icon(
                          _getFoodTypeIcon(foodType),
                          color: _getFoodTypeColor(foodType),
                          size: 24,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getFoodTypeLabel(foodType),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getFoodTypeColor(foodType),
                          fontFamily: 'Poppins',
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        foodDescription,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
          ),
          
          // Details section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (quantityText.isNotEmpty)
                  _buildInfoRow(Icons.scale_outlined, 'Quantity', quantityText),
                if (locationText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.location_on_outlined, 'Location', locationText),
                ],
                const SizedBox(height: 16),
                _buildActionButtons(donation),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
            fontFamily: 'Poppins',
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final statusLower = status.toLowerCase();
    Color badgeColor;
    String badgeText;

    switch (statusLower) {
      case 'pending':
        badgeColor = Colors.orange;
        badgeText = 'POSTED';
        break;
      case 'reserved':
        badgeColor = Colors.blue;
        badgeText = 'RESERVED';
        break;
      case 'picked_up':
      case 'completed':
        badgeColor = Colors.green;
        badgeText = 'COMPLETED';
        break;
      case 'cancelled':
        badgeColor = Colors.red;
        badgeText = 'CANCELLED';
        break;
      default:
        badgeColor = Colors.grey;
        badgeText = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        badgeText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> donation) {
    final status = donation['status']?.toString().toLowerCase() ?? '';
    
    if (status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleEdit(donation),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _handleDelete(donation['_id']),
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              label: const Text('Delete', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    return const SizedBox.shrink();
  }

  IconData _getFoodTypeIcon(String foodType) {
    final typeLower = foodType.toLowerCase();
    if (typeLower.contains('cooked')) return Icons.restaurant;
    if (typeLower.contains('raw') || typeLower.contains('vegetable')) return Icons.grass;
    if (typeLower.contains('packaged')) return Icons.inventory_2;
    return Icons.fastfood;
  }

  Color _getFoodTypeColor(String foodType) {
    final typeLower = foodType.toLowerCase();
    if (typeLower.contains('cooked_veg')) return const Color(0xFF4CAF50);
    if (typeLower.contains('cooked_non_veg')) return const Color(0xFFFF5722);
    if (typeLower.contains('raw') || typeLower.contains('vegetable')) return const Color(0xFF8BC34A);
    if (typeLower.contains('packaged')) return const Color(0xFF2196F3);
    return const Color(0xFF9E9E9E);
  }

  String _getFoodTypeLabel(String foodType) {
    final typeLower = foodType.toLowerCase();
    if (typeLower.contains('cooked_veg')) return 'COOKED VEGETARIAN';
    if (typeLower.contains('cooked_non_veg')) return 'COOKED NON-VEG';
    if (typeLower.contains('raw')) return 'RAW VEGETABLES';
    if (typeLower.contains('packaged')) return 'PACKAGED MEALS';
    return foodType.toUpperCase();
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
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
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.diamond), label: 'Active'),
          BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Impact'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  void _handleNavigation(int index) {
    if (_currentIndex == index) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DonorDashboard()),
        );
        break;
      case 1:
        // Already here
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ImpactScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
  }
}
