import 'package:flutter/material.dart';
import 'receiver_browse_screen.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../donor_pages/impact_screen.dart';
import '../pages/profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ReceiverDashboard extends StatefulWidget {
  const ReceiverDashboard({super.key});
  @override
  _ReceiverDashboardState createState() => _ReceiverDashboardState();
}

class _ReceiverDashboardState extends State<ReceiverDashboard> {
  int _currentIndex = 0;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadNotifications();
  }

  Future<void> _fetchUnreadNotifications() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final notifications = await apiService.getNotifications();
      
      if (mounted) {
        setState(() {
          _unreadNotifications = notifications.where((n) => n['isRead'] != true).length;
        });
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildCurrentScreen(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return ReceiverBrowseScreen(
          onNotificationPressed: () async {
            await Navigator.pushNamed(context, '/notifications');
            _fetchUnreadNotifications();
          },
          unreadNotifications: _unreadNotifications,
        );
      case 1:
        return _ReceiverReservedScreen();
      case 2:
        return const ImpactScreen(showBottomNav: false);
      case 3:
        return const ProfileScreen(showBottomNav: false);
      default:
        return ReceiverBrowseScreen(
          onNotificationPressed: () async {
            await Navigator.pushNamed(context, '/notifications');
            _fetchUnreadNotifications();
          },
          unreadNotifications: _unreadNotifications,
        );
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.layers),
            label: 'Reserved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Impact',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Reserved Screen
class _ReceiverReservedScreen extends StatefulWidget {
  @override
  __ReceiverReservedScreenState createState() => __ReceiverReservedScreenState();
}

class __ReceiverReservedScreenState extends State<_ReceiverReservedScreen> {
  List<Map<String, dynamic>> _reservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final data = await apiService.getMyReservations();
      if (mounted) {
        setState(() {
          _reservations = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching reservations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDistance(dynamic distance) {
    if (distance == null) return 'N/A';
    double dist = double.tryParse(distance.toString()) ?? 0.0;
    if (dist < 1) {
      return '${(dist * 1000).toInt()} m';
    }
    return '${dist.toStringAsFixed(1)} km';
  }

  Future<void> _openMap(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final activePickups = _reservations.where((item) => item['status'] == 'confirmed' || item['status'] == 'scheduled').toList();
    final completedPickups = _reservations.where((item) => item['status'] == 'picked_up' || item['status'] == 'completed').toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Reserved Pickups',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: _reservations.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.layers_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No reservations yet', style: TextStyle(fontSize: 18, color: Colors.grey, fontFamily: 'Poppins')),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Pickups (${activePickups.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 20),
            // Active Pickups
            ...activePickups.map((pickup) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildReservedPickupCard(pickup),
              );
            }).toList(),
            // Completed Pickups
            if (completedPickups.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Completed Pickups',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),
              ...completedPickups.map((pickup) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCompletedPickupCard(pickup),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReservedPickupCard(Map<String, dynamic> reservation) {
    final donation = reservation['donation'] ?? {};
    final location = donation['location'] ?? {};
    final coordinates = location['coordinates'] ?? {};
    final double? lat = coordinates['lat'] != null ? double.tryParse(coordinates['lat'].toString()) : null;
    final double? lng = coordinates['lng'] != null ? double.tryParse(coordinates['lng'].toString()) : null;

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
          Text(
            donation['foodDescription'] ?? 'Food Donation',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            donation['foodType'] ?? 'N/A',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                donation['quantity'] is Map
                    ? '${donation['quantity']['value']} ${donation['quantity']['unit']}'
                    : '${donation['quantity'] ?? 'N/A'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.near_me, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Distance: ${_formatDistance(reservation['distance'])}',
                style: TextStyle(
                  fontSize: 14,
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
              const SizedBox(width: 8),
              Text(
                'Pickup by: ${donation['pickupWindow']?['end'] ?? 'N/A'}',
                style: TextStyle(
                  fontSize: 14,
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  location['address'] ?? 'N/A',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (lat != null && lng != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openMap(lat, lng),
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('Open Map'),
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
              if (lat != null && lng != null) const SizedBox(width: 12),
              if (reservation['status'] == 'confirmed')
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _markAsPickedUp(reservation),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Mark Picked Up',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        color: Colors.white,
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

  Widget _buildCompletedPickupCard(Map<String, dynamic> reservation) {
    final donation = reservation['donation'] ?? {};
    final rating = reservation['rating'];
    final hasRating = rating != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle, color: Colors.green),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation['foodDescription'] ?? 'Food Donation',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Picked up on ${reservation['updatedAt']?.toString().split('T')[0] ?? 'Today'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasRating) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Your Rating: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                ...List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 18,
                  );
                }),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showRatingDialog(reservation),
                icon: const Icon(Icons.star_outline, size: 18),
                label: const Text('Rate Donor'),
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

  void _markAsPickedUp(Map<String, dynamic> reservation) {
    final donation = reservation['donation'] ?? {};
    final foodDesc = donation['foodDescription'] ?? 'this donation';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Pickup', style: TextStyle(fontFamily: 'Poppins')),
        content: Text('Have you successfully picked up $foodDesc?', style: const TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final apiService = Provider.of<ApiService>(context, listen: false);
                final result = await apiService.updateReservationStatus(
                  reservation['_id'],
                  'picked_up',
                );
                
                print('API Response: $result');
                
                if (result['success']) {
                  print('Updating UI optimistically...');
                  if (mounted) {
                    setState(() {
                      final index = _reservations.indexWhere((r) => r['_id'] == reservation['_id']);
                      print('Found at index: $index');
                      if (index != -1) {
                        print('Old status: ${_reservations[index]['status']}');
                        _reservations[index]['status'] = 'picked_up';
                        _reservations[index]['updatedAt'] = DateTime.now().toIso8601String();
                        print('New status: ${_reservations[index]['status']}');
                      }
                    });
                  }
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pickup confirmed! Impact updated.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                  
                  print('Fetching fresh data from server...');
                  await _fetchReservations();
                  print('UI refresh complete');
                }
              } catch (e) {
                print('Error in _markAsPickedUp: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating status: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Yes, Picked Up',
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

  void _showRatingDialog(Map<String, dynamic> reservation) {
    int selectedRating = 0;
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Rate Your Experience', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How was your experience with this donor?',
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
                            reservation['_id'],
                            selectedRating,
                            feedback: feedbackController.text.trim(),
                          );
                          if (result['success']) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Thank you for your feedback!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                            await _fetchReservations();
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['message'] ?? 'Failed to submit rating'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: const Text('Submit Rating', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}