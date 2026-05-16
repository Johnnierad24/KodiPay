import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/dashboard_components.dart';

class PropertyListScreen extends StatelessWidget {
  const PropertyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final properties = [
      const PropertyData('Sunview Apartments', 'Westlands, Nairobi', '12 Units',
          '10 Occupied', 'KSh 250,000'),
      const PropertyData('Greenfield Heights', 'Kilimani, Nairobi', '32 Units',
          '25 Occupied', 'KSh 610,000'),
      const PropertyData(
          'Lakeview Villas', 'Kisumu', '10 Units', '8 Occupied', 'KSh 180,000'),
    ];

    return _FeatureScaffold(
      title: 'My Properties',
      accentColor: AppColors.kodiGreen,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.kodiGreen,
        onPressed: () => showPropertySheet(context),
        child: const Icon(Icons.add_home_rounded, color: AppColors.white),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: properties.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final property = properties[index];
          return _TappableCard(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PropertyDetailScreen(property: property)),
            ),
            child: Row(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.kodiGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.apartment_rounded,
                      color: AppColors.kodiGreen, size: 36),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(property.name, style: _titleStyle),
                      const SizedBox(height: 4),
                      Text(property.location, style: AppStyles.caption),
                      const SizedBox(height: 9),
                      Text('${property.units}  -  ${property.occupied}',
                          style: _smallBoldStyle),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PropertyDetailScreen extends StatelessWidget {
  final PropertyData property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: property.name,
      accentColor: AppColors.kodiGreen,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          GradientPanel(
            startColor: const Color(0xFF10A55A),
            endColor: const Color(0xFF047857),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(property.location,
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.86))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: StatBox(
                            value: property.units.split(' ').first,
                            label: 'Total Units')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: StatBox(
                            value: property.occupied.split(' ').first,
                            label: 'Occupied')),
                    const SizedBox(width: 10),
                    const Expanded(
                        child: StatBox(
                            value: 'KSh 25,000', label: 'Monthly Income')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SettingsTile(
            icon: Icons.meeting_room_outlined,
            title: 'Units',
            subtitle: 'View vacancy and rent status',
            onTap: () => _showSnack(context, 'Units module opened'),
          ),
          _SettingsTile(
            icon: Icons.groups_2_outlined,
            title: 'Tenants',
            subtitle: 'Manage active tenants',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TenantListScreen())),
          ),
          _SettingsTile(
            icon: Icons.receipt_long_outlined,
            title: 'Transactions',
            subtitle: property.monthlyIncome,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const LandlordPaymentsScreen())),
          ),
          _SettingsTile(
            icon: Icons.folder_copy_outlined,
            title: 'Documents',
            subtitle: 'Leases and receipts',
            onTap: () =>
                _showSnack(context, 'Documents are ready for upload wiring'),
          ),
        ],
      ),
    );
  }
}

class TenantListScreen extends StatelessWidget {
  const TenantListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'Tenants',
      accentColor: AppColors.kodiGreen,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.kodiGreen,
        onPressed: () => showTenantSheet(context),
        child:
            const Icon(Icons.person_add_alt_1_rounded, color: AppColors.white),
      ),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: const [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search tenants...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          SizedBox(height: 14),
          _TenantRow(
              name: 'Mary Wanjiku',
              unit: 'A2 - Sunview Apartments',
              phone: '0723 456 778',
              active: true),
          _TenantRow(
              name: 'John Kamau',
              unit: 'B1 - Greenfield Heights',
              phone: '0721 987 654',
              active: true),
          _TenantRow(
              name: 'Peter Ochieng',
              unit: 'C3 - Lakeview Villas',
              phone: '0700 111 222',
              active: true),
          _TenantRow(
              name: 'Grace Njeri',
              unit: 'A1 - Sunview Apartments',
              phone: '0711 222 333',
              active: false),
        ],
      ),
    );
  }
}

class LandlordPaymentsScreen extends StatefulWidget {
  const LandlordPaymentsScreen({super.key});

  @override
  State<LandlordPaymentsScreen> createState() => _LandlordPaymentsScreenState();
}

