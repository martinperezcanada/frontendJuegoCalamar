import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class MatchCardSkeleton extends StatelessWidget {
  const MatchCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _circle(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _rect(width: 40, height: 14),
                const SizedBox(height: 4),
                _rect(width: 30, height: 12),
              ],
            ),
            _circle(),
          ],
        ),
      ),
    );
  }

  Widget _circle() => Container(
    width: 40,
    height: 40,
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
    ),
  );

  Widget _rect({required double width, required double height}) =>
      Container(width: width, height: height, color: Colors.white);
}
