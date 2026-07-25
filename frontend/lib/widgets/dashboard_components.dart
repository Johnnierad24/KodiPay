import 'package:flutter/material.dart';
import '../utils/constants.dart';

class DashboardHeader extends StatelessWidget {
  final String greeting;
  final String subtitle;
  final int unreadCount;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;

  const DashboardHeader({
    super.key,
    required this.greeting,
    required this.subtitle,
    this.unreadCount = 0,
    this.onNotifications,
    this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.kodiNavy, Color(0xFF001A33)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.kodiGreen.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                    child: const Center(child: Text('K', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.kodiGreen))),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KodiPay', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text('SECURE & ENCRYPTED', style: TextStyle(fontSize: 8, letterSpacing: 1, color: AppColors.kodiGreen)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  if (onNotifications != null)
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                          onPressed: onNotifications,
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 6, top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              child: Text('$unreadCount', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                            ),
                          ),
                      ],
                    ),
                  if (onProfile != null)
                    IconButton(
                      icon: const Icon(Icons.person_outline, color: Colors.white, size: 24),
                      onPressed: onProfile,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final String? change;

  const StatCard({super.key, required this.label, required this.value, required this.icon, this.color, this.change});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.kodiBlue;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: c.withValues(alpha: 0.7)),
              const Spacer(),
              if (change != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(999)),
                  child: Text(change!, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.success)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
        ],
      ),
    );
  }
}

class QuickActionGrid extends StatelessWidget {
  final List<QuickActionItem> actions;
  const QuickActionGrid({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: actions.map((a) => _QuickActionTile(action: a)).toList(),
    );
  }
}

class QuickActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const QuickActionItem(this.icon, this.label, this.color, this.onTap);
}

class _QuickActionTile extends StatelessWidget {
  final QuickActionItem action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 46) / 4,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: action.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: action.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(action.icon, color: action.color, size: 20),
                ),
                const SizedBox(height: 6),
                Text(action.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textDark), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const StatusPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionTitle({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}
