import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/property_data.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/dashboard_components.dart';
import 'property_detail_screen.dart';
import 'add_property_screen.dart';

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  final ApiService _api = ApiService();
  List<PropertyData> _allProperties = const [];
  List<PropertyData> _filtered = const [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  bool _showMap = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await _api.get('/properties');
      if (response.statusCode != 200) throw Exception('Could not load properties (${response.statusCode})');
      final data = jsonDecode(response.body) as List<dynamic>;
      final properties = data.map((item) => PropertyData.fromJson(item as Map<String, dynamic>)).toList();
      if (!mounted) return;
      setState(() {
        _allProperties = properties;
        _applyFilter();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _applyFilter() {
    final q = _searchQuery.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? _allProperties
          : _allProperties.where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.location.toLowerCase().contains(q))
            .toList();
    });
  }

  void _onAdd() async {
    final added = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const AddPropertyScreen()));
    if (added == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header area
        _buildHeader(),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_error != null)
          Expanded(child: _buildError())
        else
          Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLowest,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Portfolio', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'Lexend', color: AppColors.onSurface))),
              FilledButton.icon(
                onPressed: _onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Property'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.tertiaryFixed,
                  foregroundColor: AppColors.onTertiaryFixed,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) { _searchQuery = v; _applyFilter(); },
                    decoration: InputDecoration(
                      hintText: 'Search properties...',
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.secondary),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: AppColors.surfaceLow,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _FilterChip(label: 'All', selected: !_showMap, onTap: () => setState(() => _showMap = false)),
              const SizedBox(width: 8),
              _FilterChip(label: 'Map', selected: _showMap, onTap: () => setState(() => _showMap = true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.danger),
            const SizedBox(height: 14),
            Text(_error!, textAlign: TextAlign.center, style: AppStyles.bodyMedium),
            const SizedBox(height: 14),
            OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.home_work_outlined, size: 72, color: AppColors.muted),
              const SizedBox(height: 14),
              const Text('No properties found', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 16)),
              const SizedBox(height: 6),
              Text(
                _searchQuery.isNotEmpty ? 'Try a different search term.' : 'Add your first property to get started.',
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textLight),
              ),
            ],
          ),
        ),
      );
    }

    if (_showMap) return _buildMapPlaceholder();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: _filtered.length,
          itemBuilder: (context, index) => _PropertyCard(
            property: _filtered[index],
            onTap: () async {
              final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: _filtered[index])));
              if (changed == true) _load();
            },
          ),
        );
      },
    );
  }

  Widget _buildMapPlaceholder() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Property Locations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Lexend', color: AppColors.onSurface)),
        const SizedBox(height: 8),
        const Text('Tap a property to view its location on Google Maps', style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 16),
        ..._filtered.map((p) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: HSLColor.fromAHSL(1, p.name.hashCode.toDouble() % 360, 0.5, 0.9).toColor(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.map_outlined, size: 24),
            ),
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(p.location.isEmpty ? '—' : p.location, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.open_in_new, size: 18, color: AppColors.kodiGreen),
            onTap: () async {
              final uri = Uri.parse('https://www.google.com/maps/search/${Uri.encodeComponent(p.location.isEmpty ? p.name : p.location)}');
              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),
        )),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.tertiaryFixed : AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.tertiaryFixed : AppColors.outlineVariant),
        ),
        child: Center(
          child: Text(label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: selected ? AppColors.onTertiaryFixed : AppColors.secondary,
          )),
        ),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final PropertyData property;
  final VoidCallback onTap;
  const _PropertyCard({required this.property, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final seed = property.name.hashCode;
    final rng = Random(seed);
    final hue = rng.nextDouble() * 360;
    final cardColor = HSLColor.fromAHSL(1, hue, 0.5, 0.9).toColor();
    final iconColor = HSLColor.fromAHSL(1, hue, 0.6, 0.3).toColor();
    final occupancyPct = property.totalUnits > 0 ? (property.occupiedUnits / property.totalUnits * 100).round() : 0;
    final occupancyLabel = property.totalUnits > 0 ? '$occupancyPct%' : '—';

    return Material(
      color: AppColors.surfaceLowest,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colored header area
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 12, top: 12,
                      child: StatusPill(label: occupancyLabel, color: occupancyPct > 80 ? AppColors.success : (occupancyPct > 50 ? AppColors.warning : AppColors.danger)),
                    ),
                    Center(
                      child: Icon(Icons.apartment_rounded, size: 48, color: iconColor.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
              // Info section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(property.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.onSurface)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: AppColors.muted),
                          const SizedBox(width: 3),
                          Expanded(child: Text(property.location.isEmpty ? '—' : property.location,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.textLight))),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          _InfoChip(icon: Icons.meeting_room_outlined, label: property.unitsLabel),
                          const SizedBox(width: 8),
                          _InfoChip(icon: Icons.people_outline, label: property.occupiedLabel),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.muted),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
