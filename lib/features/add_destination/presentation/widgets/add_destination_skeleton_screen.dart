import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AddDestinationSkeletonScreen extends StatelessWidget {
  const AddDestinationSkeletonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Picker Skeleton
            Container(
              height: 220,
              width: double.infinity,
              color: Colors.white,
            ),

            // Content Container
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Title - Basic Information
                  _buildSectionTitleSkeleton(),
                  const SizedBox(height: 16),

                  // Name Field
                  _buildInputFieldSkeleton(),

                  // Google Maps Link Field
                  _buildInputFieldSkeleton(),

                  // Category Selector
                  _buildCategorySelectorSkeleton(),

                  // Description Field (taller)
                  _buildInputFieldSkeleton(height: 120),

                  // Section Title - Location
                  _buildSectionTitleSkeleton(),
                  const SizedBox(height: 16),

                  // Address Field
                  _buildInputFieldSkeleton(),

                  // Map Location Picker Label
                  Container(
                    width: 100,
                    height: 20,
                    margin: const EdgeInsets.only(top: 8, bottom: 4),
                    color: Colors.white,
                  ),

                  // Map Location Picker
                  Container(
                    height: 315,
                    margin: const EdgeInsets.only(top: 8, bottom: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                    ),
                  ),

                  // Submit Button
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitleSkeleton() {
    return Container(
      width: 120,
      height: 24,
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      color: Colors.white,
    );
  }

  Widget _buildInputFieldSkeleton({double height = 60}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Container(
            width: 80,
            height: 18,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          // Input field
          Container(
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelectorSkeleton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Container(
            width: 80,
            height: 18,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          // Dropdown field
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}
