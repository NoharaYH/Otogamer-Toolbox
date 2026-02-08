import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class LoginWebPage extends StatefulWidget {
  final int gameType; // 0: Maimai, 1: Chunithm

  const LoginWebPage({super.key, required this.gameType});

  @override
  State<LoginWebPage> createState() => _LoginWebPageState();
}

class _LoginWebPageState extends State<LoginWebPage> {
  // Maimai Auth URL
  static const String kMaimaiAuthUrl =
      "https://tgk-wcaime.wahlap.com/wc_auth/oauth/authorize/maimai-dx";
  // Chunithm Auth URL
  static const String kChunithmAuthUrl =
      "https://tgk-wcaime.wahlap.com/wc_auth/oauth/authorize/chunithm";

  late final String targetUrl;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    targetUrl = widget.gameType == 0 ? kMaimaiAuthUrl : kChunithmAuthUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gameType == 0 ? '登录舞萌 DX' : '登录中二节奏'),
        bottom: _progress < 1.0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(value: _progress),
              )
            : null,
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(targetUrl)),
        initialSettings: InAppWebViewSettings(
          userAgent:
              "Mozilla/5.0 (Linux; Android 13; KB2000 Build/UKQ1.230917.001; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/116.0.0.0 Mobile Safari/537.36 XWEB/1160065 MMWEBSDK/20231202 MMWEBID/2143 MicroMessenger/8.0.47.2560(0x28002F30) WeChat/arm64 Weixin NetType/WIFI Language/zh_CN ABI/arm64",
          useShouldOverrideUrlLoading: true,
        ),
        onProgressChanged: (controller, progress) {
          setState(() {
            _progress = progress / 100;
          });
        },
        onLoadStop: (controller, url) async {
          if (url == null) return;
          final urlStr = url.toString();

          // Check for success redirect
          // Maimai: https://maimai.wahlap.com/maimai-mobile/home/
          // Chunithm: https://chunithm.wahlap.com/mobile/home/
          bool isMaimaiSuccess =
              widget.gameType == 0 && urlStr.contains("maimai.wahlap.com");
          bool isChuniSuccess =
              widget.gameType == 1 && urlStr.contains("chunithm.wahlap.com");

          if (isMaimaiSuccess || isChuniSuccess) {
            // Extract Cookies
            List<Cookie> cookies = await CookieManager.instance().getCookies(
              url: url,
            );

            // Find user id
            String? userId;
            try {
              // Usually cookie name is "userId" or sometimes "_t"
              // We try to find userId first
              final cookie = cookies.firstWhere(
                (c) => c.name == "userId" || c.name == "_t",
                orElse: () => Cookie(name: "", value: ""),
              );
              if (cookie.name.isNotEmpty) {
                userId = cookie.value;
              }
            } catch (e) {
              // ignore
            }

            if (userId != null && userId.isNotEmpty) {
              // Return the cookie string (key=value)
              // For simplicity, we just return the raw userId value or the full cookie string needed?
              // Usually header needs "userId=..."
              // Let's return the full cookie value
              if (mounted) {
                Navigator.pop(context, "userId=$userId");
              }
            }
          }
        },
      ),
    );
  }
}
