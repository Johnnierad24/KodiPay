import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/property_data.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/dashboard_components.dart';
import 'tenant_list_screen.dart';
import 'landlord_payments_screen.dart';
import 'units_screen.dart';
import 'documents_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final PropertyData property;
  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final ApiService _api = ApiService();

  void _editProperty() {
    final nameCtrl = TextEditingController(text: widget.property.name);
    final locationCtrl = TextEditingController(text: widget.property.location);
    String type = 'Apartment';
    bool saving = false;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Property'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (error != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
                      const SizedBox(width: 8),
                      Expanded(child: Text(error!, style: const TextStyle(fontSize: 12, color: AppColors.danger))),
                    ]),
                  ),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Property Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: ['Apartment', 'House', 'Commercial', 'Villa', 'Townhouse', 'Studio'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) { if (v != null) setDialogState(() => type = v); },
                ),
                const SizedBox(height: 12),
                TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: saving ? null : () async {
                if (nameCtrl.text.trim().isEmpty) {
                  setDialogState(() => error = 'Name is required');
                  return;
                }
                setDialogState(() { saving = true; error = null; });
                try {
                  final response = await _api.put('/properties/${widget.property.id}', {
                    'name': nameCtrl.text.trim(),
                    'property_type': type,
                    'address': locationCtrl.text.trim(),
                  });
                  if (response.statusCode >= 400) {
                    final body = jsonDecode(response.body);
                    setDialogState(() { saving = false; error = body['error']?.toString() ?? 'Save failed'; });
                    return;
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) setState(() {});
                } catch (e) {
                  setDialogState(() { saving = false; error = e.toString(); });
                }
              },
              child: saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final id = property.id;
    final occupancyPct = property.totalUnits > 0 ? (property.occupiedUnits / property.totalUnits * 100).round() : 0;
    final collectionPct = property.expectedMonthlyRent > 0 ? (property.thisMonthIncome / property.expectedMonthlyRent * 100).round() : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(property.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Property',
            onPressed: _editProperty,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF10A55A), Color(0xFF047857)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(property.location.isEmpty ? '—' : property.location, style: TextStyle(color: Colors.white.withValues(alpha: 0.86), fontSize: 13)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _StatBox(value: '${property.totalUnits}', label: 'Total Units')),
                    Expanded(child: _StatBox(value: '${property.occupiedUnits}', label: 'Occupied')),
                    Expanded(child: _StatBox(value: 'KSh ${_fmt(property.thisMonthIncome)}', label: 'This Month')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: StatCard(label: 'Occupancy', value: '$occupancyPct%', icon: Icons.space_dashboard_outlined, color: AppColors.success)),
              const SizedBox(width: 10),
              Expanded(child: StatCard(label: 'Collection', value: '$collectionPct%', icon: Icons.trending_up, color: AppColors.kodiBlue)),
            ],
          ),
          const SizedBox(height: 18),
          _settingsTile(Icons.meeting_room_outlined, 'Units', '${property.totalUnits} total • ${property.vacantUnits} vacant', id == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => UnitsListScreen(propertyId: id, propertyName: property.name)))),
          _settingsTile(Icons.groups_2_outlined, 'Tenants', '${property.activeTenants} active in this property', id == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => TenantListScreen(propertyId: id, propertyName: property.name)))),
          _settingsTile(Icons.receipt_long_outlined, 'Transactions', 'KSh ${_fmt(property.thisMonthIncome)} this month', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LandlordPaymentsScreen()))),
          _settingsTile(Icons.folder_copy_outlined, 'Documents', 'Leases, receipts, agreements', id == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentsListScreen(propertyId: id, propertyName: property.name)))),
        ],
      ),
    );
  }

  Widget _settingsTile(IconData icon, String title, String subtitle, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: Ui.card(),
        child: ListTile(
          leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.kodiGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppColors.kodiGreen, size: 20)),
          title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: AppStyles.caption),
          trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
          onTap: onTap,
        ),
      ),
    );
  }

  String _fmt(num v) {
    final whole = v.toInt();
    return whole.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }
}