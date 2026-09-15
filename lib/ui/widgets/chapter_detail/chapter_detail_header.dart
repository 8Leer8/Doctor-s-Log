import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/chapter_preview.dart';
import '../../../utils/act_type_formatter.dart';

class ChapterDetailHeader extends StatelessWidget {
  final ChapterPreview chapter;
  final String? description;
  final bool descriptionLoaded;

  const ChapterDetailHeader({
    super.key,
    required this.chapter,
    required this.description,
    required this.descriptionLoaded,
  });

  @override
  Widget build(BuildContext context) {
    final formattedType = formatActType(chapter.subtitle);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black54, Colors.black87],
          stops: [0.0, 0.3, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            chapter.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formattedType.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
              color: AppColors.amber,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            descriptionLoaded && description != null
                ? description!
                : (descriptionLoaded ? 'No description available.' : ''),
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: (descriptionLoaded && description == null)
                  ? Colors.white60
                  : Colors.white.withValues(alpha: 0.9),
              fontStyle: (descriptionLoaded && description == null)
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}