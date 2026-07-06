import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late String _unit;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>().profile;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _weightController = TextEditingController(text: profile?.weightKg.toString() ?? '');
    _heightController = TextEditingController(text: profile?.heightCm.toString() ?? '');
    _unit = profile?.unit ?? 'km';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = context.read<ProfileProvider>();
    final current = provider.profile;
    if (current == null) return;

    await provider.updateProfile(current.copyWith(
      name: _nameController.text.trim(),
      weightKg: double.tryParse(_weightController.text) ?? current.weightKg,
      heightCm: double.tryParse(_heightController.text) ?? current.heightCm,
      unit: _unit,
    ));

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Tên')),
          const SizedBox(height: 14),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Cân nặng (kg)'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Chiều cao (cm)'),
          ),
          const SizedBox(height: 20),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'km', label: Text('Km')),
              ButtonSegment(value: 'miles', label: Text('Miles')),
            ],
            selected: {_unit},
            onSelectionChanged: (s) => setState(() => _unit = s.first),
          ),
          const SizedBox(height: 28),
          ElevatedButton(onPressed: _save, child: const Text('Lưu thay đổi')),
        ],
      ),
    );
  }
}
