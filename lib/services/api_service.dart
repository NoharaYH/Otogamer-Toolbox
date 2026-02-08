import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parse;
import '../services/storage_service.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        "User-Agent":
            "Mozilla/5.0 (Linux; Android 13; KB2000 Build/UKQ1.230917.001; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/116.0.0.0 Mobile Safari/537.36 XWEB/1160065 MMWEBSDK/20231202 MMWEBID/2143 MicroMessenger/8.0.47.2560(0x28002F30) WeChat/arm64 Weixin NetType/WIFI Language/zh_CN ABI/arm64",
      },
    ),
  );

  // Validate Diving Fish Token (Read-Only)
  static Future<bool> validateDivingFishToken(String token) async {
    try {
      // Use records endpoint to verify token validity
      // This is safe as it's a GET request
      final response = await _dio.get(
        "https://www.diving-fish.com/api/maimaidxprober/player/records",
        options: Options(
          headers: {"Import-Token": token},
          // Short timeout as we just want to verify access
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      // If 401/403, specifically return false. Other errors might be network.
      // For now, any error means validation failed for this context.
      return false;
    }
  }

  // Validate LXNS Token (Read-Only)
  static Future<bool> validateLxnsToken(String token) async {
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

  // Sync Maimai (Return status message)
  static Future<String> syncMaimai() async {
    // 1. Get Credentials
    final cookie = await StorageService.read(StorageService.kMaimaiCookie);
    final dfToken = await StorageService.read(StorageService.kDivingFishToken);
    final lxnsToken = await StorageService.read(StorageService.kLxnsToken);

    if (cookie == null) return "请先登录舞萌 DX";
    if (dfToken == null && lxnsToken == null) return "请至少配置一个查分器 Token";

    // 2. Fetch HTMLs (Diff 0-4)
    List<String> htmls = [];
    try {
      _dio.options.headers["Cookie"] = cookie;

      // Concurrent fetch
      final futures = List.generate(
        5,
        (i) => _dio.get(
          "https://maimai.wahlap.com/maimai-mobile/record/musicGenre/search/?genre=99&diff=$i",
        ),
      );

      final responses = await Future.wait(futures);
      htmls = responses.map((r) => r.data.toString()).toList();
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 302) {
        return "Cookie 已失效，请重新登录";
      }
      return "抓取成绩失败: $e";
    }

    // 3. Upload to Diving-Fish
    String result = "";
    if (dfToken != null) {
      try {
        await _dio.post(
          "https://www.diving-fish.com/api/maimaidxprober/player/update_records_html",
          data: {"data": htmls.join("\n"), "source": "otogamer_toolbox"},
          options: Options(
            headers: {
              "Import-Token": dfToken,
              "Content-Type": "application/json",
            },
          ),
        );
        result += "水鱼: 上传成功\n";
      } catch (e) {
        result += "水鱼: 上传失败 ($e)\n";
      }
    }

    // 4. Upload to LXNS (Requires Parsing - Placeholder)
    if (lxnsToken != null) {
      // TODO: Implement local parser using 'html' package
      // For now, we skip or use a proxy approach
      result += "落雪: 暂不支持直接上传(需解析)";
    }

    return result;
  }

  // Sync Chunithm
  static Future<String> syncChunithm() async {
    final cookie = await StorageService.read(StorageService.kChunithmCookie);
    final dfToken = await StorageService.read(StorageService.kDivingFishToken);

    if (cookie == null) return "请先登录中二节奏";
    if (dfToken == null) return "请先配置水鱼 Token";

    try {
      // Similar fetch logic for https://chunithm.wahlap.com/mobile/record/musicGenre/search/...
      // Implementing basic fetch for MVP
      return "中二同步功能开发中...";
    } catch (e) {
      return "同步失败: $e";
    }
  }
}
