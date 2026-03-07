import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../shared/env/app_env.dart';
import '../../../shared/errors/network_exception.dart';
import '../../../shared/result/result.dart';

/// OSS 拉取普通曲/宴谱 JSON，供 MusicLibraryRepositoryImpl → OssJsonMapper 使用。
@lazySingleton
class OssApiClient {
  OssApiClient(this._dio, this._env);

  final Dio _dio;
  final AppEnv _env;

  /// 拉取普通曲 JSON 数组。URL 未配置或请求失败时返回 Result.failure。
  Future<Result<List<dynamic>, NetworkException>> fetchNormalMusicJson() async {
    final url = _env.ossNormalMusicUrl;
    if (url.isEmpty) {
      return Result.failure(
        NetworkException.connection(message: 'OSS 普通曲 URL 未配置'),
      );
    }
    return _fetchJsonList(url);
  }

  /// 拉取宴谱 JSON 数组。URL 未配置或请求失败时返回 Result.failure。
  Future<Result<List<dynamic>, NetworkException>> fetchUtageMusicJson() async {
    final url = _env.ossUtageMusicUrl;
    if (url.isEmpty) {
      return Result.failure(
        NetworkException.connection(message: 'OSS 宴谱 URL 未配置'),
      );
    }
    return _fetchJsonList(url);
  }

  Future<Result<List<dynamic>, NetworkException>> _fetchJsonList(
    String url,
  ) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        url,
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        if (data is List<dynamic>) {
          return Result.success(data);
        }
        return Result.failure(
          NetworkException.serverError(200, message: '响应格式非 JSON 数组'),
        );
      }
      return Result.failure(NetworkException.serverError(
        response.statusCode,
        message: '请求失败',
      ));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return Result.failure(
          NetworkException.timeout(message: e.message ?? '请求超时', cause: e),
        );
      }
      if (e.type == DioExceptionType.connectionError) {
        return Result.failure(
          NetworkException.connection(
            message: e.message ?? '连接失败',
            cause: e,
          ),
        );
      }
      return Result.failure(NetworkException.serverError(
        e.response?.statusCode,
        message: e.message ?? '请求失败',
        cause: e,
      ));
    }
  }
}
