class StudentWalletModel {
  final String studentId;
  final double balance; // in Meal Credits
  final int rewardPoints;
  final int lastReloadedAt;

  const StudentWalletModel({
    required this.studentId,
    required this.balance,
    required this.rewardPoints,
    required this.lastReloadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'balance': balance,
      'reward_points': rewardPoints,
      'last_reloaded_at': lastReloadedAt,
    };
  }

  factory StudentWalletModel.fromMap(Map<String, dynamic> map) {
    return StudentWalletModel(
      studentId: map['student_id'] as String,
      balance: (map['balance'] as num).toDouble(),
      rewardPoints: (map['reward_points'] as num?)?.toInt() ?? 0,
      lastReloadedAt: (map['last_reloaded_at'] as num?)?.toInt() ?? 0,
    );
  }

  StudentWalletModel copyWith({
    String? studentId,
    double? balance,
    int? rewardPoints,
    int? lastReloadedAt,
  }) {
    return StudentWalletModel(
      studentId: studentId ?? this.studentId,
      balance: balance ?? this.balance,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      lastReloadedAt: lastReloadedAt ?? this.lastReloadedAt,
    );
  }
}
