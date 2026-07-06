import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/badges_provider.dart';
import '../../widgets/badge_grid_item.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<BadgesProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final badges = context.watch<BadgesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Huy hiệu')),
      body: badges.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Đã mở khoá ${badges.unlockedCount}/${badges.totalCount} huy hiệu',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: badges.badges.length,
                    itemBuilder: (ctx, i) {
                      final item = badges.badges[i];
                      return BadgeGridItem(item: item, onTap: () => showBadgeDetailSheet(context, item));
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
