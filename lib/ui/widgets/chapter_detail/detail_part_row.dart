import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/story_part.dart';

class DetailPartRow extends StatelessWidget {
  final StoryPart part;
  final bool finished;
  final bool downloaded;
  final VoidCallback onToggleFinished;
  final VoidCallback onToggleDownload;
  final VoidCallback onOpen;

  const DetailPartRow({
    super.key,
    required this.part,
    required this.finished,
    required this.downloaded,
    required this.onToggleFinished,
    required this.onToggleDownload,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggleFinished,
              child: Icon(
                finished ? Icons.check_circle : Icons.circle_outlined,
                size: 22,
                color: finished ? Colors.green.shade400 : AppColors.coldGray,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    part.title,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  ),
                  if (part.releaseDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatDate(part.releaseDate!),
                        style: const TextStyle(fontSize: 11, color: AppColors.coldGray),
                      ),
                    ),
                ],
              ),
            ),
            if (part.filename == null)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.cloud_off, size: 14, color: AppColors.coldGray),
              ),
            GestureDetector(
              onTap: onToggleDownload,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  downloaded ? Icons.check_circle_outline : Icons.download_outlined,
                  size: 22,
                  color: downloaded ? AppColors.amber : AppColors.coldGray,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}