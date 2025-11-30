educational_game_flutter/
│
├── lib/
│   ├── main.dart
│   │
│   ├── app/
│   │   ├── app.dart
│   │   ├── routes.dart
│   │   └── theme/
│   │       ├── app_colors.dart
│   │       ├── app_text_styles.dart
│   │       ├── app_theme.dart
│   │       └── app_animations.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   ├── asset_paths.dart
│   │   │   └── api_endpoints.dart
│   │   │
│   │   ├── errors/
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   │
│   │   ├── network/
│   │   │   ├── api_client.dart
│   │   │   └── network_info.dart
│   │   │
│   │   ├── utils/
│   │   │   ├── validators.dart
│   │   │   ├── formatters.dart
│   │   │   ├── sound_manager.dart
│   │   │   └── analytics_helper.dart
│   │   │
│   │   └── extensions/
│   │       ├── context_extensions.dart
│   │       ├── string_extensions.dart
│   │       └── datetime_extensions.dart
│   │
│   ├── data/
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   ├── lesson_model.dart
│   │   │   ├── question_model.dart
│   │   │   ├── progress_model.dart
│   │   │   ├── achievement_model.dart
│   │   │   └── leaderboard_model.dart
│   │   │
│   │   ├── repositories/
│   │   │   ├── auth_repository.dart
│   │   │   ├── lesson_repository.dart
│   │   │   ├── progress_repository.dart
│   │   │   └── user_repository.dart
│   │   │
│   │   └── datasources/
│   │       ├── local/
│   │       │   ├── local_storage.dart
│   │       │   └── hive_storage.dart
│   │       └── remote/
│   │           ├── api_service.dart
│   │           └── firebase_service.dart
│   │
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── user.dart
│   │   │   ├── lesson.dart
│   │   │   ├── question.dart
│   │   │   └── achievement.dart
│   │   │
│   │   └── usecases/
│   │       ├── auth/
│   │       │   ├── login_usecase.dart
│   │       │   └── register_usecase.dart
│   │       ├── lessons/
│   │       │   ├── get_lessons_usecase.dart
│   │       │   └── complete_lesson_usecase.dart
│   │       └── progress/
│   │           ├── update_progress_usecase.dart
│   │           └── get_streak_usecase.dart
│   │
│   ├── presentation/
│   │   ├── screens/
│   │   │   ├── splash/
│   │   │   │   ├── splash_screen.dart
│   │   │   │   └── widgets/
│   │   │   │
│   │   │   ├── onboarding/
│   │   │   │   ├── onboarding_screen.dart
│   │   │   │   └── widgets/
│   │   │   │
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── register_screen.dart
│   │   │   │   └── widgets/
│   │   │   │
│   │   │   ├── home/
│   │   │   │   ├── home_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── mascot_widget.dart
│   │   │   │       ├── streak_widget.dart
│   │   │   │       └── daily_goal_widget.dart
│   │   │   │
│   │   │   ├── lesson_map/
│   │   │   │   ├── lesson_map_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── lesson_node_widget.dart
│   │   │   │       ├── progress_path_widget.dart
│   │   │   │       └── unlock_animation_widget.dart
│   │   │   │
│   │   │   ├── gameplay/
│   │   │   │   ├── gameplay_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── question_card_widget.dart
│   │   │   │       ├── answer_option_widget.dart
│   │   │   │       ├── progress_bar_widget.dart
│   │   │   │       ├── timer_widget.dart
│   │   │   │       └── feedback_overlay_widget.dart
│   │   │   │
│   │   │   ├── results/
│   │   │   │   ├── results_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── score_animation_widget.dart
│   │   │   │       ├── xp_gained_widget.dart
│   │   │   │       └── celebration_widget.dart
│   │   │   │
│   │   │   ├── profile/
│   │   │   │   ├── profile_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── avatar_widget.dart
│   │   │   │       ├── stats_widget.dart
│   │   │   │       └── achievements_grid_widget.dart
│   │   │   │
│   │   │   ├── leaderboard/
│   │   │   │   ├── leaderboard_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── leaderboard_item_widget.dart
│   │   │   │       └── ranking_badge_widget.dart
│   │   │   │
│   │   │   ├── shop/
│   │   │   │   ├── shop_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── shop_item_widget.dart
│   │   │   │       └── currency_display_widget.dart
│   │   │   │
│   │   │   └── settings/
│   │   │       ├── settings_screen.dart
│   │   │       └── widgets/
│   │   │
│   │   ├── widgets/
│   │   │   ├── common/
│   │   │   │   ├── custom_button.dart
│   │   │   │   ├── custom_card.dart
│   │   │   │   ├── custom_dialog.dart
│   │   │   │   ├── loading_indicator.dart
│   │   │   │   └── error_widget.dart
│   │   │   │
│   │   │   ├── animations/
│   │   │   │   ├── bounce_animation.dart
│   │   │   │   ├── shake_animation.dart
│   │   │   │   ├── confetti_animation.dart
│   │   │   │   └── mascot_animation.dart
│   │   │   │
│   │   │   └── badges/
│   │   │       ├── achievement_badge.dart
│   │   │       └── level_badge.dart
│   │   │
│   │   └── providers/
│   │       ├── auth_provider.dart
│   │       ├── game_provider.dart
│   │       ├── progress_provider.dart
│   │       ├── sound_provider.dart
│   │       └── theme_provider.dart
│   │
│   └── l10n/
│       ├── app_en.arb
│       ├── app_pt.arb
│       └── app_es.arb
│
├── assets/
│   ├── images/
│   │   ├── mascot/
│   │   │   ├── mascot_idle.png
│   │   │   ├── mascot_happy.png
│   │   │   ├── mascot_sad.png
│   │   │   ├── mascot_celebrate.png
│   │   │   └── mascot_thinking.png
│   │   │
│   │   ├── backgrounds/
│   │   │   ├── home_bg.png
│   │   │   ├── lesson_map_bg.png
│   │   │   └── gameplay_bg.png
│   │   │
│   │   ├── icons/
│   │   │   ├── heart_icon.png
│   │   │   ├── gem_icon.png
│   │   │   ├── streak_icon.png
│   │   │   └── xp_icon.png
│   │   │
│   │   ├── badges/
│   │   │   ├── beginner_badge.png
│   │   │   ├── intermediate_badge.png
│   │   │   └── expert_badge.png
│   │   │
│   │   ├── avatars/
│   │   └── illustrations/
│   │
│   ├── audio/
│   │   ├── sfx/
│   │   │   ├── correct.mp3
│   │   │   ├── incorrect.mp3
│   │   │   ├── level_complete.mp3
│   │   │   ├── button_click.mp3
│   │   │   ├── achievement_unlock.mp3
│   │   │   └── streak_milestone.mp3
│   │   │
│   │   ├── music/
│   │   │   ├── menu_theme.mp3
│   │   │   └── gameplay_theme.mp3
│   │   │
│   │   └── voice/
│   │       ├── instructions/
│   │       └── feedback/
│   │
│   ├── fonts/
│   │   ├── DINRoundPro-Bold.ttf
│   │   ├── DINRoundPro-Regular.ttf
│   │   └── DINRoundPro-Medium.ttf
│   │
│   ├── lottie/
│   │   ├── celebration.json
│   │   ├── loading.json
│   │   ├── confetti.json
│   │   └── success.json
│   │
│   └── data/
│       ├── lessons/
│       │   ├── lesson_1.json
│       │   ├── lesson_2.json
│       │   └── lessons_index.json
│       │
│       ├── questions/
│       │   ├── multiple_choice/
│       │   ├── fill_blank/
│       │   ├── matching/
│       │   └── pronunciation/
│       │
│       └── achievements/
│           └── achievements.json
│
├── test/
│   ├── unit/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── widget/
│   │   └── screens/
│   │
│   └── integration/
│       └── gameplay_flow_test.dart
│
├── docs/
│   ├── architecture.md
│   ├── design_system.md
│   ├── api_documentation.md
│   └── contributing.md
│
├── android/
├── ios/
├── web/
├── macos/
├── windows/
├── linux/
│
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── deploy.yml
│
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
├── .gitignore
└── .env.example