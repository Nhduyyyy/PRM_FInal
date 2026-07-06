import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/goals_provider.dart';
import '../../state/profile_provider.dart';
import '../home/home_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _IntroSlide {
  final IconData icon;
  final String title;
  final String description;
  const _IntroSlide(this.icon, this.title, this.description);
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String _unit = 'km';

  String _goalType = 'weekly';
  double _targetKm = 20;

  bool _saving = false;

  static const _slides = [
    _IntroSlide(Icons.directions_run, 'Theo dõi mọi buổi chạy',
        'Ghi lại quãng đường, thời gian và pace bằng GPS cho từng buổi chạy bộ.'),
    _IntroSlide(Icons.flag_circle, 'Đặt mục tiêu, giữ streak',
        'Đặt mục tiêu km theo tuần/tháng và duy trì chuỗi ngày chạy liên tục.'),
    _IntroSlide(Icons.emoji_events, 'Mở khoá huy hiệu',
        'Xem tiến bộ theo thời gian và mở khoá huy hiệu khi đạt cột mốc mới.'),
  ];

  static final int _totalPages = _slides.length + 2;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  bool get _canProceedFromProfile => _nameController.text.trim().isNotEmpty;

  void _next() {
    if (_page < _totalPages - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  void _skipIntro() {
    _pageController.animateToPage(
      _slides.length,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final profileProvider = context.read<ProfileProvider>();
    final goalsProvider = context.read<GoalsProvider>();

    await profileProvider.createProfile(
      name: _nameController.text.trim(),
      weightKg: double.tryParse(_weightController.text) ?? 60,
      heightCm: double.tryParse(_heightController.text) ?? 170,
      unit: _unit,
    );
    await goalsProvider.createGoal(type: _goalType, targetKm: _targetKm);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_page < _slides.length)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(onPressed: _skipIntro, child: const Text('Bỏ qua')),
                ),
              )
            else
              const SizedBox(height: 48),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  for (final slide in _slides) _IntroPage(slide: slide),
                  _ProfilePage(
                    nameController: _nameController,
                    weightController: _weightController,
                    heightController: _heightController,
                    unit: _unit,
                    onUnitChanged: (u) => setState(() => _unit = u),
                    onChanged: () => setState(() {}),
                  ),
                  _GoalPage(
                    goalType: _goalType,
                    targetKm: _targetKm,
                    onTypeChanged: (t) => setState(() => _goalType = t),
                    onTargetChanged: (v) => setState(() => _targetKm = v),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: (_page == _slides.length && !_canProceedFromProfile) || _saving
                        ? null
                        : _next,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_page == _totalPages - 1 ? 'Hoàn tất' : 'Tiếp theo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final _IntroSlide slide;
  const _IntroPage({required this.slide});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
            child: Icon(slide.icon, size: 80, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 40),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController weightController;
  final TextEditingController heightController;
  final String unit;
  final ValueChanged<String> onUnitChanged;
  final VoidCallback onChanged;

  const _ProfilePage({
    required this.nameController,
    required this.weightController,
    required this.heightController,
    required this.unit,
    required this.onUnitChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Thiết lập hồ sơ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          TextField(
            controller: nameController,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(labelText: 'Tên của bạn'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Cân nặng (kg)'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Chiều cao (cm)'),
          ),
          const SizedBox(height: 20),
          Center(
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'km', label: Text('Km')),
                ButtonSegment(value: 'miles', label: Text('Miles')),
              ],
              selected: {unit},
              onSelectionChanged: (s) => onUnitChanged(s.first),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  final String goalType;
  final double targetKm;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<double> onTargetChanged;

  const _GoalPage({
    required this.goalType,
    required this.targetKm,
    required this.onTypeChanged,
    required this.onTargetChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Mục tiêu chạy bộ của bạn là gì?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _GoalTypeCard(
                  label: 'Theo tuần',
                  selected: goalType == 'weekly',
                  onTap: () => onTypeChanged('weekly'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GoalTypeCard(
                  label: 'Theo tháng',
                  selected: goalType == 'monthly',
                  onTap: () => onTypeChanged('monthly'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text('${targetKm.round()} km', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
          Slider(
            value: targetKm,
            min: 5,
            max: goalType == 'weekly' ? 50 : 200,
            divisions: 45,
            activeColor: scheme.primary,
            onChanged: onTargetChanged,
          ),
        ],
      ),
    );
  }
}

class _GoalTypeCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GoalTypeCard({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? scheme.primary : Colors.transparent, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
