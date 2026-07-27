import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final ApiService _api = ApiService();
  int _step = 0;
  bool _submitting = false;
  String? _error;

  // Step 1: Property Info
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  String _propertyType = 'Apartment';

  // Step 2: Units
  final List<_UnitEntry> _units = [];

  // Step 3: Financials
  final _rentDayCtrl = TextEditingController(text: '25');
  final _depositCtrl = TextEditingController();
  final _lateFeeCtrl = TextEditingController();
  final _noticePeriodCtrl = TextEditingController(text: '30');

  final _types = ['Apartment', 'House', 'Commercial', 'Villa', 'Townhouse', 'Studio'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _sizeCtrl.dispose();
    _rentDayCtrl.dispose();
    _depositCtrl.dispose();
    _lateFeeCtrl.dispose();
    _noticePeriodCtrl.dispose();
    for (final u in _units) {
      u.numberCtrl.dispose();
      u.rentCtrl.dispose();
    }
    super.dispose();
  }

  bool _validateStep() {
    setState(() => _error = null);
    switch (_step) {
      case 0:
        if (_nameCtrl.text.trim().isEmpty) { setState(() => _error = 'Property name is required'); return false; }
        if (_locationCtrl.text.trim().isEmpty) { setState(() => _error = 'Location is required'); return false; }
        return true;
      case 1:
        if (_units.isEmpty) { setState(() => _error = 'Add at least one unit'); return false; }
        for (final u in _units) {
          if (u.numberCtrl.text.trim().isEmpty) { setState(() => _error = 'All units must have a unit number'); return false; }
          if (u.rentCtrl.text.trim().isEmpty) { setState(() => _error = 'All units must have a rent amount'); return false; }
        }
        return true;
      case 2:
        if (_rentDayCtrl.text.trim().isEmpty) { setState(() => _error = 'Rent collection day is required'); return false; }
        return true;
      default:
        return true;
    }
  }

  void _next() {
    if (!_validateStep()) return;
    setState(() => _step++);
  }

  void _back() => setState(() => _step--);

  Future<void> _submit() async {
    if (!_validateStep()) return;
    setState(() { _submitting = true; _error = null; });
    try {
      final body = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'property_type': _propertyType,
        if (_sizeCtrl.text.trim().isNotEmpty) 'size': _sizeCtrl.text.trim(),
        'rent_collection_day': int.tryParse(_rentDayCtrl.text.trim()) ?? 25,
        'units': _units.map((u) => {
          'unit_number': u.numberCtrl.text.trim(),
          'unit_type': u.type,
          'bedrooms': u.bedrooms,
          'rent_amount': num.tryParse(u.rentCtrl.text.trim()) ?? 0,
        }).toList(),
        if (_depositCtrl.text.trim().isNotEmpty) 'security_deposit': num.tryParse(_depositCtrl.text.trim()),
        if (_lateFeeCtrl.text.trim().isNotEmpty) 'late_fee': num.tryParse(_lateFeeCtrl.text.trim()),
        if (_noticePeriodCtrl.text.trim().isNotEmpty) 'notice_period_days': int.tryParse(_noticePeriodCtrl.text.trim()),
      };
      final response = await _api.post('/properties', body);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _step > 0 ? _back : () => Navigator.pop(context),
        ),
        title: const Text('Add Property', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          if (_error != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.danger))),
              ]),
            ),
          Expanded(child: _buildStepContent()),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    const labels = ['Info', 'Units', 'Financials', 'Review'];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: AppColors.surfaceLowest,
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = _step >= i;
          final current = _step == i;
          return Expanded(
            child: Row(
              children: [
                if (i > 0) Expanded(
                  child: Container(height: 2, color: _step >= i ? AppColors.tertiaryFixed : AppColors.outlineVariant),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? AppColors.tertiaryFixed : AppColors.surfaceLow,
                    border: Border.all(color: active ? AppColors.tertiaryFixed : AppColors.outlineVariant, width: 2),
                  ),
                  child: Center(child: Text('${i + 1}', style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: active ? AppColors.onTertiaryFixed : AppColors.muted,
                  ))),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(labels[i], overflow: TextOverflow.ellipsis, style: TextStyle(
                    fontSize: 12, fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                    color: current ? AppColors.onSurface : AppColors.muted,
                  )),
                ),
                const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0: return _buildInfoStep();
      case 1: return _buildUnitsStep();
      case 2: return _buildFinancialsStep();
      case 3: return _buildReviewStep();
      default: return const SizedBox();
    }
  }

  // ── Step 1: Property Info ────────────────────────────
  Widget _buildInfoStep() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Property Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Lexend', color: AppColors.onSurface)),
        const SizedBox(height: 4),
        const Text('Tell us about your property', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
        const SizedBox(height: 20),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Property Name', hintText: 'e.g. Sunset Apartments')),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _propertyType,
          decoration: const InputDecoration(labelText: 'Property Type'),
          items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) { if (v != null) setState(() => _propertyType = v); },
        ),
        const SizedBox(height: 14),
        TextField(controller: _locationCtrl, decoration: const InputDecoration(labelText: 'Location', hintText: 'e.g. Kilimani, Nairobi')),
        const SizedBox(height: 14),
        TextField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description (optional)', hintText: 'Describe your property...')),
        const SizedBox(height: 14),
        TextField(controller: _sizeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Land Size (optional)', hintText: 'e.g. 0.5 acres')),
      ],
    );
  }

  // ── Step 2: Units ────────────────────────────────────
  Widget _buildUnitsStep() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              const Expanded(child: Text('Units & Layout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Lexend', color: AppColors.onSurface))),
              FilledButton.icon(
                onPressed: _addUnit,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Unit'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.tertiaryFixed,
                  foregroundColor: AppColors.onTertiaryFixed,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('${_units.length} unit${_units.length == 1 ? '' : 's'} added', style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _units.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_work_outlined, size: 48, color: AppColors.muted),
                    SizedBox(height: 8),
                    Text('No units added yet', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('Tap "Add Unit" to add units to this property', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: _units.length,
                itemBuilder: (context, i) => _buildUnitCard(i),
              ),
        ),
      ],
    );
  }

  void _addUnit() {
    setState(() => _units.add(_UnitEntry(
      numberCtrl: TextEditingController(),
      rentCtrl: TextEditingController(),
    )));
  }

  void _removeUnit(int i) {
    setState(() {
      _units[i].numberCtrl.dispose();
      _units[i].rentCtrl.dispose();
      _units.removeAt(i);
    });
  }

  Widget _buildUnitCard(int i) {
    final u = _units[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: AppColors.tertiaryFixed.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onTertiaryFixed, fontSize: 13))),
              ),
              const SizedBox(width: 10),
              const Text('Unit', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface)),
              const Spacer(),
              InkWell(
                onTap: () => _removeUnit(i),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.close_rounded, size: 18, color: AppColors.danger),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: u.numberCtrl, decoration: const InputDecoration(labelText: 'Unit Number', hintText: 'e.g. A1'))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: u.rentCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rent (KSh)', hintText: 'e.g. 25000'))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _UnitTypeChip(label: 'Studio', selected: u.type == 'Studio', onTap: () => setState(() => u.type = 'Studio')),
              const SizedBox(width: 8),
              _UnitTypeChip(label: '1-Bed', selected: u.type == '1-Bed', onTap: () => setState(() => u.type = '1-Bed')),
              const SizedBox(width: 8),
              _UnitTypeChip(label: '2-Bed', selected: u.type == '2-Bed', onTap: () => setState(() => u.type = '2-Bed')),
              const SizedBox(width: 8),
              _UnitTypeChip(label: '3-Bed', selected: u.type == '3-Bed', onTap: () => setState(() => u.type = '3-Bed')),
              const SizedBox(width: 8),
              _UnitTypeChip(label: 'Bedsitter', selected: u.type == 'Bedsitter', onTap: () => setState(() => u.type = 'Bedsitter')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Bedrooms:', style: TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              _BedroomCount(current: u.bedrooms, onChanged: (v) => setState(() => u.bedrooms = v)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Step 3: Financials ───────────────────────────────
  Widget _buildFinancialsStep() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Financial Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Lexend', color: AppColors.onSurface)),
        const SizedBox(height: 4),
        const Text('Configure rent collection and fees', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
        const SizedBox(height: 20),
        TextField(controller: _rentDayCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rent Collection Day', hintText: 'Day of month (e.g. 25)')),
        const SizedBox(height: 14),
        TextField(controller: _depositCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Security Deposit (optional)', hintText: 'e.g. 25000')),
        const SizedBox(height: 14),
        TextField(controller: _lateFeeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Late Fee (optional)', hintText: 'e.g. 500')),
        const SizedBox(height: 14),
        TextField(controller: _noticePeriodCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Notice Period (days)', hintText: 'e.g. 30')),
      ],
    );
  }

  // ── Step 4: Review ───────────────────────────────────
  Widget _buildReviewStep() {
    final totalRent = _units.fold<num>(0, (sum, u) => sum + (num.tryParse(u.rentCtrl.text.trim()) ?? 0));
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Review & Publish', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Lexend', color: AppColors.onSurface)),
        const SizedBox(height: 4),
        const Text('Review the details before publishing', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
        const SizedBox(height: 20),
        _reviewSection('Property Info', [
          _reviewRow('Name', _nameCtrl.text.trim()),
          _reviewRow('Type', _propertyType),
          _reviewRow('Location', _locationCtrl.text.trim()),
          if (_descCtrl.text.trim().isNotEmpty) _reviewRow('Description', _descCtrl.text.trim()),
          if (_sizeCtrl.text.trim().isNotEmpty) _reviewRow('Size', _sizeCtrl.text.trim()),
        ]),
        const SizedBox(height: 12),
        _reviewSection('Units', [
          _reviewRow('Total Units', '${_units.length}'),
          _reviewRow('Monthly Rent', 'KSh ${_formatNum(totalRent)}'),
        ]),
        const SizedBox(height: 12),
        _reviewSection('Financials', [
          _reviewRow('Rent Collection Day', _rentDayCtrl.text.trim()),
          if (_depositCtrl.text.trim().isNotEmpty) _reviewRow('Security Deposit', 'KSh ${_formatNum(_depositCtrl.text.trim())}'),
          if (_lateFeeCtrl.text.trim().isNotEmpty) _reviewRow('Late Fee', 'KSh ${_formatNum(_lateFeeCtrl.text.trim())}'),
          _reviewRow('Notice Period', '${_noticePeriodCtrl.text.trim()} days'),
        ]),
      ],
    );
  }

  Widget _reviewSection(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.onSurface)),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.secondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface))),
        ],
      ),
    );
  }

  // ── Bottom Bar ───────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLowest,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_step > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _back,
                  child: const Text('Back'),
                ),
              ),
            if (_step > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _step < 3 ? _next : (_submitting ? null : _submit),
                child: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_step < 3 ? 'Continue' : 'Publish Property'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNum(dynamic v) {
    final s = v.toString();
    final n = num.tryParse(s);
    if (n == null) return s;
    return n.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

// ── Helper classes ─────────────────────────────────────
class _UnitEntry {
  final TextEditingController numberCtrl;
  final TextEditingController rentCtrl;
  String type;
  int bedrooms;

  _UnitEntry({
    required this.numberCtrl,
    required this.rentCtrl,
  }) : type = '1-Bed', bedrooms = 1;
}

class _UnitTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _UnitTypeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryFixed.withValues(alpha: 0.15) : AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.primaryFixed : AppColors.outlineVariant),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: selected ? AppColors.primaryFixed : AppColors.secondary,
        )),
      ),
    );
  }
}

class _BedroomCount extends StatelessWidget {
  final int current;
  final ValueChanged<int> onChanged;
  const _BedroomCount({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final n = i;
        return GestureDetector(
          onTap: () => onChanged(n),
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: current == n ? AppColors.tertiaryFixed : AppColors.surfaceLow,
              border: Border.all(color: current == n ? AppColors.tertiaryFixed : AppColors.outlineVariant),
            ),
            child: Center(child: Text('$n', style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: current == n ? AppColors.onTertiaryFixed : AppColors.secondary,
            ))),
          ),
        );
      }),
    );
  }
}
