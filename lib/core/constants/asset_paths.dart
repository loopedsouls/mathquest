/// Asset paths for the application
class AssetPaths {
  AssetPaths._();

  // Base paths
  static const String _images = 'assets/images';
  static const String _audio = 'assets/audio';
  static const String _lottie = 'assets/lottie';
  static const String _data = 'assets/data';
  static const String _models = 'assets/models';

  // Mascot images
  static const String mascotIdle = '$_images/mascot/mascot_idle.png';
  static const String mascotHappy = '$_images/mascot/mascot_happy.png';
  static const String mascotSad = '$_images/mascot/mascot_sad.png';
  static const String mascotCelebrate = '$_images/mascot/mascot_celebrate.png';
  static const String mascotThinking = '$_images/mascot/mascot_thinking.png';

  // Background images
  static const String homeBg = '$_images/backgrounds/home_bg.png';
  static const String lessonMapBg = '$_images/backgrounds/lesson_map_bg.png';
  static const String gameplayBg = '$_images/backgrounds/gameplay_bg.png';

  // Icons
  static const String heartIcon = '$_images/icons/heart_icon.png';
  static const String gemIcon = '$_images/icons/gem_icon.png';
  static const String streakIcon = '$_images/icons/streak_icon.png';
  static const String xpIcon = '$_images/icons/xp_icon.png';

  // Badges
  static const String beginnerBadge = '$_images/badges/beginner_badge.png';
  static const String intermediateBadge = '$_images/badges/intermediate_badge.png';
  static const String expertBadge = '$_images/badges/expert_badge.png';

  // Sound effects
  static const String correctSound = '$_audio/sfx/correct.mp3';
  static const String incorrectSound = '$_audio/sfx/incorrect.mp3';
  static const String levelCompleteSound = '$_audio/sfx/level_complete.mp3';
  static const String buttonClickSound = '$_audio/sfx/button_click.mp3';
  static const String achievementUnlockSound = '$_audio/sfx/achievement_unlock.mp3';
  static const String streakMilestoneSound = '$_audio/sfx/streak_milestone.mp3';

  // Music
  static const String menuTheme = '$_audio/music/menu_theme.mp3';
  static const String gameplayTheme = '$_audio/music/gameplay_theme.mp3';

  // Lottie animations
  static const String celebrationLottie = '$_lottie/celebration.json';
  static const String loadingLottie = '$_lottie/loading.json';
  static const String confettiLottie = '$_lottie/confetti.json';
  static const String successLottie = '$_lottie/success.json';

  // Data files
  static const String lessonsIndex = '$_data/lessons/lessons_index.json';
  static const String achievementsData = '$_data/achievements/achievements.json';

  // AI Models
  static const String gemmaModel = '$_models/gemma-2b-it-int4.tflite';
}
