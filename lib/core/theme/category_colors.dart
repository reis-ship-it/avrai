import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';

class CategoryStyles {
  static Color colorFor(String category) {
    switch (category.toLowerCase()) {
      case 'restaurant':
        return AppColors.error;
      case 'cafe':
        return AppColors.grey700;
      case 'bar':
        return AppColors.grey600;
      case 'shop':
        return AppColors.grey500;
      case 'park':
        return AppColors.success;
      case 'museum':
        return AppColors.warning;
      case 'theater':
        return AppColors.grey600;
      case 'hotel':
        return AppColors.grey500;
      case 'landmark':
        return AppColors.grey600;
      default:
        return AppColors.grey600;
    }
  }

  static IconData iconFor(String category) {
    switch (category.toLowerCase()) {
      case 'restaurant':
        return Icons.restaurant;
      case 'cafe':
        return Icons.coffee;
      case 'bar':
        return Icons.local_bar;
      case 'shop':
        return Icons.storefront;
      case 'park':
        return Icons.park;
      case 'museum':
        return Icons.museum;
      case 'theater':
        return Icons.theaters;
      case 'hotel':
        return Icons.hotel;
      case 'landmark':
        return Icons.assistant_photo;
      default:
        return Icons.place;
    }
  }
}


