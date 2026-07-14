import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/activity_dao.dart';
import '../../state/badges_provider.dart';
import '../../state/profile_provider.dart';
import '../../utils/export_util.dart';
import '../backup/backup_restore_screen.dart';
import '../badges/badges_screen.dart';
import '../goals/goals_screen.dart';
import 'edit_profile_screen.dart';
import 'notification_settings_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double _totalKm = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    context.read<BadgesProvider>().load();
    final total = await ActivityDao().getTotalDistance();
    if (mounted) setState(() => _totalKm = total);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final badges = context.watch<BadgesProvider>();
    final scheme = Theme.of(context).colorScheme;
    final user = profile.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 32, color: scheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user?.name ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _QuickStat(label: 'Tổng km', value: _totalKm.toStringAsFixed(1)),
              _QuickStat(label: 'Streak tốt nhất', value: '${profile.streak.bestStreak}'),
              _QuickStat(label: 'Huy hiệu', value: '${badges.unlockedCount}/${badges.totalCount}'),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsTile(
            icon: Icons.edit_outlined,
            label: 'Chỉnh sửa hồ sơ',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
          ),
          _SettingsTile(
            icon: Icons.flag_outlined,
            label: 'Mục tiêu',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GoalsScreen())),
          ),
          _SettingsTile(
            icon: Icons.emoji_events_outlined,
            label: 'Huy hiệu',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BadgesScreen())),
          ),
          _SettingsTile(
            icon: Icons.straighten_outlined,
            label: 'Đơn vị đo',
            trailing: Text(user?.unit == 'miles' ? 'Miles' : 'Km'),
            onTap: () => profile.setUnit(user?.unit == 'miles' ? 'km' : 'miles'),
          ),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            label: 'Giao diện',
            trailing: Text(_themeLabel(user?.themeMode)),
            onTap: () => _showThemeDialog(context, profile),
          ),
          _SettingsTile(
            icon: Icons.notifications_active_outlined,
            label: 'Nhắc nhở chạy bộ',
            onTap: () => showModalBottomSheet(
              context: context,
              showDragHandle: true,
              builder: (_) => const NotificationSettingsSheet(),
            ),
          ),
          _SettingsTile(
            icon: Icons.ios_share_outlined,
            label: 'Xuất dữ liệu',
            onTap: () => _showExportSheet(context),
          ),
          _SettingsTile(
            icon: Icons.settings_backup_restore_outlined,
            label: 'Sao lưu & Khôi phục',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            label: 'Về ứng dụng',
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Run Tracker',
              applicationVersion: '1.0.0',
              children: const [Text('Ứng dụng theo dõi chạy bộ cá nhân, hoạt động hoàn toàn offline.')],
            ),
          ),
        ],
      ),
    );
  }

  String _themeLabel(String? mode) {
    switch (mode) {
      case 'light':
        return 'Sáng';
      case 'dark':
        return 'Tối';
      default:
        return 'Theo hệ thống';
    }
  }

  void _showThemeDialog(BuildContext context, ProfileProvider profile) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Giao diện'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              profile.setThemeMode('system');
              Navigator.pop(ctx);
            },
            child: const Text('Theo hệ thống'),
          ),
          SimpleDialogOption(
            onPressed: () {
              profile.setThemeMode('light');
              Navigator.pop(ctx);
            },
            child: const Text('Sáng'),
          ),
          SimpleDialogOption(
            onPressed: () {
              profile.setThemeMode('dark');
              Navigator.pop(ctx);
            },
            child: const Text('Tối'),
          ),
        ],
      ),
    );
  }

  void _showExportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Xuất dạng JSON'),
              onTap: () async {
                Navigator.pop(ctx);
                await _exportJson();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Xuất dạng CSV'),
              onTap: () async {
                Navigator.pop(ctx);
                await _exportCsv();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportJson() => ExportUtil.exportAsJson();

  Future<void> _exportCsv() => ExportUtil.exportAsCsv();
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  const _QuickStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.label, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
