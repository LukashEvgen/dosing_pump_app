import 'package:flutter/material.dart';
import '../models/pump_schedule.dart';
import '../theme.dart';

class ScheduleTile extends StatelessWidget {
  final PumpSchedule schedule;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const ScheduleTile({
    super.key,
    required this.schedule,
    required this.onTap,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(schedule.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.danger.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.danger),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Видалити розклад?'),
            content: Text('«${schedule.name}» буде видалено.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Скасувати'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                    foregroundColor: AppTheme.danger),
                child: const Text('Видалити'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        child: InkWell(
          onTap: schedule.enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Time circle
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: schedule.enabled
                        ? AppTheme.primary.withValues(alpha: 0.2)
                        : AppTheme.surfaceCard,
                    border: Border.all(
                      color: schedule.enabled
                          ? AppTheme.accent.withValues(alpha: 0.5)
                          : AppTheme.onSurfaceMuted.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      schedule.time.formatted,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: schedule.enabled
                            ? AppTheme.accent
                            : AppTheme.onSurfaceMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: schedule.enabled
                              ? AppTheme.onSurface
                              : AppTheme.onSurfaceMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.repeat,
                            size: 13,
                            color: AppTheme.onSurfaceMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            schedule.daysLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurfaceMuted,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.water_drop_outlined,
                            size: 13,
                            color: AppTheme.onSurfaceMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${schedule.volumeMl} мл',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Toggle
                Switch(
                  value: schedule.enabled,
                  onChanged: onToggle,
                  activeThumbColor: AppTheme.accent,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
