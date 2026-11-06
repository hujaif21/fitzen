import '../models/HomeResponse.dart';
import 'api_manager.dart';

class ApiService {
  // ============================================================
  // DATE HELPER (DD/MM/YYYY)
  // ============================================================

  static String formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  // ============================================================
  // GET HOME DATA
  // ============================================================

  static Future<HomeResponse> getHomeData(
      String email,
      String date,
      ) async {
    try {
      String formattedDate = date;
      final parts = date.split('-');

      if (parts.length == 3) {
        formattedDate =
        '${parts[2].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[0]}';
      }

      final response = await ApiManager().client.getHomeData({
        'action': 'getHome',
        'email': email.trim(),
        'date': formattedDate,
      });

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================
  // ADD FOOD
  // ============================================================

  static Future<Map<String, dynamic>> addFood({
    required String email,
    required String mealType,
    required String foodName,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    required double quantity,
    String unit = 'Serving',
    DateTime? date,
  }) async {
    final formattedDate = formatDate(date ?? DateTime.now());
    final normalizedMeal = mealType.trim().toLowerCase() == 'morning'
        ? 'Breakfast'
        : mealType.trim();

    final payload = {
      'action': 'addFood',
      'email': email.trim(),
      'date': formattedDate,
      'mealType': normalizedMeal,
      'foodName': foodName.trim(),
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'quantity': quantity,
      'unit': unit,
    };

    return await postRequest(payload);
  }

  // ============================================================
  // GENERIC POST API
  // ============================================================

  static Future<Map<String, dynamic>> postRequest(
      Map<String, dynamic> data,
      ) async {
    try {
      final response = await ApiManager().client.postRequest(data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================
  // LOG WEIGHT
  // ============================================================

  static Future<Map<String, dynamic>> logWeight(
      String email, double weight) async {
    final date = formatDate(DateTime.now());
    return await postRequest({
      'action': 'logWeight',
      'email': email.trim(),
      'weight': weight,
      'date': date,
    });
  }

  // ============================================================
  // GET WEIGHT LOGS
  // ============================================================

  static Future<Map<String, dynamic>> getWeightLogs(String email) async {
    return await postRequest({
      'action': 'getWeightLogs',
      'email': email.trim(),
    });
  }

  // ============================================================
  // DELETE WEIGHT LOG
  // ============================================================

  static Future<Map<String, dynamic>> deleteWeight(
      String email, String date, double weight) async {
    return await postRequest({
      'action': 'deleteWeight',
      'email': email.trim(),
      'date': date,
      'weight': weight,
    });
  }

  // ============================================================
  // GET STREAKS DATA
  // ============================================================

  static Future<Map<String, dynamic>> getStreaksData(String email) async {
    final date = formatDate(DateTime.now());
    return await postRequest({
      'action': 'getStreaksData',
      'email': email.trim(),
      'date': date,
    });
  }

  // ============================================================
  // GET PROFILE
  // ============================================================

  static Future<Map<String, dynamic>> getProfile(String email) async {
    final date = formatDate(DateTime.now());
    return await postRequest({
      'action': 'getProfile',
      'email': email.trim(),
      'date': date,
    });
  }

  // ============================================================
  // UPDATE PROFILE
  // ============================================================

  static Future<Map<String, dynamic>> updateProfile({
    required String email,
    required String fullName,
    required String gender,
    required String dob,
    required double weight,
    required double height,
    required String goal,
  }) async {
    return await postRequest({
      'action': 'updateProfile',
      'email': email.trim(),
      'fullName': fullName.trim(),
      'gender': gender.trim(),
      'dob': dob.trim(),
      'weight': weight,
      'height': height,
      'goal': goal.trim(),
    });
  }

  // ============================================================
  // GET PROGRESS
  // ============================================================

  static Future<Map<String, dynamic>> getProgress(String email,
      {int period = 7}) async {
    return await postRequest({
      'action': 'getProgress',
      'email': email.trim(),
      'period': period,
    });
  }

  // ============================================================
  // LOG SCANNED FOOD
  // ============================================================

  static Future<Map<String, dynamic>> logScannedFood({
    required String email,
    required String date,
    required String mealType,
    required String foodName,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
  }) async {
    return await postRequest({
      'action': 'logScannedFood',
      'email': email.trim(),
      'date': date,
      'mealType': mealType,
      'foodName': foodName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    });
  }

  // ============================================================
  // 1. LOG STEPS (PEDOMETER PAGE)
  // ============================================================

  static Future<Map<String, dynamic>> logSteps({
    required String email,
    required int steps,
    required double caloriesBurned,
    required double distanceKM,
  }) async {
    final date = formatDate(DateTime.now());
    return await postRequest({
      'action': 'logSteps',
      'email': email.trim(),
      'date': date,
      'steps': steps,
      'caloriesBurned': caloriesBurned,
      'distanceKM': distanceKM,
    });
  }

  // ============================================================
  // 2. GET STEPS (PEDOMETER PAGE)
  // ============================================================

  static Future<Map<String, dynamic>> getSteps(String email) async {
    final date = formatDate(DateTime.now());
    return await postRequest({
      'action': 'getSteps',
      'email': email.trim(),
      'date': date,
    });
  }

  // ============================================================
  // 3. LOG HEART RATE & BIOMETRICS (HEART RATE PAGE)
  // ============================================================

  static Future<Map<String, dynamic>> logHeartRate({
    required String email,
    required int heartRate,
    required int energy,
    required int stress,
    required int hrv,
  }) async {
    final date = formatDate(DateTime.now());
    return await postRequest({
      'action': 'logHeartRate',
      'email': email.trim(),
      'date': date,
      'heartRate': heartRate,
      'energy': energy,
      'stress': stress,
      'hrv': hrv,
    });
  }

  // ============================================================
  // 4. LOG EXERCISE SESSION (EXERCISE PAGE)
  // ============================================================

  static Future<Map<String, dynamic>> logExercise({
    required String email,
    required String sessionType, // 'Morning', 'Evening', 'Night'
    required bool isCompleted,
  }) async {
    final date = formatDate(DateTime.now());
    return await postRequest({
      'action': 'logExercise',
      'email': email.trim(),
      'date': date,
      'sessionType': sessionType,
      'isCompleted': isCompleted,
    });
  }
}