class _LandlordPaymentsScreenState extends State<LandlordPaymentsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'Payments',
      accentColor: AppColors.kodiGreen,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Row(
            children: [
              _FilterChip(
                  label: 'All',
                  selected: _filter == 'All',
                  onTap: () => setState(() => _filter = 'All')),
              const SizedBox(width: 8),
              _FilterChip(
                  label: 'Paid',
                  selected: _filter == 'Paid',
                  onTap: () => setState(() => _filter = 'Paid')),
              const SizedBox(width: 8),
              _FilterChip(
                  label: 'Pending',
                  selected: _filter == 'Pending',
                  onTap: () => setState(() => _filter = 'Pending')),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                  child: _MetricCard(
                      label: 'Total Received',
                      value: 'KSh 245,000',
                      color: AppColors.kodiGreen)),
              SizedBox(width: 10),
              Expanded(
                  child: _MetricCard(
                      label: 'Pending',
                      value: 'KSh 75,000',
                      color: AppColors.kodiOrange)),
            ],
          ),
          const SizedBox(height: 16),
          const _PaymentItem(
              name: 'Mary Wanjiku',
              unit: 'A2 - Sunview Apts',
              amount: 'KSh 25,000',
              status: 'Paid'),
          const _PaymentItem(
              name: 'John Kamau',
              unit: 'B1 - Greenfield Hts',
              amount: 'KSh 20,000',
              status: 'Paid'),
          const _PaymentItem(
              name: 'Peter Ochieng',
              unit: 'C3 - Lakeview Villas',
              amount: 'KSh 25,000',
              status: 'Pending'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showSnack(context, 'Report download queued'),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download Report'),
          ),
        ],
      ),
    );
  }
}

class LandlordReportsScreen extends StatelessWidget {
  const LandlordReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'Reports',
      accentColor: AppColors.kodiBlue,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const _MetricCard(
              label: 'Collection Rate',
              value: '92%',
              color: AppColors.kodiBlue),
          const SizedBox(height: 12),
          const _MetricCard(
              label: 'Occupancy', value: '94%', color: AppColors.kodiGreen),
          const SizedBox(height: 12),
          const _MetricCard(
              label: 'Open Maintenance',
              value: '5',
              color: AppColors.kodiOrange),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => _showSnack(
                context, 'PDF report export is ready for backend wiring'),
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('Export PDF'),
          ),
        ],
      ),
    );
  }
}

class TenantPaymentsScreen extends StatelessWidget {
  const TenantPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'My Payments',
      accentColor: AppColors.kodiBlue,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          GradientPanel(
            startColor: const Color(0xFF1D6FD8),
            endColor: const Color(0xFF0047A1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount Due',
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.86))),
                const SizedBox(height: 6),
                const Text('KSh 25,000',
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.kodiBlue),
                    onPressed: () => Navigator.pushNamed(context, '/pay-rent'),
                    child: const Text('Pay Now (M-Pesa)'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionTitle(title: 'Payment History'),
          const ListPanel(
            children: [
              _TenantPaymentHistory(month: 'Apr 2024', date: 'Apr 25, 2024'),
              Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: AppColors.border),
              _TenantPaymentHistory(month: 'Mar 2024', date: 'Mar 25, 2024'),
            ],
          ),
        ],
      ),
    );
  }
}

class TenantMaintenanceScreen extends StatelessWidget {
  const TenantMaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'My Maintenance',
      accentColor: AppColors.kodiOrange,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.kodiBlue,
        onPressed: () => showIssueSheet(context),
        icon: const Icon(Icons.add_rounded, color: AppColors.white),
        label: const Text('Report Issue',
            style: TextStyle(color: AppColors.white)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: const [
          _IssueListItem(
              title: 'Leaking Sink',
              location: 'Kitchen - A2',
              status: 'In Progress',
              color: AppColors.kodiOrange),
          _IssueListItem(
              title: 'Broken Window',
              location: 'Bedroom - A2',
              status: 'Pending',
              color: AppColors.kodiOrange),
          _IssueListItem(
              title: 'Light Not Working',
              location: 'Living Room - A2',
              status: 'Pending',
              color: AppColors.kodiOrange),
        ],
      ),
    );
  }
}

class TenantNoticesScreen extends StatelessWidget {
  const TenantNoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'Notices',
      accentColor: AppColors.kodiBlue,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: const [
          _NoticeCard(
              title: 'Water Interruption',
              body:
                  'Water service will be interrupted on Saturday from 8 AM to noon.'),
          _NoticeCard(
              title: 'Rent Reminder',
              body: 'May rent is due on 25th May 2024.'),
          _NoticeCard(
              title: 'Security Update',
              body: 'Visitor registration is now required at the main gate.'),
        ],
      ),
    );
  }
}

class CaretakerTasksScreen extends StatefulWidget {
  const CaretakerTasksScreen({super.key});

  @override
  State<CaretakerTasksScreen> createState() => _CaretakerTasksScreenState();
}

class _CaretakerTasksScreenState extends State<CaretakerTasksScreen> {
  final Set<String> _completed = {};

