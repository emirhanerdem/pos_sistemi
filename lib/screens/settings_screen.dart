import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import '../theme/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final controller = ThemeController.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Görünüm',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Uygulamanın temasını seçin.',
            style: TextStyle(color: palette.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: AppThemeOption.values
                .map(
                  (option) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _ThemeCard(
                        option: option,
                        selected: controller.option == option,
                        onTap: () => controller.setOption(option),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 32),
          const Text(
            'Vurgu / Menü Rengi',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Alt menü, düğmeler ve başlıklarda kullanılan rengi seçin.',
            style: TextStyle(color: palette.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: kAccentColorOptions
                .map(
                  (color) => _AccentSwatch(
                    color: color,
                    selected: color.toARGB32() ==
                        controller.accent.toARGB32(),
                    onTap: () => controller.setAccent(color),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final AppThemeOption option;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final preview = AppPalette.forOption(option, context.accent);
    final accent = context.accent;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 84,
            decoration: BoxDecoration(
              color: preview.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? accent : context.palette.border,
                width: selected ? 2.4 : 1.2,
              ),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 6,
                  decoration: BoxDecoration(
                    color: preview.surface,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 40,
                  height: 6,
                  decoration: BoxDecoration(
                    color: preview.surface,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            option.label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? accent : context.palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _AccentSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? context.palette.textPrimary : Colors.transparent,
            width: 2.4,
          ),
        ),
        alignment: Alignment.center,
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 22)
            : null,
      ),
    );
  }
}
