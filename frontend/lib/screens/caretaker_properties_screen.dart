import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';
import 'caretaker_report_vacancy_screen.dart';
import 'caretaker_units_screen.dart';

class CaretakerPropertiesScreen extends StatefulWidget {
  const CaretakerPropertiesScreen({super.key});
  @override
  State<CaretakerPropertiesScreen> createState() => _CaretakerPropertiesScreenState();
}

class _CaretakerPropertiesScreenState extends State<CaretakerPropertiesScreen> {
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
    final response = await _api.get('/caretakers/my-properties');
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>).cast<Map<String, dynamic>>();
    }
    throw Exception('Could not load properties (${response.statusCode})');
  }

  Future<void> _openReportVacancy() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CaretakerReportVacancyScreen()),
    );
    if (changed == true && mounted) {
      showSnack(context, 'Vacancy reported');
      _reload();
    }
  }

  Future<void> _openUnits(Map<String, dynamic> property) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CaretakerUnitsScreen(
          propertyId: _toInt(property['id']),
          propertyName: (property['property_name'] ?? '').toString(),
          propertyAddress: (property['address'] ?? '').toString(),
        ),
      ),
    );
    if (changed == true && mounted) _reload();
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            sliver: SliverToBoxAdapter(child: _buildHeader()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            sliver: SliverToBoxAdapter(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return SizedBox(
                      height: 300,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                            const SizedBox(height: 10),
                            const Text('Could not load properties', style: AppStyles.bodyMedium),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _reload,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final properties = snapshot.data ?? const <Map<String, dynamic>>[];
                  if (properties.isEmpty) {
                    return _buildEmptyState();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsGrid(properties),
                      const SizedBox(height: 18),
                      ...properties.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _propertyCard(properties.indexOf(p), p),
                      )),
                    ],
                  );
                },
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Managed Properties', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark, fontFamily: 'Lexend')),
              SizedBox(height: 4),
              Text('Properties assigned to you and their units', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: AppColors.kodiOrange,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _openReportVacancy,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text('+ Report Vacancy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(List<Map<String, dynamic>> properties) {
    var totalUnits = 0;
    var occupied = 0;
    var vacant = 0;
    for (final p in properties) {
      totalUnits += _toInt(p['total_units']);
      occupied += _toInt(p['occupied_units']);
      vacant += _toInt(p['vacant_units']);
    }

    final cards = [
      _statCard('Assigned Properties', '${properties.length}', Icons.apartment_rounded, AppColors.kodiNavy),
      _statCard('Total Units', '$totalUnits', Icons.meeting_room_outlined, AppColors.kodiBlue),
      _statCard('Occupied', '$occupied', Icons.people_outline, AppColors.kodiGreen),
      _statCard('Vacant', '$vacant', Icons.door_front_door_outlined, AppColors.kodiOrange),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        if (isNarrow) {
          return Column(
            children: [
              Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]),
              const SizedBox(height: 12),
              Row(children: [Expanded(child: cards[2]), const SizedBox(width: 12), Expanded(child: cards[3])]),
            ],
          );
        }
        return Row(
          children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: c))).toList(),
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textLight, letterSpacing: 0.5)),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: color, fontFamily: 'Lexend')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: const Column(
        children: [
          Icon(Icons.domain_add_outlined, size: 48, color: AppColors.muted),
          SizedBox(height: 12),
          Text('No properties assigned', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          SizedBox(height: 4),
          Text('You have not been assigned to any property yet.', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _propertyCard(int index, Map<String, dynamic> p) {
    final name = (p['property_name'] ?? 'Unnamed Property').toString();
    final address = (p['address'] ?? '').toString();
    final totalUnits = _toInt(p['total_units']);
    final occupied = _toInt(p['occupied_units']);
    final vacant = _toInt(p['vacant_units']);
    final maintenance = _toInt(p['maintenance_units']);
    final openMaint = _toInt(p['open_maintenance']);
    final occupancy = totalUnits > 0 ? ((occupied / totalUnits) * 100).round() : 0;
    final gradient = _gradientFor(index);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 16, left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.kodiGreen,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text('ASSIGNED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
                  ),
                ),
                Positioned(
                  bottom: 16, right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.kodiGreen, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        const Text('Active Management', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Icon(Icons.apartment_rounded, size: 60, color: Colors.white.withValues(alpha: 0.15)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark, fontFamily: 'Lexend')),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textLight),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(address.isEmpty ? 'Address unavailable' : address, style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$occupancy%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.kodiNavy, fontFamily: 'Lexend')),
                        const Text('Occupancy', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textLight, letterSpacing: 0.5)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5))),
                  ),
                  child: Row(
                    children: [
                      _unitStat('$totalUnits', 'Total Units'),
                      Container(width: 1, height: 30, color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                      _unitStat('$occupied', 'Occupied'),
                      Container(width: 1, height: 30, color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                      _unitStat('$vacant', 'Vacant', isAlert: vacant > 0),
                      Container(width: 1, height: 30, color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                      _unitStat('$maintenance', 'In Maint', isRevenue: true),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (openMaint > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 15, color: AppColors.kodiOrange),
                        const SizedBox(width: 6),
                        Text(
                          '$openMaint open maintenance ${openMaint == 1 ? 'request' : 'requests'}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.kodiOrange),
                        ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Material(
                      color: AppColors.kodiNavy,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _openUnits(p),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('View Units', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitStat(String value, String label, {bool isAlert = false, bool isRevenue = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isAlert ? AppColors.danger : (isRevenue ? AppColors.kodiGreen : AppColors.textDark),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textLight, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  List<Color> _gradientFor(int index) {
    const pool = [
      [Color(0xFF1E3A5F), Color(0xFF0D2137)],
      [Color(0xFF2D6A4F), Color(0xFF1B4332)],
      [Color(0xFF7B2D2D), Color(0xFF5C1A1A)],
      [Color(0xFF3E4C59), Color(0xFF1F2933)],
    ];
    return pool[index % pool.length];
  }
}