  @override
  Widget build(BuildContext context) {
    final tasks = [
      const _TaskData('Broken Tap', 'House 12B', 'High'),
      const _TaskData('Electrical Fault', 'House 8A', 'Medium'),
      const _TaskData('Door Lock Repair', 'House 5C', 'Low'),
    ];

    return _FeatureScaffold(
      title: 'Tasks',
      accentColor: AppColors.kodiOrange,
      child: ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final task = tasks[index];
          final done = _completed.contains(task.title);
          return _TappableCard(
            onTap: () => _showSnack(context, '${task.title} details opened'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.handyman_rounded,
                        color: AppColors.kodiOrange),
                    const SizedBox(width: 10),
                    Expanded(child: Text(task.title, style: _titleStyle)),
                    StatusPill(
                        label: done ? 'Done' : task.priority,
                        color:
                            done ? AppColors.kodiGreen : AppColors.kodiOrange),
                  ],
                ),
                const SizedBox(height: 8),
                Text(task.location, style: AppStyles.caption),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _completed.add(task.title));
                      _showSnack(context, '${task.title} marked complete');
                    },
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Mark as Complete'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CaretakerAlertsScreen extends StatelessWidget {
  const CaretakerAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'Alerts',
      accentColor: AppColors.kodiOrange,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: const [
          _AlertCard(
              title: 'Water Leakage', location: 'House 3D', type: 'Emergency'),
          _AlertCard(
              title: 'Power Outage',
              location: 'Greenfield Heights',
              type: 'General'),
          _AlertCard(
              title: 'Fire Alarm Triggered',
              location: 'House 7A',
              type: 'Emergency'),
          _AlertCard(
              title: 'Gas Smell Reported',
              location: 'House 2B',
              type: 'Emergency'),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final String role;
  final Color accentColor;

  const ProfileScreen({
    super.key,
    required this.role,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'Profile',
      accentColor: accentColor,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _TappableCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: accentColor.withValues(alpha: 0.12),
                  child: Icon(Icons.person_rounded, color: accentColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(role, style: _titleStyle),
                      const SizedBox(height: 4),
                      const Text('KodiPay account', style: AppStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            title: 'Security',
            subtitle: 'Password and session settings',
            onTap: () => _showSnack(context, 'Security settings opened'),
          ),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Support',
            subtitle: 'Contact KodiPay support',
            onTap: () => _showSnack(context, 'Support request started'),
          ),
        ],
      ),
    );
  }
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'More',
      accentColor: AppColors.kodiNavy,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _SettingsTile(
            icon: Icons.analytics_outlined,
            title: 'Reports',
            subtitle: 'Revenue, occupancy, and collections',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const LandlordReportsScreen())),
          ),
          _SettingsTile(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            subtitle: 'Reminders and system alerts',
            onTap: () => _showSnack(context, 'Notifications opened'),
          ),
          _SettingsTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'App preferences',
            onTap: () => _showSnack(context, 'Settings opened'),
          ),
        ],
      ),
    );
  }
}

Future<void> showPropertySheet(BuildContext context) {
  return _showInputSheet(
    context: context,
    title: 'Add Property',
    fields: const ['Property Name', 'Location', 'Monthly Rent'],
    submitLabel: 'Save Property',
    message: 'Property saved locally. Backend wiring comes next.',
  );
}

Future<void> showTenantSheet(BuildContext context) {
  return _showInputSheet(
    context: context,
    title: 'Add Tenant',
    fields: const ['Full Name', 'Phone Number', 'Email', 'Property', 'Unit'],
    submitLabel: 'Save Tenant',
    message: 'Tenant saved locally. Backend wiring comes next.',
  );
}

Future<void> showIssueSheet(BuildContext context) {
  return _showInputSheet(
    context: context,
    title: 'Report Maintenance Issue',
    fields: const ['Issue Title', 'Category', 'Description'],
    submitLabel: 'Submit Issue',
    message: 'Issue submitted locally. Backend wiring comes next.',
  );
}

Future<void> showReminderSheet(BuildContext context) {
  return _showInputSheet(
    context: context,
    title: 'Send Reminder',
    fields: const ['Tenant or Unit', 'Message'],
    submitLabel: 'Send Reminder',
    message: 'Reminder queued.',
  );
}

