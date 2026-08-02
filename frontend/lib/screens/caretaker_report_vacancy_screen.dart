import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';

class CaretakerReportVacancyScreen extends StatefulWidget {
  const CaretakerReportVacancyScreen({super.key});

  @override
  State<CaretakerReportVacancyScreen> createState() => _CaretakerReportVacancyScreenState();
}

class _CaretakerReportVacancyScreenState extends State<CaretakerReportVacancyScreen> {
  final ApiService _api = ApiService();
  final _notesCtrl = TextEditingController();

  List<Map<String, dynamic>> _units = [];
  bool _loading = true;
  String? _loadError;

  int? _unitId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUnits() async {
    setState(() { _loading = true; _loadError = null; });
    try {
      final response = await _api.get('/caretakers/my-units');
      if (response.statusCode == 200) {
        final data = (jsonDecode(response.body) as List<dynamic>).cast<Map<String, dynamic>>();
        if (!mounted) return;
        setState(() {
          _units = data.where((u) => (u['status'] ?? '').toString() != 'vacant').toList();
          _loading = false;
        });
      } else {
        setState(() { _loadError = 'Could not load units'; _loading = false; });
      }
    } catch (_) {
      setState(() { _loadError = 'Connection error'; _loading = false; });
    }
  }

  String _unitLabel(Map<String, dynamic> unit) {
    final unitNumber = (unit['unit_number'] ?? '').toString();
    final property = (unit['property_name'] ?? '').toString();
    final tenant = (unit['tenant_name'] ?? '').toString();
    final status = (unit['status'] ?? '').toString();
    final parts = [
      unitNumber.isNotEmpty ? 'Unit $unitNumber' : 'Unit ${unit['id']}',
      if (property.isNotEmpty) property,
      if (tenant.isNotEmpty) '$tenant • ${capitalize(status)}' else capitalize(status),
    ];
    return parts.join(' — ');
  }

  Future<void> _submit() async {
    if (_unitId == null) {
      showSnack(context, 'Please select a unit');
      return;
    }
    final selected = _units.firstWhere((u) => u['id'] == _unitId, orElse: () => const {});
    setState(() => _submitting = true);
    try {
      final response = await _api.put(
        '/caretakers/units/$_unitId/vacancy',
        {'notes': _notesCtrl.text.trim()},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => _VacancySuccessScreen(
              unitNumber: (selected['unit_number'] ?? '').toString(),
              propertyName: (selected['property_name'] ?? '').toString(),
              notes: _notesCtrl.text.trim(),
            ),
          ),
        );
      } else {
        String message = 'Could not report vacancy (${response.statusCode})';
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          if (body['error'] != null) message = body['error'].toString();
        } catch (_) {}
        setState(() => _submitting = false);
        showSnack(context, message);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showSnack(context, 'Connection error');
    }
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
        title: const Text('Report Vacancy', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800, fontFamily: 'Lexend')),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.kodiOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.kodiOrange.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.kodiOrange, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Let the landlord know a unit is now vacant. You can pick which unit and add a short note.',
                            style: TextStyle(fontSize: 13, color: AppColors.textDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _section('Unit', 'Which unit has become vacant?', _buildUnitSelector()),
                  const SizedBox(height: 18),
                  _section('Notes (optional)', 'e.g. move-out date, condition on exit', TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    maxLength: 300,
                    decoration: InputDecoration(
                      hintText: 'Add any details about the vacancy...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      counterText: '',
                    ),
                  )),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.kodiOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _submitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.door_front_door_outlined, size: 18),
                      label: Text(_submitting ? 'Submitting...' : 'Report Vacancy'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitSelector() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null) {
      return Column(
        children: [
          Text(_loadError!, style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _loadUnits,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      );
    }
    if (_units.isEmpty) {
      return const Text(
        'All assigned units are already vacant. Nothing to report.',
        style: TextStyle(fontSize: 13, color: AppColors.textLight),
      );
    }
    return DropdownButtonFormField<int>(
      initialValue: _unitId,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: 'Select a unit',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: _units.map((u) => DropdownMenuItem(
        value: u['id'] as int,
        child: Text(_unitLabel(u), overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: (v) => setState(() => _unitId = v),
    );
  }

  Widget _section(String title, String subtitle, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark, fontFamily: 'Lexend')),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _VacancySuccessScreen extends StatelessWidget {
  final String unitNumber;
  final String propertyName;
  final String notes;

  const _VacancySuccessScreen({
    required this.unitNumber,
    required this.propertyName,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(color: AppColors.kodiGreen.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, color: AppColors.kodiGreen, size: 40),
                    ),
                    const SizedBox(height: 18),
                    const Text('Vacancy Reported', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark, fontFamily: 'Lexend')),
                    const SizedBox(height: 6),
                    const Text(
                      'The landlord has been notified. The unit is now marked as vacant.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textLight),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _row('Unit', unitNumber.isEmpty ? '—' : 'Unit $unitNumber'),
                          const SizedBox(height: 10),
                          _row('Property', propertyName.isEmpty ? '—' : propertyName),
                          const SizedBox(height: 10),
                          _row('Notes', notes.isEmpty ? 'None' : notes),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.kodiGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textLight)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark))),
      ],
    );
  }
}
