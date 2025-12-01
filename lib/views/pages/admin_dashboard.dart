import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  
  // Dashboard Data
  Map<String, dynamic> _stats = {
    'totalDonors': 0,
    'totalReceivers': 0,
    'pendingVerifications': 0,
    'verifiedToday': 0,
  };
  List<dynamic> _pendingDocuments = [];

  // Users Data
  List<dynamic> _users = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingUsers = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedUserType = ''; // '' for all, 'donor', 'receiver'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchDashboardData();
    _fetchUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await ApiService().getAdminStats();
      final pending = await ApiService().getPendingVerifications();
      
      if (mounted) {
        setState(() {
          _stats = stats;
          _pendingDocuments = pending;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _fetchUsers({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _users.clear();
    }
    
    setState(() => _isLoadingUsers = true);
    try {
      final response = await ApiService().getAllUsers(
        page: _currentPage,
        limit: 20,
        search: _searchController.text,
        type: _selectedUserType.isEmpty ? null : _selectedUserType,
      );
      
      if (mounted) {
        setState(() {
          if (refresh) {
            _users = response['users'] ?? [];
          } else {
            _users.addAll(response['users'] ?? []);
          }
          _totalPages = response['totalPages'] ?? 1;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
        print('Error loading users: $e');
      }
    }
  }

  Future<void> _handleApprove(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Verification'),
        content: const Text('Are you sure you want to approve this user\'s verification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ApiService().verifyUser(userId, 'verified');
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User verified successfully'), backgroundColor: Colors.green),
        );
        _fetchDashboardData(); // Refresh list
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to verify user'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleReject(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Verification'),
        content: const Text('Are you sure you want to reject this user\'s verification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ApiService().verifyUser(userId, 'rejected');
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User verification rejected'), backgroundColor: Colors.orange),
        );
        _fetchDashboardData(); // Refresh list
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to reject user'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleDeleteUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ApiService().deleteUser(userId);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully'), backgroundColor: Colors.green),
          );
          _fetchUsers(refresh: true);
          _fetchDashboardData(); // Update stats
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete user'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleViewDocument(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('View Document'),
        content: const Text('This will open the verification document in your browser. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open in Browser'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final url = '${ApiService.baseUrl}/api/upload/$docId';
      final uri = Uri.parse(url);
      
      // Directly launch the URL without checking canLaunchUrl
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                await ApiService().logout();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'User Management'),
          ],
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.orange,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildUsersTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsSection(),
            const SizedBox(height: 24),
            _buildPendingDocumentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('Total Donors', '${_stats['totalDonors']}', Icons.volunteer_activism, Colors.green),
              const SizedBox(width: 12),
              _buildStatCard('Total Receivers', '${_stats['totalReceivers']}', Icons.family_restroom, Colors.blue),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard('Pending Verifications', '${_stats['pendingVerifications']}', Icons.pending_actions, Colors.orange),
              const SizedBox(width: 12),
              _buildStatCard('Verified Today', '${_stats['verifiedToday']}', Icons.verified, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingDocumentsSection() {
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Pending Document Verifications',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_pendingDocuments.length}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildDocumentsList(),
        ],
      ),
    );
  }

  Widget _buildDocumentsList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_pendingDocuments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        width: double.infinity,
        child: Column(
          children: [
            Icon(Icons.verified_user, size: 64, color: Colors.green.shade400),
            const SizedBox(height: 16),
            const Text(
              'All documents are verified!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _pendingDocuments
          .map((doc) => Padding(
        padding: const EdgeInsets.only(bottom: 1),
        child: _buildDocumentCard(doc),
      ))
          .toList(),
    );
  }

  Widget _buildDocumentCard(dynamic doc) {
    // Safely access properties
    final id = doc['_id'] ?? '';
    final name = doc['name'] ?? 'Unknown';
    final userType = doc['userType'] ?? 'unknown';
    final uploadedDate = doc['createdAt'] != null 
        ? DateFormat('MMM d, yyyy').format(DateTime.parse(doc['createdAt'])) 
        : 'Unknown date';
    
    // Document info might be populated or just an ID
    final docInfo = doc['verificationDocument'];
    final docType = docInfo is Map ? (docInfo['filename'] ?? 'Document') : 'Document';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: userType == 'donor' ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              userType == 'donor' ? Icons.volunteer_activism : Icons.family_restroom,
              color: userType == 'donor' ? Colors.green : Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$docType • $userType',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Uploaded: $uploadedDate',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          _buildActionButtons(id, docInfo),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String userId, dynamic docInfo) {
    // Extract document ID for URL
    final docId = docInfo is Map ? docInfo['_id'] : docInfo;
    
    return Row(
      children: [
        // View Document button
        if (docId != null)
          InkWell(
            onTap: () => _handleViewDocument(docId.toString()),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.visibility, size: 18, color: Colors.blue),
            ),
          ),
        if (docId != null) const SizedBox(width: 8),
        InkWell(
          onTap: () => _handleApprove(userId),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.check, size: 18, color: Colors.green),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => _handleReject(userId),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.close, size: 18, color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onSubmitted: (_) => _fetchUsers(refresh: true),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _selectedUserType,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: '', child: Text('All')),
                  DropdownMenuItem(value: 'donor', child: Text('Donors')),
                  DropdownMenuItem(value: 'receiver', child: Text('Receivers')),
                ],
                onChanged: (val) {
                  setState(() => _selectedUserType = val ?? '');
                  _fetchUsers(refresh: true);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingUsers && _users.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _users.length + 1,
            itemBuilder: (context, index) {
              if (index == _users.length) {
                return _totalPages > _currentPage
                    ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: () {
                      _currentPage++;
                      _fetchUsers();
                    },
                    child: const Text('Load More'),
                  ),
                )
                    : const SizedBox(height: 20);
              }
              
              final user = _users[index];
              return _buildUserListItem(user);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserListItem(dynamic user) {
    final name = user['name'] ?? 'Unknown';
    final email = user['email'] ?? '';
    final userType = user['userType'] ?? 'unknown';
    final isVerified = user['verificationStatus'] == 'verified';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: userType == 'donor' ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
          child: Icon(
            userType == 'donor' ? Icons.volunteer_activism : Icons.family_restroom,
            color: userType == 'donor' ? Colors.green : Colors.blue,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (isVerified) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified, size: 16, color: Colors.blue),
            ],
          ],
        ),
        subtitle: Text('$email • ${userType.toUpperCase()}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _handleDeleteUser(user['_id']),
        ),
      ),
    );
  }
}