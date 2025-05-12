import 'package:flutter/material.dart';
import 'package:rivil/core/config/app_colors.dart';

class RatingSelector extends StatelessWidget {
  final double initialRating;
  final ValueChanged<double> onRatingChanged;
  final int itemCount;
  final double itemSize;
  final bool allowHalfRating;

  const RatingSelector({
    super.key,
    this.initialRating = 0.0,
    required this.onRatingChanged,
    this.itemCount = 5,
    this.itemSize = 36.0,
    this.allowHalfRating = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rating',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRatingBar(context),
              const SizedBox(width: 16),
              Text(
                initialRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(BuildContext context) {
    final List<Widget> stars = [];

    for (int i = 1; i <= itemCount; i++) {
      final starPosition = i.toDouble();
      final isHalfStar =
          initialRating >= (starPosition - 0.5) && initialRating < starPosition;
      final isFullStar = initialRating >= starPosition;

      stars.add(
        GestureDetector(
          onTap: () => onRatingChanged(starPosition),
          onHorizontalDragUpdate: allowHalfRating
              ? (details) {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final localPosition =
                      box.globalToLocal(details.globalPosition);
                  final starWidth = itemSize;
                  final starStart = i * starWidth - starWidth;
                  final starEnd = i * starWidth;
                  final starCenter = (starStart + starEnd) / 2;

                  if (localPosition.dx < starCenter &&
                      localPosition.dx > starStart) {
                    onRatingChanged(i - 0.5);
                  } else if (localPosition.dx > starCenter &&
                      localPosition.dx < starEnd) {
                    onRatingChanged(i.toDouble());
                  }
                }
              : null,
          child: Icon(
            isFullStar
                ? Icons.star_rounded
                : isHalfStar
                    ? Icons.star_half_rounded
                    : Icons.star_border_rounded,
            color: AppColors.primary,
            size: itemSize,
          ),
        ),
      );
    }

    return Row(children: stars);
  }
}
