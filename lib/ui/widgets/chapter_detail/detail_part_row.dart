import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/story_part.dart';

class DetailPartRow extends StatelessWidget {
  final StoryPart part;
  final bool finished;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  const DetailPartRow({
    super.key,
    required this.part,
    required this.finished,
    required this.onToggle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: Icon(
                finished ? Icons.check_circle : Icons.circle_outlined,
                size: 20,
                color: finished ? Colors.green.shade400 : AppColors.coldGray,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                part.title,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              ),
            ),
            if (part.filename == null)
              const Icon(Icons.cloud_off, size: 14, color: AppColors.coldGray),
          ],
        ),
      ),
    );
  }
}