enum AchievementType {
  moduleComplete, // Complete a specific module
  unitComplete, // Complete an entire thematic unit
  levelReached, // Reach a level (Intermediate, Advanced, etc.)
  exerciseStreak, // Sequence of correct exercises
  totalScore, // Reach total points
  recordTime, // Solve exercise quickly
  perfectionist, // 100% accuracy in a module
  persistent, // Complete exercises several days in a row
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final AchievementType type;
  final Map<String, dynamic> criteria;
  final int bonusPoints;
  final DateTime? unlockDate;
  final bool unlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.type,
    required this.criteria,
    this.bonusPoints = 0,
    this.unlockDate,
    this.unlocked = false,
  });

  Achievement copyWith({
    DateTime? unlockDate,
    bool? unlocked,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      emoji: emoji,
      type: type,
      criteria: criteria,
      bonusPoints: bonusPoints,
      unlockDate: unlockDate ?? this.unlockDate,
      unlocked: unlocked ?? this.unlocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'emoji': emoji,
      'type': type.index,
      'criteria': criteria,
      'bonusPoints': bonusPoints,
      'unlockDate': unlockDate?.toIso8601String(),
      'unlocked': unlocked,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      emoji: json['emoji'],
      type: AchievementType.values[json['type']],
      criteria: Map<String, dynamic>.from(json['criteria']),
      bonusPoints: json['bonusPoints'] ?? 0,
      unlockDate: json['unlockDate'] != null
          ? DateTime.parse(json['unlockDate'])
          : null,
      unlocked: json['unlocked'] ?? false,
    );
  }
}

class AchievementsData {
  static final List<Achievement> _baseAchievements = [
    // Achievements for module completion
    Achievement(
      id: 'first_module',
      title: 'First Step',
      description: 'Complete your first module',
      emoji: 'models/Primeiro-Passo.svg',
      type: AchievementType.moduleComplete,
      criteria: {'quantity': 1},
      bonusPoints: 50,
    ),
    Achievement(
      id: 'ten_modules',
      title: 'Dedicated',
      description: 'Complete 10 modules',
      emoji: 'models/Dedicado.svg',
      type: AchievementType.moduleComplete,
      criteria: {'quantity': 10},
      bonusPoints: 200,
    ),

    // Achievements for unit completion
    Achievement(
      id: 'numbers_complete',
      title: 'Numbers Master',
      description: 'Complete the entire Numbers unit',
      emoji: 'models/Mestre-dos-números.svg',
      type: AchievementType.unitComplete,
      criteria: {'unit': 'Números'},
      bonusPoints: 300,
    ),
    Achievement(
      id: 'algebra_complete',
      title: 'Algebraist',
      description: 'Complete the entire Algebra unit',
      emoji: 'models/Algebrista.svg',
      type: AchievementType.unitComplete,
      criteria: {'unit': 'Álgebra'},
      bonusPoints: 300,
    ),
    Achievement(
      id: 'geometry_complete',
      title: 'Geometer',
      description: 'Complete the entire Geometry unit',
      emoji: 'models/Geômetra.svg',
      type: AchievementType.unitComplete,
      criteria: {'unit': 'Geometria'},
      bonusPoints: 300,
    ),
    Achievement(
      id: 'measurements_complete',
      title: 'Measurement Expert',
      description: 'Complete the entire Measurements and Quantities unit',
      emoji: 'models/MEdidor-Expert.svg',
      type: AchievementType.unitComplete,
      criteria: {'unit': 'Grandezas e Medidas'},
      bonusPoints: 300,
    ),
    Achievement(
      id: 'probability_complete',
      title: 'Statistician',
      description: 'Complete the entire Probability and Statistics unit',
      emoji: 'models/Estatistico.svg',
      type: AchievementType.unitComplete,
      criteria: {'unit': 'Probabilidade e Estatística'},
      bonusPoints: 300,
    ),

    // Level achievements
    Achievement(
      id: 'intermediate_level',
      title: 'Evolving',
      description: 'Reach Intermediate level',
      emoji: 'models/Evoluindo.svg',
      type: AchievementType.levelReached,
      criteria: {'level': 1}, // UserLevel.intermediate.index
      bonusPoints: 150,
    ),
    Achievement(
      id: 'advanced_level',
      title: 'Progressing',
      description: 'Reach Advanced level',
      emoji: 'models/Progredidndo.svg',
      type: AchievementType.levelReached,
      criteria: {'level': 2}, // UserLevel.advanced.index
      bonusPoints: 300,
    ),

    // Special achievements
    Achievement(
      id: 'first_exercise',
      title: 'First Exercise',
      description: 'Complete your first exercise',
      emoji: 'models/Primeiro-Passo.svg',
      type: AchievementType.moduleComplete,
      criteria: {'completed_exercises': 1},
      bonusPoints: 25,
    ),

    // Special BNCC achievement
    Achievement(
      id: 'bncc_master',
      title: 'BNCC Master',
      description: 'Master all BNCC objectives for your school year',
      emoji: 'models/Mestre-BNCC.svg',
      type: AchievementType.unitComplete,
      criteria: {'bncc_objectives_complete': true},
      bonusPoints: 1000,
    ),
  ];

  static List<Achievement> getAllAchievements() {
    return List.from(_baseAchievements);
  }

  static List<Achievement> getAchievementsByType(AchievementType type) {
    return _baseAchievements.where((a) => a.type == type).toList();
  }

  static Achievement? getAchievementById(String id) {
    try {
      return _baseAchievements.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<Achievement> getUnlockedAchievements(List<String> unlockedIds) {
    return _baseAchievements
        .where((a) => unlockedIds.contains(a.id))
        .map((a) => a.copyWith(unlocked: true))
        .toList();
  }

  static List<Achievement> getLockedAchievements(List<String> unlockedIds) {
    return _baseAchievements.where((a) => !unlockedIds.contains(a.id)).toList();
  }
}
