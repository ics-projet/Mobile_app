// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/app_bar.dart';
import '../services/sms_service.dart';
import '../services/session_manager.dart';

enum MessageType { outbound, inbound } 
enum MessageFilter { all, outbound, inbound } 

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
  bool _isLoadingMessages = false;
  List<Message> _messages = [];
  
  // Navigation state
  int _currentNavIndex = 0; // Dashboard is at index 0
  MessageFilter _currentFilter = MessageFilter.all;


  @override
  void initState() {
    super.initState();
    
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
    
    // Load sample data initially to avoid immediate API call
    _loadSampleData();
    
    // Optional: Load real data after a delay to let user see the dashboard first
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _loadMessages();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _recipientController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _loadSampleData() {
    // Load sample data immediately so user sees dashboard
    setState(() {
      _sentCount = 0;
      _receivedCount = 0;
      _pendingCount = 0;
      _messages = [];
    });
  }

  Future<void> _loadMessages() async {
    if (_isLoadingMessages) return;
    
    setState(() {
      _isLoadingMessages = true;
    });
    
    try {
      // Check if we have session data before making API call
      final hasSession = await SessionManager.hasValidSessionData();
      if (!hasSession) {
        setState(() {
          _isLoadingMessages = false;
        });
        _showSnackBar('Please login again', Colors.red);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      final result = await SmsService.getInbox();
      
      if (result['success']) {
        final messages = result['messages'] as List? ?? [];
        
        setState(() {
          _messages = messages.map((msg) {
            try {
              if (msg is Map<String, dynamic>) {
                return Message.fromJson(msg);
              } else if (msg is Map) {
                return Message.fromJson(Map<String, dynamic>.from(msg));
              } else {
                print('Invalid message format: $msg');
                return null;
              }
            } catch (e) {
              print('Error parsing message: $e');
              return null;
            }
          }).where((msg) => msg != null).cast<Message>().toList();
          
          _updateCounts();
          _isLoadingMessages = false;
        });
      } else {
        setState(() {
          _isLoadingMessages = false;
        });
        
        // FIXED: Better handling of authentication errors
        if (result['requires_login'] == true || 
            result['status_code'] == 401 || 
            result['status_code'] == 403) {
          
          // Clear the session since it's invalid
          await SessionManager.clearSession();
          
          _showSnackBar('Session expired. Please login again.', Colors.red);
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
          return;
        }
        
        // For other errors, show message but don't redirect
        _showSnackBar(result['error'] ?? 'Failed to load messages', Colors.orange);
      }
    } catch (e) {
      setState(() {
        _isLoadingMessages = false;
      });
      
      // Check if it's a network/authentication error
      if (e.toString().contains('403') || e.toString().contains('401')) {
        await SessionManager.clearSession();
        _showSnackBar('Authentication failed. Please login again.', Colors.red);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        _showSnackBar('Error loading messages: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<void> _sendSMS() async {
    if (_recipientController.text.isEmpty || _messageController.text.isEmpty) {
      _showSnackBar('Please fill in all fields', Colors.orange);
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _isSending = true;
    });

    try {
      // Check session before sending
      final hasSession = await SessionManager.hasValidSessionData();
      if (!hasSession) {
        setState(() {
          _isSending = false;
        });
        _showSnackBar('Please login again', Colors.red);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      final result = await SmsService.sendSms(
        recipient: _recipientController.text.trim(),
        message: _messageController.text.trim(),
      );

      if (result['success']) {
        final messageId = result['message_id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
final newMessage = Message(
  id: messageId,
  type: MessageType.outbound, // Changed from MessageType.sent
  recipient: _recipientController.text.trim(),
  content: _messageController.text.trim(),
  timestamp: DateTime.now(),
  status: MessageStatus.sent,
);
        
        setState(() {
          _messages.insert(0, newMessage);
          _sentCount++;
        });
        
        _recipientController.clear();
        _messageController.clear();
        
        final successMessage = result['message'] ?? 'SMS sent successfully!';
        _showSnackBar(successMessage, Colors.green);
        HapticFeedback.selectionClick();
      } else {
        // Handle authentication errors
        if (result['requires_login'] == true || 
            result['status_code'] == 401 || 
            result['status_code'] == 403) {
          
          await SessionManager.clearSession();
          _showSnackBar('Session expired. Please login again.', Colors.red);
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
          return;
        }
        
        final errorMessage = result['error'] ?? 'Failed to send SMS';
        _showSnackBar(errorMessage, Colors.red);
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      // Check for authentication errors in exceptions
      if (e.toString().contains('403') || e.toString().contains('401')) {
        await SessionManager.clearSession();
        _showSnackBar('Authentication failed. Please login again.', Colors.red);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        _showSnackBar('Error sending SMS: ${e.toString()}', Colors.red);
      }
      HapticFeedback.heavyImpact();
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showSnackBar(String message, [Color? color]) {
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
        backgroundColor: color ?? const Color(0xFF667eea),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.15,
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
void _updateCounts() {
  int sent = 0;
  int received = 0;
  int pending = 0;

  for (final message in _messages) {
    if (message.type == MessageType.outbound) {
      sent++;
    } else if (message.type == MessageType.inbound) {
      received++;
    }
    
    // Handle pending status separately if needed
    if (message.status == MessageStatus.pending) {
      pending++;
    }
  }

  setState(() {
    _sentCount = sent;
    _receivedCount = received;
    _pendingCount = pending;
  });
}
  // Navigation handling methods
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
          _handleNavigation(index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF667eea),
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment_outlined),
            activeIcon: Icon(Icons.assessment),
            label: 'Logs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            activeIcon: Icon(Icons.info),
            label: 'About',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout_outlined),
            activeIcon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
      ),
    );
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        // Already on Dashboard, do nothing
        break;
      case 1:
        _showSnackBar('Logs screen - Coming soon!');
        break;
      case 2:
        _showSnackBar('Settings screen - Coming soon!');
        break;
      case 3:
        _showSnackBar('About screen - Coming soon!');
        break;
      case 4:
        _logout();
        break;
    }
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
                        onDashboardTap: () {},
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
                        onLogout: _logout,
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async {
                            HapticFeedback.lightImpact();
                            await _loadMessages();
                          },
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(padding),
                            child: Column(
                              children: [
                                _buildStatsGrid(isTablet),
                                SizedBox(height: isTablet ? 32 : 20),
                                if (isTablet) 
                                  _buildTabletLayout()
                                else
                                  _buildMobileLayout(),
                                const SizedBox(height: 8),
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
    final childAspectRatio = isTablet ? 1.1 : 0.9;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: isTablet ? 20 : 16,
      mainAxisSpacing: isTablet ? 20 : 16,
      childAspectRatio: childAspectRatio,
      children: [
        _buildStatCard(
          'Received',
          _sentCount.toString(),
          Icons.inbox_rounded,
          const LinearGradient(
            colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
          ),
        ),
        _buildStatCard(
          'Sent',
          _receivedCount.toString(),
          Icons.send_rounded,
          const LinearGradient(
            colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
          ),
        ),
        _buildStatCard(
          'Pending',
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 28),
                      const SizedBox(height: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
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
            hintText: '0672937923 or +213672937923',
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

Widget _buildRecentMessagesCard() {
  // Filter messages based on current filter
  List<Message> filteredMessages = _messages.where((message) {
    switch (_currentFilter) {
      case MessageFilter.all:
        return true;
      case MessageFilter.outbound:
        return message.type == MessageType.outbound;
      case MessageFilter.inbound:
        return message.type == MessageType.inbound;
    }
  }).toList();

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
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header Row
        Row(
          children: [
            // Title section with proper flex
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
                  Flexible(
                    child: Text(
                      'Recent Messages',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            // Refresh button
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                onPressed: _isLoadingMessages ? null : () {
                  HapticFeedback.selectionClick();
                  _loadMessages();
                },
                icon: _isLoadingMessages 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded, 
                      color: Color(0xFF667eea),
                      size: 20,
                    ),
                tooltip: 'Refresh',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Filter buttons with SingleChildScrollView for overflow protection
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicWidth(
            child: Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width > 600 
                    ? (MediaQuery.of(context).size.width - 96) / 3 - 8
                    : 100,
                  child: _buildFilterButton(
                    'All',
                    MessageFilter.all,
                    Icons.all_inbox_rounded,
                    _messages.length,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width > 600 
                    ? (MediaQuery.of(context).size.width - 96) / 3 - 8
                    : 120,
                  child: _buildFilterButton(
                    'Received',
                    MessageFilter.outbound,
                    Icons.inbox_rounded,
                    _messages.where((m) => m.type == MessageType.outbound).length,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width > 600 
                    ? (MediaQuery.of(context).size.width - 96) / 3 - 8
                    : 100,
                  child: _buildFilterButton(
                    'Sent',
                    MessageFilter.inbound,
                    Icons.send_rounded,
                    _messages.where((m) => m.type == MessageType.inbound).length,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        
        // Content area with proper constraints
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
                minHeight: 100,
              ),
              child: filteredMessages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _currentFilter == MessageFilter.all 
                                ? Icons.message_outlined
                                : _currentFilter == MessageFilter.outbound
                                  ? Icons.send_outlined
                                  : Icons.inbox_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Flexible(
                              child: Text(
                                _isLoadingMessages 
                                  ? 'Loading messages...' 
                                  : _getEmptyStateMessage(),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                            if (!_isLoadingMessages) ...[
                              const SizedBox(height: 8),
                              Flexible(
                                child: Text(
                                  _getEmptyStateSubtitle(),
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredMessages.length,
                      itemBuilder: (context, index) {
                        final message = filteredMessages[index];
                        return _buildMessageItem(message, index);
                      },
                    ),
            );
          },
        ),
      ],
    ),
  );
}

// 4. Add these helper methods to your _DashboardScreenState class:
Widget _buildFilterButton(String label, MessageFilter filter, IconData icon, int count) {
  final isSelected = _currentFilter == filter;
  
  return GestureDetector(
    onTap: () {
      HapticFeedback.selectionClick();
      setState(() {
        _currentFilter = filter;
      });
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: isSelected 
          ? const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            )
          : null,
        color: isSelected ? null : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: isSelected 
          ? null 
          : Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected 
                  ? Colors.white.withOpacity(0.2)
                  : const Color(0xFF667eea).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

String _getEmptyStateMessage() {
  switch (_currentFilter) {
    case MessageFilter.all:
      return 'No messages yet';
    case MessageFilter.outbound:
      return 'No sent messages';
    case MessageFilter.inbound:
      return 'No received messages';
  }
}

String _getEmptyStateSubtitle() {
  switch (_currentFilter) {
    case MessageFilter.all:
      return 'Send your first SMS to get started!';
    case MessageFilter.outbound:
      return 'Send an SMS to see it here';
    case MessageFilter.inbound:
      return 'Received messages will appear here';
  }
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
              color: message.type == MessageType.outbound
                  ? const Color(0xFFf0fff4)
                  : const Color(0xFFf0f8ff),
              borderRadius: BorderRadius.circular(16),
              border: Border(
                left: BorderSide(
                  color: message.type == MessageType.outbound
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
                        message.type == MessageType.outbound
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

  // Add the missing fromJson factory method
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? json['message_id']?.toString() ?? '',
      type: _parseMessageType(json['type']?.toString()),
      recipient: json['recipient']?.toString(),
      sender: json['sender']?.toString() ?? json['phone_number']?.toString(),
      content: json['message']?.toString() ?? json['content']?.toString() ?? '',
      timestamp: _parseTimestamp(json['timestamp'] ?? json['created_at']),
      status: _parseMessageStatus(json['status']?.toString()),
    );
  }

static MessageType _parseMessageType(String? type) {
  switch (type?.toLowerCase()) {
    case 'outbound':
    case 'sent':
    case 'outgoing':
      return MessageType.outbound;
    case 'inbound':
    case 'received':
    case 'incoming':
      return MessageType.inbound;
    default:
      return MessageType.outbound; // Default to outbound
  }
}

  static MessageStatus _parseMessageStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'sent':
      case 'delivered':
      case 'success':
        return MessageStatus.sent;
      case 'received':
        return MessageStatus.received;
      case 'pending':
      case 'processing':
        return MessageStatus.pending;
      default:
        return MessageStatus.pending;
    }
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return DateTime.now();
      }
    }
    
    if (timestamp is int) {
      // Handle Unix timestamp (seconds or milliseconds)
      if (timestamp.toString().length == 10) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      } else {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    }
    
    return DateTime.now();
  }

  // Convert to JSON for sending to backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'recipient': recipient,
      'sender': sender,
      'message': content,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
    };
  }
}