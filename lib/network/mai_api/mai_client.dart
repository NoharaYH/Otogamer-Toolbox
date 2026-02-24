import 'dart:convert';
import 'dart:io';

class MaiClient {
  static const String divingFishUrl =
      'https://www.diving-fish.com/api/maimaidxprober/music_data';
  static const String lxnsUrl =
      'https://maimai.lxns.net/api/v0/maimai/song/list';
  static const String lxnsMetadataUrl =
      'https://maimai.lxns.net/api/v0/maimai/version/list';

  final HttpClient _client = HttpClient();

  /// 获取游戏版本元数据（用于指纹校验）
  Future<List<dynamic>> fetchVersions() async {
    final request = await _client.getUrl(Uri.parse(lxnsMetadataUrl));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw HttpException('LXNS Version API error: ${response.statusCode}');
    }
    final content = await response.transform(utf8.decoder).join();
    final Map<String, dynamic> data = jsonDecode(content);
    return data['versions'] ?? [];
  }

  /// 获取水鱼原始数据
  Future<List<dynamic>> fetchDivingFishRaw() async {
    final request = await _client.getUrl(Uri.parse(divingFishUrl));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw HttpException('Diving Fish API error: ${response.statusCode}');
    }
    final content = await response.transform(utf8.decoder).join();
    return jsonDecode(content);
  }

  /// 获取落雪原始数据
  Future<List<dynamic>> fetchLxnsRaw() async {
    final request = await _client.getUrl(Uri.parse(lxnsUrl));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw HttpException('LXNS API error: ${response.statusCode}');
    }
    final content = await response.transform(utf8.decoder).join();
    final Map<String, dynamic> data = jsonDecode(content);
    return data['songs'] ?? [];
  }

  void dispose() {
    _client.close();
  }
}
