import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../utils/constants.dart';

class UnitsListScreen extends StatefulWidget {
  final int propertyId;
  final String propertyName;

  const UnitsListScreen({
    super.key,
    required this.propertyId,
    required this.propertyName,
  });

  @override
  State<UnitsListScreen> createState() => _UnitsListScreenState();
}

class _UnitsListScreenState extends State<UnitsListScreen> {
  final ApiService _api = ApiService();
  Future<List<UnitRecord>>? _future;

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

  Future<List<UnitRecord>> _fetch() async {
    final response = await _api.get('/units/property/${widget.propertyId}');
    if (response.statusCode != 200) {
      throw Exception('Could not load units (${response.statusCode})');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => UnitRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _onAdd() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddUnitSheet(propertyId: widget.propertyId),
    );
    if (changed == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Units — ${widget.propertyName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.kodiGreen,
        foregroundColor: AppColors.white,
        onPressed: _onAdd,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Unit'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: FutureBuilder<List<UnitRecord>>(
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
                        style: const TextStyle(color: AppColors.textLight),
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
              final units = snapshot.data ?? const <UnitRecord>[];
              if (units.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(40),
                  children: [
                    const SizedBox(height: 60),
                    const Icon(Icons.meeting_room_outlined,
                        size: 72, color: AppColors.muted),
                    const SizedBox(height: 14),
                    const Center(
                      child: Text(
                        'No units yet',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'Add units like A1, A2... to start assigning tenants.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textLight),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _onAdd,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add First Unit'),
                      ),
                    ),
                  ],
                );
              }

              final occupied = units.where((u) => u.status == 'occupied').length;
              final vacant = units.where((u) => u.status == 'vacant').length;
              final maintenance = units.where((u) => u.status == 'maintenance').length;

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
                children: [
                  _SummaryStrip(
                    occupied: occupied,
                    vacant: vacant,
                    maintenance: maintenance,
                    total: units.length,
                  ),
                  const SizedBox(height: 18),
                  for (final unit in units) ...[
                    _UnitTile(unit: unit),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class UnitRecord {
  final int id;
  final String unitNumber;
  final String status;
  final num rentAmount;
  final num depositAmount;
  final String? tenantName;
  final String? tenantPhone;
  final int? tenantId;
  final int? tenancyId;
  final DateTime? startDate;
  final int unpaidInvoices;
  final int overdueInvoices;
  final num arrearsAmount;
  final DateTime? lastPaymentDate;

  const UnitRecord({
    required this.id,
    required this.unitNumber,
    required this.status,
    required this.rentAmount,
    required this.depositAmount,
    required this.tenantName,
    required this.tenantPhone,
    required this.tenantId,
    required this.tenancyId,
    required this.startDate,
    required this.unpaidInvoices,
    required this.overdueInvoices,
    required this.arrearsAmount,
    required this.lastPaymentDate,
  });

  factory UnitRecord.fromJson(Map<String, dynamic> json) {
    return UnitRecord(
      id: json['id'] as int,
      unitNumber: (json['unit_number'] ?? '').toString(),
      status: (json['status'] ?? 'vacant').toString(),
      rentAmount: _toNum(json['rent_amount']),
      depositAmount: _toNum(json['deposit_amount']),
      tenantName: json['tenant_name'] as String?,
      tenantPhone: json['tenant_phone'] as String?,
      tenantId: json['tenant_id'] is int ? json['tenant_id'] as int : null,
      tenancyId: json['tenancy_id'] is int ? json['tenancy_id'] as int : null,
      startDate: _parseDate(json['start_date']),
      unpaidInvoices: _toInt(json['unpaid_invoices']),
      overdueInvoices: _toInt(json['overdue_invoices']),
      arrearsAmount: _toNum(json['arrears_amount']),
      lastPaymentDate: _parseDate(json['last_payment_date']),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final int occupied;
  final int vacant;
  final int maintenance;
  final int total;

  const _SummaryStrip({
    required this.occupied,
    required this.vacant,
    required this.maintenance,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryBox(
            label: 'Total',
            value: total.toString(),
            color: AppColors.kodiNavy,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryBox(
            label: 'Occupied',
            value: occupied.toString(),
            color: AppColors.kodiGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryBox(
            label: 'Vacant',
            value: vacant.toString(),
            color: AppColors.kodiOrange,
          ),
        ),
        if (maintenance > 0) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryBox(
              label: 'Maint.',
              value: maintenance.toString(),
              color: AppColors.danger,
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitTile extends StatelessWidget {
  final UnitRecord unit;
  const _UnitTile({required this.unit});

  ({Color color, String label}) get _statusBadge {
    switch (unit.status) {
      case 'occupied':
        return (color: AppColors.kodiGreen, label: 'Occupied');
      case 'maintenance':
        return (color: AppColors.danger, label: 'Maintenance');
      default:
        return (color: AppColors.kodiOrange, label: 'Vacant');
    }
  }

  ({Color color, String label, IconData icon})? get _rentStatusBadge {
    if (unit.status != 'occupied') return null;
    if (unit.overdueInvoices > 0) {
      return (
        color: AppColors.danger,
        label: 'Overdue • KSh ${_formatKsh(unit.arrearsAmount)}',
        icon: Icons.warning_amber_rounded,
      );
    }
    if (unit.unpaidInvoices > 0) {
      return (
        color: AppColors.kodiOrange,
        label: 'Due • KSh ${_formatKsh(unit.arrearsAmount)}',
        icon: Icons.schedule_rounded,
      );
    }
    return (
      color: AppColors.kodiGreen,
      label: 'Up to date',
      icon: Icons.check_circle_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusBadge;
    final rent = _rentStatusBadge;
    final df = DateFormat('d MMM yyyy');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  unit.unitNumber.isEmpty ? '?' : unit.unitNumber,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: status.color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unit ${unit.unitNumber}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'KSh ${_formatKsh(unit.rentAmount)} /month',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    color: status.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          if (unit.status == 'occupied' && unit.tenantName != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 16, color: AppColors.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    unit.tenantName!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (unit.tenantPhone != null && unit.tenantPhone!.isNotEmpty)
                  Text(
                    unit.tenantPhone!,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            if (rent != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: rent.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(rent.icon, color: rent.color, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        rent.label,
                        style: TextStyle(
                          color: rent.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (unit.lastPaymentDate != null)
                      Text(
                        'Last: ${df.format(unit.lastPaymentDate!)}',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _AddUnitSheet extends StatefulWidget {
  final int propertyId;
  const _AddUnitSheet({required this.propertyId});

  @override
  State<_AddUnitSheet> createState() => _AddUnitSheetState();
}

class _AddUnitSheetState extends State<_AddUnitSheet> {
  final ApiService _api = ApiService();
  final TextEditingController _unitNumber = TextEditingController();
  final TextEditingController _rentAmount = TextEditingController();
  final TextEditingController _depositAmount = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _unitNumber.dispose();
    _rentAmount.dispose();
    _depositAmount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final rent = num.tryParse(_rentAmount.text.trim());
    if (_unitNumber.text.trim().isEmpty) {
      setState(() => _error = 'Unit number is required');
      return;
    }
    if (rent == null || rent <= 0) {
      setState(() => _error = 'Enter a valid monthly rent');
      return;
    }
    final deposit = _depositAmount.text.trim().isEmpty
        ? null
        : num.tryParse(_depositAmount.text.trim());

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final response = await _api.post('/units', {
        'property_id': widget.propertyId,
        'unit_number': _unitNumber.text.trim(),
        'rent_amount': rent,
        if (deposit != null) 'deposit_amount': deposit,
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
        _error = 'Failed to save unit: $e';
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
            const Text('Add Unit',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.textDark)),
            const SizedBox(height: 16),
            TextField(
              controller: _unitNumber,
              decoration: const InputDecoration(
                labelText: 'Unit number',
                hintText: 'e.g. A1, B2',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rentAmount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Monthly rent',
                prefixText: 'KSh ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _depositAmount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Deposit amount (optional)',
                prefixText: 'KSh ',
              ),
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
                    : const Text('Save Unit'),
              ),
            ),
          ],
        ),
      ),
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

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  try {
    return DateTime.parse(value.toString());
  } catch (_) {
    return null;
  }
}

String _formatKsh(num value) {
  final whole = value.toInt();
  return whole.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match.group(1)},',
      );
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
