import 'package:flutter/material.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  _HelpSupportScreenState createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<FAQItem> _faqs = [
    FAQItem(
      question: 'How do I post a donation?',
      answer: 'To post a donation:\n\n1. Click on "Post Donation" from the dashboard\n2. Fill in the food details, quantity, and timing\n3. Set pickup window and dietary information\n4. Submit the donation for NGOs to view',
    ),
    FAQItem(
      question: 'What are the food safety requirements?',
      answer: 'Food safety requirements:\n\n• Food must be stored at safe temperatures\n• Proper packaging and covering is mandatory\n• Food should be fresh and of good quality\n• Label with preparation time if applicable\n• Follow all local food safety guidelines',
    ),
    FAQItem(
      question: 'How do NGOs find my donations?',
      answer: 'NGOs can:\n\n• Browse active donations in their area\n• Set preferences for food types they need\n• Receive notifications for new donations\n• Contact you directly through the app',
    ),
    FAQItem(
      question: 'Can I edit or cancel a donation?',
      answer: 'Yes, you can:\n\n• Edit active donations before they are reserved\n• Cancel donations if no NGO has shown interest\n• Update pickup times if needed\n• Contact reserved NGOs to make changes',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Help & Support',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FAQ Section
            _buildFAQSection(),
            const SizedBox(height: 32),

            // Contact Support Section
            _buildContactSupport(),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequently Asked Questions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 16),
        ..._faqs.map((faq) => _buildFAQItem(faq)).toList(),
      ],
    );
  }

  Widget _buildFAQItem(FAQItem faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              faq.answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontFamily: 'Poppins',
                height: 1.5,
              ),
            ),
          ),
        ],
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  Widget _buildContactSupport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Support',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 16),

        // Email Support
        _buildContactCard(
          icon: Icons.email,
          title: 'Email Support',
          subtitle: 'support@annadaan.org',
          onTap: () {
            // TODO: Implement email
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Opening email app...', style: TextStyle(fontFamily: 'Poppins')),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Phone Support
        _buildContactCard(
          icon: Icons.phone,
          title: 'Phone Support',
          subtitle: '+91800 1234567 (Toll Free)',
          onTap: () {
            // TODO: Implement phone call
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Calling support...', style: TextStyle(fontFamily: 'Poppins')),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Live Chat
        _buildContactCard(
          icon: Icons.chat,
          title: 'Live Chat',
          subtitle: 'Available 9 AM - 6 PM',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Live chat coming soon!', style: TextStyle(fontFamily: 'Poppins')),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFF2E7D32),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontFamily: 'Poppins',
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade600),
        onTap: onTap,
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}