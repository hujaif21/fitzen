class HomeResponse {
  String status;
  HomeData? data;

  HomeResponse({
    this.status = '',
    this.data,
  });

  factory HomeResponse.fromJson(
      Map<String, dynamic> json,
      ) {
    return HomeResponse(
      status: json['status']?.toString() ?? '',
      data: json['data'] is Map<String, dynamic>
          ? HomeData.fromJson(
        json['data'] as Map<String, dynamic>,
      )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data?.toJson(),
    };
  }
}

class HomeData {
  String name;

  num caloriesConsumed;
  num calorieTarget;

  num proteinConsumed;
  num proteinTarget;

  num carbsConsumed;
  num carbsTarget;

  num fatConsumed;
  num fatTarget;

  num waterML;
  num waterGoalML;

  num streak;

  String breakfast;
  String lunch;
  String snack;
  String dinner;
  final String breakfastFoods;
  final String lunchFoods;
  final String snackFoods;
  final String dinnerFoods;

  HomeData({
    this.name = '',
    this.caloriesConsumed = 0,
    this.calorieTarget = 0,
    this.proteinConsumed = 0,
    this.proteinTarget = 0,
    this.carbsConsumed = 0,
    this.carbsTarget = 0,
    this.fatConsumed = 0,
    this.fatTarget = 0,
    this.waterML = 0,
    this.waterGoalML = 0,
    this.streak = 0,
    this.breakfast = '',
    this.lunch = '',
    this.snack = '',
    this.dinner = '',
    required this.breakfastFoods,
    required this.lunchFoods,
    required this.snackFoods,
    required this.dinnerFoods,
  });

  factory HomeData.fromJson(
      Map<String, dynamic> json,
      ) {
    return HomeData(
      name: json['name']?.toString() ?? '',

      caloriesConsumed:
      _toNum(json['caloriesConsumed']),

      calorieTarget:
      _toNum(json['calorieTarget']),

      proteinConsumed:
      _toNum(json['proteinConsumed']),

      proteinTarget:
      _toNum(json['proteinTarget']),

      carbsConsumed:
      _toNum(json['carbsConsumed']),

      carbsTarget:
      _toNum(json['carbsTarget']),

      fatConsumed:
      _toNum(json['fatConsumed']),

      fatTarget:
      _toNum(json['fatTarget']),

      waterML:
      _toNum(json['waterML']),

      waterGoalML:
      _toNum(json['waterGoalML']),

      streak:
      _toNum(json['streak']),

      breakfast:
      json['breakfast']?.toString() ?? '',

      lunch:
      json['lunch']?.toString() ?? '',

      snack:
      json['snack']?.toString() ?? '',

      dinner:
      json['dinner']?.toString() ?? '',
      breakfastFoods: json['breakfastFoods'] ?? '',
      lunchFoods: json['lunchFoods'] ?? '',
      snackFoods: json['snackFoods'] ?? '',
      dinnerFoods: json['dinnerFoods'] ?? '',
    );
  }

  static num _toNum(dynamic value) {
    if (value is num) {
      return value;
    }

    if (value is String) {
      return num.tryParse(value) ?? 0;
    }

    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,

      'caloriesConsumed': caloriesConsumed,
      'calorieTarget': calorieTarget,

      'proteinConsumed': proteinConsumed,
      'proteinTarget': proteinTarget,

      'carbsConsumed': carbsConsumed,
      'carbsTarget': carbsTarget,

      'fatConsumed': fatConsumed,
      'fatTarget': fatTarget,

      'waterML': waterML,
      'waterGoalML': waterGoalML,

      'streak': streak,

      'breakfast': breakfast,
      'lunch': lunch,
      'snack': snack,
      'dinner': dinner,
    };
  }
}