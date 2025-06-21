import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SMSGatewaySettingsScreen extends StatefulWidget {
  const SMSGatewaySettingsScreen({Key? key}) : super(key: key);

  @override
  State<SMSGatewaySettingsScreen> createState() => _SMSGatewaySettingsScreenState();
}

class _SMSGatewaySettingsScreenState extends State<SMSGatewaySettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
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
  }

  @override
  void dispose() {
    _tabController.dispose();
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
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
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
    );
  }

  Widget _buildAppBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use responsive layout based on available width
          if (constraints.maxWidth > 800) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    '📱 SMS Gateway',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF667eea),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNavButton('🏠 Dashboard', () {}),
                      const SizedBox(width: 12),
                      _buildNavButton('📊 Logs', () {}),
                      const SizedBox(width: 12),
                      _buildActiveNavButton('⚙️ Settings'),
                      const SizedBox(width: 12),
                      _buildLogoutButton(),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // Stack layout for smaller screens
            return Column(
              children: [
                const Text(
                  '📱 SMS Gateway',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF667eea),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildNavButton('🏠 Dashboard', () {}),
                    _buildNavButton('📊 Logs', () {}),
                    _buildActiveNavButton('⚙️ Settings'),
                    _buildLogoutButton(),
                  ],
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildNavButton(String text, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildActiveNavButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF667eea),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      onPressed: _logout,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFe74c3c),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      child: const Text(
        '🚪 Logout',
        style: TextStyle(color: Colors.white, fontSize: 14),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚙️ Settings & Configuration',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure your SMS gateway settings and preferences',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black87,
            isScrollable: constraints.maxWidth < 600,
            indicator: BoxDecoration(
              color: const Color(0xFF667eea),
              borderRadius: BorderRadius.circular(10),
            ),
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: const [
              Tab(text: '🔧 General'),
              Tab(text: '🔑 API'),
              Tab(text: '📡 GSM'),
              Tab(text: '🔗 Webhooks'),
              Tab(text: '⚡ Advanced'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildCard(
                    '🔧 General Configuration',
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
                        _buildTextField('Auto-Response Message', _autoResponseController, maxLines: 3),
                        const SizedBox(height: 16),
                        _buildButton('💾 Save General Settings', () => _showSnackBar('General settings saved successfully!')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildCard(
                    '📊 System Status',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusIndicator('🟢 System Online', true),
                        const SizedBox(height: 16),
                        const Text('System Information:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildInfoRow('Uptime:', '2 days, 14 hours'),
                        _buildInfoRow('Memory Usage:', '45%'),
                        _buildInfoRow('Storage:', '1.2GB / 4GB'),
                        _buildInfoRow('Version:', 'v1.0.0'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildSecondaryButton('🔄 Restart', () => _showSnackBar('System restart initiated...'))),
                            const SizedBox(width: 8),
                            Expanded(child: _buildSuccessButton('📥 Updates', () => _showSnackBar('Checking for updates...'))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                _buildCard(
                  '🔧 General Configuration',
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
                      _buildTextField('Auto-Response Message', _autoResponseController, maxLines: 3),
                      const SizedBox(height: 16),
                      _buildButton('💾 Save General Settings', () => _showSnackBar('General settings saved successfully!')),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildCard(
                  '📊 System Status',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusIndicator('🟢 System Online', true),
                      const SizedBox(height: 16),
                      const Text('System Information:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildInfoRow('Uptime:', '2 days, 14 hours'),
                      _buildInfoRow('Memory Usage:', '45%'),
                      _buildInfoRow('Storage:', '1.2GB / 4GB'),
                      _buildInfoRow('Version:', 'v1.0.0'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildSecondaryButton('🔄 Restart', () => _showSnackBar('System restart initiated...'))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildSuccessButton('📥 Updates', () => _showSnackBar('Checking for updates...'))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildApiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildCard(
                    '🔑 API Keys Management',
                    Column(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Primary API Key', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _apiKey,
                                    obscureText: !_showApiKey,
                                    readOnly: true,
                                    style: const TextStyle(fontFamily: 'monospace'),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _copyApiKey,
                                  icon: const Icon(Icons.copy, size: 20),
                                  tooltip: 'Copy',
                                ),
                                ElevatedButton(
                                  onPressed: _regenerateApiKey,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFe74c3c),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  child: const Text('🔄 Regenerate', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSwitch('Enable API Rate Limiting', _rateLimiting, (value) => setState(() => _rateLimiting = value)),
                        _buildTextField('Rate Limit (requests per minute)', _rateLimitController, keyboardType: TextInputType.number),
                        _buildTextField('Allowed IP Addresses', _allowedIPsController, maxLines: 3),
                        const SizedBox(height: 16),
                        _buildButton('💾 Save API Settings', () => _showSnackBar('API settings saved successfully!')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildCard(
                    '🔐 Security Settings',
                    Column(
                      children: [
                        _buildSwitch('Enable HTTPS Only', _httpsOnly, (value) => setState(() => _httpsOnly = value)),
                        _buildSwitch('Enable Request Logging', _requestLogging, (value) => setState(() => _requestLogging = value)),
                        _buildTextField('Session Timeout (minutes)', _sessionTimeoutController, keyboardType: TextInputType.number),
                        _buildTextField('Max Login Attempts', _maxLoginAttemptsController, keyboardType: TextInputType.number),
                        const SizedBox(height: 16),
                        _buildButton('🔒 Save Security Settings', () => _showSnackBar('Security settings saved successfully!')),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                _buildCard(
                  '🔑 API Keys Management',
                  Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Primary API Key', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: _apiKey,
                            obscureText: !_showApiKey,
                            readOnly: true,
                            style: const TextStyle(fontFamily: 'monospace'),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _copyApiKey,
                                  icon: const Icon(Icons.copy, size: 16),
                                  label: const Text('Copy', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6c757d),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _regenerateApiKey,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFe74c3c),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  child: const Text('🔄 Regenerate', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSwitch('Enable API Rate Limiting', _rateLimiting, (value) => setState(() => _rateLimiting = value)),
                      _buildTextField('Rate Limit (requests per minute)', _rateLimitController, keyboardType: TextInputType.number),
                      _buildTextField('Allowed IP Addresses', _allowedIPsController, maxLines: 3),
                      const SizedBox(height: 16),
                      _buildButton('💾 Save API Settings', () => _showSnackBar('API settings saved successfully!')),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildCard(
                  '🔐 Security Settings',
                  Column(
                    children: [
                      _buildSwitch('Enable HTTPS Only', _httpsOnly, (value) => setState(() => _httpsOnly = value)),
                      _buildSwitch('Enable Request Logging', _requestLogging, (value) => setState(() => _requestLogging = value)),
                      _buildTextField('Session Timeout (minutes)', _sessionTimeoutController, keyboardType: TextInputType.number),
                      _buildTextField('Max Login Attempts', _maxLoginAttemptsController, keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      _buildButton('🔒 Save Security Settings', () => _showSnackBar('Security settings saved successfully!')),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildGsmTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildCard(
                    '📡 GSM Module Configuration',
                    Column(
                      children: [
                        _buildStatusIndicator('📶 GSM Connected - Signal: 85%', true),
                        const SizedBox(height: 16),
                        _buildDropdown('GSM Module Type', _gsmModule, ['SIM800L', 'SIM900', 'A6', 'SIM7600'], (value) => setState(() => _gsmModule = value!)),
                        _buildDropdown('Baud Rate', _baudRate, ['9600', '19200', '38400', '57600', '115200'], (value) => setState(() => _baudRate = value!)),
                        _buildTextField('Serial Port', _serialPortController),
                        _buildTextField('SIM PIN (if required)', _simPinController, obscureText: true),
                        _buildSwitch('Auto-Reconnect on Failure', _autoReconnect, (value) => setState(() => _autoReconnect = value)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildButton('📡 Save GSM Settings', () => _showSnackBar('GSM settings saved successfully!'))),
                            const SizedBox(width: 8),
                            Expanded(child: _buildSecondaryButton('🔧 Test Connection', () => _showSnackBar('GSM Connection Test: SUCCESS'))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildCard(
                    '📋 GSM Diagnostics',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Current Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildInfoRow('Network:', 'Connected'),
                        _buildInfoRow('Signal Strength:', '85%'),
                        _buildInfoRow('Operator:', 'Verizon'),
                        _buildInfoRow('SMS Center:', '+1234567890'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildSecondaryButton('🔄 Refresh', () => _showSnackBar('GSM status refreshed!'))),
                            const SizedBox(width: 8),
                            Expanded(child: _buildSuccessButton('📤 Test SMS', () => _showSnackBar('Test SMS sent successfully!'))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                _buildCard(
                  '📡 GSM Module Configuration',
                  Column(
                    children: [
                      _buildStatusIndicator('📶 GSM Connected - Signal: 85%', true),
                      const SizedBox(height: 16),
                      _buildDropdown('GSM Module Type', _gsmModule, ['SIM800L', 'SIM900', 'A6', 'SIM7600'], (value) => setState(() => _gsmModule = value!)),
                      _buildDropdown('Baud Rate', _baudRate, ['9600', '19200', '38400', '57600', '115200'], (value) => setState(() => _baudRate = value!)),
                      _buildTextField('Serial Port', _serialPortController),
                      _buildTextField('SIM PIN (if required)', _simPinController, obscureText: true),
                      _buildSwitch('Auto-Reconnect on Failure', _autoReconnect, (value) => setState(() => _autoReconnect = value)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildButton('📡 Save GSM Settings', () => _showSnackBar('GSM settings saved successfully!'))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildSecondaryButton('🔧 Test Connection', () => _showSnackBar('GSM Connection Test: SUCCESS'))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildCard(
                  '📋 GSM Diagnostics',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildInfoRow('Network:', 'Connected'),
                      _buildInfoRow('Signal Strength:', '85%'),
                      _buildInfoRow('Operator:', 'Verizon'),
                      _buildInfoRow('SMS Center:', '+1234567890'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildSecondaryButton('🔄 Refresh', () => _showSnackBar('GSM status refreshed!'))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildSuccessButton('📤 Test SMS', () => _showSnackBar('Test SMS sent successfully!'))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

Widget _buildWebhooksTab() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final webhookSection = _buildCard(
          '🔗 Webhook Configuration',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSwitch('Enable Webhooks', _enableWebhooks, (value) => setState(() => _enableWebhooks = value)),
              if (_enableWebhooks) ...[
                _buildTextField('Webhook URL', _webhookUrlController),
                _buildTextField('Webhook Secret', _webhookSecretController, obscureText: true),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Webhook Events:', style: TextStyle(fontWeight: FontWeight.w500)),
                ),
                _buildCheckbox('SMS Sent Successfully', _webhookSent, (value) => setState(() => _webhookSent = value!)),
                _buildCheckbox('SMS Received', _webhookReceived, (value) => setState(() => _webhookReceived = value!)),
                _buildCheckbox('SMS Failed', _webhookFailed, (value) => setState(() => _webhookFailed = value!)),
                _buildCheckbox('Status Changes', _webhookStatus, (value) => setState(() => _webhookStatus = value!)),
                const SizedBox(height: 16),
                _buildSecondaryButton('🧪 Test Webhook', () => _showSnackBar('Webhook Test: SUCCESS - HTTP 200 OK received')),
              ],
              const SizedBox(height: 16),
              _buildButton('🔗 Save Webhook Settings', () => _showSnackBar('Webhook settings saved successfully!')),
            ],
          ),
        );

        final integrationsSection = _buildCard(
          '🔌 External Integrations',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIntegrationItem('Google Calendar Integration', '🔗 Connect Google Calendar', 'Send SMS reminders for calendar events'),
              _buildIntegrationItem('Zapier Integration', '🔗 Connect Zapier', 'Automate SMS workflows with 3000+ apps'),
              const Text('WhatsApp API', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'WhatsApp API Token',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.5), width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              _buildSecondaryButton('🔗 Connect WhatsApp', () => _showSnackBar('WhatsApp integration configured!')),
              const SizedBox(height: 4),
              Text('Bridge SMS and WhatsApp messages', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        );

        if (constraints.maxWidth > 800) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: webhookSection),
              const SizedBox(width: 20),
              Expanded(child: integrationsSection),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              webhookSection,
              const SizedBox(height: 20),
              integrationsSection,
            ],
          );
        }
      },
    ),
  );
}


  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildCard(
                    '⚡ Advanced Configuration',
                    Column(
                      children: [
                        _buildTextField('Max Retry Attempts', _maxRetriesController, keyboardType: TextInputType.number),
                        _buildTextField('Retry Delay (seconds)', _retryDelayController, keyboardType: TextInputType.number),
                        _buildTextField('Message Queue Size', _queueSizeController, keyboardType: TextInputType.number),
                        const SizedBox(height: 16),
                        _buildButton('⚡ Save Advanced Settings', () => _showSnackBar('Advanced settings saved successfully!')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildCard(
                    '🗂️ Data Management',
                    Column(
                      children: [
                        _buildTextField('Data Retention (days)', _dataRetentionController, keyboardType: TextInputType.number),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildSuccessButton('📥 Export Data', () => _showSnackBar('Data export started...'))),
                            const SizedBox(width: 8),
                            Expanded(child: _buildSecondaryButton('📤 Import Data', () => _showSnackBar('Import functionality triggered'))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.only(top: 16),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1)),
                          ),
                          child: Column(
                            children: [
                              const Text('⚠️ Danger Zone', style: TextStyle(color: Color(0xFFe74c3c), fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _buildDangerButton('🗑️ Clear All Data', () => _confirmDangerousAction('clear all data'))),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildDangerButton('🔄 Factory Reset', () => _confirmDangerousAction('perform factory reset'))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('These actions cannot be undone!', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                _buildCard(
                  '⚡ Advanced Configuration',
                  Column(
                    children: [
                      _buildTextField('Max Retry Attempts', _maxRetriesController, keyboardType: TextInputType.number),
                      _buildTextField('Retry Delay (seconds)', _retryDelayController, keyboardType: TextInputType.number),
                      _buildTextField('Message Queue Size', _queueSizeController, keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      _buildButton('⚡ Save Advanced Settings', () => _showSnackBar('Advanced settings saved successfully!')),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildCard(
                  '🗂️ Data Management',
                  Column(
                    children: [
                      _buildTextField('Data Retention (days)', _dataRetentionController, keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildSuccessButton('📥 Export Data', () => _showSnackBar('Data export started...'))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildSecondaryButton('📤 Import Data', () => _showSnackBar('Import functionality triggered'))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1)),
                        ),
                        child: Column(
                          children: [
                            const Text('⚠️ Danger Zone', style: TextStyle(color: Color(0xFFe74c3c), fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildDangerButton('🗑️ Clear All Data', () => _confirmDangerousAction('clear all data'))),
                                const SizedBox(width: 8),
                                Expanded(child: _buildDangerButton('🔄 Factory Reset', () => _confirmDangerousAction('perform factory reset'))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('These actions cannot be undone!', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildCard(String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.15), width: 1)),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          content,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, bool obscureText = false, TextInputType? keyboardType}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label, 
            style: const TextStyle(
              fontWeight: FontWeight.w600, 
              color: Colors.black87,
              fontSize: 15,
            )
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            obscureText: obscureText,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)),
            ),
            style: const TextStyle(fontSize: 15),
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
              color: Colors.black87,
              fontSize: 15,
            )
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: const TextStyle(fontSize: 15, color: Colors.black87),
            items: items.map((item) => DropdownMenuItem(
              value: item, 
              child: Text(item),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label, 
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
          Transform.scale(
            scale: 1.1,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF667eea),
              activeTrackColor: const Color(0xFF667eea).withOpacity(0.3),
              inactiveThumbColor: Colors.grey.shade400,
              inactiveTrackColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Transform.scale(
            scale: 1.1,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF667eea),
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF667eea),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          shadowColor: const Color(0xFF667eea).withOpacity(0.3),
        ),
        child: Text(
          text, 
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6c757d),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          shadowColor: const Color(0xFF6c757d).withOpacity(0.3),
        ),
        child: Text(
          text, 
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF28a745),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          shadowColor: const Color(0xFF28a745).withOpacity(0.3),
        ),
        child: Text(
          text, 
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDangerButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFe74c3c),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          shadowColor: const Color(0xFFe74c3c).withOpacity(0.3),
        ),
        child: Text(
          text, 
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String text, bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnline ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isOnline ? Colors.green[700] : Colors.red[700],
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value, 
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationItem(String title, String buttonText, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title, 
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description, 
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => _showSnackBar('${title} integration configured!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyApiKey() {
    Clipboard.setData(ClipboardData(text: _apiKey));
    _showSnackBar('API key copied to clipboard!');
    setState(() {
      _showApiKey = !_showApiKey;
    });
    
    // Hide API key after 3 seconds
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
          title: const Text(
            '⚠️ Regenerate API Key',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to regenerate the API key? This will invalidate the current key and may break existing integrations.',
            style: TextStyle(fontSize: 15, height: 1.4),
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
          title: Text(
            '⚠️ Confirm ${action.toUpperCase()}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to $action? This action cannot be undone!',
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF667eea),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 6,
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
          title: const Text(
            '🚪 Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Add logout logic here
                _showSnackBar('Logged out successfully!');
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
                          