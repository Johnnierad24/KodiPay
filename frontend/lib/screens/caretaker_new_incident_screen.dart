import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';

class CaretakerNewIncidentScreen extends StatefulWidget {
  const CaretakerNewIncidentScreen({super.key});

  @override
  State<CaretakerNewIncidentScreen> createState() => _CaretakerNewIncidentScreenState();
}

class _CaretakerNewIncidentScreenState extends State<CaretakerNewIncidentScreen> {
  final ApiService _api = ApiService();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  List<Map<String, dynamic>> _units = [];
  bool _loading = true;
  String? _loadError;

  int? _unitId;
  String _category = 'plumbing';
  String _priority = 'medium';
  bool _submitting = false;

  static const _categories = ['electrical', 'plumbing', 'structural', 'other'];
  static const _priorities = ['low', 'medium', 'high', 'urgent', 'emergency'];

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
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
          _units = data;
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
      if (tenant.isNotEmpty) '$tenant • $status' else capitalize(status),
    ];
    return parts.join(' — ');
  }

  Future<void> _submit() async {
    if (_unitId == null) {
      showSnack(context, 'Please select a unit');
      return;
    }
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      showSnack(context, 'Please enter a short title');
      return;
    }
    final selected = _units.firstWhere((u) => u['id'] == _unitId, orElse: () => const {});
    setState(() => _submitting = true);
    try {
      final response = await _api.post('/maintenance', {
        'unit_id': _unitId,
        'tenant_id': selected['tenant_id'],
        'title': title,
        'description': _descCtrl.text.trim(),
        'category': _category,
        'priority': _priority,
      });
      if (!mounted) return;
      if (response.statusCode == 201) {
        showSnack(context, 'Incident reported successfully');
        Navigator.pop(context, true);
      } else {
        String message = 'Could not report incident (${response.statusCode})';
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
        title: const Text('Report New Incident', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800, fontFamily: 'Lexend')),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUnitField(),
                  const SizedBox(height: 18),
                  _buildTitleField(),
                  const SizedBox(height: 18),
                  _buildCategorySelector(),
                  const SizedBox(height: 18),
                  _buildPrioritySelector(),
                  const SizedBox(height: 18),
                  _buildDescriptionField(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.kodiNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _submitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(_submitting ? 'Submitting...' : 'Submit Incident'),
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

  Widget _buildUnitField() {
    Widget content;
    if (_loading) {
      content = const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_loadError != null) {
      content = Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_loadError!, style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _loadUnits,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    } else {
      content = DropdownButtonFormField<int>(
        initialValue: _unitId,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Unit',
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
    return _FormSection(
      title: 'Unit',
      subtitle: 'Select the unit this incident relates to.',
      child: content,
    );
  }

  Widget _buildTitleField() {
    return _FormSection(
      title: 'Short Title',
      subtitle: 'A brief summary of the issue.',
      child: TextField(
        controller: _titleCtrl,
        maxLength: 80,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          hintText: 'e.g. Burst water pipe in kitchen',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return _FormSection(
      title: 'Category',
      subtitle: 'What type of issue is this?',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _categories.map((c) {
          final selected = _category == c;
          return ChoiceChip(
            label: Text(capitalize(c)),
            selected: selected,
            selectedColor: AppColors.kodiNavy.withValues(alpha: 0.12),
            labelStyle: TextStyle(
              color: selected ? AppColors.kodiNavy : AppColors.textDark,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            side: BorderSide(color: selected ? AppColors.kodiNavy : AppColors.outlineVariant),
            onSelected: (_) => setState(() => _category = c),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return _FormSection(
      title: 'Priority',
      subtitle: 'How urgent is this incident?',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _priorities.map((p) {
          final selected = _priority == p;
          final color = maintenancePriorityColor(p);
          return ChoiceChip(
            label: Text(capitalize(p)),
            selected: selected,
            selectedColor: color.withValues(alpha: 0.15),
            labelStyle: TextStyle(
              color: selected ? color : AppColors.textDark,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            side: BorderSide(color: selected ? color : AppColors.outlineVariant),
            onSelected: (_) => setState(() => _priority = p),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return _FormSection(
      title: 'Description',
      subtitle: 'Add any helpful details (optional).',
      child: TextField(
        controller: _descCtrl,
        maxLines: 4,
        maxLength: 500,
        decoration: InputDecoration(
          hintText: 'Describe the issue in detail...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          counterText: '',
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _FormSection({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
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
