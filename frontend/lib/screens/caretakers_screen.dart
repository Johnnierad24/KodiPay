import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/caretaker_entry.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_screen_components.dart';
import 'caretaker_detail_screen.dart';

class CaretakersScreen extends StatefulWidget {
  const CaretakersScreen({super.key});

  @override
  State<CaretakersScreen> createState() => _CaretakersScreenState();
}

class _CaretakersScreenState extends State<CaretakersScreen> {
  final ApiService _api = ApiService();
  Future<List<CaretakerEntry>>? _future;

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

  Future<List<CaretakerEntry>> _fetch() async {
    final response = await _api.get('/caretakers');
    if (response.statusCode != 200) {
      throw Exception('Could not load caretakers (${response.statusCode})');
    }
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => CaretakerEntry.fromJson(item as Map<String, dynamic>))
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
      builder: (_) => const AddCaretakerSheet(),
    );
    if (added == true) _reload();
  }

  Future<void> _onRemove(CaretakerEntry entry) async {
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
        showSnack(context, 'Caretaker removed.');
        _reload();
      } else {
        Map<String, dynamic>? data;
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}
        showSnack(context,
            data?['error']?.toString() ??
                'Failed to remove caretaker (${response.statusCode}).');
      }
    } catch (e) {
      if (!mounted) return;
      showSnack(context, 'Failed to remove caretaker: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
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
        child: FutureBuilder<List<CaretakerEntry>>(
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
            final items = snapshot.data ?? const <CaretakerEntry>[];
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
            final groups = <String, List<CaretakerEntry>>{};
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
                  PropertyGroupHeader(
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

class _CaretakerCard extends StatelessWidget {
  final CaretakerEntry entry;
  final VoidCallback onRemove;
  const _CaretakerCard({required this.entry, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final name = entry.fullName.isEmpty ? entry.email : entry.fullName;
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    return TappableCard(
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
                Text(name, style: titleStyle),
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

