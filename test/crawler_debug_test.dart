import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/score_sync/wechat_crawler.dart';

void main() {
  // 注意：运行该测试需要一个有效的、未过期的微信授权链接
  // 你可以从 App 运行日志中捕获该链接
  const String testAuthUrl = "PASTE_YOUR_AUTH_URL_HERE";

  test('Wechat Crawler Data Dump Test', () async {
    if (testAuthUrl == "PASTE_YOUR_AUTH_URL_HERE") {
      print("跳过测试：请先填入有效的 wechatAuthUrl");
      return;
    }

    final dumpDir = Directory('test/dumped_data');
    if (!await dumpDir.exists()) {
      await dumpDir.create(recursive: true);
    }

    final crawler = WechatCrawler(
      onLog: (msg) => print("[LOG] $msg"),
      onError: (err) => print("[ERROR] $err"),
      onDataFetched: (diff, data) {
        final file = File('test/dumped_data/diff_$diff.html');
        file.writeAsStringSync(data);
        print("[DEBUG] 原始数据已缓存至: ${file.path} (长度: ${data.length})");
      },
    );

    print("开始测试抓取流程...");

    try {
      // 执行同步（这里会尝试上传到水鱼，测试时建议使用虚假账号或观察日志）
      await crawler.executeSync(
        username: "test_user",
        password: "test_password",
        difficulties: {3}, // 仅抓取 Master 难度作为示例
        wechatAuthUrl: testAuthUrl,
      );

      print("抓取结束，请查看 test/dumped_data 目录。");
    } catch (e) {
      print("测试过程中出现异常: $e");
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
