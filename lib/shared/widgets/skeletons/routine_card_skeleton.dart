import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Skeleton placeholder for routine cards while loading.
class RoutineCardSkeleton extends StatelessWidget {
  const RoutineCardSkeleton({super.key});

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
              // Icon placeholder
              Container(
                width: 56,
                height: 56,
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
                    // Routine name
                    Container(
                      width: 140,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.shimmerBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Exercise count
                    Container(
                      width: 90,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.shimmerBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),

              // Menu button placeholder
              Container(
                width: 32,
                height: 32,
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

/// A list of routine skeleton cards for loading state.
class RoutineListSkeleton extends StatelessWidget {
  final int itemCount;

  const RoutineListSkeleton({
    super.key,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: itemCount,
      itemBuilder: (context, index) => const RoutineCardSkeleton(),
    );
  }
}
