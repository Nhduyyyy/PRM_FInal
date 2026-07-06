import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/profile_provider.dart';

class NotificationSettingsSheet extends StatelessWidget {
  const NotificationSettingsSheet({super.key});

  Future<void> _pickTime(BuildContext context, ProfileProvider provider, String current) async {
    final parts = current.split(':');
    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    await provider.setDailyReminder(enabled: true, time: formatted);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final user = profile.profile;
    final dailyEnabled = user?.dailyReminderEnabled ?? false;
    final time = user?.dailyReminderTime ?? '18:00';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Thông báo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Nhắc nhở hằng ngày'),
              subtitle: Text(dailyEnabled ? 'Lúc $time' : 'Đang tắt'),
              value: dailyEnabled,
              onChanged: (v) => profile.setDailyReminder(enabled: v, time: time),
            ),
            if (dailyEnabled)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _pickTime(context, profile, time),
                  icon: const Icon(Icons.access_time),
                  label: const Text('Chọn giờ nhắc'),
                ),
              ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Nhắc khi gần đạt mục tiêu tuần'),
              value: user?.goalReminderEnabled ?? false,
              onChanged: (v) => profile.setGoalReminder(v),
            ),
          ],
        ),
      ),
    );
  }
}
