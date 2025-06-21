// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/app_bar.dart'; 


class DashboardScreen extends StatefulWidget {
  final String username;
  
  const DashboardScreen({Key? key, required this.username}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  // Controllers for form inputs
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  

  
  // App state
  int _sentCount = 0;
  int _receivedCount = 0;
  int _pendingCount = 0;
  bool _isSending = false;
  List<Message> _messages = [];
  
  @override
  void initState() {
    super.initState();
    
    final String username = widget.username;
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Start animation
    _animationController.forward();
    
    // Load initial data
    _loadInitialData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _recipientController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    // Simulate loading data
    setState(() {
      _sentCount = 15;
      _receivedCount = 8;
      _pendingCount = 2;
      _messages = [
        Message(
          id: '1',
          type: MessageType.sent,
          recipient: '+1234567890',
          content: 'Hello! This is a test message.',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          status: MessageStatus.sent,
        ),
        Message(
          id: '2',
          type: MessageType.received,
          sender: '+0987654321',
          content: 'Thanks for the update!',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          status: MessageStatus.received,
        ),
      ];
    });
  }

  Future<void> _sendSMS() async {
    if (_recipientController.text.isEmpty || _messageController.text.isEmpty) {
      _showSnackBar('Please fill in all fields', Colors.orange);
      return;
    }

    // Haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      _isSending = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate success (90% success rate)
      if (DateTime.now().millisecond % 10 != 0) {
        // Success - add message to list
        final newMessage = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: MessageType.sent,
          recipient: _recipientController.text,
          content: _messageController.text,
          timestamp: DateTime.now(),
          status: MessageStatus.sent,
        );
        
        setState(() {
          _messages.insert(0, newMessage);
          _sentCount++;
        });
        
        _recipientController.clear();
        _messageController.clear();
        _showSnackBar('SMS sent successfully!', Colors.green);
        HapticFeedback.selectionClick();
      } else {
        // Simulate failure
        _showSnackBar('Failed to send SMS. Please try again.', Colors.red);
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      _showSnackBar('Error sending SMS', Colors.red);
      HapticFeedback.heavyImpact();
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : 
              color == Colors.red ? Icons.error : Icons.info,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.1,
          left: 16,
          right: 16,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _logout() {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final padding = isTablet ? 24.0 : 16.0;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    children: [
                      CustomAppBar(
                        activeTab: 'dashboard',
                        onDashboardTap: () {}, // already here, or navigate
                        onLogsTap: () => Navigator.pushNamed(
                                            context,
                                            '/logs',
                                            arguments: {'username': widget.username},

                                          ),

                        onSettingsTap: () => Navigator.pushNamed(
                                context,
                                '/settings',
                                arguments: {'username': widget.username},
                            ),
                        onLogout: _logout, // your existing logout function
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async {
                            HapticFeedback.lightImpact();
                            _loadInitialData();
                            await Future.delayed(const Duration(milliseconds: 500));
                          },
                          color: const Color(0xFF667eea),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.all(padding),
                            child: Column(
                              children: [
                                _buildStatsGrid(isTablet),
                                SizedBox(height: isTablet ? 32 : 20),
                                if (isTablet) 
                                  _buildTabletLayout()
                                else
                                  _buildMobileLayout(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }



  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: _buildSendSMSCard(),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: _buildRecentMessagesCard(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildSendSMSCard(),
        const SizedBox(height: 20),
        _buildRecentMessagesCard(),
      ],
    );
  }

    Widget _buildStatsGrid(bool isTablet) {
    final crossAxisCount = isTablet ? 4 : 2;
    // Increased aspect ratio to give more height
    final childAspectRatio = isTablet ? 1.1 : 0.9; // Changed from 1.3 : 1.2
    
    return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: isTablet ? 20 : 16,
        mainAxisSpacing: isTablet ? 20 : 16,
        childAspectRatio: childAspectRatio,
        children: [
        _buildStatCard(
            'Sent', // Shortened from 'Messages Sent'
            _sentCount.toString(),
            Icons.send_rounded,
            const LinearGradient(
            colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
            ),
        ),
        _buildStatCard(
            'Received', // Shortened from 'Messages Received'
            _receivedCount.toString(),
            Icons.inbox_rounded,
            const LinearGradient(
            colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
            ),
        ),
        _buildStatCard(
            'Pending', // Shortened from 'Pending Messages'
            _pendingCount.toString(),
            Icons.schedule_rounded,
            const LinearGradient(
            colors: [Color(0xFFfa709a), Color(0xFFfee140)],
            ),
        ),
        _buildStatCard(
            'Success Rate',
            '${_calculateSuccessRate()}%',
            Icons.trending_up_rounded,
            const LinearGradient(
            colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
            ),
        ),
        ],
    );
    }

    Widget _buildStatCard(String title, String value, IconData icon, LinearGradient gradient) {
    return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 800),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, animationValue, child) {
        return Transform.scale(
            scale: 0.8 + (0.2 * animationValue),
            child: Container(
            decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                BoxShadow(
                    color: gradient.colors.first.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                ),
                ],
            ),
            child: Material(
                color: Colors.transparent,
                child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => HapticFeedback.selectionClick(),
                child: Padding(
                    padding: const EdgeInsets.all(16), // Reduced from 20
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(icon, color: Colors.white, size: 28), // Reduced from 32
                        const SizedBox(height: 8), // Reduced from 12
                        Flexible( // Added Flexible wrapper
                        child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                            value,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24, // Reduced from 28
                                fontWeight: FontWeight.bold,
                            ),
                            ),
                        ),
                        ),
                        const SizedBox(height: 4), // Reduced from 6
                        Flexible( // Added Flexible wrapper for title
                        child: Text(
                            title,
                            style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11, // Reduced from 12
                            fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                        ),
                        ),
                    ],
                    ),
                ),
                ),
            ),
            ),
        );
        },
    );
    }

  Widget _buildSendSMSCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Send SMS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _recipientController,
            labelText: 'Recipient',
            hintText: '+1234567890',
            prefixIcon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _messageController,
            labelText: 'Message',
            hintText: 'Type your message here...',
            prefixIcon: Icons.message_rounded,
            maxLines: 3,
            maxLength: 160,
            showCounter: true,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendSMS,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43e97b),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child: _isSending
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Sending...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    )
                  : const Text(
                      'Send SMS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    bool showCounter = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF667eea)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        counterText: showCounter ? '${controller.text.length}/${maxLength ?? 0}' : null,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: showCounter ? (value) => setState(() {}) : null,
    );
  }

 // Fixed version of the Recent Messages Card header

