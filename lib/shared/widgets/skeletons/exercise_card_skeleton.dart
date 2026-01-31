import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Skeleton placeholder for exercise cards while loading.
class ExerciseCardSkeleton extends StatelessWidget {
  const ExerciseCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.shimmerBase,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),

              // Info placeholder
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Container(
                      width: double.infinity,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.shimmerBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Muscle group badge
                    Container(
                      width: 80,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.shimmerBase,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Arrow placeholder
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.shimmerBase,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A list of skeleton cards for loading state.
class ExerciseListSkeleton extends StatelessWidget {
  final int itemCount;

  const ExerciseListSkeleton({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ExerciseCardSkeleton(),
    );
  }
}
