import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SMSGatewaySettingsScreen extends StatefulWidget {
  const SMSGatewaySettingsScreen({Key? key}) : super(key: key);

  @override
  State<SMSGatewaySettingsScreen> createState() => _SMSGatewaySettingsScreenState();
}

class _SMSGatewaySettingsScreenState extends State<SMSGatewaySettingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // General Settings
  final TextEditingController _deviceNameController = TextEditingController(text: 'SMS Gateway #1');
  final TextEditingController _autoResponseController = TextEditingController();
  String _selectedTimezone = 'UTC';
  bool _autoResponses = true;
  
  // API Settings
  final TextEditingController _rateLimitController = TextEditingController(text: '60');
  final TextEditingController _allowedIPsController = TextEditingController();
  bool _rateLimiting = true;
  bool _httpsOnly = true;
  bool _requestLogging = true;
  final TextEditingController _sessionTimeoutController = TextEditingController(text: '30');
  final TextEditingController _maxLoginAttemptsController = TextEditingController(text: '5');
  String _apiKey = 'sk_1234567890abcdef';
  bool _showApiKey = false;
  
  // GSM Settings
  String _gsmModule = 'SIM800L';
  String _baudRate = '115200';
  final TextEditingController _serialPortController = TextEditingController(text: '/dev/ttyUSB0');
  final TextEditingController _simPinController = TextEditingController();
  bool _autoReconnect = true;
  bool _gsmConnected = true;
  
  // Webhook Settings
  bool _enableWebhooks = false;
  final TextEditingController _webhookUrlController = TextEditingController();
  final TextEditingController _webhookSecretController = TextEditingController();
  bool _webhookSent = true;
  bool _webhookReceived = true;
  bool _webhookFailed = false;
  bool _webhookStatus = false;
  
  // Advanced Settings
  final TextEditingController _maxRetriesController = TextEditingController(text: '3');
  final TextEditingController _retryDelayController = TextEditingController(text: '30');
  final TextEditingController _queueSizeController = TextEditingController(text: '100');
  final TextEditingController _dataRetentionController = TextEditingController(text: '30');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    // Dispose all controllers
    _deviceNameController.dispose();
    _autoResponseController.dispose();
    _rateLimitController.dispose();
    _allowedIPsController.dispose();
    _sessionTimeoutController.dispose();
    _maxLoginAttemptsController.dispose();
    _serialPortController.dispose();
    _simPinController.dispose();
    _webhookUrlController.dispose();
    _webhookSecretController.dispose();
    _maxRetriesController.dispose();
    _retryDelayController.dispose();
    _queueSizeController.dispose();
    _dataRetentionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFF667eea),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildHeader(),
                          _buildTabBar(),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildGeneralTab(),
                                _buildApiTab(),
                                _buildGsmTab(),
                                _buildWebhooksTab(),
                                _buildAdvancedTab(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.sms, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'SMS Gateway',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2c3e50),
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildNavButton('🏠 Dashboard', Icons.dashboard, () {}),
              const SizedBox(width: 12),
              _buildNavButton('📊 Logs', Icons.analytics, () {}),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.settings, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildLogoutButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(String text, IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 6),
              Text(
                text.replaceAll(RegExp(r'[^\w\s]'), ''),
                style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _logout,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFe74c3c).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFe74c3c).withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.logout, color: Color(0xFFe74c3c), size: 18),
              SizedBox(width: 6),
              Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xFFe74c3c),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(Icons.settings, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings & Configuration',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2c3e50),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Configure your SMS gateway settings and preferences',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF7f8c8d),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF7f8c8d),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withOpacity(0.3),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.tune, size: 16),
                SizedBox(width: 4),
                Text('General'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, size: 16),
                SizedBox(width: 4),
                Text('API'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.router, size: 16),
                SizedBox(width: 4),
                Text('GSM'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.webhook, size: 16),
                SizedBox(width: 4),
                Text('Webhooks'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.advanced, size: 16),
                SizedBox(width: 4),
                Text('Advanced'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildCard(
                  'General Configuration',
                  Icons.tune,
                  Column(
                    children: [
                      _buildTextField('Device Name', _deviceNameController),
                      _buildDropdown('Timezone', _selectedTimezone, [
                        'UTC',
                        'America/New_York',
                        'America/Chicago',
                        'America/Denver',
                        'America/Los_Angeles',
                        'Europe/London',
                        'Europe/Paris',
                        'Asia/Tokyo',
                      ], (value) => setState(() => _selectedTimezone = value!)),
                      _buildSwitch('Enable Auto-Responses', _autoResponses, (value) => setState(() => _autoResponses = value)),
                      if (_autoResponses)
                        _buildTextField('Auto-Response Message', _autoResponseController, maxLines: 3),
                      const SizedBox(height: 20),
                      _buildPrimaryButton('Save General Settings', Icons.save, () => _showSnackBar('General settings saved successfully!')),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildCard(
                  'System Status',
                  Icons.monitor_heart,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusIndicator('System Online', true),
                      const SizedBox(height: 24),
                      _buildSectionHeader('System Information'),
                      const SizedBox(height: 16),
                      _buildInfoRow('Uptime', '2 days, 14 hours', Icons.schedule),
                      _buildInfoRow('Memory Usage', '45%', Icons.memory),
                      _buildInfoRow('Storage', '1.2GB / 4GB', Icons.storage),
                      _buildInfoRow('Version', 'v1.0.0', Icons.info),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: _buildSecondaryButton('Restart', Icons.refresh, () => _showSnackBar('System restart initiated...'))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildSuccessButton('Updates', Icons.system_update, () => _showSnackBar('Checking for updates...'))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildCard(
                  'API Keys Management',
                  Icons.key,
                  Column(
                    children: [
                      _buildApiKeyField(),
                      const SizedBox(height: 20),
                      _buildSwitch('Enable API Rate Limiting', _rateLimiting, (value) => setState(() => _rateLimiting = value)),
                      if (_rateLimiting)
                        _buildTextField('Rate Limit (requests per minute)', _rateLimitController, keyboardType: TextInputType.number),
                      _buildTextField('Allowed IP Addresses', _allowedIPsController, maxLines: 3),
                      const SizedBox(height: 20),
                      _buildPrimaryButton('Save API Settings', Icons.save, () => _showSnackBar('API settings saved successfully!')),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildCard(
                  'Security Settings',
                  Icons.shield,
                  Column(
                    children: [
                      _buildSwitch('Enable HTTPS Only', _httpsOnly, (value) => setState(() => _httpsOnly = value)),
                      _buildSwitch('Enable Request Logging', _requestLogging, (value) => setState(() => _requestLogging = value)),
                      _buildTextField('Session Timeout (minutes)', _sessionTimeoutController, keyboardType: TextInputType.number),
                      _buildTextField('Max Login Attempts', _maxLoginAttemptsController, keyboardType: TextInputType.number),
                      const SizedBox(height: 20),
                      _buildPrimaryButton('Save Security Settings', Icons.security, () => _showSnackBar('Security settings saved successfully!')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGsmTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildCard(
                  'GSM Module Configuration',
                  Icons.router,
                  Column(
                    children: [
                      _buildStatusIndicator('GSM Connected - Signal: 85%', _gsmConnected),
                      const SizedBox(height: 20),
                      _buildDropdown('GSM Module Type', _gsmModule, ['SIM800L', 'SIM900', 'A6', 'SIM7600'], (value) => setState(() => _gsmModule = value!)),
                      _buildDropdown('Baud Rate', _baudRate, ['9600', '19200', '38400', '57600', '115200'], (value) => setState(() => _baudRate = value!)),
                      _buildTextField('Serial Port', _serialPortController),
                      _buildTextField('SIM PIN (if required)', _simPinController, obscureText: true),
                      _buildSwitch('Auto-Reconnect on Failure', _autoReconnect, (value) => setState(() => _autoReconnect = value)),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _buildPrimaryButton('Save GSM Settings', Icons.save, () => _showSnackBar('GSM settings saved successfully!'))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildSecondaryButton('Test Connection', Icons.network_check, () => _showSnackBar('GSM Connection Test: SUCCESS'))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildCard(
                  'GSM Diagnostics',
                  Icons.analytics,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Current Status'),
                      const SizedBox(height: 16),
                      _buildInfoRow('Network', 'Connected', Icons.network_cell),
                      _buildInfoRow('Signal Strength', '85%', Icons.signal_cellular_alt),
                      _buildInfoRow('Operator', 'Verizon', Icons.business),
                      _buildInfoRow('SMS Center', '+1234567890', Icons.sms),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: _buildSecondaryButton('Refresh', Icons.refresh, () => _showSnackBar('GSM status refreshed!'))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildSuccessButton('Test SMS', Icons.send, () => _showSnackBar('Test SMS sent successfully!'))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebhooksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildCard(
                  'Webhook Configuration',
                  Icons.webhook,
                  Column(
                    children: [
                      _buildSwitch('Enable Webhooks', _enableWebhooks, (value) => setState(() => _enableWebhooks = value)),
                      if (_enableWebhooks) ...[
                        const SizedBox(height: 16),
                        _buildTextField('Webhook URL', _webhookUrlController),
                        _buildTextField('Webhook Secret', _webhookSecretController, obscureText: true),
                        const SizedBox(height: 16),
                        _buildSectionHeader('Webhook Events'),
                        const SizedBox(height: 12),
                        _buildCheckboxTile('SMS Sent Successfully', _webhookSent, (value) => setState(() => _webhookSent = value!)),
                        _buildCheckboxTile('SMS Received', _webhookReceived, (value) => setState(() => _webhookReceived = value!)),
                        _buildCheckboxTile('SMS Failed', _webhookFailed, (value) => setState(() => _webhookFailed = value!)),
                        _buildCheckboxTile('Status Changes', _webhookStatus, (value) => setState(() => _webhookStatus = value!)),
                        const SizedBox(height: 16),
                        _buildSecondaryButton('Test Webhook', Icons.bug_report, () => _showSnackBar('Webhook Test: SUCCESS - HTTP 200 OK received')),
                      ],
                      const SizedBox(height: 20),
                      _buildPrimaryButton('Save Webhook Settings', Icons.save, () => _showSnackBar('Webhook settings saved successfully!')),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildCard(
                  'External Integrations',
                  Icons.extension,
                  Column(
                    children: [
                      _buildIntegrationTile(
                        'Google Calendar',
                        'Send SMS reminders for calendar events',
                        Icons.calendar_today,
                        false,
                      ),
                      _buildIntegrationTile(
                        'Zapier',
                        'Automate SMS workflows with 3000+ apps',
                        Icons.autorenew,
                        false,
                      ),
                      _buildIntegrationTile(
                        'WhatsApp API',
                        'Bridge SMS and WhatsApp messages',
                        Icons.chat,
                        false,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildCard(
                  'Advanced Configuration',
                  Icons.tune,
                  Column(
                    children: [
                      _buildTextField('Max Retry Attempts', _maxRetriesController, keyboardType: TextInputType.number),
                      _buildTextField('Retry Delay (seconds)', _retryDelayController, keyboardType: TextInputType.number),
                      _buildTextField('Message Queue Size', _queueSizeController, keyboardType: TextInputType.number),
                      const SizedBox(height: 20),
                      _buildPrimaryButton('Save Advanced Settings', Icons.save, () => _showSnackBar('Advanced settings saved successfully!')),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildCard(
                  'Data Management',
                  Icons.storage,
                  Column(
                    children: [
                      _buildTextField('Data Retention (days)', _dataRetentionController, keyboardType: TextInputType.number),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _buildSuccessButton('Export Data', Icons.download, () => _showSnackBar('Data export started...'))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildSecondaryButton('Import Data', Icons.upload, () => _showSnackBar('Import functionality triggered'))),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildDangerSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, Widget content) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2c3e50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          content,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {
    int maxLines = 1,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2c3e50),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            obscureText: obscureText,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              hintStyle: TextStyle(color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2c3e50),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF667eea)),
            items: items.map((item) => DropdownMenuItem(
              value: item,
              child: Text(item, style: const TextStyle(color: Color(0xFF2c3e50))),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF2c3e50),
                fontSize: 14,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF667eea),
              activeTrackColor: const Color(0xFF667eea).withOpacity(0.3),
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile(String label, bool value, ValueChanged<bool?> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF2c3e50),
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF667eea),
        checkColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildPrimaryButton(String text, IconData icon, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String text, IconData icon, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: const Color(0xFF667eea), size: 18),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF667eea),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessButton(String text, IconData icon, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF27ae60),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF27ae60).withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDangerButton(String text, IconData icon, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFe74c3c),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFe74c3c).withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String text, bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFF27ae60).withOpacity(0.1) : const Color(0xFFe74c3c).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnline ? const Color(0xFF27ae60) : const Color(0xFFe74c3c),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFF27ae60) : const Color(0xFFe74c3c),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isOnline ? const Color(0xFF27ae60) : const Color(0xFFe74c3c),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2c3e50),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF667eea)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2c3e50),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationTile(String title, String description, IconData icon, bool isEnabled) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEnabled ? const Color(0xFF667eea).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isEnabled ? const Color(0xFF667eea) : Colors.grey[500],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2c3e50),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: isEnabled,
              onChanged: (value) {
                _showSnackBar('${title} ${value ? 'enabled' : 'disabled'}');
              },
              activeColor: const Color(0xFF667eea),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'API Key',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2c3e50),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _showApiKey ? _apiKey : '••••••••••••••••••••',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: Color(0xFF2c3e50),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _showApiKey = !_showApiKey),
                  icon: Icon(_showApiKey ? Icons.visibility_off : Icons.visibility),
                  color: const Color(0xFF667eea),
                  iconSize: 20,
                ),
                IconButton(
                  onPressed: _copyApiKey,
                  icon: const Icon(Icons.copy),
                  color: const Color(0xFF667eea),
                  iconSize: 20,
                ),
                IconButton(
                  onPressed: _regenerateApiKey,
                  icon: const Icon(Icons.refresh),
                  color: const Color(0xFFe74c3c),
                  iconSize: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFe74c3c).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe74c3c).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: Color(0xFFe74c3c), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Danger Zone',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFe74c3c),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'These actions are irreversible. Please proceed with caution.',
            style: TextStyle(
              color: Color(0xFFe74c3c),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDangerButton(
                  'Clear All Data',
                  Icons.delete_forever,
                  () => _confirmDangerousAction('clear all data'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDangerButton(
                  'Factory Reset',
                  Icons.settings_backup_restore,
                  () => _confirmDangerousAction('factory reset'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyApiKey() {
    Clipboard.setData(ClipboardData(text: _apiKey));
    _showSnackBar('API key copied to clipboard!');
    setState(() {
      _showApiKey = true;
    });
    
    // Hide API key after 3 seconds for security
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showApiKey = false;
        });
      }
    });
  }

  void _regenerateApiKey() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Color(0xFFe74c3c)),
              SizedBox(width: 8),
              Text('Regenerate API Key'),
            ],
          ),
          content: const Text(
            'Are you sure you want to regenerate the API key? This will invalidate the current key and may break existing integrations.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _apiKey = 'sk_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}${(DateTime.now().microsecond * 1000).toRadixString(36)}';
                });
                _showSnackBar('API key regenerated successfully!');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFe74c3c),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Regenerate', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDangerousAction(String action) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning, color: Color(0xFFe74c3c)),
              const SizedBox(width: 8),
              Text('Confirm ${action.toUpperCase()}'),
            ],
          ),
          content: Text('Are you sure you want to $action? This action cannot be undone!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSnackBar('${action.substring(0, 1).toUpperCase()}${action.substring(1)} completed!');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFe74c3c),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF667eea),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Color(0xFFe74c3c)),
              SizedBox(width: 8),
              Text('Logout'),
            ],
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSnackBar('Logged out successfully!');
                // Add actual logout navigation logic here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFe74c3c),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}