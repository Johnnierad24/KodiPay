import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

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
    final response = await _api.get('/tenancies');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    return [];
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
            sliver: SliverToBoxAdapter(child: _buildStatsGrid()),
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
                  final properties = _buildPropertyCards();
                  return Column(
                    children: [
                      ...properties.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: p,
                      )),
                      _buildAddPropertyCard(),
                    ],
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            sliver: SliverToBoxAdapter(child: _buildRentCollection()),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Managed Properties', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              SizedBox(height: 4),
              Text('Overview of your real estate portfolio in Nairobi', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
            ],
          ),
        ),
        Material(
          color: AppColors.kodiNavy,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {},
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text('+ Add Property', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        return isNarrow
            ? Column(
                children: [
                  _statCard('Total Portfolio Value', 'KSh 12.4M', Icons.payments_rounded, AppColors.kodiGreen, change: '+4.2% from last month', changeColor: AppColors.kodiGreen),
                  const SizedBox(height: 12),
                  _statCard('Average Occupancy', '94.8%', Icons.group_outlined, AppColors.kodiNavy, showProgress: true, progressValue: 0.948),
                  const SizedBox(height: 12),
                  _statCard('Pending Issues', '12', Icons.warning_amber_rounded, AppColors.danger, subtitle: 'Requires immediate attention'),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _statCard('Total Portfolio Value', 'KSh 12.4M', Icons.payments_rounded, AppColors.kodiGreen, change: '+4.2% from last month', changeColor: AppColors.kodiGreen)),
                  const SizedBox(width: 16),
                  Expanded(child: _statCard('Average Occupancy', '94.8%', Icons.group_outlined, AppColors.kodiNavy, showProgress: true, progressValue: 0.948)),
                  const SizedBox(width: 16),
                  Expanded(child: _statCard('Pending Issues', '12', Icons.warning_amber_rounded, AppColors.danger, subtitle: 'Requires immediate attention')),
                ],
              );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, {String? change, Color? changeColor, bool showProgress = false, double? progressValue, String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textLight, letterSpacing: 0.5)),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: color, fontFamily: 'Lexend', letterSpacing: -0.02)),
          if (change != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.trending_up_rounded, size: 14, color: changeColor ?? AppColors.kodiGreen),
                const SizedBox(width: 4),
                Text(change, style: TextStyle(fontSize: 12, color: changeColor ?? AppColors.kodiGreen, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
          if (showProgress && progressValue != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: AppColors.surfaceHigh,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildPropertyCards() {
    return [
      _propertyCard(
        name: 'Blue Heights Estate',
        location: 'Westlands, Nairobi',
        badge: 'Premium Asset',
        badgeColor: AppColors.kodiNavy,
        occupancy: '96%',
        totalUnits: '120',
        moveouts: '3',
        monthlyRev: 'KSh 1.2M',
        avatarCount: 12,
        gradientColors: const [Color(0xFF1E3A5F), Color(0xFF0D2137)],
      ),
      _propertyCard(
        name: 'Crimson Courts',
        location: 'Kilimani, Nairobi',
        badge: 'High Yield',
        badgeColor: AppColors.kodiGreen,
        occupancy: '88%',
        totalUnits: '45',
        moveouts: '8',
        monthlyRev: 'KSh 640K',
        avatarCount: 5,
        gradientColors: const [Color(0xFF7B2D2D), Color(0xFF5C1A1A)],
      ),
      _propertyCard(
        name: 'Emerald Gardens',
        location: 'Lavington, Nairobi',
        badge: 'Stable Growth',
        badgeColor: AppColors.secondary,
        occupancy: '100%',
        totalUnits: '18',
        moveouts: '0',
        monthlyRev: 'KSh 920K',
        avatarCount: 2,
        gradientColors: const [Color(0xFF2D6A4F), Color(0xFF1B4332)],
      ),
    ];
  }

  Widget _propertyCard({
    required String name,
    required String location,
    required String badge,
    required Color badgeColor,
    required String occupancy,
    required String totalUnits,
    required String moveouts,
    required String monthlyRev,
    required int avatarCount,
    required List<Color> gradientColors,
  }) {
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
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradientColors),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16, left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(badge.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
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
                  child: Icon(_propertyIcon(name), size: 64, color: Colors.white.withValues(alpha: 0.15)),
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
                              Text(location, style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(occupancy, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.kodiNavy, fontFamily: 'Lexend')),
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
                      _unitStat(totalUnits, 'Total Units'),
                      Container(width: 1, height: 30, color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                      _unitStat(moveouts, 'Move-outs', isAlert: int.tryParse(moveouts) != null && int.parse(moveouts) > 0),
                      Container(width: 1, height: 30, color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                      _unitStat(monthlyRev, 'Monthly Rev', isRevenue: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(
                        avatarCount > 3 ? 3 : avatarCount,
                        (i) => Container(
                          margin: const EdgeInsets.only(right: 4),
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHigh,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + i),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textDark),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (avatarCount > 3)
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.kodiNavy,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text('+$avatarCount', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                    const Spacer(),
                    Material(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {},
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
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAddPropertyCard() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant, width: 2, strokeAlign: BorderSide.strokeAlignInside),
          ),
          child: Column(
            children: [
              Container(
                width: 64, height: 64,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
                child: const Icon(Icons.add_business_rounded, color: AppColors.kodiNavy, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Onboard New Property', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark, fontFamily: 'Lexend')),
              const SizedBox(height: 8),
              const Text('Expand your portfolio. Start the verification\nprocess for a new building.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textLight)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRentCollection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.kodiNavy, Color(0xFF0A2744)]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.kodiNavy.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Automated Rent Collection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Lexend')),
          const SizedBox(height: 8),
          Text(
            'Your properties at Blue Heights Estate have successfully processed 84% of this month\'s rent. Automated reminders will be sent to the remaining 16 tenants tomorrow morning.',
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Material(
                color: AppColors.kodiGreen,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {},
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: Text('View Collection Report', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: const Text('Settings', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _propertyIcon(String name) {
    if (name.toLowerCase().contains('height') || name.toLowerCase().contains('tower')) return Icons.apartment_rounded;
    if (name.toLowerCase().contains('court') || name.toLowerCase().contains('apartment')) return Icons.villa_rounded;
    if (name.toLowerCase().contains('garden')) return Icons.park_rounded;
    return Icons.business_rounded;
  }
}
