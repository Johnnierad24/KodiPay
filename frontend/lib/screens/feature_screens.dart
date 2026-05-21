import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;
import '../providers/auth_provider.dart';
import '../services/pdf_report_service.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';
import 'dart:convert';
import '../widgets/dashboard_components.dart';
import '../widgets/kodi_pay_logo.dart';
import 'documents_screen.dart';
import 'units_screen.dart';

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  final ApiService _api = ApiService();
  Future<List<PropertyData>>? _future;

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

  Future<List<PropertyData>> _fetch() async {
    final response = await _api.get('/properties');
    if (response.statusCode != 200) {
      throw Exception('Could not load properties (${response.statusCode})');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => PropertyData.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _onAdd() async {
    final changed = await showPropertySheet(context);
    if (changed == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'My Properties',
      accentColor: AppColors.kodiGreen,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.kodiGreen,
        onPressed: _onAdd,
        child: const Icon(Icons.add_home_rounded, color: AppColors.white),
      ),
      child: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<PropertyData>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(40),
                children: [
                  const SizedBox(height: 60),
                  const Icon(Icons.error_outline_rounded,
                      size: 56, color: AppColors.danger),
                  const SizedBox(height: 14),
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
            final properties = snapshot.data ?? const <PropertyData>[];
            if (properties.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(40),
                children: [
                  const SizedBox(height: 60),
                  const Icon(Icons.home_work_outlined,
                      size: 72, color: AppColors.muted),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text(
                      'No properties yet',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Add your first property to start tracking units, tenants, and payments.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textLight),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _onAdd,
                      icon: const Icon(Icons.add_home_rounded),
                      label: const Text('Add Property'),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: properties.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final property = properties[index];
                return _TappableCard(
                  onTap: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PropertyDetailScreen(property: property),
                      ),
                    );
                    if (changed == true) _reload();
                  },
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
                            Text(
                              property.location.isEmpty
                                  ? '—'
                                  : property.location,
                              style: AppStyles.caption,
                            ),
                            const SizedBox(height: 9),
                            Text(
                              '${property.unitsLabel}  •  ${property.occupiedLabel}',
                              style: _smallBoldStyle,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.muted),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class PropertyDetailScreen extends StatelessWidget {
  final PropertyData property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final propertyId = property.id;
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
                Text(
                  property.location.isEmpty ? '—' : property.location,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.86)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StatBox(
                        value: property.totalUnits.toString(),
                        label: 'Total Units',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatBox(
                        value: property.occupiedUnits.toString(),
                        label: 'Occupied',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatBox(
                        value: 'KSh ${_formatKsh(property.thisMonthIncome)}',
                        label: 'This Month',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SettingsTile(
            icon: Icons.meeting_room_outlined,
            title: 'Units',
            subtitle:
                '${property.totalUnits} total • ${property.vacantUnits} vacant',
            onTap: propertyId == null
                ? () => _showSnack(context,
                    'Property is missing an ID — refresh and try again')
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UnitsListScreen(
                          propertyId: propertyId,
                          propertyName: property.name,
                        ),
                      ),
                    ),
          ),
          _SettingsTile(
            icon: Icons.groups_2_outlined,
            title: 'Tenants',
            subtitle:
                '${property.activeTenants} active in this property',
            onTap: propertyId == null
                ? () => _showSnack(context,
                    'Property is missing an ID — refresh and try again')
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TenantListScreen(
                          propertyId: propertyId,
                          propertyName: property.name,
                        ),
                      ),
                    ),
          ),
          _SettingsTile(
            icon: Icons.receipt_long_outlined,
            title: 'Transactions',
            subtitle: 'KSh ${_formatKsh(property.thisMonthIncome)} this month',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const LandlordPaymentsScreen())),
          ),
          _SettingsTile(
            icon: Icons.folder_copy_outlined,
            title: 'Documents',
            subtitle: 'Leases, receipts, agreements',
            onTap: propertyId == null
                ? () => _showSnack(context,
                    'Property is missing an ID — refresh and try again')
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DocumentsListScreen(
                          propertyId: propertyId,
                          propertyName: property.name,
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

class TenantListScreen extends StatefulWidget {
  final int? propertyId;
  final String? propertyName;

  const TenantListScreen({super.key, this.propertyId, this.propertyName});

  @override
  State<TenantListScreen> createState() => _TenantListScreenState();
}

class _TenantListScreenState extends State<TenantListScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  Future<List<TenancyRecord>>? _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = _fetch();
    });
  }

  Future<List<TenancyRecord>> _fetch() async {
    final response = await _api.get('/tenancies', query: {
      if (widget.propertyId != null) 'propertyId': widget.propertyId,
    });
    if (response.statusCode != 200) {
      throw Exception('Could not load tenants (${response.statusCode})');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => TenancyRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  bool _matchesSearch(TenancyRecord t) {
    if (_search.isEmpty) return true;
    final q = _search.toLowerCase();
    return t.tenantName.toLowerCase().contains(q) ||
        t.unitNumber.toLowerCase().contains(q) ||
        t.propertyName.toLowerCase().contains(q) ||
        (t.tenantPhone ?? '').toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final scoped = widget.propertyId != null;
    final title = scoped
        ? 'Tenants — ${widget.propertyName ?? ''}'
        : 'All Tenants';

    return _FeatureScaffold(
      title: title,
      accentColor: AppColors.kodiGreen,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.kodiGreen,
        onPressed: () async {
          final changed = await showTenantSheet(context);
          if (changed == true) _reload();
        },
        child:
            const Icon(Icons.person_add_alt_1_rounded, color: AppColors.white),
      ),
      child: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<TenancyRecord>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(40),
                children: [
                  const SizedBox(height: 60),
                  const Icon(Icons.error_outline_rounded,
                      size: 56, color: AppColors.danger),
                  const SizedBox(height: 14),
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
            final all = (snapshot.data ?? const <TenancyRecord>[])
                .where(_matchesSearch)
                .toList();

            if (all.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(40),
                children: [
                  const SizedBox(height: 60),
                  const Icon(Icons.groups_2_outlined,
                      size: 72, color: AppColors.muted),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      _search.isEmpty
                          ? 'No tenants yet'
                          : 'No tenants match "$_search"',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Add a tenancy to start tracking rent and payments.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textLight),
                    ),
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _search = value.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search tenants by name, unit, or phone...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                if (scoped)
                  ..._buildFlatList(all)
                else
                  ..._buildGroupedList(all),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildFlatList(List<TenancyRecord> tenancies) {
    return tenancies
        .map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TenantTile(
                tenancy: t,
                onTap: () => _openDetail(t),
              ),
            ))
        .toList();
  }

  List<Widget> _buildGroupedList(List<TenancyRecord> tenancies) {
    final groups = <String, List<TenancyRecord>>{};
    for (final t in tenancies) {
      groups.putIfAbsent(t.propertyName, () => []).add(t);
    }
    final sortedKeys = groups.keys.toList()..sort();
    return [
      for (final key in sortedKeys) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
          child: Row(
            children: [
              const Icon(Icons.apartment_rounded,
                  size: 18, color: AppColors.kodiGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  key,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.kodiGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${groups[key]!.length}',
                  style: const TextStyle(
                    color: AppColors.kodiGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final t in groups[key]!) ...[
          _TenantTile(tenancy: t, onTap: () => _openDetail(t)),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 14),
      ],
    ];
  }

  Future<void> _openDetail(TenancyRecord tenancy) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TenantDetailScreen(tenancy: tenancy),
      ),
    );
    if (changed == true) _reload();
  }
}

class TenancyRecord {
  final int id;
  final int tenantId;
  final String tenantName;
  final String? tenantPhone;
  final String? tenantEmail;
  final String unitNumber;
  final int unitId;
  final String propertyName;
  final int propertyId;
  final num rentAmount;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;

  const TenancyRecord({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.tenantPhone,
    required this.tenantEmail,
    required this.unitNumber,
    required this.unitId,
    required this.propertyName,
    required this.propertyId,
    required this.rentAmount,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory TenancyRecord.fromJson(Map<String, dynamic> json) {
    final firstName = json['first_name']?.toString() ?? '';
    final lastName = json['last_name']?.toString() ?? '';
    return TenancyRecord(
      id: json['id'] as int,
      tenantId: _toInt(json['tenant_id']),
      tenantName: '$firstName $lastName'.trim(),
      tenantPhone: json['tenant_phone'] as String?,
      tenantEmail: json['tenant_email'] as String?,
      unitNumber: (json['unit_number'] ?? '').toString(),
      unitId: _toInt(json['unit_id']),
      propertyName: (json['property_name'] ?? '').toString(),
      propertyId: _toInt(json['property_id']),
      rentAmount: _toNum(json['rent_amount']),
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
      status: (json['status'] ?? 'active').toString(),
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  try {
    return DateTime.parse(value.toString());
  } catch (_) {
    return null;
  }
}

class _TenantTile extends StatelessWidget {
  final TenancyRecord tenancy;
  final VoidCallback onTap;

  const _TenantTile({required this.tenancy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initials = tenancy.tenantName.isNotEmpty
        ? tenancy.tenantName
            .split(' ')
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p[0])
            .join()
            .toUpperCase()
        : '?';
    final active = tenancy.status == 'active';

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.kodiGreen.withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.kodiGreen,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenancy.tenantName.isEmpty ? 'Unnamed' : tenancy.tenantName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Unit ${tenancy.unitNumber} • ${tenancy.propertyName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.caption,
                    ),
                    if (tenancy.tenantPhone != null &&
                        tenancy.tenantPhone!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        tenancy.tenantPhone!,
                        style: AppStyles.caption,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.successSoft
                          : AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      active ? 'Active' : tenancy.status.toUpperCase(),
                      style: TextStyle(
                        color: active ? AppColors.kodiGreen : AppColors.danger,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'KSh ${_formatKsh(tenancy.rentAmount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class TenantDetailScreen extends StatefulWidget {
  final TenancyRecord tenancy;
  const TenantDetailScreen({super.key, required this.tenancy});

  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  final ApiService _api = ApiService();
  Future<List<_PaymentSummary>>? _paymentsFuture;
  bool _removing = false;

  @override
  void initState() {
    super.initState();
    _paymentsFuture = _loadPayments();
  }

  Future<List<_PaymentSummary>> _loadPayments() async {
    final response = await _api.get('/payments/tenancy/${widget.tenancy.id}');
    if (response.statusCode != 200) return const [];
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => _PaymentSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _removeTenant() async {
    final t = widget.tenancy;
    final name = t.tenantName.isEmpty ? 'this tenant' : t.tenantName;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: AppColors.danger, size: 44),
        title: const Text('Remove tenant?'),
        content: Text(
          'This will end $name\'s tenancy on Unit ${t.unitNumber} of ${t.propertyName} '
          'and mark the unit vacant. Their payment history is kept. This cannot be undone from the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _removing = true);
    try {
      final response = await _api.delete('/tenancies/${t.id}/end');
      if (!mounted) return;
      if (response.statusCode == 200) {
        _showSnack(context, '$name removed from Unit ${t.unitNumber}.');
        Navigator.pop(context, true);
      } else {
        Map<String, dynamic>? data;
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}
        setState(() => _removing = false);
        _showSnack(
          context,
          data?['error']?.toString() ??
              'Failed to remove tenant (${response.statusCode}).',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _removing = false);
      _showSnack(context, 'Failed to remove tenant: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tenancy;
    final initials = t.tenantName.isNotEmpty
        ? t.tenantName
            .split(' ')
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p[0])
            .join()
            .toUpperCase()
        : '?';

    return _FeatureScaffold(
      title: t.tenantName.isEmpty ? 'Tenant' : t.tenantName,
      accentColor: AppColors.kodiGreen,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor:
                      AppColors.kodiGreen.withValues(alpha: 0.12),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.kodiGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  t.tenantName.isEmpty ? 'Unnamed' : t.tenantName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${t.propertyName} • Unit ${t.unitNumber}',
                  style: AppStyles.caption,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _DetailChip(
                      icon: Icons.phone_rounded,
                      label: t.tenantPhone?.isNotEmpty == true
                          ? t.tenantPhone!
                          : 'No phone',
                    ),
                    _DetailChip(
                      icon: Icons.email_rounded,
                      label: t.tenantEmail?.isNotEmpty == true
                          ? t.tenantEmail!
                          : 'No email',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                _DetailRow(
                  row: _DetailRowData(
                    'Status',
                    t.status.isEmpty
                        ? '—'
                        : t.status[0].toUpperCase() + t.status.substring(1),
                  ),
                ),
                const Divider(height: 16, color: AppColors.border),
                _DetailRow(
                  row: _DetailRowData(
                    'Monthly rent',
                    'KSh ${_formatKsh(t.rentAmount)}',
                  ),
                ),
                const Divider(height: 16, color: AppColors.border),
                _DetailRow(
                  row: _DetailRowData(
                    'Start date',
                    t.startDate == null
                        ? '—'
                        : '${t.startDate!.day}/${t.startDate!.month}/${t.startDate!.year}',
                  ),
                ),
                if (t.endDate != null) ...[
                  const Divider(height: 16, color: AppColors.border),
                  _DetailRow(
                    row: _DetailRowData(
                      'End date',
                      '${t.endDate!.day}/${t.endDate!.month}/${t.endDate!.year}',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DocumentsListScreen(
                        propertyId: t.propertyId,
                        propertyName: t.propertyName,
                        tenantId: t.tenantId,
                        tenancyId: t.id,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.folder_copy_outlined),
                  label: const Text('Documents'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => showReminderSheet(context),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Reminder'),
                ),
              ),
            ],
          ),
          if (widget.tenancy.status == 'active') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _removing ? null : _removeTenant,
                icon: _removing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.danger),
                      )
                    : const Icon(Icons.person_remove_outlined),
                label: Text(_removing ? 'Removing...' : 'Remove tenant'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Recent Payments',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<_PaymentSummary>>(
            future: _paymentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final payments = snapshot.data ?? const <_PaymentSummary>[];
              if (payments.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'No payments recorded for this tenancy yet.',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                );
              }
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < payments.length && i < 5; i++) ...[
                      if (i > 0)
                        const Divider(
                            height: 1,
                            indent: 14,
                            endIndent: 14,
                            color: AppColors.border),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.kodiGreen
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.payments_outlined,
                                  color: AppColors.kodiGreen, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'KSh ${_formatKsh(payments[i].amount)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    '${payments[i].method} • ${payments[i].paymentDate.day}/${payments[i].paymentDate.month}/${payments[i].paymentDate.year}',
                                    style: AppStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: payments[i].status == 'completed'
                                    ? AppColors.successSoft
                                    : AppColors.warningSoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                payments[i].status.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  color: payments[i].status == 'completed'
                                      ? AppColors.kodiGreen
                                      : AppColors.kodiOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textLight),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSummary {
  final num amount;
  final String method;
  final String status;
  final DateTime paymentDate;

  const _PaymentSummary({
    required this.amount,
    required this.method,
    required this.status,
    required this.paymentDate,
  });

  factory _PaymentSummary.fromJson(Map<String, dynamic> json) {
    return _PaymentSummary(
      amount: _toNum(json['amount']),
      method: (json['payment_method'] ?? '—').toString(),
      status: (json['status'] ?? 'pending').toString(),
      paymentDate:
          _parseDate(json['payment_date']) ?? DateTime.now(),
    );
  }
}

class LandlordPaymentsScreen extends StatefulWidget {
  const LandlordPaymentsScreen({super.key});

  @override
  State<LandlordPaymentsScreen> createState() => _LandlordPaymentsScreenState();
}

class _LandlordPaymentsScreenState extends State<LandlordPaymentsScreen> {
  final ApiService _api = ApiService();
  String _filter = 'All';
  Future<List<PaymentRecord>>? _future;

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

  Future<List<PaymentRecord>> _fetch() async {
    final tenancyResp = await _api.get('/tenancies');
    if (tenancyResp.statusCode != 200) {
      throw Exception('Could not load tenancies (${tenancyResp.statusCode})');
    }
    final tenancies = (jsonDecode(tenancyResp.body) as List<dynamic>)
        .map((item) =>
            TenancyRecord.fromJson(item as Map<String, dynamic>))
        .toList();

    final records = <PaymentRecord>[];
    for (final tenancy in tenancies) {
      List<Map<String, dynamic>> payments = const [];
      try {
        final paymentsResp =
            await _api.get('/payments/tenancy/${tenancy.id}');
        if (paymentsResp.statusCode == 200) {
          payments = (jsonDecode(paymentsResp.body) as List<dynamic>)
              .cast<Map<String, dynamic>>();
        }
      } catch (_) {
        // Skip tenancies whose payment fetch fails; show pending fallback.
      }

      if (payments.isEmpty) {
        if (tenancy.status == 'active') {
          records.add(PaymentRecord.pendingFor(tenancy));
        }
        continue;
      }

      final now = DateTime.now();
      final hasPaymentThisMonth = payments.any((p) {
        final date = _parseDate(p['payment_date']) ??
            _parseDate(p['created_at']);
        return date != null &&
            date.year == now.year &&
            date.month == now.month;
      });

      for (final payment in payments) {
        records.add(PaymentRecord.fromTenancyAndPayment(tenancy, payment));
      }

      // Only synthesize a "Pending" row when there is no payment at all
      // this month — otherwise the existing pending payment row already
      // represents this month's rent.
      if (!hasPaymentThisMonth && tenancy.status == 'active') {
        records.add(PaymentRecord.pendingFor(tenancy));
      }
    }

    records.sort((a, b) {
      if (a.isPending && !b.isPending) return -1;
      if (!a.isPending && b.isPending) return 1;
      return 0;
    });
    return records;
  }

  Future<void> _sendPaymentReminder(PaymentRecord payment) async {
    if (payment.tenancyId == null) {
      _showSnack(context, 'Missing tenancy info — cannot send reminder.');
      return;
    }
    try {
      final response = await _api.post('/notifications/rent-reminder', {
        'tenancy_id': payment.tenancyId,
        'message':
            'Dear ${payment.tenantName}, your rent of ${_money(payment.amount)} for ${payment.property} (Unit ${payment.unit}) is overdue by ${payment.daysLate} days. Please make payment to avoid penalties.',
      });
      if (!mounted) return;
      if (response.statusCode == 200) {
        _showSnack(context, 'Reminder sent to ${payment.tenantName}.');
      } else {
        _showSnack(context,
            'Reminder failed (${response.statusCode}) for ${payment.tenantName}.');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(context, 'Reminder failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'Payments',
      accentColor: AppColors.kodiGreen,
      child: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<PaymentRecord>>(
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
            final allPayments = snapshot.data ?? const <PaymentRecord>[];
            final visiblePayments = _filter == 'All'
                ? allPayments
                : allPayments
                    .where((payment) => payment.status == _filter)
                    .toList();
            final totalCollected = allPayments
                .where((payment) => payment.isPaid)
                .fold<int>(0, (sum, payment) => sum + payment.amount);
            final totalPending = allPayments
                .where((payment) => payment.isPending)
                .fold<int>(0, (sum, payment) => sum + payment.amount);

            return ListView(
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
                Row(
                  children: [
                    Expanded(
                        child: _MetricCard(
                            label: 'Total Received',
                            value: _money(totalCollected),
                            color: AppColors.kodiGreen)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _MetricCard(
                            label: 'Pending',
                            value: _money(totalPending),
                            color: AppColors.kodiOrange)),
                  ],
                ),
                const SizedBox(height: 16),
                if (visiblePayments.isEmpty)
                  const _EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No payments found',
                    subtitle: 'Try a different payment filter.',
                  )
                else
                  ...visiblePayments.map(
                    (payment) => _PaymentItem(
                      payment: payment,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PaymentDetailScreen(payment: payment),
                        ),
                      ),
                      onReminder: payment.isPending && payment.tenancyId != null
                          ? () => _sendPaymentReminder(payment)
                          : null,
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: allPayments.isEmpty
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PaymentReportScreen(payments: allPayments),
                            ),
                          ),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download Report'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PaymentDetailScreen extends StatelessWidget {
  final PaymentRecord payment;

  const PaymentDetailScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'Payment Details',
      accentColor: _paymentStatusColor(payment.status),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _TappableCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  payment.isPaid
                      ? Icons.check_circle_rounded
                      : Icons.pending_actions_rounded,
                  color: _paymentStatusColor(payment.status),
                  size: 54,
                ),
                const SizedBox(height: 12),
                Text(
                  _money(payment.amount),
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                StatusPill(
                  label: payment.status,
                  color: _paymentStatusColor(payment.status),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _DetailSection(
            title: 'Tenant',
            rows: [
              _DetailRowData('Name', payment.tenantName),
              _DetailRowData('Phone', payment.tenantPhone),
              _DetailRowData('Email', payment.tenantEmail),
            ],
          ),
          const SizedBox(height: 14),
          _DetailSection(
            title: 'Property',
            rows: [
              _DetailRowData('Property', payment.property),
              _DetailRowData('Unit', payment.unit),
              _DetailRowData('Due Date', payment.dueDate),
            ],
          ),
          const SizedBox(height: 14),
          _DetailSection(
            title: 'Transaction',
            rows: [
              _DetailRowData('Method', payment.method),
              _DetailRowData('Reference', payment.transactionRef),
              _DetailRowData('Created', payment.createdAt),
              _DetailRowData('Updated', payment.updatedAt),
              _DetailRowData('Paid At', payment.paidAt ?? 'Not paid yet'),
            ],
          ),
          if (payment.isPending) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: payment.tenancyId == null
                    ? null
                    : () async {
                        final api = ApiService();
                        try {
                          final response = await api
                              .post('/notifications/rent-reminder', {
                            'tenancy_id': payment.tenancyId,
                            'message':
                                'Dear ${payment.tenantName}, your rent of ${_money(payment.amount)} for ${payment.property} is due.',
                          });
                          if (!context.mounted) return;
                          if (response.statusCode == 200) {
                            _showSnack(context,
                                'Reminder sent to ${payment.tenantName}.');
                          } else {
                            _showSnack(context,
                                'Reminder failed (${response.statusCode}).');
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          _showSnack(context, 'Reminder failed: $e');
                        }
                      },
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text(payment.tenancyId == null
                    ? 'Tenancy missing — cannot send reminder'
                    : 'Send Payment Reminder'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PaymentReportScreen extends StatelessWidget {
  final List<PaymentRecord> payments;

  const PaymentReportScreen({super.key, required this.payments});

  @override
  Widget build(BuildContext context) {
    final totalExpected =
        payments.fold<int>(0, (sum, payment) => sum + payment.amount);
    final totalCollected = payments
        .where((payment) => payment.isPaid)
        .fold<int>(0, (sum, payment) => sum + payment.amount);
    final totalPending = totalExpected - totalCollected;
    final collectionRate = totalExpected == 0
        ? 0
        : ((totalCollected / totalExpected) * 100).round();
    final arrears = payments.where((payment) => payment.isPending).toList();
    final propertyBreakdown = _buildPropertyBreakdown(payments);

    return _FeatureScaffold(
      title: 'Payment Report',
      accentColor: AppColors.kodiGreen,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _ReportDocumentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PaymentReportHeader(
                  generatedDate: '19 May 2026',
                  period: 'May 2026',
                ),
                const SizedBox(height: 18),
                const _LandlordReportInfo(),
                const SizedBox(height: 18),
                _PaymentReportSummary(
                  totalExpected: totalExpected,
                  totalCollected: totalCollected,
                  totalPending: totalPending,
                  collectionRate: collectionRate,
                ),
                const SizedBox(height: 18),
                _PropertyBreakdownTable(rows: propertyBreakdown),
                const SizedBox(height: 18),
                _DetailedPaymentTable(payments: payments),
                const SizedBox(height: 18),
                _ArrearsTable(payments: arrears),
                const SizedBox(height: 18),
                _ReportCharts(
                  propertyRows: propertyBreakdown,
                  totalCollected: totalCollected,
                  totalPending: totalPending,
                ),
                const SizedBox(height: 18),
                const Divider(color: AppColors.border),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Generated by KodiPay',
                        style: TextStyle(
                          color: AppColors.kodiNavy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text('support@kodipay.co.ke  |  Page 1'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final pdfService = PdfReportService();
                    await pdfService.generatePaymentReport(
                      landlordName: 'Johnnie Njenga',
                      landlordEmail: 'njengajohnnie@gmail.com',
                      landlordPhone: '+254 700 000 000',
                      propertyCount: 3,
                      totalExpected: totalExpected,
                      totalCollected: totalCollected,
                      totalPending: totalPending,
                      period: 'May 2026',
                      payments: payments.map((p) => {
                        'tenant': p.tenantName,
                        'unit': p.unit,
                        'property': p.property,
                        'amount': _money(p.amount),
                        'status': p.status,
                        'date': p.paidAt ?? '-',
                      }).toList(),
                      propertyBreakdown: propertyBreakdown.map((pb) => {
                        'name': pb.propertyName,
                        'units': pb.units.toString(),
                        'collected': _money(pb.collected),
                        'pending': _money(pb.pending),
                      }).toList(),
                      arrears: arrears.map((a) => {
                        'tenant': a.tenantName,
                        'unit': a.unit,
                        'amount': _money(a.amount),
                        'days': '${a.daysLate} days',
                      }).toList(),
                      barChartData: propertyBreakdown.map((pb) => {
                        'label': pb.propertyName,
                        'value': pb.collected,
                      }).toList(),
                      pieCollected: totalCollected,
                      piePending: totalPending,
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Download PDF'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final csv = StringBuffer();
                    csv.writeln('Tenant,Unit,Property,Amount,Status,Date');
                    for (final p in payments) {
                      csv.writeln('${p.tenantName},${p.unit},${p.property},${p.amount},${p.status},${p.paidAt ?? '-'}');
                    }
                    final blob = html.Blob([csv.toString()], 'text/csv');
                    final url = html.Url.createObjectUrlFromBlob(blob);
                    final anchor = html.AnchorElement(href: url)
                      ..setAttribute('download', 'payment_report_May2026.csv')
                      ..click();
                    html.Url.revokeObjectUrl(url);
                  },
                  icon: const Icon(Icons.table_chart_outlined),
                  label: const Text('CSV'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LandlordReportsScreen extends StatefulWidget {
  const LandlordReportsScreen({super.key});

  @override
  State<LandlordReportsScreen> createState() => _LandlordReportsScreenState();
}

class _LandlordReportsScreenState extends State<LandlordReportsScreen> {
  String _reportType = 'Income';
  String _property = 'All Properties';
  String _period = 'This Month';
  String _status = 'All';

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'Reports',
      accentColor: AppColors.kodiBlue,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _ReportFilters(
            period: _period,
            property: _property,
            status: _status,
            onPeriodChanged: (value) => setState(() => _period = value),
            onPropertyChanged: (value) => setState(() => _property = value),
            onStatusChanged: (value) => setState(() => _status = value),
          ),
          const SizedBox(height: 16),
          _ReportTypeSelector(
            selected: _reportType,
            onChanged: (value) => setState(() => _reportType = value),
          ),
          const SizedBox(height: 16),
          _ReportSummaryGrid(reportType: _reportType),
          const SizedBox(height: 16),
          if (_reportType == 'Income') ...[
            const _IncomeTrendCard(),
            const SizedBox(height: 16),
            const _PropertyIncomeBreakdown(),
          ] else if (_reportType == 'Arrears') ...[
            _ArrearsReport(onReminder: _sendReminder),
          ] else if (_reportType == 'Property') ...[
            const _PropertyPerformanceReport(),
          ] else if (_reportType == 'Maintenance') ...[
            const _MaintenanceReport(),
          ] else if (_reportType == 'Trends') ...[
            const _IncomeTrendCard(),
            const SizedBox(height: 16),
            const _PaidVsPendingCard(),
          ] else ...[
            const _TransactionReport(),
          ],
          const SizedBox(height: 18),
          _ReportActions(
            onExportPdf: () async {
              final pdf = PdfReportService();
              await pdf.generatePaymentReport(
                landlordName: 'Johnnie Njenga',
                landlordEmail: 'njengajohnnie@gmail.com',
                landlordPhone: '+254 700 000 000',
                propertyCount: 3,
                totalExpected: 245000,
                totalCollected: 195000,
                totalPending: 50000,
                period: '$_period $_property',
                payments: [
                  {'tenant': 'Mary Wanjiku', 'unit': 'A2 - Sunview Apts', 'property': 'Sunview Apartments', 'amount': 'KSh 25,000', 'status': 'Paid', 'date': '15 May 2026'},
                  {'tenant': 'John Kamau', 'unit': 'B1 - Greenfield Hts', 'property': 'Greenfield Heights', 'amount': 'KSh 20,000', 'status': 'Paid', 'date': '14 May 2026'},
                  {'tenant': 'Peter Ochieng', 'unit': 'C3 - Lakeview Villas', 'property': 'Lakeview Villas', 'amount': 'KSh 25,000', 'status': 'Pending', 'date': '-'},
                ],
                propertyBreakdown: [
                  {'name': 'Sunview Apartments', 'units': '3', 'collected': 'KSh 75,000', 'pending': 'KSh 0'},
                  {'name': 'Greenfield Heights', 'units': '3', 'collected': 'KSh 60,000', 'pending': 'KSh 25,000'},
                  {'name': 'Lakeview Villas', 'units': '3', 'collected': 'KSh 60,000', 'pending': 'KSh 25,000'},
                ],
                arrears: [
                  {'tenant': 'Peter Ochieng', 'unit': 'C3', 'amount': 'KSh 25,000', 'days': '5 days'},
                ],
                barChartData: [
                  {'label': 'Sunview Apartments', 'value': 75000},
                  {'label': 'Greenfield Heights', 'value': 60000},
                  {'label': 'Lakeview Villas', 'value': 60000},
                ],
                pieCollected: 195000,
                piePending: 50000,
              );
            },
            onExportCsv: () {
              final csv = StringBuffer();
              csv.writeln('Tenant,Unit,Property,Amount,Status,Date');
              for (final row in [
                ['Mary Wanjiku', 'A2 - Sunview Apts', 'Sunview Apartments', 'KSh 25,000', 'Paid', '15 May 2026'],
                ['John Kamau', 'B1 - Greenfield Hts', 'Greenfield Heights', 'KSh 20,000', 'Paid', '14 May 2026'],
                ['Peter Ochieng', 'C3 - Lakeview Villas', 'Lakeview Villas', 'KSh 25,000', 'Pending', '-'],
              ]) {
                csv.writeln(row.join(','));
              }
              final blob = html.Blob([csv.toString()], 'text/csv');
              final url = html.Url.createObjectUrlFromBlob(blob);
              html.AnchorElement(href: url)
                ..setAttribute('download', 'report_${_period.replaceAll(' ', '_')}.csv')
                ..click();
              html.Url.revokeObjectUrl(url);
            },
            onSendReminders: () =>
                _showSnack(context, 'Reminders queued for overdue tenants.'),
          ),
        ],
      ),
    );
  }

  void _sendReminder(String tenant) {
    _showSnack(context, 'Reminder sent to $tenant.');
  }
}

class _ReportFilters extends StatelessWidget {
  final String period;
  final String property;
  final String status;
  final ValueChanged<String> onPeriodChanged;
  final ValueChanged<String> onPropertyChanged;
  final ValueChanged<String> onStatusChanged;

  const _ReportFilters({
    required this.period,
    required this.property,
    required this.status,
    required this.onPeriodChanged,
    required this.onPropertyChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _TappableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filters', style: _titleStyle),
          const SizedBox(height: 12),
          _ReportDropdown(
            label: 'Date Range',
            value: period,
            values: const ['Today', 'This Month', 'This Quarter', 'This Year'],
            onChanged: onPeriodChanged,
          ),
          const SizedBox(height: 10),
          _ReportDropdown(
            label: 'Property',
            value: property,
            values: const [
              'All Properties',
              'Sunview Apartments',
              'Greenfield Heights',
              'Lakeview Villas',
            ],
            onChanged: onPropertyChanged,
          ),
          const SizedBox(height: 10),
          _ReportDropdown(
            label: 'Status',
            value: status,
            values: const ['All', 'Paid', 'Pending', 'Overdue'],
            onChanged: onStatusChanged,
          ),
        ],
      ),
    );
  }
}

class _ReportDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  const _ReportDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _ReportTypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _ReportTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const types = [
      'Income',
      'Arrears',
      'Property',
      'Maintenance',
      'Trends',
      'Transactions'
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: types
            .map(
              (type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(type),
                  selected: selected == type,
                  selectedColor: AppColors.kodiBlue.withValues(alpha: 0.14),
                  labelStyle: TextStyle(
                    color: selected == type
                        ? AppColors.kodiBlue
                        : AppColors.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) => onChanged(type),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ReportSummaryGrid extends StatelessWidget {
  final String reportType;

  const _ReportSummaryGrid({required this.reportType});

  @override
  Widget build(BuildContext context) {
    final cards = switch (reportType) {
      'Arrears' => const [
          _ReportMetric(
              label: 'Overdue Amount',
              value: 'KSh 75,000',
              color: AppColors.danger),
          _ReportMetric(
              label: 'Tenants Overdue',
              value: '5',
              color: AppColors.kodiOrange),
          _ReportMetric(
              label: 'Avg Days Late', value: '9', color: AppColors.kodiBlue),
        ],
      'Maintenance' => const [
          _ReportMetric(
              label: 'Open Issues', value: '12', color: AppColors.kodiOrange),
          _ReportMetric(
              label: 'Completed', value: '18', color: AppColors.kodiGreen),
          _ReportMetric(
              label: 'Cost', value: 'KSh 38k', color: AppColors.kodiBlue),
        ],
      'Property' => const [
          _ReportMetric(
              label: 'Best Property',
              value: 'Greenfield',
              color: AppColors.kodiGreen),
          _ReportMetric(
              label: 'Occupancy', value: '94%', color: AppColors.kodiBlue),
          _ReportMetric(
              label: 'Vacant Units', value: '6', color: AppColors.kodiOrange),
        ],
      _ => const [
          _ReportMetric(
              label: 'Collected',
              value: 'KSh 245k',
              color: AppColors.kodiGreen),
          _ReportMetric(
              label: 'Expected', value: 'KSh 320k', color: AppColors.kodiBlue),
          _ReportMetric(
              label: 'Pending', value: 'KSh 75k', color: AppColors.kodiOrange),
        ],
    };

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.92,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: cards,
    );
  }
}

class _ReportMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ReportMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _TappableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppStyles.caption),
          const SizedBox(height: 8),
          FittedBox(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                  color: color, fontSize: 19, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeTrendCard extends StatelessWidget {
  const _IncomeTrendCard();

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      title: 'Monthly Income Trend',
      child: SizedBox(
        height: 210,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May'];
                    final index = value.toInt();
                    if (index < 0 || index >= labels.length) {
                      return const SizedBox.shrink();
                    }
                    return Text(labels[index], style: AppStyles.caption);
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: 4,
            minY: 0,
            maxY: 320,
            lineBarsData: [
              LineChartBarData(
                spots: const [
                  FlSpot(0, 180),
                  FlSpot(1, 210),
                  FlSpot(2, 195),
                  FlSpot(3, 245),
                  FlSpot(4, 275),
                ],
                isCurved: true,
                barWidth: 4,
                color: AppColors.kodiBlue,
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.kodiBlue.withValues(alpha: 0.12),
                ),
                dotData: const FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaidVsPendingCard extends StatelessWidget {
  const _PaidVsPendingCard();

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      title: 'Paid vs Pending',
      child: Row(
        children: [
          SizedBox(
            width: 132,
            height: 132,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 34,
                sections: [
                  PieChartSectionData(
                    value: 77,
                    color: AppColors.kodiGreen,
                    title: '77%',
                    radius: 32,
                    titleStyle: const TextStyle(
                        color: AppColors.white, fontWeight: FontWeight.w800),
                  ),
                  PieChartSectionData(
                    value: 23,
                    color: AppColors.kodiOrange,
                    title: '23%',
                    radius: 32,
                    titleStyle: const TextStyle(
                        color: AppColors.white, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendRow(
                    color: AppColors.kodiGreen,
                    label: 'Paid',
                    value: 'KSh 245,000'),
                SizedBox(height: 12),
                _LegendRow(
                    color: AppColors.kodiOrange,
                    label: 'Pending',
                    value: 'KSh 75,000'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: _titleStyle)),
        Text(value, style: _smallBoldStyle),
      ],
    );
  }
}

class _PropertyIncomeBreakdown extends StatelessWidget {
  const _PropertyIncomeBreakdown();

  @override
  Widget build(BuildContext context) {
    return const _ReportSection(
      title: 'Per Property Breakdown',
      child: Column(
        children: [
          _ReportDataRow(
              label: 'Sunview Apartments',
              value: 'KSh 250,000',
              status: '92% paid',
              color: AppColors.kodiGreen),
          _ReportDivider(),
          _ReportDataRow(
              label: 'Greenfield Heights',
              value: 'KSh 610,000',
              status: '96% paid',
              color: AppColors.kodiGreen),
          _ReportDivider(),
          _ReportDataRow(
              label: 'Lakeview Villas',
              value: 'KSh 180,000',
              status: '78% paid',
              color: AppColors.kodiOrange),
        ],
      ),
    );
  }
}

class _ArrearsReport extends StatelessWidget {
  final ValueChanged<String> onReminder;

  const _ArrearsReport({required this.onReminder});

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      title: 'Tenants With Unpaid Rent',
      child: Column(
        children: [
          _ArrearsRow(
              tenant: 'Peter Ochieng',
              unit: 'C3 - Lakeview Villas',
              amount: 'KSh 25,000',
              days: '12 days',
              onReminder: onReminder),
          const _ReportDivider(),
          _ArrearsRow(
              tenant: 'Grace Njeri',
              unit: 'A1 - Sunview Apts',
              amount: 'KSh 30,000',
              days: '8 days',
              onReminder: onReminder),
          const _ReportDivider(),
          _ArrearsRow(
              tenant: 'Brian Otieno',
              unit: 'B8 - Greenfield Hts',
              amount: 'KSh 20,000',
              days: '5 days',
              onReminder: onReminder),
        ],
      ),
    );
  }
}

class _ArrearsRow extends StatelessWidget {
  final String tenant;
  final String unit;
  final String amount;
  final String days;
  final ValueChanged<String> onReminder;

  const _ArrearsRow({
    required this.tenant,
    required this.unit,
    required this.amount,
    required this.days,
    required this.onReminder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(tenant, style: _titleStyle)),
              Text(amount,
                  style: const TextStyle(
                      color: AppColors.danger, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 4),
          Text('$unit  -  $days overdue', style: AppStyles.caption),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onReminder(tenant),
              icon: const Icon(Icons.sms_outlined),
              label: const Text('Send Reminder'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyPerformanceReport extends StatelessWidget {
  const _PropertyPerformanceReport();

  @override
  Widget build(BuildContext context) {
    return const _ReportSection(
      title: 'Property Performance',
      child: Column(
        children: [
          _ReportDataRow(
              label: 'Greenfield Heights',
              value: 'KSh 610,000',
              status: '25/32 occupied',
              color: AppColors.kodiGreen),
          _ReportDivider(),
          _ReportDataRow(
              label: 'Sunview Apartments',
              value: 'KSh 250,000',
              status: '10/12 occupied',
              color: AppColors.kodiBlue),
          _ReportDivider(),
          _ReportDataRow(
              label: 'Lakeview Villas',
              value: 'KSh 180,000',
              status: '8/10 occupied',
              color: AppColors.kodiOrange),
        ],
      ),
    );
  }
}

class _MaintenanceReport extends StatelessWidget {
  const _MaintenanceReport();

  @override
  Widget build(BuildContext context) {
    return const _ReportSection(
      title: 'Maintenance Costs & Issues',
      child: Column(
        children: [
          _ReportDataRow(
              label: 'Plumbing',
              value: '6 issues',
              status: 'KSh 18,000',
              color: AppColors.kodiOrange),
          _ReportDivider(),
          _ReportDataRow(
              label: 'Electrical',
              value: '3 issues',
              status: 'KSh 12,500',
              color: AppColors.danger),
          _ReportDivider(),
          _ReportDataRow(
              label: 'Locks & Doors',
              value: '3 issues',
              status: 'KSh 7,500',
              color: AppColors.kodiBlue),
        ],
      ),
    );
  }
}

class _TransactionReport extends StatelessWidget {
  const _TransactionReport();

  @override
  Widget build(BuildContext context) {
    return const _ReportSection(
      title: 'Transaction History',
      child: Column(
        children: [
          _ReportDataRow(
              label: 'Mary Wanjiku',
              value: 'KSh 25,000',
              status: 'M-Pesa - Paid',
              color: AppColors.kodiGreen),
          _ReportDivider(),
          _ReportDataRow(
              label: 'John Kamau',
              value: 'KSh 20,000',
              status: 'Bank - Paid',
              color: AppColors.kodiGreen),
          _ReportDivider(),
          _ReportDataRow(
              label: 'Peter Ochieng',
              value: 'KSh 25,000',
              status: 'Pending',
              color: AppColors.kodiOrange),
        ],
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ReportSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _TappableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _titleStyle),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ReportDataRow extends StatelessWidget {
  final String label;
  final String value;
  final String status;
  final Color color;

  const _ReportDataRow({
    required this.label,
    required this.value,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _titleStyle),
                const SizedBox(height: 4),
                Text(status, style: AppStyles.caption),
              ],
            ),
          ),
          Text(value,
              style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ReportDivider extends StatelessWidget {
  const _ReportDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.border);
  }
}

class _ReportActions extends StatelessWidget {
  final VoidCallback onExportPdf;
  final VoidCallback onExportCsv;
  final VoidCallback onSendReminders;

  const _ReportActions({
    required this.onExportPdf,
    required this.onExportCsv,
    required this.onSendReminders,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onExportPdf,
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('PDF'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onExportCsv,
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('CSV'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onSendReminders,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Send Arrears Reminders'),
          ),
        ),
      ],
    );
  }
}

void _showExportSheet(BuildContext context, String type) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Export $type Report', style: AppStyles.heading2),
            const SizedBox(height: 10),
            const Text(
              'Includes filters, summaries, arrears, property performance, maintenance, and transactions.',
              style: AppStyles.bodyMedium,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showSnack(context, '$type export generated.');
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class TenantPaymentsScreen extends StatefulWidget {
  const TenantPaymentsScreen({super.key});

  @override
  State<TenantPaymentsScreen> createState() => _TenantPaymentsScreenState();
}

class _TenantPaymentsScreenState extends State<TenantPaymentsScreen> {
  final ApiService _api = ApiService();
  Future<_TenantPaymentsBundle>? _future;

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

  Future<_TenantPaymentsBundle> _fetch() async {
    final tenancyResp = await _api.get('/tenancies');
    if (tenancyResp.statusCode != 200) {
      throw Exception('Could not load tenancy (${tenancyResp.statusCode})');
    }
    final tenancies = (jsonDecode(tenancyResp.body) as List<dynamic>)
        .cast<Map<String, dynamic>>();
    if (tenancies.isEmpty) {
      return const _TenantPaymentsBundle(payments: [], tenancy: null);
    }
    final active = tenancies.firstWhere(
      (t) => (t['status']?.toString() ?? 'active') == 'active',
      orElse: () => tenancies.first,
    );
    final tenancyId = active['id'];
    final paymentsResp = await _api.get('/payments/tenancy/$tenancyId');
    if (paymentsResp.statusCode != 200) {
      throw Exception('Could not load payments (${paymentsResp.statusCode})');
    }
    final payments = (jsonDecode(paymentsResp.body) as List<dynamic>)
        .map((item) =>
            _TenantPayment.fromJson(item as Map<String, dynamic>))
        .toList();
    return _TenantPaymentsBundle(
      payments: payments,
      tenancy: _TenantTenancySummary.fromJson(active),
    );
  }

  void _downloadCsv(List<_TenantPayment> payments,
      _TenantTenancySummary? tenancy) {
    if (payments.isEmpty) {
      _showSnack(context, 'No payments to download yet.');
      return;
    }
    final csv = StringBuffer();
    csv.writeln('Date,Amount,Method,Reference,Status');
    for (final p in payments) {
      csv.writeln([
        p.paymentDate?.toIso8601String().split('T').first ?? '',
        p.amount.toStringAsFixed(2),
        _csvField(p.method),
        _csvField(p.transactionRef ?? ''),
        _csvField(p.status),
      ].join(','));
    }
    final blob = html.Blob([csv.toString()], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final name = tenancy?.propertyName ?? 'tenant';
    html.AnchorElement(href: url)
      ..setAttribute('download', 'my_payments_${name.replaceAll(' ', '_')}.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'My Payments',
      accentColor: AppColors.kodiBlue,
      child: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<_TenantPaymentsBundle>(
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
            final bundle = snapshot.data ??
                const _TenantPaymentsBundle(payments: [], tenancy: null);
            final payments = bundle.payments;
            final tenancy = bundle.tenancy;
            final amountDue =
                tenancy?.rentAmount ?? 0;
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                GradientPanel(
                  startColor: const Color(0xFF1D6FD8),
                  endColor: const Color(0xFF0047A1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount Due',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.86)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        amountDue > 0
                            ? 'KSh ${_formatKsh(amountDue)}'
                            : 'KSh 0',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (tenancy != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${tenancy.propertyName} • Unit ${tenancy.unitNumber}',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.86),
                              fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.white,
                              foregroundColor: AppColors.kodiBlue),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/pay-rent'),
                          child: const Text('Pay Now (M-Pesa)'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: SectionTitle(title: 'Payment History'),
                    ),
                    TextButton.icon(
                      onPressed: () => _downloadCsv(payments, tenancy),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download'),
                    ),
                  ],
                ),
                if (payments.isEmpty)
                  const _EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No payments yet',
                    subtitle:
                        'Your rent receipts will show up here once payments are recorded.',
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < payments.length; i++) ...[
                          if (i > 0)
                            const Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: AppColors.border),
                          _TenantPaymentRow(payment: payments[i]),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _csvField(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

class _TenantPaymentsBundle {
  final List<_TenantPayment> payments;
  final _TenantTenancySummary? tenancy;
  const _TenantPaymentsBundle({required this.payments, required this.tenancy});
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
      id: _toInt(json['id']),
      propertyName: (json['property_name'] ?? '').toString(),
      unitNumber: (json['unit_number'] ?? '').toString(),
      rentAmount: _toNum(json['rent_amount']),
    );
  }
}

class _TenantPayment {
  final int id;
  final num amount;
  final String method;
  final String? transactionRef;
  final String status;
  final DateTime? paymentDate;

  const _TenantPayment({
    required this.id,
    required this.amount,
    required this.method,
    required this.transactionRef,
    required this.status,
    required this.paymentDate,
  });

  factory _TenantPayment.fromJson(Map<String, dynamic> json) {
    return _TenantPayment(
      id: _toInt(json['id']),
      amount: _toNum(json['amount']),
      method: (json['payment_method'] ?? '').toString(),
      transactionRef: json['transaction_ref']?.toString(),
      status: (json['status'] ?? '').toString(),
      paymentDate: DateTime.tryParse(json['payment_date']?.toString() ?? ''),
    );
  }
}

class _TenantPaymentRow extends StatelessWidget {
  final _TenantPayment payment;
  const _TenantPaymentRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    final isPaid = payment.status.toLowerCase() == 'completed';
    final color = isPaid ? AppColors.kodiGreen : AppColors.kodiOrange;
    final label = isPaid ? 'Paid' : _capitalize(payment.status);
    final dateText = payment.paymentDate == null
        ? '—'
        : '${payment.paymentDate!.day}/${payment.paymentDate!.month}/${payment.paymentDate!.year}';
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPaid ? Icons.check_circle_outline : Icons.pending_actions,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('KSh ${_formatKsh(payment.amount)}', style: _titleStyle),
                const SizedBox(height: 4),
                Text(
                  '${_capitalize(payment.method)} • ${payment.transactionRef ?? 'No reference'}',
                  style: AppStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(dateText,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      fontSize: 12)),
              const SizedBox(height: 4),
              StatusPill(label: label, color: color),
            ],
          ),
        ],
      ),
    );
  }
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

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
      unitId = _toInt(active['unit_id']);
    }

    final response = await _api.get('/maintenance/mine');
    if (response.statusCode != 200) {
      throw Exception('Could not load issues (${response.statusCode})');
    }
    final items = (jsonDecode(response.body) as List<dynamic>)
        .map((item) =>
            _MaintenanceItem.fromJson(item as Map<String, dynamic>))
        .toList();
    return _TenantMaintenanceBundle(
      items: items,
      tenancy: tenancy,
      unitId: unitId,
    );
  }

  Future<void> _onReport(_TenantMaintenanceBundle bundle) async {
    if (bundle.unitId == null) {
      _showSnack(context, 'No active tenancy — please contact your landlord.');
      return;
    }
    final created = await showIssueSheet(context, unitId: bundle.unitId!);
    if (created == true) _reload();
  }

  Future<void> _openDetail(_MaintenanceItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MaintenanceDetailScreen(item: item)),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
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
            final items = bundle?.items ?? const <_MaintenanceItem>[];
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
  final List<_MaintenanceItem> items;
  final _TenantTenancySummary? tenancy;
  final int? unitId;
  const _TenantMaintenanceBundle({
    required this.items,
    required this.tenancy,
    required this.unitId,
  });
}

class _MaintenanceItem {
  final int id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String category;
  final String propertyName;
  final String unitNumber;
  final String tenantName;
  final String? tenantPhone;
  final String? tenantEmail;
  final DateTime createdAt;
  final DateTime updatedAt;

  const _MaintenanceItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.propertyName,
    required this.unitNumber,
    required this.tenantName,
    required this.tenantPhone,
    required this.tenantEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isEmergency => priority.toLowerCase() == 'emergency';
  bool get isResolved => status.toLowerCase() == 'completed';

  factory _MaintenanceItem.fromJson(Map<String, dynamic> json) {
    final first = (json['tenant_first_name'] ?? '').toString();
    final last = (json['tenant_last_name'] ?? '').toString();
    final fullName = '$first $last'.trim();
    return _MaintenanceItem(
      id: _toInt(json['id']),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      priority: (json['priority'] ?? 'medium').toString(),
      category: (json['category'] ?? 'other').toString(),
      propertyName: (json['property_name'] ?? '').toString(),
      unitNumber: (json['unit_number'] ?? '').toString(),
      tenantName: fullName,
      tenantPhone: json['tenant_phone']?.toString(),
      tenantEmail: json['tenant_email']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
              DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
              DateTime.now(),
    );
  }
}

Color _maintenanceStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return AppColors.kodiGreen;
    case 'in_progress':
      return AppColors.kodiBlue;
    case 'cancelled':
      return AppColors.muted;
    default:
      return AppColors.kodiOrange;
  }
}

String _maintenanceStatusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'in_progress':
      return 'In Progress';
    case 'completed':
      return 'Completed';
    case 'cancelled':
      return 'Cancelled';
    default:
      return 'Pending';
  }
}

Color _maintenancePriorityColor(String priority) {
  switch (priority.toLowerCase()) {
    case 'emergency':
      return AppColors.danger;
    case 'urgent':
    case 'high':
      return AppColors.kodiOrange;
    case 'low':
      return AppColors.muted;
    default:
      return AppColors.kodiBlue;
  }
}

String _capitalizeWord(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

class _MaintenanceItemCard extends StatelessWidget {
  final _MaintenanceItem item;
  final VoidCallback onTap;
  const _MaintenanceItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _maintenanceStatusColor(item.status);
    final statusLabel = _maintenanceStatusLabel(item.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _TappableCard(
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
                      Text(item.title, style: _titleStyle),
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
                _MaintenanceTag(
                    label: _capitalizeWord(item.category),
                    color: AppColors.kodiNavy),
                const SizedBox(width: 8),
                _MaintenanceTag(
                  label: _capitalizeWord(item.priority),
                  color: _maintenancePriorityColor(item.priority),
                ),
                const Spacer(),
                Text(_relativeTime(item.createdAt), style: AppStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceTag extends StatelessWidget {
  final String label;
  final Color color;
  const _MaintenanceTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class MaintenanceDetailScreen extends StatelessWidget {
  final _MaintenanceItem item;
  const MaintenanceDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = _maintenanceStatusColor(item.status);
    final statusLabel = _maintenanceStatusLabel(item.status);
    return _FeatureScaffold(
      title: 'Issue Details',
      accentColor: statusColor,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _TappableCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.build_circle_outlined,
                          color: statusColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: AppStyles.heading2),
                          const SizedBox(height: 4),
                          Text(
                            item.unitNumber.isEmpty
                                ? item.propertyName
                                : '${item.propertyName} • Unit ${item.unitNumber}',
                            style: AppStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    StatusPill(label: statusLabel, color: statusColor),
                    const SizedBox(width: 8),
                    _MaintenanceTag(
                      label: _capitalizeWord(item.priority),
                      color: _maintenancePriorityColor(item.priority),
                    ),
                    const SizedBox(width: 8),
                    _MaintenanceTag(
                      label: _capitalizeWord(item.category),
                      color: AppColors.kodiNavy,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _TappableCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Description', style: _titleStyle),
                const SizedBox(height: 8),
                Text(
                  item.description.isEmpty
                      ? 'No description provided.'
                      : item.description,
                  style: const TextStyle(
                      color: AppColors.textDark, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _TappableCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Timeline', style: _titleStyle),
                const SizedBox(height: 12),
                _MaintenanceTimelineRow(
                  icon: Icons.report_problem_outlined,
                  color: AppColors.kodiBlue,
                  label: 'Reported',
                  time: item.createdAt,
                ),
                if (item.updatedAt != item.createdAt)
                  _MaintenanceTimelineRow(
                    icon: item.status.toLowerCase() == 'completed'
                        ? Icons.check_circle_outline
                        : Icons.timelapse_outlined,
                    color: statusColor,
                    label: 'Last updated ($statusLabel)',
                    time: item.updatedAt,
                  ),
                if (item.status.toLowerCase() == 'completed') ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Your caretaker marked this issue as completed.',
                    style: AppStyles.caption,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceTimelineRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final DateTime time;
  const _MaintenanceTimelineRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${time.day}/${time.month}/${time.year} • '
                  '${time.hour.toString().padLeft(2, '0')}:'
                  '${time.minute.toString().padLeft(2, '0')}',
                  style: AppStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TenantNoticesScreen extends StatefulWidget {
  const TenantNoticesScreen({super.key});

  @override
  State<TenantNoticesScreen> createState() => _TenantNoticesScreenState();
}

class _TenantNoticesScreenState extends State<TenantNoticesScreen> {
  final ApiService _api = ApiService();
  Future<List<_NotificationItem>>? _future;

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

  Future<List<_NotificationItem>> _fetch() async {
    final response = await _api.get('/notifications');
    if (response.statusCode != 200) {
      throw Exception('Could not load notices (${response.statusCode})');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => _NotificationItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _openNotice(_NotificationItem item) async {
    if (!item.isRead) {
      try {
        await _api.put('/notifications/${item.id}/read');
      } catch (_) {
        // Non-fatal — proceed to open the detail screen.
      }
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoticeDetailScreen(item: item)),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'Notices',
      accentColor: AppColors.kodiBlue,
      child: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<_NotificationItem>>(
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
            final items = snapshot.data ?? const <_NotificationItem>[];
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(40),
                children: const [
                  SizedBox(height: 80),
                  Icon(Icons.notifications_none_rounded,
                      size: 72, color: AppColors.muted),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'No notices yet',
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
                      'Reminders, announcements, and maintenance updates will appear here.',
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
                  _TenantNoticeCard(
                    item: item,
                    onTap: () => _openNotice(item),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TenantNoticeCard extends StatelessWidget {
  final _NotificationItem item;
  final VoidCallback onTap;

  const _TenantNoticeCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = _paletteForType(item.type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _TappableCard(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: palette.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(palette.icon, color: palette.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(item.title, style: _titleStyle)),
                      if (!item.isRead)
                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: AppColors.kodiBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (item.message.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.caption,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(_relativeTime(item.createdAt), style: AppStyles.caption),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class NoticeDetailScreen extends StatelessWidget {
  final _NotificationItem item;
  const NoticeDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final palette = _paletteForType(item.type);
    return _FeatureScaffold(
      title: _labelForType(item.type),
      accentColor: palette.color,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _TappableCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: palette.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(palette.icon, color: palette.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: AppStyles.heading2),
                          const SizedBox(height: 4),
                          Text(
                            _relativeTime(item.createdAt),
                            style: AppStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: palette.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _labelForType(item.type),
                    style: TextStyle(
                      color: palette.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _TappableCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Message', style: _titleStyle),
                const SizedBox(height: 10),
                Text(
                  item.message.isEmpty
                      ? 'No additional details provided.'
                      : item.message,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Received ${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year} at '
                  '${item.createdAt.hour.toString().padLeft(2, '0')}:'
                  '${item.createdAt.minute.toString().padLeft(2, '0')}',
                  style: AppStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _labelForType(String type) {
  switch (type.toLowerCase()) {
    case 'reminder':
    case 'rent_reminder':
    case 'sms_reminder':
      return 'Rent Reminder';
    case 'maintenance':
      return 'Maintenance Update';
    case 'announcement':
      return 'Announcement';
    case 'payment':
    case 'mpesa':
      return 'Payment';
    case 'alert':
    case 'warning':
      return 'Alert';
    default:
      return 'Notice';
  }
}

class CaretakerTasksScreen extends StatefulWidget {
  const CaretakerTasksScreen({super.key});

  @override
  State<CaretakerTasksScreen> createState() => _CaretakerTasksScreenState();
}

class _CaretakerTasksScreenState extends State<CaretakerTasksScreen> {
  final ApiService _api = ApiService();
  Future<List<_MaintenanceItem>>? _future;

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

  Future<List<_MaintenanceItem>> _fetch() async {
    final response = await _api.get('/maintenance/mine');
    if (response.statusCode != 200) {
      throw Exception('Could not load tasks (${response.statusCode})');
    }
    final all = (jsonDecode(response.body) as List<dynamic>)
        .map((item) =>
            _MaintenanceItem.fromJson(item as Map<String, dynamic>))
        .where((m) => !m.isEmergency && !m.isResolved)
        .toList();
    return all;
  }

  Future<void> _open(_MaintenanceItem item) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CaretakerTaskDetailScreen(item: item),
      ),
    );
    if (changed == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'Tasks',
      accentColor: AppColors.kodiOrange,
      child: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<_MaintenanceItem>>(
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
            final items = snapshot.data ?? const <_MaintenanceItem>[];
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(30),
                children: const [
                  SizedBox(height: 60),
                  Icon(Icons.task_alt_rounded,
                      size: 72, color: AppColors.muted),
                  SizedBox(height: 14),
                  Center(
                    child: Text(
                      'No open tasks',
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
                      'Non-emergency issues reported by tenants will show up here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textLight),
                    ),
                  ),
                ],
              );
            }
            final groups = _groupByProperty(items);
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                for (final entry in groups.entries) ...[
                  _PropertyGroupHeader(
                      name: entry.key, count: entry.value.length),
                  const SizedBox(height: 10),
                  for (var i = 0; i < entry.value.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    _CaretakerTaskCard(
                      item: entry.value[i],
                      onTap: () => _open(entry.value[i]),
                    ),
                  ],
                  const SizedBox(height: 18),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class CaretakerAlertsScreen extends StatefulWidget {
  const CaretakerAlertsScreen({super.key});

  @override
  State<CaretakerAlertsScreen> createState() => _CaretakerAlertsScreenState();
}

class _CaretakerAlertsScreenState extends State<CaretakerAlertsScreen> {
  final ApiService _api = ApiService();
  Future<List<_MaintenanceItem>>? _future;

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

  Future<List<_MaintenanceItem>> _fetch() async {
    final response =
        await _api.get('/maintenance/mine', query: {'priority': 'emergency'});
    if (response.statusCode != 200) {
      throw Exception('Could not load alerts (${response.statusCode})');
    }
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) =>
            _MaintenanceItem.fromJson(item as Map<String, dynamic>))
        .where((m) => !m.isResolved)
        .toList();
  }

  Future<void> _open(_MaintenanceItem item) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CaretakerTaskDetailScreen(item: item, isEmergency: true),
      ),
    );
    if (changed == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'Alerts',
      accentColor: AppColors.danger,
      child: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<_MaintenanceItem>>(
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
            final items = snapshot.data ?? const <_MaintenanceItem>[];
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(30),
                children: const [
                  SizedBox(height: 60),
                  Icon(Icons.shield_outlined,
                      size: 72, color: AppColors.kodiGreen),
                  SizedBox(height: 14),
                  Center(
                    child: Text(
                      'No active emergencies',
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
                      'Emergencies reported by tenants will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textLight),
                    ),
                  ),
                ],
              );
            }
            final groups = _groupByProperty(items);
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                for (final entry in groups.entries) ...[
                  _PropertyGroupHeader(
                      name: entry.key,
                      count: entry.value.length,
                      accent: AppColors.danger),
                  const SizedBox(height: 10),
                  for (var i = 0; i < entry.value.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    _CaretakerEmergencyCard(
                      item: entry.value[i],
                      onTap: () => _open(entry.value[i]),
                    ),
                  ],
                  const SizedBox(height: 18),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

Map<String, List<_MaintenanceItem>> _groupByProperty(
    List<_MaintenanceItem> items) {
  final groups = <String, List<_MaintenanceItem>>{};
  for (final item in items) {
    final key = item.propertyName.trim().isEmpty
        ? 'Unassigned'
        : item.propertyName;
    groups.putIfAbsent(key, () => []).add(item);
  }
  return groups;
}

class _PropertyGroupHeader extends StatelessWidget {
  final String name;
  final int count;
  final Color accent;
  const _PropertyGroupHeader({
    required this.name,
    required this.count,
    this.accent = AppColors.kodiOrange,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.apartment_rounded, color: accent, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _CaretakerTaskCard extends StatelessWidget {
  final _MaintenanceItem item;
  final VoidCallback onTap;
  const _CaretakerTaskCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _maintenanceStatusColor(item.status);
    final statusLabel = _maintenanceStatusLabel(item.status);
    return _TappableCard(
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
                  color: AppColors.kodiOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.handyman_rounded,
                    color: AppColors.kodiOrange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: _titleStyle),
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
              _MaintenanceTag(
                  label: _capitalizeWord(item.category),
                  color: AppColors.kodiNavy),
              const SizedBox(width: 8),
              _MaintenanceTag(
                label: _capitalizeWord(item.priority),
                color: _maintenancePriorityColor(item.priority),
              ),
              const Spacer(),
              Text(_relativeTime(item.createdAt), style: AppStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _CaretakerEmergencyCard extends StatelessWidget {
  final _MaintenanceItem item;
  final VoidCallback onTap;
  const _CaretakerEmergencyCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _TappableCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_rounded, color: AppColors.danger),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: _titleStyle),
                const SizedBox(height: 3),
                Text(
                  item.unitNumber.isEmpty
                      ? item.propertyName
                      : '${item.propertyName} • Unit ${item.unitNumber}',
                  style: AppStyles.caption,
                ),
                const SizedBox(height: 4),
                Text(
                  _relativeTime(item.createdAt),
                  style: AppStyles.caption,
                ),
              ],
            ),
          ),
          const StatusPill(label: 'Emergency', color: AppColors.danger),
        ],
      ),
    );
  }
}

class CaretakerTaskDetailScreen extends StatefulWidget {
  final _MaintenanceItem item;
  final bool isEmergency;
  const CaretakerTaskDetailScreen({
    super.key,
    required this.item,
    this.isEmergency = false,
  });

  @override
  State<CaretakerTaskDetailScreen> createState() =>
      _CaretakerTaskDetailScreenState();
}

class _CaretakerTaskDetailScreenState extends State<CaretakerTaskDetailScreen> {
  final ApiService _api = ApiService();
  late _MaintenanceItem _item;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  Future<void> _setStatus(String status, String label) async {
    setState(() => _submitting = true);
    try {
      final response = await _api
          .put('/maintenance/${_item.id}/status', {'status': status});
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _item = _MaintenanceItem(
            id: _item.id,
            title: _item.title,
            description: _item.description,
            status: (data['status'] ?? status).toString(),
            priority: _item.priority,
            category: _item.category,
            propertyName: _item.propertyName,
            unitNumber: _item.unitNumber,
            tenantName: _item.tenantName,
            tenantPhone: _item.tenantPhone,
            tenantEmail: _item.tenantEmail,
            createdAt: _item.createdAt,
            updatedAt: DateTime.tryParse(data['updated_at']?.toString() ?? '') ??
                DateTime.now(),
          );
          _submitting = false;
        });
        _showSnack(context, '$label.');
      } else {
        setState(() => _submitting = false);
        _showSnack(context,
            'Failed to update status (${response.statusCode}).');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSnack(context, 'Failed to update status: $e');
    }
  }

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    _showSnack(context, '$label copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _maintenanceStatusColor(_item.status);
    final statusLabel = _maintenanceStatusLabel(_item.status);
    final accent =
        widget.isEmergency ? AppColors.danger : AppColors.kodiOrange;
    final phone = _item.tenantPhone?.trim();
    final email = _item.tenantEmail?.trim();
    final tenantName = _item.tenantName.isEmpty ? 'Tenant' : _item.tenantName;

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pop(context, _item.status != widget.item.status);
      },
      child: _FeatureScaffold(
        title: widget.isEmergency ? 'Emergency' : 'Task',
        accentColor: accent,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _TappableCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          widget.isEmergency
                              ? Icons.warning_rounded
                              : Icons.handyman_rounded,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_item.title, style: AppStyles.heading2),
                            const SizedBox(height: 4),
                            Text(
                              _item.unitNumber.isEmpty
                                  ? _item.propertyName
                                  : '${_item.propertyName} • Unit ${_item.unitNumber}',
                              style: AppStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      StatusPill(label: statusLabel, color: statusColor),
                      _MaintenanceTag(
                        label: _capitalizeWord(_item.priority),
                        color: _maintenancePriorityColor(_item.priority),
                      ),
                      _MaintenanceTag(
                        label: _capitalizeWord(_item.category),
                        color: AppColors.kodiNavy,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _TappableCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Description', style: _titleStyle),
                  const SizedBox(height: 8),
                  Text(
                    _item.description.isEmpty
                        ? 'No description provided.'
                        : _item.description,
                    style: const TextStyle(
                        color: AppColors.textDark, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _TappableCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reported by', style: _titleStyle),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: accent.withValues(alpha: 0.12),
                        child: Text(
                          tenantName.isNotEmpty
                              ? tenantName.characters.first.toUpperCase()
                              : '?',
                          style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(tenantName,
                            style: const TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  if (phone != null && phone.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _ContactRow(
                      icon: Icons.call_outlined,
                      label: phone,
                      onTap: () => _copy('Phone number', phone),
                    ),
                  ],
                  if (email != null && email.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _ContactRow(
                      icon: Icons.mail_outline_rounded,
                      label: email,
                      onTap: () => _copy('Email', email),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _TappableCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Timeline', style: _titleStyle),
                  const SizedBox(height: 12),
                  _MaintenanceTimelineRow(
                    icon: Icons.report_problem_outlined,
                    color: AppColors.kodiBlue,
                    label: 'Reported',
                    time: _item.createdAt,
                  ),
                  if (_item.updatedAt != _item.createdAt)
                    _MaintenanceTimelineRow(
                      icon: _item.isResolved
                          ? Icons.check_circle_outline
                          : Icons.timelapse_outlined,
                      color: statusColor,
                      label: 'Last updated ($statusLabel)',
                      time: _item.updatedAt,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_item.isResolved)
              _TappableCard(
                child: Row(
                  children: const [
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.kodiGreen),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This has been marked completed. The tenant has been notified.',
                        style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              if (_item.status.toLowerCase() == 'pending')
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _submitting
                        ? null
                        : () => _setStatus('in_progress', 'Marked in progress'),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start working on this'),
                  ),
                ),
              if (_item.status.toLowerCase() == 'pending')
                const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _submitting
                      ? null
                      : () => _setStatus(
                            'completed',
                            widget.isEmergency
                                ? 'Emergency resolved'
                                : 'Task completed',
                          ),
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.white),
                        )
                      : Icon(widget.isEmergency
                          ? Icons.health_and_safety_outlined
                          : Icons.check_circle_outline_rounded),
                  label: Text(
                    widget.isEmergency
                        ? 'Mark Emergency Resolved'
                        : 'Mark Task Complete',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: AppColors.kodiBlue, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600)),
            ),
            const Icon(Icons.copy_rounded, color: AppColors.muted, size: 16),
          ],
        ),
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

  String _initials(String firstName, String lastName) {
    final f = firstName.trim();
    final l = lastName.trim();
    if (f.isEmpty && l.isEmpty) return '?';
    return ((f.isNotEmpty ? f[0] : '') + (l.isNotEmpty ? l[0] : ''))
        .toUpperCase();
  }

  Future<void> _confirmAndSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
            'You will need to sign in again to use KodiPay on this device.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!context.mounted) return;
    await context.read<AuthProvider>().logout();
  }

  Future<void> _openChangePasswordSheet(BuildContext context) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ChangePasswordSheet(accentColor: accentColor),
    );
  }

  Future<void> _openEditProfileSheet(BuildContext context) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditProfileSheet(accentColor: accentColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = user?.firstName ?? '';
    final lastName = user?.lastName ?? '';
    final fullName = '$firstName $lastName'.trim();
    final email = user?.email ?? '—';
    final phone = (user?.phone?.trim().isNotEmpty ?? false)
        ? user!.phone!.trim()
        : 'Not added';

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
                  child: Text(
                    _initials(firstName, lastName),
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.isEmpty ? role : fullName,
                        style: _titleStyle,
                      ),
                      const SizedBox(height: 4),
                      Text(email, style: AppStyles.caption),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _DetailSection(
            title: 'Account',
            rows: [
              _DetailRowData('Full name', fullName.isEmpty ? '—' : fullName),
              _DetailRowData('Email', email),
              _DetailRowData('Phone', phone),
              _DetailRowData('Role', role),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsTile(
            icon: Icons.edit_outlined,
            title: 'Edit profile',
            subtitle: 'Update your name, email, or phone number',
            onTap: () => _openEditProfileSheet(context),
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 4),
            child: Text('Security', style: _smallBoldStyle),
          ),
          _SettingsTile(
            icon: Icons.lock_reset_rounded,
            title: 'Change password',
            subtitle: 'Set a new password without signing out',
            onTap: () => _openChangePasswordSheet(context),
          ),
          _SettingsTile(
            icon: Icons.copy_all_outlined,
            title: 'Copy email',
            subtitle: email,
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: email));
              if (!context.mounted) return;
              _showSnack(context, 'Email copied to clipboard');
            },
          ),
          _SettingsTile(
            icon: Icons.logout_rounded,
            title: 'Sign out',
            subtitle: 'End your KodiPay session on this device',
            onTap: () => _confirmAndSignOut(context),
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
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'App preferences, alerts, and exports',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppPreferencesScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            title: 'Profile',
            subtitle: 'Landlord account and security',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(
                  role: 'Landlord',
                  accentColor: AppColors.kodiGreen,
                ),
              ),
            ),
          ),
          _SettingsTile(
            icon: Icons.engineering_outlined,
            title: 'Caretakers',
            subtitle: 'Add or remove caretakers for your properties',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CaretakersScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.gavel_outlined,
            title: 'Your Rights',
            subtitle: 'Landlord & tenant rights, plain English',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RightsScreen(role: 'landlord'),
              ),
            ),
          ),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Support',
            subtitle: 'Get help with payments or reports',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SupportScreen(
                  accentColor: AppColors.kodiGreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CaretakersScreen extends StatefulWidget {
  const CaretakersScreen({super.key});

  @override
  State<CaretakersScreen> createState() => _CaretakersScreenState();
}

class _CaretakersScreenState extends State<CaretakersScreen> {
  final ApiService _api = ApiService();
  Future<List<_CaretakerEntry>>? _future;

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

  Future<List<_CaretakerEntry>> _fetch() async {
    final response = await _api.get('/caretakers');
    if (response.statusCode != 200) {
      throw Exception('Could not load caretakers (${response.statusCode})');
    }
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => _CaretakerEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _onAdd() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddCaretakerSheet(),
    );
    if (added == true) _reload();
  }

  Future<void> _onRemove(_CaretakerEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: AppColors.danger, size: 44),
        title: const Text('Remove caretaker?'),
        content: Text(
          '${entry.fullName.isEmpty ? entry.email : entry.fullName} will lose access to your properties\' maintenance requests. Their KodiPay account stays active.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    try {
      final response = await _api.delete('/caretakers/${entry.assignmentId}');
      if (!mounted) return;
      if (response.statusCode == 200) {
        _showSnack(context, 'Caretaker removed.');
        _reload();
      } else {
        Map<String, dynamic>? data;
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}
        _showSnack(context,
            data?['error']?.toString() ??
                'Failed to remove caretaker (${response.statusCode}).');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(context, 'Failed to remove caretaker: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'Caretakers',
      accentColor: AppColors.kodiGreen,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.kodiGreen,
        onPressed: _onAdd,
        icon: const Icon(Icons.person_add_alt_1_rounded,
            color: AppColors.white),
        label: const Text('Add Caretaker',
            style: TextStyle(color: AppColors.white)),
      ),
      child: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<_CaretakerEntry>>(
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
            final items = snapshot.data ?? const <_CaretakerEntry>[];
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(30),
                children: const [
                  SizedBox(height: 60),
                  Icon(Icons.engineering_outlined,
                      size: 72, color: AppColors.muted),
                  SizedBox(height: 14),
                  Center(
                    child: Text(
                      'No caretakers yet',
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
                      'Tap "Add Caretaker" to invite one. They\'ll see maintenance requests across all your properties.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textLight),
                    ),
                  ),
                ],
              );
            }
            final groups = <String, List<_CaretakerEntry>>{};
            for (final e in items) {
              final key = e.propertyName.isEmpty
                  ? 'Unassigned'
                  : e.propertyName;
              groups.putIfAbsent(key, () => []).add(e);
            }
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                for (final entry in groups.entries) ...[
                  _PropertyGroupHeader(
                    name: entry.key,
                    count: entry.value.length,
                    accent: AppColors.kodiGreen,
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < entry.value.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    _CaretakerCard(
                      entry: entry.value[i],
                      onRemove: () => _onRemove(entry.value[i]),
                    ),
                  ],
                  const SizedBox(height: 18),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CaretakerEntry {
  final int assignmentId;
  final int caretakerId;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final int propertyId;
  final String propertyName;
  final String propertyAddress;

  const _CaretakerEntry({
    required this.assignmentId,
    required this.caretakerId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.propertyId,
    required this.propertyName,
    required this.propertyAddress,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory _CaretakerEntry.fromJson(Map<String, dynamic> json) {
    return _CaretakerEntry(
      assignmentId: _toInt(json['assignment_id']),
      caretakerId: _toInt(json['caretaker_id']),
      email: (json['email'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      phone: json['phone']?.toString(),
      propertyId: _toInt(json['property_id']),
      propertyName: (json['property_name'] ?? '').toString(),
      propertyAddress: (json['property_address'] ?? '').toString(),
    );
  }
}

class _CaretakerCard extends StatelessWidget {
  final _CaretakerEntry entry;
  final VoidCallback onRemove;
  const _CaretakerCard({required this.entry, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final name = entry.fullName.isEmpty ? entry.email : entry.fullName;
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    return _TappableCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CaretakerDetailScreen(
            entry: entry,
            onRemove: onRemove,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.kodiOrange.withValues(alpha: 0.12),
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.kodiOrange,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: _titleStyle),
                const SizedBox(height: 3),
                Text(entry.email, style: AppStyles.caption),
                if ((entry.phone?.trim().isNotEmpty ?? false)) ...[
                  const SizedBox(height: 2),
                  Text(entry.phone!, style: AppStyles.caption),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

class CaretakerDetailScreen extends StatelessWidget {
  final _CaretakerEntry entry;
  final VoidCallback onRemove;
  const CaretakerDetailScreen({
    super.key,
    required this.entry,
    required this.onRemove,
  });

  Future<void> _copy(BuildContext context, String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    _showSnack(context, '$label copied');
  }

  @override
  Widget build(BuildContext context) {
    final name = entry.fullName.isEmpty ? entry.email : entry.fullName;
    final initials = entry.fullName.isEmpty
        ? entry.email.characters.first.toUpperCase()
        : entry.fullName
            .split(' ')
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p[0])
            .join()
            .toUpperCase();
    final phone = entry.phone?.trim();
    return _FeatureScaffold(
      title: 'Caretaker',
      accentColor: AppColors.kodiOrange,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _TappableCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor:
                      AppColors.kodiOrange.withValues(alpha: 0.12),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.kodiOrange,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(name, style: AppStyles.heading2),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.kodiOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Caretaker',
                    style: TextStyle(
                      color: AppColors.kodiOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _DetailSection(
            title: 'Contact',
            rows: [
              _DetailRowData('Full name', name),
              _DetailRowData('Email', entry.email),
              _DetailRowData(
                  'Phone',
                  (phone?.isNotEmpty ?? false) ? phone! : 'Not added'),
            ],
          ),
          const SizedBox(height: 14),
          _DetailSection(
            title: 'Assigned property',
            rows: [
              _DetailRowData(
                  'Property',
                  entry.propertyName.isEmpty ? '—' : entry.propertyName),
              _DetailRowData(
                  'Address',
                  entry.propertyAddress.isEmpty
                      ? '—'
                      : entry.propertyAddress),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsTile(
            icon: Icons.copy_all_outlined,
            title: 'Copy email',
            subtitle: entry.email,
            onTap: () => _copy(context, 'Email', entry.email),
          ),
          if (phone != null && phone.isNotEmpty)
            _SettingsTile(
              icon: Icons.call_outlined,
              title: 'Copy phone',
              subtitle: phone,
              onTap: () => _copy(context, 'Phone', phone),
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onRemove();
              },
              icon: const Icon(Icons.person_remove_outlined),
              label: Text(
                  'Remove from ${entry.propertyName.isEmpty ? "this property" : entry.propertyName}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Removing only removes this caretaker from this property. Other property assignments stay intact.',
            style: AppStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _AddCaretakerSheet extends StatefulWidget {
  const _AddCaretakerSheet();

  @override
  State<_AddCaretakerSheet> createState() => _AddCaretakerSheetState();
}

class _AddCaretakerSheetState extends State<_AddCaretakerSheet> {
  final ApiService _api = ApiService();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _submitting = false;
  String? _tempPassword;

  List<PropertyData> _properties = const [];
  int? _propertyId;
  String? _selectedPropertyName;
  bool _loadingProperties = true;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    try {
      final response = await _api.get('/properties');
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _properties = data
              .map((item) =>
                  PropertyData.fromJson(item as Map<String, dynamic>))
              .where((p) => p.id != null)
              .toList();
          _loadingProperties = false;
          if (_properties.length == 1) {
            _propertyId = _properties.first.id;
            _selectedPropertyName = _properties.first.name;
          }
        });
      } else {
        setState(() => _loadingProperties = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingProperties = false);
    }
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();
    if (_propertyId == null) {
      _showSnack(context, 'Pick a property first.');
      return;
    }
    if (email.isEmpty) {
      _showSnack(context, 'Email is required.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final response = await _api.post('/caretakers', {
        'property_id': _propertyId,
        'email': email,
        if (firstName.isNotEmpty) 'first_name': firstName,
        if (lastName.isNotEmpty) 'last_name': lastName,
        if (phone.isNotEmpty) 'phone': phone,
      });
      if (!mounted) return;
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tempPassword = data['temp_password']?.toString();
        if (tempPassword != null && tempPassword.isNotEmpty) {
          setState(() {
            _tempPassword = tempPassword;
            _submitting = false;
          });
        } else {
          Navigator.pop(context, true);
          _showSnack(context, 'Caretaker added.');
        }
      } else {
        Map<String, dynamic>? data;
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}
        setState(() => _submitting = false);
        _showSnack(context,
            data?['error']?.toString() ??
                'Failed to add caretaker (${response.statusCode}).');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSnack(context, 'Failed to add caretaker: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tempPassword = _tempPassword;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tempPassword != null) ...[
              const Text('Caretaker invited', style: AppStyles.heading2),
              const SizedBox(height: 8),
              Text(
                'Share this temporary password with ${_emailController.text.trim()}. They should change it after first sign-in.',
                style: AppStyles.caption,
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.kodiGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.kodiGreen),
                ),
                child: Text(
                  tempPassword,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: tempPassword));
                        if (!mounted) return;
                        _showSnack(context, 'Password copied');
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Done'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.kodiGreen,
                        foregroundColor: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Text('Add Caretaker', style: AppStyles.heading2),
              const SizedBox(height: 6),
              Text(
                _selectedPropertyName == null
                    ? 'Pick the property this caretaker will handle, then enter their email. If they already have a KodiPay caretaker account we link them; otherwise we create one and give you a temporary password.'
                    : 'Assigning to "$_selectedPropertyName". You can repeat this for other properties.',
                style: AppStyles.caption,
              ),
              const SizedBox(height: 16),
              const Text('Property', style: AppStyles.caption),
              const SizedBox(height: 6),
              if (_loadingProperties)
                const LinearProgressIndicator()
              else if (_properties.isEmpty)
                const Text(
                  'You have no properties yet. Add one first, then come back here.',
                  style: AppStyles.caption,
                )
              else
                DropdownButtonFormField<int>(
                  value: _propertyId,
                  isExpanded: true,
                  items: [
                    for (final p in _properties)
                      if (p.id != null)
                        DropdownMenuItem<int>(
                          value: p.id,
                          child: Text(p.name),
                        ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _propertyId = value;
                      _selectedPropertyName = _properties
                          .firstWhere((p) => p.id == value)
                          .name;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Name fields are required only if no account exists for this email yet.',
                style: AppStyles.caption,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.white),
                        )
                      : const Icon(Icons.person_add_alt_1_rounded),
                  label: Text(_submitting ? 'Adding...' : 'Add caretaker'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kodiGreen,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RightsScreen extends StatelessWidget {
  final String role;
  const RightsScreen({super.key, required this.role});

  bool get _isLandlord => role.toLowerCase() == 'landlord';
  Color get _accent =>
      _isLandlord ? AppColors.kodiGreen : AppColors.kodiBlue;

  static const List<_RightsTopic> _topics = [
    _RightsTopic(
      icon: Icons.payments_outlined,
      title: 'Rent & rent increases',
      landlord: [
        'You set rent by agreement. If a tenant disputes it, the Tribunal can set a fair rent based on comparable lettings.',
        'You can raise rent only after at least 12 months since the previous increase (residential), and only after giving 90 days\' written notice.',
        'Permitted reasons include capital improvements, a new or extra service you provide, or inflation tracked to the Consumer Price Index.',
        'A rent increase that has not been notified in writing is void.',
      ],
      tenant: [
        'Rent is fixed by the agreement you signed. If you think it\'s unfair, you can ask the Tribunal to assess it.',
        'A rent increase needs 90 days\' written notice and cannot happen more than once every 12 months (residential).',
        'If your landlord stops providing a service that was part of the rent (e.g. water, security), you can ask for a proportional rent reduction.',
        'Any increase without proper written notice is not enforceable.',
      ],
      source: 'Rent Restriction Act ss.9–13 · Landlord & Tenant Bill 2021 ss.17–22',
    ),
    _RightsTopic(
      icon: Icons.exit_to_app_rounded,
      title: 'Eviction & notice to quit',
      landlord: [
        'You can only end a tenancy on specific grounds (e.g. unpaid rent, breach, you reasonably need the unit, repairs/demolition, or a fixed term ending).',
        'Notice must be in writing, state the reason, and give at least 2 months for residential premises (3 months for business).',
        'For "I need the unit for myself or family", you must act in good faith and give a minimum of 60 days.',
        'You may never lock out, harass, or evict a tenant without a Tribunal order — that is a criminal offence.',
      ],
      tenant: [
        'You can only be evicted on legal grounds (mostly unpaid rent, breach, or the landlord legitimately needing the premises).',
        'Eviction always requires a written termination notice of at least 2 months (residential) and, if you don\'t leave, a Tribunal order.',
        'A landlord who locks you out, removes your belongings, cuts services, or harasses you to leave commits an offence.',
        'You can give your landlord at least 1 month\'s written notice to end your own tenancy.',
      ],
      source: 'Rent Restriction Act ss.14–15 · Landlord & Tenant Bill 2021 ss.19, 24–29, 47',
    ),
    _RightsTopic(
      icon: Icons.handyman_outlined,
      title: 'Repairs & habitability',
      landlord: [
        'You are responsible for keeping the premises structurally sound, weather-proof, and fit for human habitation.',
        'You must repair roofs, main walls, drainage, main electrical wiring, and the common parts of the building.',
        'If you don\'t do a repair you are liable for, the Tribunal can order it done at your cost — including authorising the tenant to do it and deduct from rent.',
      ],
      tenant: [
        'Your landlord must keep the building structurally sound and fit to live in — including roof, walls, main wiring, plumbing, and common areas.',
        'You are responsible for normal internal upkeep — fair wear and tear is not your fault.',
        'If your landlord ignores a repair they owe you, you can apply to the Tribunal; the Tribunal can authorise you to do it and deduct the cost from your rent.',
      ],
      source: 'Rent Restriction Act s.26 · Landlord & Tenant Bill 2021 s.45 & Schedule',
    ),
    _RightsTopic(
      icon: Icons.money_off_outlined,
      title: 'Deposits, key money & receipts',
      landlord: [
        'You may not demand a "premium", "key money", or any extra payment as a condition of letting — only rent and lawful deposits.',
        'Charging key money is an offence punishable by up to 12 months\' imprisonment.',
        'If you intend to deduct from a security deposit (for damages or unpaid rent), you must give the tenant receipts for the expenses.',
        'You must keep a rent record and provide the tenant with a copy.',
      ],
      tenant: [
        'It is illegal for a landlord to ask for "key money", a premium, or any payment in addition to rent and a normal deposit.',
        'If you paid one already, you can recover it from your landlord through the Tribunal within 2 years.',
        'When your landlord deducts from your deposit, they must show you receipts for what they\'re charging you for.',
        'You\'re entitled to a rent record/rent book showing each payment.',
      ],
      source: 'Rent Restriction Act ss.17, 19, 21 · Landlord & Tenant Bill 2021 ss.40, 45',
    ),
    _RightsTopic(
      icon: Icons.swap_horiz_rounded,
      title: 'Subletting & assignment',
      landlord: [
        'A tenant cannot sublet or assign the tenancy without your written consent — but you cannot unreasonably refuse.',
        'If you refuse unreasonably and the tenant goes to the Tribunal, the Tribunal can grant the assignment over your refusal.',
        'If you discover an unauthorised sublet, it is a ground to terminate the tenancy.',
      ],
      tenant: [
        'You need the landlord\'s written consent before subletting or assigning your tenancy — but the landlord cannot refuse unreasonably.',
        'If consent is unreasonably refused, you can apply to the Tribunal to allow the sublet or assignment.',
        'Subletting without consent is a ground for the landlord to terminate your tenancy.',
      ],
      source: 'Rent Restriction Act ss.27–28 · Landlord & Tenant Bill 2021 ss.30–32',
    ),
    _RightsTopic(
      icon: Icons.power_settings_new_rounded,
      title: 'Services & lockouts',
      landlord: [
        'You cannot cut off water, light, sanitation, or any other service to force a tenant to leave or pay — even if they are in arrears.',
        'Doing so is an offence with a fine of up to KSh 10,000 or up to 6 months\' imprisonment.',
        'Distress (seizing property) for unpaid rent requires legal process — you cannot do it on your own.',
      ],
      tenant: [
        'Your landlord cannot disconnect your water, electricity, drainage, or any service to pressure you to leave or pay rent.',
        'If they do, that\'s an offence. You can report it and the Tribunal can order the service restored.',
        'A landlord cannot seize your property for unpaid rent without going through legal process.',
      ],
      source: 'Rent Restriction Act ss.16, 23, 29 · Landlord & Tenant Bill 2021 ss.42, 48, 57',
    ),
    _RightsTopic(
      icon: Icons.balance_outlined,
      title: 'Disputes & where to go',
      landlord: [
        'Rent, eviction, repair, deposit, and service disputes are handled by the Landlord and Tenant Tribunal (which replaces the older Rent Tribunal).',
        'You must obey Tribunal orders. Ignoring one is an offence.',
        'You can appeal a Tribunal decision to the Environment and Land Court only on points of law.',
      ],
      tenant: [
        'You can take any rent, eviction, repair, deposit, or service complaint to the Landlord and Tenant Tribunal.',
        'Filing fees are small. The Tribunal aims to decide within 3 months.',
        'If you disagree with the Tribunal\'s decision on a point of law, you can appeal to the Environment and Land Court.',
      ],
      source: 'Rent Restriction Act ss.4–8 · Landlord & Tenant Bill 2021 ss.4–7',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'Your Rights',
      accentColor: _accent,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _TappableCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.gavel_outlined, color: _accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isLandlord
                            ? 'What landlords need to know'
                            : 'What tenants need to know',
                        style: _titleStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Plain-English summary of the Rent Restriction Act (Cap. 296) and the Landlord and Tenant Bill 2021. This is for orientation only — it is not legal advice.',
                  style: AppStyles.caption,
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => launchUrl(
                    Uri.parse('https://www.kenyalaw.org'),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.open_in_new_rounded,
                          color: AppColors.kodiBlue, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Read the official text on kenyalaw.org',
                        style: TextStyle(
                          color: AppColors.kodiBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final topic in _topics) ...[
            _RightsTopicCard(
              topic: topic,
              accent: _accent,
              isLandlord: _isLandlord,
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 6),
          Text(
            'This summary may not reflect the latest amendments. When in doubt, refer to the published Act on kenyalaw.org or consult a lawyer.',
            style: AppStyles.caption.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _RightsTopic {
  final IconData icon;
  final String title;
  final List<String> landlord;
  final List<String> tenant;
  final String source;
  const _RightsTopic({
    required this.icon,
    required this.title,
    required this.landlord,
    required this.tenant,
    required this.source,
  });
}

class _RightsTopicCard extends StatelessWidget {
  final _RightsTopic topic;
  final Color accent;
  final bool isLandlord;
  const _RightsTopicCard({
    required this.topic,
    required this.accent,
    required this.isLandlord,
  });

  @override
  Widget build(BuildContext context) {
    final bullets = isLandlord ? topic.landlord : topic.tenant;
    return _TappableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(topic.icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(topic.title, style: _titleStyle),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bullet,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(
            topic.source,
            style: AppStyles.caption.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class SupportScreen extends StatefulWidget {
  final Color accentColor;
  const SupportScreen({super.key, this.accentColor = AppColors.kodiBlue});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  static const String _supportEmail = 'support@kodipay.co.ke';
  static const String _supportPhone = '+254 700 123 456';
  static const String _supportWhatsAppDigits = '254700123456';

  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _category = 'Payments';

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _launch(Uri uri, {String fallbackCopy = ''}) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ok) return;
    } catch (_) {
      // fallthrough to clipboard
    }
    if (!mounted) return;
    if (fallbackCopy.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: fallbackCopy));
      if (!mounted) return;
      _showSnack(context, 'Could not open app — copied "$fallbackCopy" instead.');
    } else {
      _showSnack(context, 'Could not open the requested app.');
    }
  }

  Future<void> _openEmail({String? subject, String? body}) async {
    final query = <String, String>{};
    if (subject != null && subject.isNotEmpty) query['subject'] = subject;
    if (body != null && body.isNotEmpty) query['body'] = body;
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: query.isEmpty
          ? null
          : query.entries
              .map((e) =>
                  '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
              .join('&'),
    );
    await _launch(uri, fallbackCopy: _supportEmail);
  }

  Future<void> _openDialer() async {
    final uri = Uri(scheme: 'tel', path: _supportPhone.replaceAll(' ', ''));
    await _launch(uri, fallbackCopy: _supportPhone);
  }

  Future<void> _openWhatsApp({String? text}) async {
    final base = 'https://wa.me/$_supportWhatsAppDigits';
    final uri = (text == null || text.isEmpty)
        ? Uri.parse(base)
        : Uri.parse('$base?text=${Uri.encodeQueryComponent(text)}');
    await _launch(uri, fallbackCopy: '+$_supportWhatsAppDigits');
  }

  Future<void> _sendMessage() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      _showSnack(context, 'Please add a subject and a message.');
      return;
    }
    await _openEmail(
      subject: '[$_category] $subject',
      body: 'Category: $_category\n\n$message',
    );
  }

  Future<void> _sendOnWhatsApp() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      _showSnack(context, 'Please add a subject and a message.');
      return;
    }
    await _openWhatsApp(
      text: 'KodiPay support — $_category\n$subject\n\n$message',
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'Support',
      accentColor: widget.accentColor,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _TappableCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          widget.accentColor.withValues(alpha: 0.12),
                      child: Icon(Icons.support_agent_rounded,
                          color: widget.accentColor),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text("We're here to help", style: _titleStyle),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Reach out about payments, reports, account access, or anything else. We typically respond within a few hours on business days.',
                  style: AppStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 4),
            child: Text('Contact KodiPay', style: _smallBoldStyle),
          ),
          _SettingsTile(
            icon: Icons.email_outlined,
            title: 'Email support',
            subtitle: _supportEmail,
            onTap: () => _openEmail(),
          ),
          _SettingsTile(
            icon: Icons.call_outlined,
            title: 'Call us',
            subtitle: _supportPhone,
            onTap: _openDialer,
          ),
          _SettingsTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'WhatsApp',
            subtitle: '+$_supportWhatsAppDigits',
            onTap: () => _openWhatsApp(),
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 4),
            child: Text('Send us a message', style: _smallBoldStyle),
          ),
          _TappableCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('What do you need help with?',
                    style: AppStyles.caption),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _category,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                        value: 'Payments',
                        child: Text('Payments (M-Pesa, invoices)')),
                    DropdownMenuItem(
                        value: 'Reports',
                        child: Text('Reports (PDF, CSV, charts)')),
                    DropdownMenuItem(
                        value: 'Account', child: Text('Account & security')),
                    DropdownMenuItem(
                        value: 'Other', child: Text('Something else')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _messageController,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Describe the issue',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.email_outlined),
                          label: const Text('Email'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.accentColor,
                            foregroundColor: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _sendOnWhatsApp,
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: const Text('WhatsApp'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF25D366),
                            side: const BorderSide(color: Color(0xFF25D366)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Opens your email app or WhatsApp with the message prefilled. If neither opens, the address is copied to your clipboard.',
                  style: AppStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 4),
            child: Text('Quick answers', style: _smallBoldStyle),
          ),
          _TappableCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _HelpRow(
                  icon: Icons.payments_outlined,
                  title: 'Payment not showing up?',
                  body:
                      'Confirm the tenant used the correct M-Pesa till and reference. Most receipts post within 2–3 minutes.',
                ),
                SizedBox(height: 12),
                _HelpRow(
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'Report missing data?',
                  body:
                      'Make sure the date range covers the invoices, then re-download the PDF or CSV from Reports.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _HelpRow({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.kodiBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _titleStyle),
              const SizedBox(height: 3),
              Text(body, style: AppStyles.caption),
            ],
          ),
        ),
      ],
    );
  }
}

class LandlordNotificationsScreen extends StatefulWidget {
  const LandlordNotificationsScreen({super.key});

  @override
  State<LandlordNotificationsScreen> createState() =>
      _LandlordNotificationsScreenState();
}

class _LandlordNotificationsScreenState
    extends State<LandlordNotificationsScreen> {
  final ApiService _api = ApiService();
  Future<List<_NotificationItem>>? _future;
  bool _markingAll = false;
  bool _changed = false;

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

  Future<List<_NotificationItem>> _fetch() async {
    final response = await _api.get('/notifications');
    if (response.statusCode != 200) {
      throw Exception('Could not load notifications (${response.statusCode})');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => _NotificationItem.fromJson(item as Map<String, dynamic>))
        .where((item) => !item.isRead)
        .toList();
  }

  Future<void> _markOne(int id) async {
    try {
      await _api.put('/notifications/$id/read');
      _changed = true;
      _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not mark as read')),
      );
    }
  }

  Future<void> _markAll() async {
    setState(() => _markingAll = true);
    try {
      await _api.put('/notifications/read-all');
      _changed = true;
      if (!mounted) return;
      _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not mark all as read')),
      );
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pop(context, _changed);
      },
      child: _FeatureScaffold(
        title: 'Notifications',
        accentColor: AppColors.kodiBlue,
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: FutureBuilder<List<_NotificationItem>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.all(40),
                  children: [
                    const SizedBox(height: 60),
                    const Icon(Icons.error_outline_rounded,
                        size: 56, color: AppColors.danger),
                    const SizedBox(height: 14),
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
              final items = snapshot.data ?? const <_NotificationItem>[];
              if (items.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(40),
                  children: [
                    const SizedBox(height: 80),
                    const Icon(Icons.notifications_none_rounded,
                        size: 72, color: AppColors.muted),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'You\'re all caught up',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'New activity will show up here.',
                        style: TextStyle(color: AppColors.textLight),
                      ),
                    ),
                  ],
                );
              }
              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  for (final item in items) _NotificationApiCard(
                    item: item,
                    onMarkRead: () => _markOne(item.id),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _markingAll ? null : _markAll,
                    icon: _markingAll
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.done_all_rounded),
                    label: Text(_markingAll
                        ? 'Marking...'
                        : 'Mark All as Read (${items.length})'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationItem {
  final int id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const _NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory _NotificationItem.fromJson(Map<String, dynamic> json) {
    return _NotificationItem(
      id: json['id'] as int,
      type: (json['type'] ?? 'system').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      isRead: json['is_read'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class _NotificationApiCard extends StatelessWidget {
  final _NotificationItem item;
  final VoidCallback onMarkRead;

  const _NotificationApiCard({required this.item, required this.onMarkRead});

  @override
  Widget build(BuildContext context) {
    final palette = _paletteForType(item.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: palette.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(palette.icon, color: palette.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                if (item.message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(item.message, style: AppStyles.bodyMedium),
                ],
                const SizedBox(height: 6),
                Text(
                  _relativeTime(item.createdAt),
                  style: AppStyles.caption,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Mark as read',
            onPressed: onMarkRead,
            icon: const Icon(Icons.check_circle_outline_rounded,
                color: AppColors.kodiGreen),
          ),
        ],
      ),
    );
  }
}

class _NotificationPalette {
  final Color color;
  final IconData icon;
  const _NotificationPalette(this.color, this.icon);
}

_NotificationPalette _paletteForType(String type) {
  switch (type.toLowerCase()) {
    case 'reminder':
    case 'rent_reminder':
      return const _NotificationPalette(AppColors.kodiBlue, Icons.sms_outlined);
    case 'maintenance':
      return const _NotificationPalette(
          AppColors.kodiOrange, Icons.build_outlined);
    case 'payment':
    case 'mpesa':
      return const _NotificationPalette(
          AppColors.kodiGreen, Icons.verified_outlined);
    case 'alert':
    case 'warning':
      return const _NotificationPalette(
          AppColors.danger, Icons.warning_amber_rounded);
    default:
      return const _NotificationPalette(
          AppColors.kodiNavy, Icons.notifications_active_outlined);
  }
}

String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${time.day}/${time.month}/${time.year}';
}

class AppPreferencesScreen extends StatefulWidget {
  const AppPreferencesScreen({super.key});

  @override
  State<AppPreferencesScreen> createState() => _AppPreferencesScreenState();
}

class _AppPreferencesScreenState extends State<AppPreferencesScreen> {
  bool _rentReminders = true;
  bool _maintenanceAlerts = true;
  bool _systemAlerts = true;
  bool _monthlyReports = true;
  String _defaultExport = 'PDF';
  String _currency = 'KES';

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'App Preferences',
      accentColor: AppColors.kodiNavy,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _PreferenceSwitch(
            title: 'Rent reminders',
            subtitle: 'Notify when rent is due or overdue',
            value: _rentReminders,
            onChanged: (value) => setState(() => _rentReminders = value),
          ),
          _PreferenceSwitch(
            title: 'Maintenance alerts',
            subtitle: 'Notify when tenants report or update issues',
            value: _maintenanceAlerts,
            onChanged: (value) => setState(() => _maintenanceAlerts = value),
          ),
          _PreferenceSwitch(
            title: 'System alerts',
            subtitle: 'Payment callbacks, exports, and account notices',
            value: _systemAlerts,
            onChanged: (value) => setState(() => _systemAlerts = value),
          ),
          _PreferenceSwitch(
            title: 'Monthly report summary',
            subtitle: 'Send income and arrears summary every month',
            value: _monthlyReports,
            onChanged: (value) => setState(() => _monthlyReports = value),
          ),
          const SizedBox(height: 12),
          _TappableCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Report Defaults', style: _titleStyle),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _defaultExport,
                  decoration: const InputDecoration(labelText: 'Export Format'),
                  items: const [
                    DropdownMenuItem(value: 'PDF', child: Text('PDF')),
                    DropdownMenuItem(value: 'CSV', child: Text('CSV')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _defaultExport = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: const InputDecoration(labelText: 'Currency'),
                  items: const [
                    DropdownMenuItem(value: 'KES', child: Text('KES')),
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _currency = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _showSnack(context, 'Preferences saved.'),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Preferences'),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool?> showPropertySheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _AddPropertySheet(),
  );
}

class _AddPropertySheet extends StatefulWidget {
  const _AddPropertySheet();

  @override
  State<_AddPropertySheet> createState() => _AddPropertySheetState();
}

class _AddPropertySheetState extends State<_AddPropertySheet> {
  final ApiService _api = ApiService();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _description = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _address.text.trim().isEmpty) {
      setState(() => _error = 'Name and address are required');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final response = await _api.post('/properties', {
        'name': _name.text.trim(),
        'address': _address.text.trim(),
        if (_description.text.trim().isNotEmpty)
          'description': _description.text.trim(),
      });
      if (response.statusCode >= 400) {
        setState(() {
          _submitting = false;
          _error = _decodeError(response.body);
        });
        return;
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Failed to save property: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Property', style: AppStyles.heading2),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Property name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Address / Location'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              maxLines: 2,
              decoration:
                  const InputDecoration(labelText: 'Description (optional)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white),
                      )
                    : const Text('Save Property'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _decodeError(String body) {
  try {
    final data = jsonDecode(body);
    if (data is Map && data['error'] is String) return data['error'] as String;
    if (data is Map && data['errors'] is List) {
      final list = data['errors'] as List;
      if (list.isNotEmpty && list.first is Map) {
        final first = list.first as Map;
        return (first['msg'] ?? 'Validation failed').toString();
      }
    }
  } catch (_) {}
  return 'Request failed';
}

Future<bool?> showTenantSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _AddTenantSheet(),
  );
}

class _AddTenantSheet extends StatefulWidget {
  const _AddTenantSheet();

  @override
  State<_AddTenantSheet> createState() => _AddTenantSheetState();
}

class _AddTenantSheetState extends State<_AddTenantSheet> {
  final ApiService _api = ApiService();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();

  Future<List<PropertyData>>? _propertiesFuture;
  PropertyData? _selectedProperty;
  List<_VacantUnit> _vacantUnits = const [];
  bool _loadingUnits = false;
  _VacantUnit? _selectedUnit;
  DateTime _startDate = DateTime.now();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _propertiesFuture = _loadProperties();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<List<PropertyData>> _loadProperties() async {
    final response = await _api.get('/properties');
    if (response.statusCode != 200) {
      throw Exception('Could not load properties (${response.statusCode})');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => PropertyData.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _loadUnitsFor(int propertyId) async {
    setState(() {
      _loadingUnits = true;
      _vacantUnits = const [];
      _selectedUnit = null;
    });
    try {
      final response = await _api.get('/units/property/$propertyId');
      if (response.statusCode != 200) {
        throw Exception('Could not load units');
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      final vacant = data
          .map((item) => _VacantUnit.fromJson(item as Map<String, dynamic>))
          .where((u) => u.status == 'vacant')
          .toList();
      if (!mounted) return;
      setState(() {
        _vacantUnits = vacant;
        _loadingUnits = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingUnits = false;
        _error = 'Failed to load units: $e';
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedProperty == null) {
      setState(() => _error = 'Pick a property');
      return;
    }
    if (_selectedUnit == null) {
      setState(() => _error = 'Pick a vacant unit');
      return;
    }
    if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty) {
      setState(() => _error = 'Tenant name is required');
      return;
    }
    if (_email.text.trim().isEmpty || !_email.text.contains('@')) {
      setState(() => _error = 'A valid email is required');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final response = await _api.post('/tenancies/with-new-tenant', {
        'unit_id': _selectedUnit!.id,
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'email': _email.text.trim(),
        if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
        'start_date': _startDate.toIso8601String().split('T').first,
      });

      if (response.statusCode >= 400) {
        setState(() {
          _submitting = false;
          _error = _decodeError(response.body);
        });
        return;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final tempPassword = body['temp_password'] as String?;
      if (!mounted) return;
      Navigator.pop(context, true);

      if (tempPassword != null) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Tenant added'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_firstName.text.trim()} ${_lastName.text.trim()} can now log in with:',
                ),
                const SizedBox(height: 12),
                _PasswordBox(password: tempPassword),
                const SizedBox(height: 12),
                const Text(
                  'Share this with the tenant. They can change it via "Forgot password" on the login screen.',
                  style: TextStyle(color: AppColors.textLight, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Failed to add tenant: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Tenant',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.textDark)),
            const SizedBox(height: 16),
            FutureBuilder<List<PropertyData>>(
              future: _propertiesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Text(snapshot.error.toString(),
                      style: const TextStyle(color: AppColors.danger));
                }
                final properties = snapshot.data ?? const <PropertyData>[];
                if (properties.isEmpty) {
                  return const Text(
                    'No properties yet. Add a property first.',
                    style: TextStyle(color: AppColors.textLight),
                  );
                }
                return DropdownButtonFormField<PropertyData>(
                  value: _selectedProperty,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Property'),
                  items: properties
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedProperty = value);
                    if (value?.id != null) _loadUnitsFor(value!.id!);
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            if (_loadingUnits)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              )
            else if (_selectedProperty != null && _vacantUnits.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No vacant units in this property. Add a unit first.',
                  style: TextStyle(color: AppColors.textLight),
                ),
              )
            else if (_vacantUnits.isNotEmpty)
              DropdownButtonFormField<_VacantUnit>(
                value: _selectedUnit,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Vacant unit'),
                items: _vacantUnits
                    .map((u) => DropdownMenuItem(
                          value: u,
                          child: Text(
                            'Unit ${u.unitNumber} • KSh ${_formatKsh(u.rentAmount)}/mo',
                          ),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedUnit = value),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _firstName,
              decoration: const InputDecoration(labelText: 'First name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastName,
              decoration: const InputDecoration(labelText: 'Last name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone (optional)'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Start date'),
                child: Text(
                  '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                  style: const TextStyle(color: AppColors.textDark),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white),
                      )
                    : const Text('Save Tenant'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VacantUnit {
  final int id;
  final String unitNumber;
  final num rentAmount;
  final String status;

  const _VacantUnit({
    required this.id,
    required this.unitNumber,
    required this.rentAmount,
    required this.status,
  });

  factory _VacantUnit.fromJson(Map<String, dynamic> json) {
    final rent = json['rent_amount'];
    return _VacantUnit(
      id: json['id'] as int,
      unitNumber: (json['unit_number'] ?? '').toString(),
      rentAmount: rent is num
          ? rent
          : num.tryParse(rent?.toString() ?? '') ?? 0,
      status: (json['status'] ?? 'vacant').toString(),
    );
  }
}

class _PasswordBox extends StatelessWidget {
  final String password;
  const _PasswordBox({required this.password});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              password,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.textDark,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: password));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
          ),
        ],
      ),
    );
  }
}

Future<bool?> showIssueSheet(BuildContext context, {required int unitId}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ReportIssueSheet(unitId: unitId),
  );
}

class _ReportIssueSheet extends StatefulWidget {
  final int unitId;
  const _ReportIssueSheet({required this.unitId});

  @override
  State<_ReportIssueSheet> createState() => _ReportIssueSheetState();
}

class _ReportIssueSheetState extends State<_ReportIssueSheet> {
  final ApiService _api = ApiService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customPriorityController = TextEditingController();

  String _category = 'plumbing';
  String _urgency = 'urgent';
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customPriorityController.dispose();
    super.dispose();
  }

  String _categoryHint(String value) {
    switch (value) {
      case 'electrical':
        return 'Sockets, wiring, lighting circuits';
      case 'structural':
        return 'Walls, doors, windows, floors';
      case 'plumbing':
        return 'Taps, pipes, drainage, water leaks';
      default:
        return 'Anything that doesn\'t fit the other categories';
    }
  }

  String _urgencyHint(String value) {
    switch (value) {
      case 'emergency':
        return 'Fire, flood, electrical failure, gas leak';
      case 'urgent':
        return 'Lighting replacement, minor plumbing leak';
      default:
        return 'Describe how urgent this is in your own words';
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add a title and a description.')),
      );
      return;
    }
    String priorityToSend = _urgency;
    String descriptionToSend = description;
    if (_urgency == 'other') {
      final custom = _customPriorityController.text.trim();
      if (custom.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Describe the urgency in the "Other" field, or pick Emergency / Urgent.')),
        );
        return;
      }
      priorityToSend = 'medium';
      descriptionToSend = 'Urgency note: $custom\n\n$description';
    }

    setState(() => _submitting = true);
    try {
      final response = await _api.post('/maintenance', {
        'unit_id': widget.unitId,
        'title': title,
        'description': descriptionToSend,
        'category': _category,
        'priority': priorityToSend,
      });
      if (!mounted) return;
      if (response.statusCode == 201) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Issue reported.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to report issue (${response.statusCode}).')),
        );
        setState(() => _submitting = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to report issue: $e')),
      );
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Report Maintenance Issue', style: AppStyles.heading2),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title (e.g. Leaking sink)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Category', style: AppStyles.caption),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _category,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                    value: 'electrical', child: Text('Electrical')),
                DropdownMenuItem(
                    value: 'structural',
                    child: Text('Structural (walls, doors, windows)')),
                DropdownMenuItem(
                    value: 'plumbing', child: Text('Plumbing')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 4),
            Text(_categoryHint(_category), style: AppStyles.caption),
            const SizedBox(height: 14),
            const Text('Urgency', style: AppStyles.caption),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _urgency,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                    value: 'emergency',
                    child: Text('Emergency (fire, flood, electrical failure)')),
                DropdownMenuItem(
                    value: 'urgent',
                    child: Text(
                        'Urgent (lighting replacement, minor leak)')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _urgency = value);
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 4),
            Text(_urgencyHint(_urgency), style: AppStyles.caption),
            if (_urgency == 'other') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customPriorityController,
                decoration: const InputDecoration(
                  labelText: 'Describe the urgency',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _descriptionController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Describe the issue',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_submitting ? 'Submitting...' : 'Submit Issue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kodiBlue,
                  foregroundColor: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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

Future<bool?> showAnnouncementSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => const _AnnouncementSheet(),
  );
}

class _EditProfileSheet extends StatefulWidget {
  final Color accentColor;
  const _EditProfileSheet({required this.accentColor});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _firstNameController.text = user?.firstName ?? '';
    _lastNameController.text = user?.lastName ?? '';
    _emailController.text = user?.email ?? '';
    _phoneController.text = user?.phone ?? '';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty) {
      _showSnack(context, 'First name, last name, and email are required.');
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showSnack(context, 'Enter a valid email address.');
      return;
    }

    setState(() => _submitting = true);
    final success = await context.read<AuthProvider>().updateProfile(
          firstName: firstName,
          lastName: lastName,
          email: email,
          phone: phone,
        );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.pop(context, true);
      _showSnack(context, 'Profile updated.');
    } else {
      _showSnack(context, 'Failed to update profile.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit profile', style: AppStyles.heading2),
            const SizedBox(height: 6),
            const Text(
              'Update your name, email, or phone number.',
              style: AppStyles.caption,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_submitting ? 'Saving...' : 'Save changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kodiGreen,
                  foregroundColor: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  final Color accentColor;
  const _ChangePasswordSheet({required this.accentColor});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final ApiService _api = ApiService();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _submitting = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentController.text;
    final next = _newController.text;
    final confirm = _confirmController.text;
    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      _showSnack(context, 'Fill in all three fields.');
      return;
    }
    if (next.length < 6) {
      _showSnack(context, 'New password must be at least 6 characters.');
      return;
    }
    if (next != confirm) {
      _showSnack(context, 'New password and confirmation do not match.');
      return;
    }
    if (next == current) {
      _showSnack(context, 'New password must be different from the current one.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final response = await _api.post('/auth/change-password', {
        'current_password': current,
        'new_password': next,
      });
      if (!mounted) return;
      if (response.statusCode == 200) {
        Navigator.pop(context, true);
        _showSnack(context, 'Password updated.');
        return;
      }
      Map<String, dynamic>? data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}
      setState(() => _submitting = false);
      _showSnack(
        context,
        data?['error']?.toString() ??
            'Failed to change password (${response.statusCode}).',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSnack(context, 'Failed to change password: $e');
    }
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Change password', style: AppStyles.heading2),
            const SizedBox(height: 6),
            const Text(
              'Set a new password using your current one. You will stay signed in.',
              style: AppStyles.caption,
            ),
            const SizedBox(height: 16),
            _passwordField(
              label: 'Current password',
              controller: _currentController,
              obscure: !_showCurrent,
              onToggle: () => setState(() => _showCurrent = !_showCurrent),
            ),
            const SizedBox(height: 12),
            _passwordField(
              label: 'New password',
              controller: _newController,
              obscure: !_showNew,
              onToggle: () => setState(() => _showNew = !_showNew),
            ),
            const SizedBox(height: 12),
            _passwordField(
              label: 'Confirm new password',
              controller: _confirmController,
              obscure: !_showConfirm,
              onToggle: () => setState(() => _showConfirm = !_showConfirm),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white),
                      )
                    : const Icon(Icons.lock_reset_rounded),
                label: Text(_submitting ? 'Updating...' : 'Update password'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  foregroundColor: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementSheet extends StatefulWidget {
  const _AnnouncementSheet();

  @override
  State<_AnnouncementSheet> createState() => _AnnouncementSheetState();
}

class _AnnouncementSheetState extends State<_AnnouncementSheet> {
  final ApiService _api = ApiService();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  List<PropertyData> _properties = const [];
  int? _propertyId;
  bool _loadingProperties = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    try {
      final response = await _api.get('/properties');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        if (!mounted) return;
        setState(() {
          _properties = data
              .map((item) =>
                  PropertyData.fromJson(item as Map<String, dynamic>))
              .toList();
          _loadingProperties = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _loadingProperties = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingProperties = false);
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a title and a message.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final body = <String, dynamic>{'title': title, 'message': message};
      if (_propertyId != null) body['property_id'] = _propertyId;
      final response = await _api.post('/notifications/announcement', body);
      if (!mounted) return;
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final recipients = data['recipients'] ?? 0;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Announcement sent to $recipients tenant(s).')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to send announcement (${response.statusCode})')),
        );
        setState(() => _submitting = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send announcement: $e')),
      );
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Post Announcement', style: AppStyles.heading2),
            const SizedBox(height: 6),
            const Text(
              'Every active tenant of the chosen property — or all of your tenants — will see this in their Notices.',
              style: AppStyles.caption,
            ),
            const SizedBox(height: 16),
            const Text('Audience', style: AppStyles.caption),
            const SizedBox(height: 6),
            if (_loadingProperties)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<int?>(
                value: _propertyId,
                isExpanded: true,
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All my tenants'),
                  ),
                  for (final property in _properties)
                    if (property.id != null)
                      DropdownMenuItem<int?>(
                        value: property.id,
                        child: Text(property.name),
                      ),
                ],
                onChanged: (value) => setState(() => _propertyId = value),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white),
                      )
                    : const Icon(Icons.campaign_outlined),
                label: Text(_submitting ? 'Sending...' : 'Send Announcement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kodiGreen,
                  foregroundColor: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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

class _DetailSection extends StatelessWidget {
  final String title;
  final List<_DetailRowData> rows;

  const _DetailSection({
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return _TappableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _titleStyle),
          const SizedBox(height: 12),
          ...rows.map((row) => _DetailRow(row: row)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final _DetailRowData row;

  const _DetailRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(row.label, style: AppStyles.caption)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              row.value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return _TappableCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Icon(icon, color: AppColors.muted, size: 34),
            const SizedBox(height: 10),
            Text(title, style: _titleStyle),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: AppStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _ReportDocumentCard extends StatelessWidget {
  final Widget child;

  const _ReportDocumentCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.kodiNavy.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PaymentReportHeader extends StatelessWidget {
  final String generatedDate;
  final String period;

  const _PaymentReportHeader({
    required this.generatedDate,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const KodiPayLogo(iconSize: 38, fontSize: 18),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'KodiPay',
              style: TextStyle(
                color: AppColors.kodiNavy,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 3),
            Text('Pay Rent. Stay Worry-Free.', style: AppStyles.caption),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Payment Report',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text('Generated: $generatedDate', style: AppStyles.caption),
            Text('Period: $period', style: AppStyles.caption),
          ],
        ),
      ],
    );
  }
}

class _LandlordReportInfo extends StatelessWidget {
  const _LandlordReportInfo();

  @override
  Widget build(BuildContext context) {
    return const _ReportBlock(
      title: 'Landlord Information',
      child: Column(
        children: [
          _ReportInfoRow(label: 'Landlord Name', value: 'James Mwangi'),
          _ReportInfoRow(label: 'Email / Phone', value: 'james@kodipay.co.ke / 0700 000 111'),
          _ReportInfoRow(label: 'Property Count', value: '3 properties'),
        ],
      ),
    );
  }
}

class _PaymentReportSummary extends StatelessWidget {
  final int totalExpected;
  final int totalCollected;
  final int totalPending;
  final int collectionRate;

  const _PaymentReportSummary({
    required this.totalExpected,
    required this.totalCollected,
    required this.totalPending,
    required this.collectionRate,
  });

  @override
  Widget build(BuildContext context) {
    return _ReportBlock(
      title: 'Summary',
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.15,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        children: [
          _ReportSummaryCard(
            label: 'Total Expected',
            value: _money(totalExpected),
            color: AppColors.kodiBlue,
          ),
          _ReportSummaryCard(
            label: 'Collected',
            value: _money(totalCollected),
            color: AppColors.kodiGreen,
          ),
          _ReportSummaryCard(
            label: 'Pending',
            value: _money(totalPending),
            color: AppColors.danger,
          ),
          _ReportSummaryCard(
            label: 'Collection Rate',
            value: '$collectionRate%',
            color: AppColors.kodiOrange,
          ),
        ],
      ),
    );
  }
}

class _PropertyBreakdownTable extends StatelessWidget {
  final List<_PropertyPaymentBreakdown> rows;

  const _PropertyBreakdownTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return _ReportBlock(
      title: 'Property Breakdown',
      child: Column(
        children: [
          const _ReportTableHeader(
            columns: ['Property', 'Units', 'Collected', 'Pending'],
          ),
          ...rows.map(
            (row) => _ReportTableRow(
              cells: [
                row.propertyName,
                row.units.toString(),
                _money(row.collected),
                _money(row.pending),
              ],
              statusColor: row.pending > 0 ? AppColors.danger : AppColors.kodiGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailedPaymentTable extends StatelessWidget {
  final List<PaymentRecord> payments;

  const _DetailedPaymentTable({required this.payments});

  @override
  Widget build(BuildContext context) {
    return _ReportBlock(
      title: 'Detailed Payment Table',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 760,
          child: Column(
            children: [
              const _ReportTableHeader(
                columns: ['Tenant', 'Unit', 'Property', 'Amount', 'Status', 'Date'],
              ),
              ...payments.map(
                (payment) => _ReportTableRow(
                  cells: [
                    payment.tenantName,
                    payment.unit,
                    payment.property,
                    _money(payment.amount),
                    payment.status,
                    payment.paidAt ?? '-',
                  ],
                  statusColor: _paymentStatusColor(payment.status),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArrearsTable extends StatelessWidget {
  final List<PaymentRecord> payments;

  const _ArrearsTable({required this.payments});

  @override
  Widget build(BuildContext context) {
    return _ReportBlock(
      title: 'Arrears Section',
      child: Column(
        children: [
          const _ReportTableHeader(
            columns: ['Tenant', 'Unit', 'Amount Owed', 'Days Late'],
          ),
          if (payments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text('No arrears for this period.', style: AppStyles.caption),
            )
          else
            ...payments.map(
              (payment) => _ReportTableRow(
                cells: [
                  payment.tenantName,
                  payment.unit,
                  _money(payment.amount),
                  '${payment.daysLate} days',
                ],
                statusColor: AppColors.danger,
              ),
            ),
        ],
      ),
    );
  }
}

class _ReportCharts extends StatelessWidget {
  final List<_PropertyPaymentBreakdown> propertyRows;
  final int totalCollected;
  final int totalPending;

  const _ReportCharts({
    required this.propertyRows,
    required this.totalCollected,
    required this.totalPending,
  });

  @override
  Widget build(BuildContext context) {
    return _ReportBlock(
      title: 'Charts',
      child: Column(
        children: [
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: propertyRows
                    .asMap()
                    .entries
                    .map(
                      (entry) => BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.collected / 1000,
                            color: AppColors.kodiGreen,
                            width: 22,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PaidPendingMiniChart(
            totalCollected: totalCollected,
            totalPending: totalPending,
          ),
        ],
      ),
    );
  }
}

class _PaidPendingMiniChart extends StatelessWidget {
  final int totalCollected;
  final int totalPending;

  const _PaidPendingMiniChart({
    required this.totalCollected,
    required this.totalPending,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 118,
          height: 118,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 30,
              sectionsSpace: 2,
              sections: [
                PieChartSectionData(
                  value: totalCollected.toDouble(),
                  color: AppColors.kodiGreen,
                  title: 'Paid',
                  radius: 28,
                  titleStyle: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                PieChartSectionData(
                  value: totalPending.toDouble(),
                  color: AppColors.danger,
                  title: 'Pending',
                  radius: 28,
                  titleStyle: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _LegendRow(
                color: AppColors.kodiGreen,
                label: 'Paid',
                value: _money(totalCollected),
              ),
              const SizedBox(height: 10),
              _LegendRow(
                color: AppColors.danger,
                label: 'Pending',
                value: _money(totalPending),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const _ReportBlock({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _titleStyle),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ReportInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReportInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppStyles.caption)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: _smallBoldStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ReportSummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppStyles.caption),
          const SizedBox(height: 6),
          FittedBox(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTableHeader extends StatelessWidget {
  final List<String> columns;

  const _ReportTableHeader({required this.columns});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: columns
            .map(
              (column) => Expanded(
                child: Text(
                  column,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ReportTableRow extends StatelessWidget {
  final List<String> cells;
  final Color statusColor;

  const _ReportTableRow({
    required this.cells,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: cells
            .asMap()
            .entries
            .map(
              (entry) => Expanded(
                child: Text(
                  entry.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: entry.key == cells.length - 2
                        ? statusColor
                        : AppColors.textDark,
                    fontSize: 11,
                    fontWeight: entry.key == 0 ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PaymentItem extends StatelessWidget {
  final PaymentRecord payment;
  final VoidCallback onTap;
  final VoidCallback? onReminder;

  const _PaymentItem({
    required this.payment,
    required this.onTap,
    this.onReminder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _TappableCard(
        onTap: onTap,
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(payment.tenantName.characters.first)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(payment.tenantName, style: _titleStyle),
                      Text('${payment.unit} - ${payment.property}',
                          style: AppStyles.caption),
                      const SizedBox(height: 3),
                      Text(
                        payment.isPaid
                            ? 'Paid ${payment.paidAt}'
                            : 'Due ${payment.dueDate} - ${payment.daysLate} days late',
                        style: AppStyles.caption,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_money(payment.amount), style: _smallBoldStyle),
                    const SizedBox(height: 5),
                    StatusPill(
                      label: payment.status,
                      color: _paymentStatusColor(payment.status),
                    ),
                  ],
                ),
              ],
            ),
            if (payment.isPending && onReminder != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onReminder,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Send Reminder'),
                ),
              ),
            ],
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


class _PreferenceSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreferenceSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _TappableCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _titleStyle),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppStyles.caption),
                ],
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: AppColors.kodiGreen,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentRecord {
  final int? tenancyId;
  final String tenantName;
  final String tenantPhone;
  final String tenantEmail;
  final String unit;
  final String property;
  final int amount;
  final String status;
  final String method;
  final String transactionRef;
  final String dueDate;
  final String? paidAt;
  final String createdAt;
  final String updatedAt;
  final int daysLate;

  const PaymentRecord({
    this.tenancyId,
    required this.tenantName,
    required this.tenantPhone,
    required this.tenantEmail,
    required this.unit,
    required this.property,
    required this.amount,
    required this.status,
    required this.method,
    required this.transactionRef,
    required this.dueDate,
    this.paidAt,
    required this.createdAt,
    required this.updatedAt,
    required this.daysLate,
  });

  bool get isPaid => status == 'Paid';
  bool get isPending => status == 'Pending';

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  static String _formatDateTime(DateTime d) {
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '${_formatDate(d)}, ${hour12.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $ampm';
  }

  static String _displayMethod(String raw) {
    switch (raw.toLowerCase()) {
      case 'mpesa':
        return 'M-Pesa';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'cash':
        return 'Cash';
      default:
        return raw.isEmpty ? '—' : raw;
    }
  }

  factory PaymentRecord.fromTenancyAndPayment(
    TenancyRecord tenancy,
    Map<String, dynamic> payment,
  ) {
    final amount = _toNum(payment['amount']).toInt();
    final rawStatus = (payment['status'] ?? 'pending').toString().toLowerCase();
    final paymentDate = _parseDate(payment['payment_date']);
    final createdAt = _parseDate(payment['created_at']);
    final updatedAt = _parseDate(payment['updated_at']);
    final dueDate = _assumedDueDate(tenancy.startDate, paymentDate);
    final daysLate = rawStatus == 'completed'
        ? 0
        : _daysBetween(dueDate, DateTime.now()).clamp(0, 9999);
    return PaymentRecord(
      tenancyId: tenancy.id,
      tenantName: tenancy.tenantName.isEmpty ? 'Tenant' : tenancy.tenantName,
      tenantPhone: tenancy.tenantPhone ?? '—',
      tenantEmail: tenancy.tenantEmail ?? '—',
      unit: tenancy.unitNumber,
      property: tenancy.propertyName,
      amount: amount,
      status: rawStatus == 'completed' ? 'Paid' : 'Pending',
      method: _displayMethod((payment['payment_method'] ?? '').toString()),
      transactionRef:
          (payment['transaction_ref']?.toString().trim().isNotEmpty ?? false)
              ? payment['transaction_ref'].toString()
              : 'Pending',
      dueDate: _formatDate(dueDate),
      paidAt:
          rawStatus == 'completed' && paymentDate != null
              ? _formatDateTime(paymentDate)
              : null,
      createdAt:
          createdAt != null ? _formatDateTime(createdAt) : '—',
      updatedAt:
          updatedAt != null ? _formatDateTime(updatedAt) : '—',
      daysLate: daysLate,
    );
  }

  factory PaymentRecord.pendingFor(TenancyRecord tenancy) {
    final dueDate = _assumedDueDate(tenancy.startDate, null);
    final daysLate = _daysBetween(dueDate, DateTime.now()).clamp(0, 9999);
    return PaymentRecord(
      tenancyId: tenancy.id,
      tenantName: tenancy.tenantName.isEmpty ? 'Tenant' : tenancy.tenantName,
      tenantPhone: tenancy.tenantPhone ?? '—',
      tenantEmail: tenancy.tenantEmail ?? '—',
      unit: tenancy.unitNumber,
      property: tenancy.propertyName,
      amount: tenancy.rentAmount.toInt(),
      status: 'Pending',
      method: 'M-Pesa',
      transactionRef: 'Pending',
      dueDate: _formatDate(dueDate),
      paidAt: null,
      createdAt: '—',
      updatedAt: '—',
      daysLate: daysLate,
    );
  }

  static DateTime _assumedDueDate(DateTime? tenancyStart, DateTime? paymentDate) {
    final reference = paymentDate ?? DateTime.now();
    final dueDay = tenancyStart?.day ?? 25;
    final day = dueDay.clamp(1, 28);
    return DateTime(reference.year, reference.month, day);
  }

  static int _daysBetween(DateTime from, DateTime to) {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }
}

class PropertyData {
  final int? id;
  final String name;
  final String location;
  final int totalUnits;
  final int occupiedUnits;
  final int vacantUnits;
  final num thisMonthIncome;
  final num expectedMonthlyRent;
  final int activeTenants;

  const PropertyData({
    this.id,
    required this.name,
    required this.location,
    required this.totalUnits,
    required this.occupiedUnits,
    required this.vacantUnits,
    required this.thisMonthIncome,
    required this.expectedMonthlyRent,
    required this.activeTenants,
  });

  String get unitsLabel => '$totalUnits ${totalUnits == 1 ? 'Unit' : 'Units'}';
  String get occupiedLabel => '$occupiedUnits Occupied';
  String get monthlyIncomeLabel => 'KSh ${_formatKsh(thisMonthIncome)}';

  factory PropertyData.fromJson(Map<String, dynamic> json) {
    return PropertyData(
      id: json['id'] is int ? json['id'] as int : null,
      name: (json['name'] ?? '').toString(),
      location: (json['address'] ?? '').toString(),
      totalUnits: _toInt(json['total_units']),
      occupiedUnits: _toInt(json['occupied_units']),
      vacantUnits: _toInt(json['vacant_units']),
      thisMonthIncome: _toNum(json['this_month_income']),
      expectedMonthlyRent: _toNum(json['expected_monthly_rent']),
      activeTenants: _toInt(json['active_tenants']),
    );
  }
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

num _toNum(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  return num.tryParse(value.toString()) ?? 0;
}

String _formatKsh(num value) {
  final whole = value.toInt();
  final formatted = whole.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match.group(1)},',
      );
  return formatted;
}


class _DetailRowData {
  final String label;
  final String value;

  const _DetailRowData(this.label, this.value);
}

class _PropertyPaymentBreakdown {
  final String propertyName;
  final int units;
  final int collected;
  final int pending;

  const _PropertyPaymentBreakdown({
    required this.propertyName,
    required this.units,
    required this.collected,
    required this.pending,
  });
}

String _money(int amount) {
  return 'KSh ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
}

Color _paymentStatusColor(String status) {
  switch (status) {
    case 'Paid':
      return AppColors.kodiGreen;
    case 'Pending':
      return AppColors.kodiOrange;
    case 'Overdue':
      return AppColors.danger;
    default:
      return AppColors.muted;
  }
}

List<_PropertyPaymentBreakdown> _buildPropertyBreakdown(List<PaymentRecord> payments) {
  final map = <String, _PropertyPaymentBreakdown>{};
  for (final payment in payments) {
    final propertyName = payment.property;
    final existing = map[propertyName];
    if (existing != null) {
      map[propertyName] = _PropertyPaymentBreakdown(
        propertyName: propertyName,
        units: existing.units,
        collected: existing.collected + (payment.isPaid ? payment.amount : 0),
        pending: existing.pending + (payment.isPending ? payment.amount : 0),
      );
    } else {
      map[propertyName] = _PropertyPaymentBreakdown(
        propertyName: propertyName,
        units: 1,
        collected: payment.isPaid ? payment.amount : 0,
        pending: payment.isPending ? payment.amount : 0,
      );
    }
  }
  return map.values.toList();
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