Widget _buildRecentMessagesCard() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fixed header row with proper spacing
        Row(
          children: [
            // Left side with icon and title - flexible to take available space
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.message_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Flexible( // Added Flexible to prevent overflow
                    child: Text(
                      'Recent Messages',
                      style: TextStyle(
                        fontSize: 18, // Reduced from 20 to give more space
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Right side with refresh button - fixed width
            const SizedBox(width: 8), // Small spacing
            Container(
              width: 40, // Fixed width for button
              height: 40, // Fixed height for button
              child: IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _loadInitialData();
                },
                icon: const Icon(
                  Icons.refresh_rounded, 
                  color: Color(0xFF667eea),
                  size: 20, // Reduced icon size
                ),
                tooltip: 'Refresh',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.zero, // Remove default padding
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _messages.isEmpty
            ? Container(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.message_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No messages yet',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Send your first SMS to get started!',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageItem(message, index);
                },
              ),
      ],
    ),
  );
}

  Widget _buildMessageItem(Message message, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.type == MessageType.sent
                    ? const Color(0xFFf0fff4)
                    : const Color(0xFFf0f8ff),
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(
                    color: message.type == MessageType.sent
                        ? const Color(0xFF43e97b)
                        : const Color(0xFF4facfe),
                    width: 4,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          message.type == MessageType.sent
                              ? 'To: ${message.recipient ?? 'Unknown'}'
                              : 'From: ${message.sender ?? 'Unknown'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(message.status),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          message.status.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDateTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message.content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return Colors.green.shade600;
      case MessageStatus.received:
        return Colors.blue.shade600;
      case MessageStatus.pending:
        return Colors.orange.shade600;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  int _calculateSuccessRate() {
    final total = _sentCount + _receivedCount;
    if (total == 0) return 0;
    return ((_sentCount / total) * 100).round();
  }
}

// Data Models
enum MessageType { sent, received }
enum MessageStatus { sent, received, pending }

class Message {
  final String id;
  final MessageType type;
  final String? recipient;
  final String? sender;
  final String content;
  final DateTime timestamp;
  final MessageStatus status;

  Message({
    required this.id,
    required this.type,
    this.recipient,
    this.sender,
    required this.content,
    required this.timestamp,
    required this.status,
  });
}