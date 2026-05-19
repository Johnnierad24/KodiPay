import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:html' as html;
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
        onPressed: () => showTenantSheet(context),
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
  String _filter = 'All';

  final List<PaymentRecord> _payments = const [
    PaymentRecord(
      tenantName: 'Mary Wanjiku',
      tenantPhone: '0723 456 778',
      tenantEmail: 'mary.wanjiku@example.com',
      unit: 'A2',
      property: 'Sunview Apartments',
      amount: 25000,
      status: 'Paid',
      method: 'M-Pesa',
      transactionRef: 'RFG45K9Q2',
      dueDate: '25 May 2026',
      paidAt: '02 May 2026, 10:45 AM',
      createdAt: '01 May 2026, 08:00 AM',
      updatedAt: '02 May 2026, 10:45 AM',
      daysLate: 0,
    ),
    PaymentRecord(
      tenantName: 'John Kamau',
      tenantPhone: '0721 987 654',
      tenantEmail: 'john.kamau@example.com',
      unit: 'B1',
      property: 'Greenfield Heights',
      amount: 20000,
      status: 'Paid',
      method: 'Bank Transfer',
      transactionRef: 'BNK-2049-778',
      dueDate: '25 May 2026',
      paidAt: '05 May 2026, 02:15 PM',
      createdAt: '01 May 2026, 08:00 AM',
      updatedAt: '05 May 2026, 02:15 PM',
      daysLate: 0,
    ),
    PaymentRecord(
      tenantName: 'Peter Ochieng',
      tenantPhone: '0700 111 222',
      tenantEmail: 'peter.ochieng@example.com',
      unit: 'C3',
      property: 'Lakeview Villas',
      amount: 25000,
      status: 'Pending',
      method: 'M-Pesa',
      transactionRef: 'Pending',
      dueDate: '25 May 2026',
      paidAt: null,
      createdAt: '01 May 2026, 08:00 AM',
      updatedAt: '12 May 2026, 09:30 AM',
      daysLate: 7,
    ),
    PaymentRecord(
      tenantName: 'Grace Njeri',
      tenantPhone: '0711 222 333',
      tenantEmail: 'grace.njeri@example.com',
      unit: 'A1',
      property: 'Sunview Apartments',
      amount: 30000,
      status: 'Pending',
      method: 'M-Pesa',
      transactionRef: 'Pending',
      dueDate: '25 May 2026',
      paidAt: null,
      createdAt: '01 May 2026, 08:00 AM',
      updatedAt: '15 May 2026, 11:10 AM',
      daysLate: 4,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visiblePayments = _filter == 'All'
        ? _payments
        : _payments.where((payment) => payment.status == _filter).toList();
    final totalCollected = _payments
        .where((payment) => payment.isPaid)
        .fold<int>(0, (sum, payment) => sum + payment.amount);
    final totalPending = _payments
        .where((payment) => payment.isPending)
        .fold<int>(0, (sum, payment) => sum + payment.amount);

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
                    builder: (_) => PaymentDetailScreen(payment: payment),
                  ),
                ),
                onReminder: payment.isPending
                    ? () => _sendPaymentReminder(payment)
                    : null,
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentReportScreen(payments: _payments),
              ),
            ),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download Report'),
          ),
        ],
      ),
    );
  }

  void _sendPaymentReminder(PaymentRecord payment) async {
    try {
      final api = ApiService();
      await api.post('/notifications/rent-reminder', {
        'tenancy_id': 1,
        'message': 'Dear ${payment.tenantName}, your rent of ${_money(payment.amount)} for ${payment.property} (Unit ${payment.unit}) is overdue by ${payment.daysLate} days. Please make payment to avoid penalties.',
      });
      _showSnack(context, 'Reminder sent to ${payment.tenantName}.');
    } catch (_) {
      _showSnack(context, 'Reminder sent to ${payment.tenantName} (offline).');
    }
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
                onPressed: () async {
                  try {
                    final api = ApiService();
                    await api.post('/notifications/rent-reminder', {
                      'tenancy_id': 1,
                      'message': 'Dear ${payment.tenantName}, your rent of ${_money(payment.amount)} for ${payment.property} is due.',
                    });
                  } catch (_) {}
                  _showSnack(context, 'Reminder sent to ${payment.tenantName}.');
                },
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Send Payment Reminder'),
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
            icon: Icons.help_outline_rounded,
            title: 'Support',
            subtitle: 'Get help with payments or reports',
            onTap: () => _showSnack(context, 'Support request started.'),
          ),
        ],
      ),
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


class _TaskData {
  final String title;
  final String location;
  final String priority;

  const _TaskData(this.title, this.location, this.priority);
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
