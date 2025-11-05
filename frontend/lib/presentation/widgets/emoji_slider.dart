import 'package:flutter/material.dart';
import 'package:sana_app/core/theme/app_colors.dart';

class EmojiSlider extends StatefulWidget {
  final String label;
  final List<String> emojis;
  final int value;
  final Function(int) onChanged;

  const EmojiSlider({
    super.key,
    required this.label,
    required this.emojis,
    required this.value,
    required this.onChanged,
  });

  @override
  State<EmojiSlider> createState() => _EmojiSliderState();
}

class _EmojiSliderState extends State<EmojiSlider> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              widget.emojis[widget.value - 1],
              style: const TextStyle(fontSize: 32),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final value = index + 1;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  widget.onChanged(value);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: widget.value == value
                        ? AppColors.primary.withOpacity(0.1)
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.value == value
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.emojis[index],
                      style: TextStyle(
                        fontSize: widget.value == value ? 32 : 24,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '5',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}
