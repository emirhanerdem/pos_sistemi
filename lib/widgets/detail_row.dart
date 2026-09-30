import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class DetailSectionTitle extends StatelessWidget {
  final String title;
  const DetailSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final Widget? value;
  final String? text;
  final bool highlight;
  final bool bold;

  const DetailRow({
    super.key,
    required this.label,
    required Widget this.value,
    this.highlight = false,
  })  : text = null,
        bold = false;

  const DetailRow.text(
    this.label,
    this.text, {
    super.key,
    this.highlight = false,
    this.bold = false,
  }) : value = null;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accentColor = highlight ? context.accent : palette.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                color: accentColor,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(':  ', style: TextStyle(color: palette.textSecondary)),
          Expanded(
            child: value ??
                Text(
                  text!,
                  style: TextStyle(
                    fontWeight: (highlight || bold)
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: accentColor,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
