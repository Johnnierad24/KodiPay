import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/maintenance_item.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/dashboard_components.dart';
import '../widgets/shared_screen_components.dart';
import 'maintenance_detail_screen.dart';

class TenantMaintenanceScreen extends StatefulWidget {
  const TenantMaintenanceScreen({super.key});

  @override
  State<TenantMaintenanceScreen> createState() =>
      _TenantMaintenanceScreenState();
}

class _TenantMaintenanceScreenState extends State<TenantMaintenanceScreen> {
  final ApiService _api = ApiService();
  Future<_TenantMaintenanceBundle>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _fetch();
    });
  }

  Future<_TenantMaintenanceBundle> _fetch() async {
    final tenancyResp = await _api.get('/tenancies');
    if (tenancyResp.statusCode != 200) {
      throw Exception('Could not load tenancy (${tenancyResp.statusCode})');
    }
    final tenancies = (jsonDecode(tenancyResp.body) as List<dynamic>)
        .cast<Map<String, dynamic>>();
    _TenantTenancySummary? tenancy;
    int? unitId;
    if (tenancies.isNotEmpty) {
      final active = tenancies.firstWhere(
        (t) => (t['status']?.toString() ?? 'active') == 'active',
        orElse: () => tenancies.first,
      );
      tenancy = _TenantTenancySummary.fromJson(active);
      unitId = toInt(active['unit_id']);
    }

    final response = await _api.get('/maintenance/mine');
    if (response.statusCode != 200) {
      throw Exception('Could not load issues (${response.statusCode})');
    }
    final items = (jsonDecode(response.body) as List<dynamic>)
        .map((item) =>
            MaintenanceItem.fromJson(item as Map<String, dynamic>))
        .toList();
    return _TenantMaintenanceBundle(
      items: items,
      tenancy: tenancy,
      unitId: unitId,
    );
  }

  Future<void> _onReport(_TenantMaintenanceBundle bundle) async {
    if (bundle.unitId == null) {
      showSnack(context, 'No active tenancy — please contact your landlord.');
      return;
    }
    final created = await showIssueSheet(context, unitId: bundle.unitId!);
    if (created == true) _reload();
  }

  Future<void> _openDetail(MaintenanceItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MaintenanceDetailScreen(item: item)),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'My Maintenance',
      accentColor: AppColors.kodiOrange,
      floatingActionButton: FutureBuilder<_TenantMaintenanceBundle>(
        future: _future,
        builder: (context, snapshot) {
          final bundle = snapshot.data;
          return FloatingActionButton.extended(
            backgroundColor: AppColors.kodiBlue,
            onPressed: bundle == null ? null : () => _onReport(bundle),
            icon: const Icon(Icons.add_rounded, color: AppColors.white),
            label: const Text('Report Issue',
                style: TextStyle(color: AppColors.white)),
          );
        },
      ),
      child: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<_TenantMaintenanceBundle>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(30),
                children: [
                  const SizedBox(height: 60),
                  const Icon(Icons.error_outline_rounded,
                      size: 56, color: AppColors.danger),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: AppStyles.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ),
                ],
              );
            }
            final bundle = snapshot.data;
            final items = bundle?.items ?? const <MaintenanceItem>[];
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(30),
                children: const [
                  SizedBox(height: 60),
                  Icon(Icons.handyman_outlined,
                      size: 72, color: AppColors.muted),
                  SizedBox(height: 14),
                  Center(
                    child: Text(
                      'No issues yet',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Tap "Report Issue" to let your landlord or caretaker know.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textLight),
                    ),
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                for (final item in items)
                  _MaintenanceItemCard(
                    item: item,
                    onTap: () => _openDetail(item),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TenantMaintenanceBundle {
  final List<MaintenanceItem> items;
  final _TenantTenancySummary? tenancy;
  final int? unitId;
  const _TenantMaintenanceBundle({
    required this.items,
    required this.tenancy,
    required this.unitId,
  });
}

class _TenantTenancySummary {
  final int id;
  final String propertyName;
  final String unitNumber;
  final num rentAmount;

  const _TenantTenancySummary({
    required this.id,
    required this.propertyName,
    required this.unitNumber,
    required this.rentAmount,
  });

  factory _TenantTenancySummary.fromJson(Map<String, dynamic> json) {
    return _TenantTenancySummary(
      id: toInt(json['id']),
      propertyName: (json['property_name'] ?? '').toString(),
      unitNumber: (json['unit_number'] ?? '').toString(),
      rentAmount: toNum(json['rent_amount']),
    );
  }
}

class _MaintenanceItemCard extends StatelessWidget {
  final MaintenanceItem item;
  final VoidCallback onTap;
  const _MaintenanceItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = maintenanceStatusColor(item.status);
    final statusLabel = maintenanceStatusLabel(item.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TappableCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.build_circle_outlined, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: titleStyle),
                      const SizedBox(height: 3),
                      Text(
                        item.unitNumber.isEmpty
                            ? item.propertyName
                            : '${item.propertyName} • Unit ${item.unitNumber}',
                        style: AppStyles.caption,
                      ),
                    ],
                  ),
                ),
                StatusPill(label: statusLabel, color: statusColor),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                MaintenanceTag(
                    label: capitalizeWord(item.category),
                    color: AppColors.kodiNavy),
                const SizedBox(width: 8),
                MaintenanceTag(
                  label: capitalizeWord(item.priority),
                  color: maintenancePriorityColor(item.priority),
                ),
                const Spacer(),
                Text(relativeTime(item.createdAt), style: AppStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
