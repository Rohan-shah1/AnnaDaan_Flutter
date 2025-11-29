import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import 'donor_dashboard.dart';
import 'active_donations_screen.dart';
import '../pages/profile_screen.dart';

class ImpactScreen extends StatefulWidget {
  final bool showBottomNav;

  const ImpactScreen({super.key, this.showBottomNav = true});

  @override
  _ImpactScreenState createState() => _ImpactScreenState();
}

class _ImpactScreenState extends State<ImpactScreen> {
  int _currentIndex = 2;
  bool _isLoading = true;
  Map<String, dynamic> _impactData = {};

  @override
  void initState() {
    super.initState();
    _fetchImpactData();
  }

  Future<void> _fetchImpactData() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final result = await api.getImpactMetrics();

      if (mounted) {
        setState(() {
          if (result['success'] == true) {
            _impactData = result['data'] ?? {};
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching impact data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<ApiService>(context).userProfile;
    final userType = userProfile?['userType'] ?? 'donor';
    final isDonor = userType == 'donor';

    final primaryColor = isDonor ? const Color(0xFF2E7D32) : const Color(0xFF1565C0);
    final lightColor = isDonor ? const Color(0xFF4CAF50) : const Color(0xFF1976D2);
    final shadowColor = isDonor ? Colors.green.shade200 : Colors.blue.shade200;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isDonor ? 'My Impact' : 'Our Impact',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: widget.showBottomNav
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (isDonor) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DonorDashboard()),
              );
            } else {
              Navigator.pop(context);
            }
          },
        )
            : null,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchImpactData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTotalImpactSection(primaryColor, lightColor, shadowColor, isDonor),
              const SizedBox(height: 32),
              _buildAchievementsSection(isDonor),
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.showBottomNav ? _buildBottomNavigationBar() : null,
    );
  }

  Widget _buildTotalImpactSection(Color primary, Color light, Color shadow, bool isDonor) {
    final foodSaved = _impactData['foodSaved'] ?? '0kg';
    final estimatedMeals = _impactData['estimatedMeals']?.toString() ?? '0';
    final totalDonations = _impactData['totalDonations']?.toString() ?? '0';
    final peopleHelped = _impactData['peopleHelped']?.toString() ?? '0';

    final foodCollected = _impactData['foodCollected'] ?? foodSaved;
    final pickupsDone = _impactData['pickupsDone']?.toString() ?? totalDonations;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, light],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            isDonor ? 'Your Total Impact' : 'Total Impact',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildImpactStat(
                  isDonor ? foodSaved : foodCollected,
                  isDonor ? 'Food Donated' : 'Food Collected',
                  Icons.restaurant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildImpactStat(
                  estimatedMeals,
                  'Meals Served',
                  Icons.people,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection(bool isDonor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Achievements',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          _buildAchievementCard(isDonor),
          const SizedBox(height: 12),
          _buildAchievementCard2(isDonor),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(bool isDonor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDonor ? 'Top Donor This Month' : 'Most Active NGO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDonor
                      ? "You're in the top 10% of donors in your area!"
                      : "Ranked #1 in your area this month!",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.amber.shade700,
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

  Widget _buildAchievementCard2(bool isDonor) {
    final foodSaved = _impactData['foodSaved'] ?? '480kg';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            isDonor ? Icons.eco : Icons.star,
            color: isDonor ? Colors.blue.shade700 : Colors.yellow.shade700,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDonor ? 'Environmental Champion' : '5.0 Rating',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDonor ? Colors.blue.shade800 : Colors.yellow.shade800,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDonor
                      ? 'Saved $foodSaved of food from waste!'
                      : 'Perfect rating from all donors',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDonor ? Colors.blue.shade700 : Colors.yellow.shade700,
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
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DonorDashboard()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ActiveDonationsScreen()),
        );
        break;
      case 2:
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
