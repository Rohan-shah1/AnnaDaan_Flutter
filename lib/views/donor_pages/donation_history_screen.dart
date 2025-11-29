import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';

class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({super.key});

  @override
  _DonationHistoryScreenState createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  int _currentIndex = 3; // Profile tab selected
  bool _isLoading = true;
  String _selectedTimeFilter = 'This Month'; // Default filter
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
      print('Error fetching donation history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Filter donations based on selected time and completed status
  List<Map<String, dynamic>> get _filteredDonations {
    final now = DateTime.now();
    List<Map<String, dynamic>> filtered = [];
    
    if (_selectedTimeFilter == 'This Week') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      filtered = _donations.where((don) {
        final dateStr = don['date'] ?? don['createdAt'];
        if (dateStr == null) return false;
        final donationDate = DateTime.tryParse(dateStr.toString());
        return donationDate != null && donationDate.isAfter(startOfWeek);
      }).toList();
    } else {
      final startOfMonth = DateTime(now.year, now.month, 1);
      filtered = _donations.where((don) {
        final dateStr = don['date'] ?? don['createdAt'];
        if (dateStr == null) return false;
        final donationDate = DateTime.tryParse(dateStr.toString());
        return donationDate != null && donationDate.isAfter(startOfMonth);
      }).toList();
    }
    
    // Show completed and picked up donations
    return filtered.where((don) {
      final status = don['status']?.toString().toLowerCase();
      return status == 'completed' || status == 'picked_up';
    }).map((don) {
      // Map backend fields to UI fields
      return {
        ...don,
        'title': don['foodDescription'] ?? 'Food Donation',
        'time': _formatDate(don['createdAt']),
        'organization': don['reservedBy']?['organizationName'] ?? 'Unknown Receiver',
        'impact': _calculateImpact(don['quantity']),
        'type': _formatFoodType(don['foodType']),
        'quantity': '${don['quantity']?['value']} ${don['quantity']?['unit']}',
        'status': don['status'],
        'id': don['_id'],
      };
    }).toList();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _calculateImpact(dynamic quantity) {
    if (quantity == null || quantity['value'] == null) return 'Helped 0 people';
    
    final value = (quantity['value'] is int) 
        ? quantity['value'] 
        : double.tryParse(quantity['value'].toString())?.toInt() ?? 0;
    final unit = (quantity['unit'] ?? '').toString().toLowerCase();
    
    int peopleHelped = 0;
    
    if (unit == 'portions') {
      peopleHelped = value; // 1 portion = 1 person
    } else if (unit == 'crates' || unit == 'boxes') {
      peopleHelped = value * 26; // 1 crate/box = 26 people
    } else {
      peopleHelped = value; // Default: use raw value
    }
    
    return 'Helped $peopleHelped people';
  }

  String _formatFoodType(String? type) {
    if (type == null) return '';
    return type.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  void _setTimeFilter(String filter) {
    setState(() {
      _selectedTimeFilter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Donation History', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAITimeSection(),
                  const SizedBox(height: 24),
                  _buildDonationCount(),
                  const SizedBox(height: 16),
                  _buildDonationHistoryList(),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildAITimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AI Time', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Poppins')),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTimeFilterButton('This Month', isSelected: _selectedTimeFilter == 'This Month')),
            const SizedBox(width: 12),
            Expanded(child: _buildTimeFilterButton('This Week', isSelected: _selectedTimeFilter == 'This Week')),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeFilterButton(String text, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () => _setTimeFilter(text),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
          border: Border.all(color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDonationCount() {
    return Text(
      '${_filteredDonations.length} Donations',
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey, fontFamily: 'Poppins'),
    );
  }

  Widget _buildDonationHistoryList() {
    if (_filteredDonations.isEmpty) {
      return _buildEmptyState();
    }
    return Column(
      children: _filteredDonations.map((donation) => Column(
        children: [
          _buildDonationItem(
            title: donation['title'] ?? '',
            time: donation['time'] ?? '',
            organization: donation['organization'] ?? '',
            impact: donation['impact'] ?? '',
            type: donation['type'] ?? '',
            quantity: donation['quantity'] ?? '',
            donation: donation,
          ),
          const SizedBox(height: 20),
          _buildViewReceiptButton(donation),
          const SizedBox(height: 24),
          if (_filteredDonations.last != donation) ...[
            const Divider(color: Colors.grey),
            const SizedBox(height: 24),
          ],
        ],
      )).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: const [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No donations found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey, fontFamily: 'Poppins')),
          SizedBox(height: 8),
          Text('You haven\'t made any donations this month', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Poppins')),
        ],
      ),
    );
  }

  Widget _buildDonationItem({
    required String title, 
    required String time, 
    required String organization, 
    required String impact, 
    required String type, 
    required String quantity,
    required Map<String, dynamic> donation
  }) {
    final canRate = donation['status'] == 'picked_up' || donation['status'] == 'completed';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Poppins')),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.access_time, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(time, style: const TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Poppins')),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.location_on, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text('@ $organization', style: const TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Poppins')),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.people, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(impact, style: const TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Poppins')),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.category, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text('$type • $quantity', style: const TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Poppins')),
          ]),
          if (canRate) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleRateReceiver(donation),
                icon: const Icon(Icons.star_outline, size: 18),
                label: const Text('Rate Receiver'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFF1565C0)),
                  foregroundColor: const Color(0xFF1565C0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleRateReceiver(Map<String, dynamic> donation) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final api = Provider.of<ApiService>(context, listen: false);
      final reservations = await api.getDonationReservations(donation['id']);
      
      Navigator.pop(context); // Hide loading

      // Find the completed reservation
      final completedReservation = reservations.firstWhere(
        (res) => res['status'] == 'picked_up' || res['status'] == 'completed',
        orElse: () => null,
      );

      if (completedReservation != null) {
        // Check if already rated
        if (completedReservation['donorRating'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You have already rated this receiver')),
          );
          return;
        }
        _showRatingDialog(completedReservation['_id']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No completed reservation found to rate')),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Hide loading if error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showRatingDialog(String reservationId) {
    int selectedRating = 0;
    final feedbackController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Rate Receiver', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How was your experience with this receiver?',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          index < selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            selectedRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: feedbackController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add feedback (optional)',
                      hintStyle: const TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: const TextStyle(fontFamily: 'Poppins'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins')),
              ),
              ElevatedButton(
                onPressed: selectedRating > 0
                    ? () async {
                        Navigator.pop(context);
                        try {
                          final apiService = Provider.of<ApiService>(context, listen: false);
                          final result = await apiService.submitRating(
                            reservationId,
                            selectedRating,
                            feedback: feedbackController.text.trim(),
                          );
                          if (result['success']) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Thank you for your feedback!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            // Refresh the donations list to show the rating immediately
                            _fetchDonations();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message'] ?? 'Failed to submit rating'),
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
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: const Text('Submit', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildViewReceiptButton(Map<String, dynamic> donation) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _showReceiptDialog(donation),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: const BorderSide(color: Color(0xFF2E7D32)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: const Text('View Receipt', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
      ),
    );
  }

  void _showReceiptDialog(Map<String, dynamic> donation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Donation Receipt', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(donation['title'] ?? '', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 16),
                _buildReceiptDetail('Date', donation['time'] ?? ''),
                _buildReceiptDetail('Organization', donation['organization'] ?? ''),
                _buildReceiptDetail('Impact', donation['impact'] ?? ''),
                _buildReceiptDetail('Food Type', donation['type'] ?? ''),
                _buildReceiptDetail('Quantity', donation['quantity'] ?? ''),
                _buildReceiptDetail('Status', donation['status'] ?? ''),
                _buildReceiptDetail('Donation ID', donation['id'] ?? ''),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade100)),
                  child: Row(
                    children: const [
                      Icon(Icons.eco, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(child: Text('You helped many people with this donation!', style: TextStyle(fontFamily: 'Poppins', color: Colors.green, fontSize: 14))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close', style: TextStyle(fontFamily: 'Poppins'))),
            TextButton(onPressed: () { _showShareMessage(); Navigator.of(context).pop(); }, child: const Text('Share', style: TextStyle(fontFamily: 'Poppins'))),
          ],
        );
      },
    );
  }

  Widget _buildReceiptDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontFamily: 'Poppins', color: Colors.grey)),
        ],
      ),
    );
  }

  void _showShareMessage() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt shared successfully!', style: TextStyle(fontFamily: 'Poppins')), backgroundColor: Colors.green, duration: Duration(seconds: 2)));
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Color(0x33AAAAAA), spreadRadius: 1, blurRadius: 5, offset: Offset(0, -2))]),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _handleNavigation(index);
        },
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
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/donor-dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/active-donations');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/impact-screen');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile-screen');
        break;
    }
  }
}
