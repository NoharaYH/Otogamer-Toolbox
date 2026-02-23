import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  // Validate Diving Fish Token (Read-Only)
  Future<bool> validateDivingFishToken(String token) async {
    try {
      final response = await _dio.get(
        "https://www.diving-fish.com/api/maimaidxprober/player/records",
        options: Options(
          headers: {"Import-Token": token},
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Validate LXNS Token (Read-Only)
  Future<bool> validateLxnsToken(String token) async {
    try {
      final response = await _dio.get(
        "https://maimai.lxns.net/api/v0/user/maimai/player",
        options: Options(headers: {"Authorization": token}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
