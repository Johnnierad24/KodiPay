class PropertyData {
  final int? id;
  final String name;
  final String location;
  final int totalUnits;
  final int occupiedUnits;
  final int vacantUnits;
  final num thisMonthIncome;
  final num expectedMonthlyRent;
  final int activeTenants;

  const PropertyData({
    this.id,
    required this.name,
    required this.location,
    required this.totalUnits,
    required this.occupiedUnits,
    required this.vacantUnits,
    required this.thisMonthIncome,
    required this.expectedMonthlyRent,
    required this.activeTenants,
  });

  String get unitsLabel => '$totalUnits ${totalUnits == 1 ? 'Unit' : 'Units'}';
  String get occupiedLabel => '$occupiedUnits Occupied';
  String get monthlyIncomeLabel => 'KSh ${_formatKsh(thisMonthIncome)}';

  factory PropertyData.fromJson(Map<String, dynamic> json) {
    return PropertyData(
      id: json['id'] is int ? json['id'] as int : null,
      name: (json['name'] ?? '').toString(),
      location: (json['address'] ?? '').toString(),
      totalUnits: _toInt(json['total_units']),
      occupiedUnits: _toInt(json['occupied_units']),
      vacantUnits: _toInt(json['vacant_units']),
      thisMonthIncome: _toNum(json['this_month_income']),
      expectedMonthlyRent: _toNum(json['expected_monthly_rent']),
      activeTenants: _toInt(json['active_tenants']),
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

String _formatKsh(num value) {
  final whole = value.toInt();
  final formatted = whole.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match.group(1)},',
      );
  return formatted;
}
