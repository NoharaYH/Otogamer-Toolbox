import 'package:dio/dio.dart';
import '../../kernel/di/injection.dart';

class MaiClient {
  static const String divingFishUrl =
      'https://www.diving-fish.com/api/maimaidxprober/music_data';
  static const String lxnsUrl =
      'https://maimai.lxns.net/api/v0/maimai/song/list';
  static const String lxnsMetadataUrl =
      'https://maimai.lxns.net/api/v0/maimai/version/list';

  final Dio _dio = getIt<Dio>();

  /// 获取游戏版本元数据（用于指纹校验）
  Future<List<dynamic>> fetchVersions() async {
    final response = await _dio.get(lxnsMetadataUrl);
    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'LXNS Version API error: ${response.statusCode}',
      );
    }
    return response.data['data'] ?? [];
  }

  /// 获取水鱼原始数据
  Future<List<dynamic>> fetchDivingFishRaw() async {
    final response = await _dio.get(divingFishUrl);
    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Diving Fish API error: ${response.statusCode}',
      );
    }
    return response.data;
  }

  /// 获取落雪原始数据
  Future<List<dynamic>> fetchLxnsRaw() async {
    final response = await _dio.get(lxnsUrl);
    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'LXNS API error: ${response.statusCode}',
      );
    }
    // 落雪 API 的 /song/list 返回结构中曲目列表位于 data.songs
    final dataNode = response.data['data'];
    if (dataNode is Map) {
      return dataNode['songs'] ?? [];
    }
    return [];
  }

  void dispose() {
    // Dio instance managed by getIt doesn't need local dispose here
  }
}
