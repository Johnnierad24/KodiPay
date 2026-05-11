import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/kodi_pay_logo.dart';

class LandlordDashboard extends StatelessWidget {
  const LandlordDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const KodiPayLogo(iconSize: 30, fontSize: 20),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.logout_rounded, color: AppColors.textDark),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Portfolio Summary',
              style: AppStyles.heading2,
            ),
            const SizedBox(height: 16),
            _buildStatGrid(),
            const SizedBox(height: 32),
            const Text(
              'Management Tools',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 16),
            _buildToolCard(
              title: 'My Properties',
              subtitle: 'Manage buildings and units',
              icon: Icons.business_rounded,
              color: AppColors.kodiBlue,
            ),
            _buildToolCard(
              title: 'Tenants',
              subtitle: 'Active and upcoming leases',
              icon: Icons.people_alt_rounded,
              color: Colors.purple,
            ),
            _buildToolCard(
              title: 'Financial Reports',
              subtitle: 'Revenue and collection trends',
              icon: Icons.analytics_rounded,
              color: Colors.teal,
            ),
            _buildToolCard(
              title: 'Maintenance Desk',
              subtitle: '5 pending requests',
              icon: Icons.build_circle_rounded,
              color: AppColors.kodiOrange,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.kodiBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatCard('Total Revenue', 'KES 1.2M', Colors.green),
        _buildStatCard('Occupancy', '94%', AppColors.kodiBlue),
        _buildStatCard('Unpaid Rent', 'KES 45k', Colors.red),
        _buildStatCard('Maintenance', '5 Open', AppColors.kodiOrange),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard({required String title, required String subtitle, required IconData icon, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        subtitle: Text(subtitle, style: AppStyles.bodyMedium),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}
