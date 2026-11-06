import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/login_response.dart';
import '../models/HomeResponse.dart';

part 'api_client.g.dart';

@RestApi(
  baseUrl:
  "https://script.google.com/macros/s/AKfycbw5oQl3_bQt2wInN7zjiZP1fOv9991zTI2Mnz-NJTWDo1NTAc7ug8wSqxXXJoGJmq9xpA/exec",
)
abstract class ApiClient {
  factory ApiClient(Dio dio, {String? baseUrl}) = _ApiClient;

  // ============================================================
  // LOGIN
  // ============================================================

  @POST("")
  Future<LoginResponse> loginUser(
      @Body() Map<String, dynamic> credentials,
      );

  // ============================================================
  // HOME
  // ============================================================

  @POST("")
  Future<HomeResponse> getHomeData(
      @Body() Map<String, dynamic> data,
      );

  // ============================================================
  // GENERIC POST
  // Water, Food, Diet, Progress, BMI, etc.
  // ============================================================

  @POST("")
  Future<Map<String, dynamic>> postRequest(
      @Body() Map<String, dynamic> data,
      );
}