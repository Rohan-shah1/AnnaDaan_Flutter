import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final notifications = await apiService.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _markAsRead(String id) async {
    // Optimistic update
    setState(() {
      final index = _notifications.indexWhere((n) => n['_id'] == id);
      if (index != -1) {
        _notifications[index]['isRead'] = true;
      }
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.markNotificationRead(id);
    } catch (e) {
      print('Error marking notification read: $e');
    }
  }

  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
    // TODO: Call API to clear all if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'mark_all_read') {
                  // _markAllAsRead();
                } else if (value == 'clear_all') {
                  _clearAll();
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.mark_email_read, color: Colors.grey.shade700),
                      SizedBox(width: 8),
                      Text('Mark all as read', style: TextStyle(fontFamily: 'Poppins')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, color: Colors.grey.shade700),
                      SizedBox(width: 8),
                      Text('Clear all', style: TextStyle(fontFamily: 'Poppins')),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.all(20),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return _buildNotificationItem(notification);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(dynamic notification) {
    bool isRead = notification['isRead'] ?? false;
    return Dismissible(
      key: Key(notification['_id'] ?? UniqueKey().toString()),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        margin: EdgeInsets.only(bottom: 16),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        setState(() {
          _notifications.removeWhere((item) => item['_id'] == notification['_id']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification cleared')),
        );
      },
      child: GestureDetector(
        onTap: () {
          if (!isRead) {
            _markAsRead(notification['_id']);
          }
          _showNotificationDetails(notification);
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRead ? Colors.grey.shade200 : Color(0xFFC8E6C9),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getIconColor(notification['type'] ?? 'system').withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(notification['type'] ?? 'system'),
                  color: _getIconColor(notification['type'] ?? 'system'),
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'] ?? 'Notification',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isRead ? Colors.black87 : Color(0xFF2E7D32),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        Text(
                          notification['createdAt'] != null 
                              ? _formatTime(notification['createdAt']) 
                              : 'Just now',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      notification['message'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else {
        return '${diff.inDays}d ago';
      }
    } catch (e) {
      return 'Just now';
    }
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(_getNotificationIcon(notification['type'] ?? 'system'),
                  color: _getNotificationColor(notification['type'] ?? 'system')),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  notification['title'] ?? 'Notification',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  notification['message'] ?? '',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
                ),
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 8),
                Text(
                  'Time: ${notification['createdAt'] != null ? _formatTime(notification['createdAt']) : 'Just now'}',
                  style: TextStyle(fontFamily: 'Poppins', color: Colors.grey.shade600),
                ),
                SizedBox(height: 4),
                Text(
                  'Status: ${(notification['isRead'] ?? false) ? 'Read' : 'Unread'}',
                  style: TextStyle(fontFamily: 'Poppins', color: Colors.grey.shade600),
                ),
                SizedBox(height: 16),

                // Action buttons based on notification type
                if (notification['type'] == 'reservation')
                  _buildReservationActions()
                else if (notification['type'] == 'request')
                  _buildRequestActions()
                else if (notification['type'] == 'reminder')
                    _buildReminderActions(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(fontFamily: 'Poppins')),
            ),
            if (!(notification['isRead'] ?? false))
              TextButton(
                onPressed: () {
                  _markAsRead(notification['_id']);
                  Navigator.of(context).pop();
                },
                child: Text('Mark as Read', style: TextStyle(fontFamily: 'Poppins')),
              ),
          ],
        );
      },
    );
  }

  Widget _buildReservationActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _showMessage('Contacting Hope Foundation...');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF2E7D32),
          ),
          child: Text('Contact NGO',selectionColor: Colors.white, style: TextStyle(fontFamily: 'Poppins')),
        ),
        SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _showMessage('Viewing donation details...');
          },
          child: Text('View Donation', style: TextStyle(fontFamily: 'Poppins')),
        ),
      ],
    );
  }

  Widget _buildRequestActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showMessage('Donation request accepted!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2E7D32),
            ),
            child: Text('Accept', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showMessage('Donation request declined');
            },
            child: Text('Decline', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _showMessage('Extending donation expiry...');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade600,
          ),
          child: Text('Extend Expiry', style: TextStyle(fontFamily: 'Poppins')),
        ),
        SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _showMessage('Opening donation management...');
          },
          child: Text('Manage Donation', style: TextStyle(fontFamily: 'Poppins')),
        ),
      ],
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: 'Poppins')),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'reservation':
        return Color(0xFF4CAF50); // Green
      case 'request':
        return Color(0xFF2196F3); // Blue
      case 'completion':
        return Color(0xFF9C27B0); // Purple
      case 'impact':
        return Color(0xFFFF9800); // Orange
      case 'interest':
        return Color(0xFF607D8B); // Blue Grey
      case 'reminder':
        return Color(0xFFF44336); // Red
      default:
        return Color(0xFF2E7D32); // Default green
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'reservation':
        return Icons.assignment_turned_in;
      case 'request':
        return Icons.notifications_active;
      case 'completion':
        return Icons.check_circle;
      case 'impact':
        return Icons.emoji_events;
      case 'interest':
        return Icons.thumb_up;
      case 'reminder':
        return Icons.access_time;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String type) {
    return _getNotificationColor(type);
  }
}