// lib/screens/logs_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LogsScreen extends StatefulWidget {
  final String username;
  
  const LogsScreen({Key? key, required this.username}) : super(key: key);

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  // Filter controllers
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String _statusFilter = '';
  String _typeFilter = '';
  
  // App state
  List<SMSLog> _allLogs = [];
  List<SMSLog> _filteredLogs = [];
  int _currentPage = 1;
  final int _logsPerPage = 10;
  bool _isLoading = false;
  bool _isRefreshing = false;
  
  // Statistics
  int _totalMessages = 0;
  int _successfulMessages = 0;
  int _failedMessages = 0;
  double _successRate = 0.0;

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
    
    // Set default date range (last 30 days)
    final now = DateTime.now();
    _dateTo = now;
    _dateFrom = now.subtract(const Duration(days: 30));
    
    // Start animation and load data
    _animationController.forward();
    _loadLogs();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Generate mock logs data
  List<SMSLog> _generateMockLogs() {
    final logs = <SMSLog>[];
    final statuses = [LogStatus.sent, LogStatus.failed, LogStatus.pending];
    final types = [LogType.outbound, LogType.inbound];
    final phones = ['+1234567890', '+0987654321', '+1122334455', '+5566778899'];
    final messages = [
      'Hello, this is a test message',
      'Your appointment is confirmed for tomorrow',
      'Thank you for your purchase',
      'Meeting reminder: 3 PM today',
      'Your verification code is 123456',
      'Welcome to our service!',
      'Payment received successfully',
      'Order #12345 has been shipped'
    ];

    for (int i = 0; i < 50; i++) {
      final date = DateTime.now().subtract(Duration(
        days: (DateTime.now().millisecond % 30),
        hours: (DateTime.now().millisecond % 24),
        minutes: (DateTime.now().millisecond % 60),
      ));
      
      logs.add(SMSLog(
        id: (i + 1).toString(),
        phoneNumber: phones[i % phones.length],
        message: messages[i % messages.length],
        status: statuses[i % statuses.length],
        type: types[i % types.length],
        timestamp: date,
        deliveryTime: (i % 10) + 1.0,
      ));
    }

    return logs..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> _loadLogs() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 800));
      
      _allLogs = _generateMockLogs();
      _applyFilters();
      _updateStatistics();
    } catch (e) {
      _showSnackBar('Error loading logs', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshLogs() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    HapticFeedback.lightImpact();
    await _loadLogs();
    
    setState(() {
      _isRefreshing = false;
    });
  }

  void _applyFilters() {
    _filteredLogs = _allLogs.where((log) {
      // Date filter
      if (_dateFrom != null && log.timestamp.isBefore(_dateFrom!)) return false;
      if (_dateTo != null && log.timestamp.isAfter(_dateTo!.add(const Duration(days: 1)))) return false;
      
      // Status filter
      if (_statusFilter.isNotEmpty && log.status.name != _statusFilter) return false;
      
      // Type filter
      if (_typeFilter.isNotEmpty && log.type.name != _typeFilter) return false;
      
      // Search filter
      final searchTerm = _searchController.text.toLowerCase();
      if (searchTerm.isNotEmpty &&
          !log.phoneNumber.toLowerCase().contains(searchTerm) &&
          !log.message.toLowerCase().contains(searchTerm)) {
        return false;
      }
      
      return true;
    }).toList();

    _currentPage = 1;
    _updateStatistics();
    setState(() {});
  }

  void _updateStatistics() {
    _totalMessages = _filteredLogs.length;
    _successfulMessages = _filteredLogs.where((log) => log.status == LogStatus.sent).length;
    _failedMessages = _filteredLogs.where((log) => log.status == LogStatus.failed).length;
    _successRate = _totalMessages > 0 ? (_successfulMessages / _totalMessages) * 100 : 0.0;
  }

  void _showLogDetails(SMSLog log) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            const Expanded(child: Text('Log Details')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', log.id),
              _buildDetailRow('Phone', log.phoneNumber),
              _buildDetailRow('Message', log.message),
              _buildDetailRow('Status', log.status.name.toUpperCase()),
              _buildDetailRow('Type', log.type.name.toUpperCase()),
              _buildDetailRow('Time', _formatDateTime(log.timestamp)),
              _buildDetailRow('Delivery Time', '${log.deliveryTime.toStringAsFixed(2)}s'),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _exportLogs() {
    HapticFeedback.selectionClick();
    // Simulate export functionality
    _showSnackBar('Logs exported successfully!', Colors.green);
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
            const Expanded(child: Text('Logout')),
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
                      _buildAppBar(padding),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _refreshLogs,
                          color: const Color(0xFF667eea),
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.all(padding),
                            child: Column(
                              children: [
                                _buildFiltersCard(isTablet),
                                SizedBox(height: isTablet ? 24 : 16),
                                _buildStatsGrid(isTablet),
                                SizedBox(height: isTablet ? 24 : 16),
                                _buildLogsCard(isTablet),
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

  Widget _buildAppBar(double padding) {
    return Container(
      margin: EdgeInsets.all(padding),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.analytics, color: Colors.white, size: 20),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'SMS Logs',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF667eea),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dashboard button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.dashboard, color: Color(0xFF667eea), size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Hi, ${widget.username}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _logout,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.logout, color: Colors.red, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersCard(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
                child: const Icon(Icons.filter_list, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _exportLogs,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF667eea),
                  backgroundColor: const Color(0xFF667eea).withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isTablet)
            _buildTabletFilters()
          else
            _buildMobileFilters(),
        ],
      ),
    );
  }

  Widget _buildTabletFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildDateFromField()),
            const SizedBox(width: 16),
            Expanded(child: _buildDateToField()),
            const SizedBox(width: 16),
            Expanded(child: _buildStatusFilter()),
            const SizedBox(width: 16),
            Expanded(child: _buildTypeFilter()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(flex: 3, child: _buildSearchField()),
            const SizedBox(width: 16),
            Expanded(child: _buildFilterButton()),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildDateFromField()),
            const SizedBox(width: 12),
            Expanded(child: _buildDateToField()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatusFilter()),
            const SizedBox(width: 12),
            Expanded(child: _buildTypeFilter()),
          ],
        ),
        const SizedBox(height: 12),
        _buildSearchField(),
        const SizedBox(height: 16),
        _buildFilterButton(),
      ],
    );
  }

  Widget _buildDateFromField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date From', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _dateFrom ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() {
                _dateFrom = date;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _dateFrom != null ? _formatDate(_dateFrom!) : 'Select date',
                    style: TextStyle(color: Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateToField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date To', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _dateTo ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() {
                _dateTo = date;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _dateTo != null ? _formatDate(_dateTo!) : 'Select date',
                    style: TextStyle(color: Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _statusFilter.isEmpty ? null : _statusFilter,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          hint: const Text('All Status'),
          items: const [
            DropdownMenuItem(value: '', child: Text('All Status')),
            DropdownMenuItem(value: 'sent', child: Text('Sent')),
            DropdownMenuItem(value: 'failed', child: Text('Failed')),
            DropdownMenuItem(value: 'pending', child: Text('Pending')),
          ],
          onChanged: (value) {
            setState(() {
              _statusFilter = value ?? '';
            });
          },
        ),
      ],
    );
  }

  Widget _buildTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _typeFilter.isEmpty ? null : _typeFilter,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          hint: const Text('All Types'),
          items: const [
            DropdownMenuItem(value: '', child: Text('All Types')),
            DropdownMenuItem(value: 'outbound', child: Text('Outbound')),
            DropdownMenuItem(value: 'inbound', child: Text('Inbound')),
          ],
          onChanged: (value) {
            setState(() {
              _typeFilter = value ?? '';
            });
          },
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Search',
        hintText: 'Search messages or phone numbers...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      onChanged: (value) => _applyFilters(),
    );
  }

  Widget _buildFilterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.selectionClick();
          _applyFilters();
        },
        icon: const Icon(Icons.filter_list, size: 18),
        label: const Text('Apply Filters'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF667eea),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(bool isTablet) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isTablet ? 4 : 2,
      crossAxisSpacing: isTablet ? 20 : 16,
      mainAxisSpacing: isTablet ? 20 : 16,
      childAspectRatio: isTablet ? 1.1 : 0.9,
      children: [
        _buildStatCard(
          'Total',
          _totalMessages.toString(),
          Icons.message_rounded,
          const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]),
        ),
        _buildStatCard(
          'Successful',
          _successfulMessages.toString(),
          Icons.check_circle_rounded,
          const LinearGradient(colors: [Color(0xFF43e97b), Color(0xFF38f9d7)]),
        ),
        _buildStatCard(
          'Failed',
          _failedMessages.toString(),
          Icons.error_rounded,
          const LinearGradient(colors: [Color(0xFFfa709a), Color(0xFFfee140)]),
        ),
        _buildStatCard(
          'Success Rate',
          '${_successRate.toStringAsFixed(1)}%',
          Icons.trending_up_rounded,
          const LinearGradient(colors: [Color(0xFFf093fb), Color(0xFFf5576c)]),
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
        );
      },
    );
  }



  Widget _buildLogsCard(bool isTablet) {
    return Container(
      width: double.infinity,
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
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
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
                  child: const Icon(Icons.list, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Message Logs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                const SizedBox(width: 8),
                Text(
                  '${_filteredLogs.length} messages',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Table/List content
          if (_filteredLogs.isEmpty && !_isLoading)
            _buildEmptyState()
          else
            _buildLogsTable(isTablet),
            
          // Pagination
          if (_filteredLogs.isNotEmpty)
            _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or date range',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsTable(bool isTablet) {
    final startIndex = (_currentPage - 1) * _logsPerPage;
    final endIndex = startIndex + _logsPerPage;
    final logsToShow = _filteredLogs.length > endIndex 
        ? _filteredLogs.sublist(startIndex, endIndex)
        : _filteredLogs.sublist(startIndex);

    if (isTablet) {
      return _buildTableView(logsToShow);
    } else {
      return _buildListView(logsToShow);
    }
  }

  Widget _buildTableView(List<SMSLog> logs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
        dataRowHeight: 60,
        headingRowHeight: 50,
        horizontalMargin: 20,
        columnSpacing: 24,
        columns: const [
          DataColumn(
            label: Text(
              'Date/Time',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          DataColumn(
            label: Text(
              'Phone Number',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          DataColumn(
            label: Text(
              'Message',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          DataColumn(
            label: Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          DataColumn(
            label: Text(
              'Type',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          DataColumn(
            label: Text(
              'Actions',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
        rows: logs.map((log) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  _formatDateTime(log.timestamp),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              DataCell(
                Text(
                  log.phoneNumber,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 200,
                  child: Text(
                    log.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              DataCell(_buildStatusBadge(log.status)),
              DataCell(_buildTypeBadge(log.type)),
              DataCell(
                IconButton(
                  onPressed: () => _showLogDetails(log),
                  icon: const Icon(Icons.visibility, size: 18),
                  color: const Color(0xFF667eea),
                  tooltip: 'View Details',
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListView(List<SMSLog> logs) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Card(
            elevation: 0,
            color: Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(log.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  log.type == LogType.outbound 
                      ? Icons.call_made 
                      : Icons.call_received,
                  color: _getStatusColor(log.status),
                  size: 20,
                ),
              ),
              title: Text(
                log.phoneNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    log.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildStatusBadge(log.status),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateTime(log.timestamp),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: IconButton(
                onPressed: () => _showLogDetails(log),
                icon: const Icon(Icons.more_vert),
                color: Colors.grey.shade600,
              ),
              onTap: () => _showLogDetails(log),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(LogStatus status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case LogStatus.sent:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle;
        break;
      case LogStatus.failed:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        icon = Icons.error;
        break;
      case LogStatus.pending:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.schedule;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.name.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(LogType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: type == LogType.outbound 
            ? Colors.blue.shade100 
            : Colors.purple.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            type == LogType.outbound ? Icons.call_made : Icons.call_received,
            size: 12,
            color: type == LogType.outbound 
                ? Colors.blue.shade700 
                : Colors.purple.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            type.name.toUpperCase(),
            style: TextStyle(
              color: type == LogType.outbound 
                  ? Colors.blue.shade700 
                  : Colors.purple.shade700,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    final totalPages = (_filteredLogs.length / _logsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous button
            IconButton(
              onPressed: _currentPage > 1 
                  ? () {
                      setState(() {
                        _currentPage--;
                      });
                    }
                  : null,
              icon: const Icon(Icons.chevron_left),
              style: IconButton.styleFrom(
                backgroundColor: _currentPage > 1 
                    ? const Color(0xFF667eea).withOpacity(0.1)
                    : Colors.grey.shade100,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Page numbers
            ...List.generate(
              totalPages > 5 ? 5 : totalPages,
              (index) {
                int pageNumber;
                if (totalPages <= 5) {
                  pageNumber = index + 1;
                } else {
                  if (_currentPage <= 3) {
                    pageNumber = index + 1;
                  } else if (_currentPage >= totalPages - 2) {
                    pageNumber = totalPages - 4 + index;
                  } else {
                    pageNumber = _currentPage - 2 + index;
                  }
                }
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentPage = pageNumber;
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _currentPage == pageNumber
                            ? const Color(0xFF667eea)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _currentPage == pageNumber
                              ? const Color(0xFF667eea)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          pageNumber.toString(),
                          style: TextStyle(
                            color: _currentPage == pageNumber
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(width: 16),
            
            // Next button
            IconButton(
              onPressed: _currentPage < totalPages 
                  ? () {
                      setState(() {
                        _currentPage++;
                      });
                    }
                  : null,
              icon: const Icon(Icons.chevron_right),
              style: IconButton.styleFrom(
                backgroundColor: _currentPage < totalPages 
                    ? const Color(0xFF667eea).withOpacity(0.1)
                    : Colors.grey.shade100,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(LogStatus status) {
    switch (status) {
      case LogStatus.sent:
        return Colors.green.shade600;
      case LogStatus.failed:
        return Colors.red.shade600;
      case LogStatus.pending:
        return Colors.orange.shade600;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    
    return '$day/$month/$year $hour:$minute';
  }
}

// Data Models
class SMSLog {
  final String id;
  final String phoneNumber;
  final String message;
  final LogStatus status;
  final LogType type;
  final DateTime timestamp;
  final double deliveryTime;

  SMSLog({
    required this.id,
    required this.phoneNumber,
    required this.message,
    required this.status,
    required this.type,
    required this.timestamp,
    required this.deliveryTime,
  });
}

enum LogStatus { sent, failed, pending }
enum LogType { outbound, inbound }