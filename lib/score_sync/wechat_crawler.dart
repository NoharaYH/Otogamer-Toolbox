import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'simple_cookie_jar.dart';

class WechatCrawler {
  static const String WX_WINDOWS_UA =
      "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) "
      "Chrome/81.0.4044.138 Safari/537.36 NetType/WIFI "
      "MicroMessenger/7.0.20.1781(0x6700143B) WindowsWechat(0x6307001e)";

  final SimpleCookieJar jar = SimpleCookieJar();
  late Dio _client;

  final void Function(String) onLog;
  final void Function(dynamic) onError;
  final void Function(int diff, String data)? onDataFetched;

  WechatCrawler({
    required this.onLog,
    required this.onError,
    this.onDataFetched,
  }) {
    _client = _buildClient(false);
  }

  Dio _buildClient(bool followRedirect) {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 120),
        followRedirects: followRedirect,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    dio.interceptors.add(SimpleCookieInterceptor(jar));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Cache-Control'] = 'no-cache';
          handler.next(options);
        },
      ),
    );

    return dio;
  }

  Future<String> getWechatAuthUrl() async {
    final client = _buildClient(true);
    final response = await client.get(
      "https://tgk-wcaime.wahlap.com/wc_auth/oauth/authorize/maimai-dx",
      options: Options(
        headers: {
          "Host": "tgk-wcaime.wahlap.com",
          "Upgrade-Insecure-Requests": "1",
          "User-Agent":
              "Mozilla/5.0 (Linux; Android 12; IN2010 Build/RKQ1.211119.001; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/86.0.4240.99 XWEB/4317 MMWEBSDK/20220903 Mobile Safari/537.36 MMWEBID/363 MicroMessenger/8.0.28.2240(0x28001C57) WeChat/arm64 Weixin NetType/WIFI Language/zh_CN ABI/arm64",
          "Accept":
              "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/wxpic,image/tpg,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
          "X-Requested-With": "com.tencent.mm",
          "Sec-Fetch-Site": "none",
          "Sec-Fetch-Mode": "navigate",
          "Sec-Fetch-User": "?1",
          "Sec-Fetch-Dest": "document",
          "Accept-Encoding": "gzip, deflate",
          "Accept-Language": "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7",
        },
      ),
    );

    // Replicate Java line 148: String url = response.request().url().toString().replace("redirect_uri=https", "redirect_uri=http");
    String url = response.realUri.toString().replaceFirst(
      "redirect_uri=https",
      "redirect_uri=http",
    );
    return url;
  }

  Future<void> executeSync({
    required String username,
    required String password,
    required Set<int> difficulties,
    required String wechatAuthUrl,
  }) async {
    String finalUrl = wechatAuthUrl;
    if (finalUrl.startsWith("http:")) {
      finalUrl = finalUrl.replaceFirst("http:", "https:");
    }

    jar.clear();

    try {
      onLog("开始登录net，请稍后...");
      await _loginWechat(finalUrl);
      onLog("登陆完成");
    } catch (e) {
      onLog("登陆时出现错误:\n");
      onError(e);
      return;
    }

    try {
      await _fetchMaimaiData(username, password, difficulties);
      onLog("maimai 数据更新完成");
    } catch (e) {
      onLog("maimai 数据更新时出现错误:");
      onError(e);
    }
  }

  Future<void> _loginWechat(String wechatAuthUrl) async {
    final client = _buildClient(true);

    final response = await client.get(
      wechatAuthUrl,
      options: Options(
        headers: {
          "Connection": "keep-alive",
          "Upgrade-Insecure-Requests": "1",
          "User-Agent": WX_WINDOWS_UA,
          "Accept":
              "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
          "Sec-Fetch-Site": "none",
          "Sec-Fetch-Mode": "navigate",
          "Sec-Fetch-User": "?1",
          "Sec-Fetch-Dest": "document",
          "Accept-Encoding": "gzip, deflate, br",
          "Accept-Language": "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7",
        },
      ),
    );

    if (response.statusCode! >= 400) {
      throw Exception("登陆时出现错误，状态码: ${response.statusCode}");
    }

    // Handle redirect manually as in Java code lines 231-236
    String? location = response.headers.value("location");
    if (response.statusCode! >= 300 &&
        response.statusCode! < 400 &&
        location != null) {
      await client.get(location);
    }
  }

  Future<void> _fetchMaimaiData(
    String username,
    String password,
    Set<int> difficulties,
  ) async {
    _client = _buildClient(false);
    final random = Random();

    for (var diff in difficulties) {
      // 1300ms ± 400ms = 900ms ~ 1700ms
      final delay = 900 + random.nextInt(801);

      // 第一个之后才开始加延迟
      if (difficulties.lookup(diff) != difficulties.first) {
        onLog("[ANTI-CRAWL] 正在等待 ${delay}ms...");
        await Future.delayed(Duration(milliseconds: delay));
      }

      await _fetchAndUploadData(username, password, diff, 1);
    }
  }

  Future<void> _fetchAndUploadData(
    String username,
    String password,
    int diff,
    int retryCount,
  ) async {
    final diffName = _getDiffName(diff);
    onLog("开始获取 $diffName 难度的数据");

    try {
      final response = await _client.get(
        "https://maimai.wahlap.com/maimai-mobile/record/musicGenre/search/?genre=99&diff=$diff",
      );
      final data = response.data.toString();
      onDataFetched?.call(diff, data);

      onLog("$diffName 难度的数据已获取，正在上传至水鱼查分器");
      await _uploadData(
        diff,
        "<login><u>$username</u><p>$password</p></login>$data",
        1,
      );
    } catch (e) {
      onLog("获取 $diffName 难度数据时出现错误: $e");
      if (retryCount < 4) {
        onLog("进行第$retryCount次重试");
        await _fetchAndUploadData(username, password, diff, retryCount + 1);
      } else {
        onLog("$diffName难度数据更新失败！");
      }
    }
  }

  Future<void> _uploadData(int diff, String data, int retryCount) async {
    final diffName = _getDiffName(diff);
    try {
      final response = await _client.post(
        "https://www.diving-fish.com/api/pageparser/page",
        data: data,
        options: Options(headers: {"Content-Type": "text/plain"}),
      );
      onLog("$diffName 难度数据上传状态：${response.data}");
    } catch (e) {
      onLog("上传 $diffName 分数数据至水鱼查分器时出现错误: $e");
      if (retryCount < 4) {
        onLog("进行第$retryCount次重试");
        await _uploadData(diff, data, retryCount + 1);
      } else {
        onLog("$diffName难度数据上传失败！");
      }
    }
  }

  String _getDiffName(int diff) {
    switch (diff) {
      case 0:
        return "Basic";
      case 1:
        return "Advance";
      case 2:
        return "Expert";
      case 3:
        return "Master";
      case 4:
        return "Re:Master";
      case 5:
        return "Utage";
      default:
        return "Unknown";
    }
  }
}
