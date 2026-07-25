import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/payment_record.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';
import 'tenant_detail_screen.dart';

class TenantListScreen extends StatefulWidget {
  final int? propertyId;
  final String? propertyName;

  const TenantListScreen({super.key, this.propertyId, this.propertyName});

  @override
  State<TenantListScreen> createState() => _TenantListScreenState();
}

class _TenantListScreenState extends State<TenantListScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();
  Future<List<TenancyRecord>>? _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    _future = _fetch();
    setState(() {});
  }

  Future<List<TenancyRecord>> _fetch() async {
    final response = await _api.get('/tenancies', query: {
      if (widget.propertyId != null) 'property_id': widget.propertyId,
    });
    if (response.statusCode != 200) throw Exception('Could not load tenants (${response.statusCode})');
    final data = jsonDecode(response.body) as List<dynamic>;
    var list = data.map((item) => TenancyRecord.fromJson(item as Map<String, dynamic>)).toList();
    if (widget.propertyId != null) {
      list = list.where((t) => t.propertyId == widget.propertyId).toList();
    }
    return list;
  }

  bool _matchesSearch(TenancyRecord t) {
    if (_search.isEmpty) return true;
    final q = _search.toLowerCase();
    return t.tenantName.toLowerCase().contains(q) || t.unitNumber.toLowerCase().contains(q) || t.propertyName.toLowerCase().contains(q) || (t.tenantPhone?.toLowerCase().contains(q) ?? false);
  }

  Future<void> _onAdd() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _AddTenantSheet(),
    );
    if (changed == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final scoped = widget.propertyId != null;
    final title = scoped ? 'Tenants — ${widget.propertyName ?? ''}' : 'All Tenants';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [IconButton(
          icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.kodiGreen),
          onPressed: _onAdd,
        )],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<TenancyRecord>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) {
              return ListView(padding: const EdgeInsets.all(40), children: [
                const SizedBox(height: 60),
                const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.danger),
                const SizedBox(height: 14),
                Center(child: Text(snapshot.error.toString(), textAlign: TextAlign.center, style: AppStyles.bodyMedium)),
                const SizedBox(height: 14),
                Center(child: OutlinedButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry'))),
              ]);
            }
            final all = (snapshot.data ?? const <TenancyRecord>[]).where(_matchesSearch).toList();

            if (all.isEmpty) {
              return ListView(padding: const EdgeInsets.all(40), children: [
                const SizedBox(height: 60),
                const Icon(Icons.groups_2_outlined, size: 72, color: AppColors.muted),
                const SizedBox(height: 16),
                Center(child: Text(_search.isEmpty ? 'No tenants yet' : 'No tenants match "$_search"', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 16))),
                const SizedBox(height: 6),
                const Center(child: Text('Add a tenancy to start tracking rent and payments.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textLight))),
              ]);
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _search = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search tenants by name, unit, or phone...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.isEmpty ? null : IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); }),
                  ),
                ),
                const SizedBox(height: 18),
                if (scoped)
                  ...all.map((t) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _TenantTile(tenancy: t, onTap: () => _openDetail(t))))
                else
                  ..._buildGroupedList(all),
              ],
            );
          },
        ),
      ),
    );
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
          child: Row(children: [
            const Icon(Icons.apartment_rounded, size: 18, color: AppColors.kodiGreen),
            const SizedBox(width: 8),
            Expanded(child: Text(key, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 14))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.kodiGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)), child: Text('${groups[key]!.length}', style: const TextStyle(color: AppColors.kodiGreen, fontWeight: FontWeight.w800, fontSize: 11))),
          ]),
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
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => TenantDetailScreen(tenancy: tenancy)));
    if (changed == true) _reload();
  }
}

class _TenantTile extends StatelessWidget {
  final TenancyRecord tenancy;
  final VoidCallback onTap;

  const _TenantTile({required this.tenancy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initials = tenancy.tenantName.isNotEmpty
        ? tenancy.tenantName.split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join().toUpperCase()
        : '?';
    final active = tenancy.status == 'active';

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 22, backgroundColor: AppColors.kodiGreen.withValues(alpha: 0.12), child: Text(initials, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.kodiGreen))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tenancy.tenantName.isEmpty ? 'Unnamed' : tenancy.tenantName, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('Unit ${tenancy.unitNumber} • ${tenancy.propertyName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppStyles.caption),
                    if (tenancy.tenantPhone != null && tenancy.tenantPhone!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(tenancy.tenantPhone!, style: AppStyles.caption),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: active ? AppColors.successSoft : AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(active ? 'Active' : tenancy.status.toUpperCase(), style: TextStyle(color: active ? AppColors.success : AppColors.danger, fontWeight: FontWeight.w800, fontSize: 11)),
                  ),
                  const SizedBox(height: 6),
                  Text('KSh ${formatKsh(tenancy.rentAmount)}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 12)),
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

// ── Add Tenant Sheet ────────────────────────────────────
class _AddTenantSheet extends StatefulWidget {
  const _AddTenantSheet();

  @override
  State<_AddTenantSheet> createState() => _AddTenantSheetState();
}

class _AddTenantSheetState extends State<_AddTenantSheet> {
  final ApiService _api = ApiService();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_firstNameCtrl.text.trim().isEmpty || _lastNameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'First and last name are required');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      final response = await _api.post('/auth/register', {
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'password': 'TempPass123!',
        'role': 'tenant',
      });
      if (response.statusCode >= 400) {
        if (!mounted) return;
        setState(() { _submitting = false; _error = _decodeError(response.body); });
        return;
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() { _submitting = false; _error = 'Failed: $e'; });
    }
  }

  String _decodeError(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map && data['error'] is String) return data['error'] as String;
    } catch (_) {}
    return 'Request failed';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.kodiGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.kodiGreen)),
              const SizedBox(width: 12),
              const Text('Add Tenant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: TextField(controller: _firstNameCtrl, decoration: const InputDecoration(labelText: 'First name'))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _lastNameCtrl, decoration: const InputDecoration(labelText: 'Last name'))),
            ]),
            const SizedBox(height: 12),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.error_outline, size: 16, color: AppColors.danger), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.danger)))])),
            ],
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _submitting ? null : _submit, child: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Add Tenant'))),
          ],
        ),
      ),
    );
  }
}
