import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';

class CaretakerUnitsScreen extends StatefulWidget {
  final int propertyId;
  final String propertyName;
  final String propertyAddress;

  const CaretakerUnitsScreen({
    super.key,
    required this.propertyId,
    required this.propertyName,
    required this.propertyAddress,
  });

  @override
  State<CaretakerUnitsScreen> createState() => _CaretakerUnitsScreenState();
}

class _CaretakerUnitsScreenState extends State<CaretakerUnitsScreen> {
  final ApiService _api = ApiService();
  Future<List<Map<String, dynamic>>>? _future;

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

  Future<List<Map<String, dynamic>>> _fetch() async {
    final response = await _api.get('/caretakers/my-units', query: {'propertyId': widget.propertyId});
    if (response.statusCode != 200) {
      throw Exception('Could not load units (${response.statusCode})');
    }
    return (jsonDecode(response.body) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> _reportVacancy(Map<String, dynamic> unit) async {
    final unitNumber = (unit['unit_number'] ?? '').toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Vacancy?'),
        content: Text('Mark Unit $unitNumber as vacant? This will notify the landlord.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Report Vacancy', style: TextStyle(color: AppColors.kodiOrange)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final response = await _api.put('/caretakers/units/${unit['id']}/vacancy', const {'notes': 'Reported from unit list'});
      if (!mounted) return;
      if (response.statusCode == 200) {
        showSnack(context, 'Unit $unitNumber marked as vacant');
        _reload();
      } else {
        String message = 'Could not report vacancy (${response.statusCode})';
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          if (body['error'] != null) message = body['error'].toString();
        } catch (_) {}
        showSnack(context, message);
      }
    } catch (_) {
      showSnack(context, 'Connection error');
    }
  }

  num _toNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.propertyName, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800, fontFamily: 'Lexend')),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                    const SizedBox(height: 10),
                    const Text('Could not load units', style: AppStyles.bodyMedium),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            final units = snapshot.data ?? const <Map<String, dynamic>>[];
            final occupied = units.where((u) => (u['status'] ?? '').toString() == 'occupied').length;
            final vacant = units.where((u) => (u['status'] ?? '').toString() == 'vacant').length;

            return RefreshIndicator(
              onRefresh: () async { _reload(); await _future; },
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _buildSummaryCard(units.length, occupied, vacant),
                  const SizedBox(height: 16),
                  if (units.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.meeting_room_outlined, size: 40, color: AppColors.muted),
                          SizedBox(height: 10),
                          Text('No units found', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                        ],
                      ),
                    )
                  else
                    ...units.map((u) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _unitCard(u),
                    )),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int total, int occupied, int vacant) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.kodiNavy, Color(0xFF0A2744)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.kodiNavy.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.propertyAddress.isEmpty ? widget.propertyName : widget.propertyAddress,
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryStat('$total', 'Total Units'),
              _summaryStat('$occupied', 'Occupied'),
              _summaryStat('$vacant', 'Vacant'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Lexend')),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _unitCard(Map<String, dynamic> unit) {
    final unitNumber = (unit['unit_number'] ?? '').toString();
    final status = (unit['status'] ?? 'vacant').toString();
    final tenantName = (unit['tenant_name'] ?? '').toString();
    final tenantPhone = (unit['tenant_phone'] ?? '').toString();
    final rent = _toNum(unit['rent_amount']);

    final (statusColor, statusLabel) = switch (status) {
      'occupied' => (AppColors.kodiGreen, 'Occupied'),
      'maintenance' => (AppColors.kodiOrange, 'In Maintenance'),
      _ => (AppColors.muted, 'Vacant'),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(status == 'occupied' ? Icons.person_pin_rounded : Icons.door_front_door_outlined, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unitNumber.isEmpty ? 'Unit ${unit['id']}' : 'Unit $unitNumber',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status == 'occupied' && tenantName.isNotEmpty ? tenantName : capitalize(status),
                      style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                child: Text(statusLabel.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.4)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.payments_outlined, size: 14, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(money(rent.toInt()), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const Spacer(),
              if (tenantPhone.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 13, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text(tenantPhone, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
            ],
          ),
          if (status != 'vacant') ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Material(
                  color: AppColors.kodiOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _reportVacancy(unit),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.meeting_room_outlined, size: 14, color: AppColors.kodiOrange),
                          SizedBox(width: 6),
                          Text('Report Vacancy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.kodiOrange)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
