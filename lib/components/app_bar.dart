import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget {
  final String activeTab;
  final VoidCallback onDashboardTap;
  final VoidCallback onLogsTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onLogout;

  const CustomAppBar({
    super.key,
    required this.activeTab,
    required this.onDashboardTap,
    required this.onLogsTap,
    required this.onSettingsTap,
    required this.onLogout,
  });

  Widget _buildNavButton(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      child: Text(label, style: const TextStyle(color: Colors.black87)),
    );
  }

  Widget _buildActiveNavButton(String label) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }

  Widget _buildLogoutButton() {
    return IconButton(
      icon: const Icon(Icons.logout),
      color: Colors.redAccent,
      onPressed: onLogout,
    );
  }

  @override
  Widget build(BuildContext context) {
    final navButtons = [
      activeTab == 'dashboard'
          ? _buildActiveNavButton('🏠 Dashboard')
          : _buildNavButton('🏠 Dashboard', onDashboardTap),
      activeTab == 'logs'
          ? _buildActiveNavButton('📊 Logs')
          : _buildNavButton('📊 Logs', onLogsTap),
      activeTab == 'settings'
          ? _buildActiveNavButton('⚙️ Settings')
          : _buildNavButton('⚙️ Settings', onSettingsTap),
      _buildLogoutButton(),
    ];

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
                    children: navButtons,
                  ),
                ),
              ],
            );
          } else {
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
                  children: navButtons,
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