Future<void> _showInputSheet({
  required BuildContext context,
  required String title,
  required List<String> fields,
  required String submitLabel,
  required String message,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
            18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppStyles.heading2),
              const SizedBox(height: 16),
              ...fields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child:
                      TextField(decoration: InputDecoration(labelText: field)),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showSnack(context, message);
                  },
                  child: Text(submitLabel),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _FeatureScaffold extends StatelessWidget {
  final String title;
  final Color accentColor;
  final Widget child;
  final Widget? floatingActionButton;

  const _FeatureScaffold({
    required this.title,
    required this.accentColor,
    required this.child,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title,
            style: const TextStyle(
                color: AppColors.textDark, fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(child: child),
    );
  }
}

class _TappableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TappableCard({
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _TappableCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: AppColors.kodiBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _titleStyle),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AppStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _TenantRow extends StatelessWidget {
  final String name;
  final String unit;
  final String phone;
  final bool active;

  const _TenantRow({
    required this.name,
    required this.unit,
    required this.phone,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _TappableCard(
        onTap: () => _showSnack(context, '$name selected'),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.kodiGreen.withValues(alpha: 0.12),
              child: Text(name.characters.first,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: _titleStyle),
                  const SizedBox(height: 3),
                  Text(unit, style: AppStyles.caption),
                  Text(phone, style: AppStyles.caption),
                ],
              ),
            ),
            StatusPill(
                label: active ? 'Active' : 'Inactive',
                color: active ? AppColors.kodiGreen : AppColors.danger),
          ],
        ),
      ),
    );
  }
}

class _PaymentItem extends StatelessWidget {
  final String name;
  final String unit;
  final String amount;
  final String status;

  const _PaymentItem({
    required this.name,
    required this.unit,
    required this.amount,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final paid = status == 'Paid';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _TappableCard(
        onTap: () => _showSnack(context, 'Receipt for $name opened'),
        child: Row(
          children: [
            CircleAvatar(child: Text(name.characters.first)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: _titleStyle),
                  Text(unit, style: AppStyles.caption),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amount, style: _smallBoldStyle),
                const SizedBox(height: 5),
                StatusPill(
                    label: status,
                    color: paid ? AppColors.kodiGreen : AppColors.kodiOrange),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _TappableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppStyles.caption),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.kodiGreen.withValues(alpha: 0.16),
      onSelected: (_) => onTap(),
    );
  }
}

class _TenantPaymentHistory extends StatelessWidget {
  final String month;
  final String date;

  const _TenantPaymentHistory({
    required this.month,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(month, style: _titleStyle),
                const SizedBox(height: 5),
                const Row(
                  children: [
                    Text('KSh 25,000',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(width: 10),
                    StatusPill(label: 'Paid', color: AppColors.kodiGreen),
                  ],
                ),
              ],
            ),
          ),
          Text(date, style: AppStyles.caption),
        ],
      ),
    );
  }
}

class _IssueListItem extends StatelessWidget {
  final String title;
  final String location;
  final String status;
  final Color color;

  const _IssueListItem({
    required this.title,
    required this.location,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _TappableCard(
        onTap: () => _showSnack(context, '$title details opened'),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.build_circle_outlined,
                  color: AppColors.kodiOrange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _titleStyle),
                  const SizedBox(height: 3),
                  Text(location, style: AppStyles.caption),
                ],
              ),
            ),
            StatusPill(label: status, color: color),
          ],
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final String title;
  final String body;

  const _NoticeCard({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _TappableCard(
        onTap: () => _showSnack(context, title),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.campaign_outlined, color: AppColors.kodiBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _titleStyle),
                  const SizedBox(height: 4),
                  Text(body, style: AppStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String title;
  final String location;
  final String type;

  const _AlertCard({
    required this.title,
    required this.location,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final emergency = type == 'Emergency';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _TappableCard(
        onTap: () => _showSnack(context, '$title assigned'),
        child: Row(
          children: [
            Icon(emergency ? Icons.warning_rounded : Icons.info_outline_rounded,
                color: emergency ? AppColors.danger : AppColors.kodiOrange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _titleStyle),
                  const SizedBox(height: 3),
                  Text(location, style: AppStyles.caption),
                ],
              ),
            ),
            StatusPill(
                label: type,
                color: emergency ? AppColors.danger : AppColors.kodiOrange),
          ],
        ),
      ),
    );
  }
}

class PropertyData {
  final String name;
  final String location;
  final String units;
  final String occupied;
  final String monthlyIncome;

  const PropertyData(
      this.name, this.location, this.units, this.occupied, this.monthlyIncome);
}

class _TaskData {
  final String title;
  final String location;
  final String priority;

  const _TaskData(this.title, this.location, this.priority);
}

const _titleStyle = TextStyle(
  color: AppColors.textDark,
  fontWeight: FontWeight.w800,
);

const _smallBoldStyle = TextStyle(
  color: AppColors.textDark,
  fontSize: 12,
  fontWeight: FontWeight.w800,
);

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
