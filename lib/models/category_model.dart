import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class CategoryModel {
  final String id;
  final String title;
  final String subtitle;
  final String bannerAsset;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final int totalQuestions;

  const CategoryModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.bannerAsset,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    this.totalQuestions = 100,
  });

  static List<CategoryModel> defaultCategories = const [
    CategoryModel(
      id: 'movies',
      title: 'Bollywood & Cinema',
      subtitle: 'Blockbusters, Dialogues & Stars',
      bannerAsset: 'assets/images/category_movies.png',
      icon: Icons.movie_creation_rounded,
      primaryColor: AppColors.catMoviesPrimary,
      secondaryColor: AppColors.catMoviesSecondary,
      totalQuestions: 100,
    ),
    CategoryModel(
      id: 'gk',
      title: 'General Knowledge',
      subtitle: 'India, World History & Global Facts',
      bannerAsset: 'assets/images/category_gk.png',
      icon: Icons.public_rounded,
      primaryColor: AppColors.catGkPrimary,
      secondaryColor: AppColors.catGkSecondary,
      totalQuestions: 100,
    ),
    CategoryModel(
      id: 'science',
      title: 'Science & Technology',
      subtitle: 'Space, AI, Physics & Modern Tech',
      bannerAsset: 'assets/images/category_science.png',
      icon: Icons.biotech_rounded,
      primaryColor: AppColors.catSciencePrimary,
      secondaryColor: AppColors.catScienceSecondary,
      totalQuestions: 100,
    ),
    CategoryModel(
      id: 'math',
      title: 'Mathematics & Reasoning',
      subtitle: 'Logic Puzzles, Patterns & Mental Math',
      bannerAsset: 'assets/images/category_math.png',
      icon: Icons.calculate_rounded,
      primaryColor: AppColors.catMathPrimary,
      secondaryColor: AppColors.catMathSecondary,
      totalQuestions: 100,
    ),
    CategoryModel(
      id: 'sports',
      title: 'Sports & Entertainment',
      subtitle: 'Cricket, Movies, Music & Champions',
      bannerAsset: 'assets/images/category_sports.png',
      icon: Icons.emoji_events_rounded,
      primaryColor: AppColors.catSportsPrimary,
      secondaryColor: AppColors.catSportsSecondary,
      totalQuestions: 100,
    ),
    CategoryModel(
      id: 'image',
      title: 'Image Quiz & Mystery',
      subtitle: 'Guess Landmarks, Logos & Puzzles',
      bannerAsset: 'assets/images/category_image.png',
      icon: Icons.image_search_rounded,
      primaryColor: AppColors.catImagePrimary,
      secondaryColor: AppColors.catImageSecondary,
      totalQuestions: 100,
    ),
  ];
}
