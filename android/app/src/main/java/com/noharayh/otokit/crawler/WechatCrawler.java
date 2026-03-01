package com.noharayh.otokit.crawler;


import static com.noharayh.otokit.crawler.CrawlerCaller.finishUpdate;
import static com.noharayh.otokit.crawler.CrawlerCaller.onError;
import static com.noharayh.otokit.crawler.CrawlerCaller.startAuth;
import static com.noharayh.otokit.crawler.CrawlerCaller.writeLog;

import android.util.Log;

import java.io.IOException;
import java.security.cert.CertificateException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

import okhttp3.Call;
import okhttp3.ConnectionSpec;
import okhttp3.Headers;
import okhttp3.Interceptor;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;
import okhttp3.TlsVersion;

public class WechatCrawler {
    // Make this true for Fiddler to capture https request
    private static final boolean IGNORE_CERT = false;

    private static final int MAX_RETRY_COUNT = 4;

    private static final String TAG = "Crawler";

    private static final String WX_WINDOWS_UA =
            "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) " +
                    "Chrome/81.0.4044.138 Safari/537.36 NetType/WIFI " +
                    "MicroMessenger/7.0.20.1781(0x6700143B) WindowsWechat(0x6307001e)";


    private static final MediaType JSON = MediaType.parse("application/json; charset=utf-8");

    private static final MediaType TEXT = MediaType.parse("text/plain");

    private static OkHttpClient client;
    private static final SimpleCookieJar jar = new SimpleCookieJar();
    private static final Map<Integer, String> diffMap = new HashMap<>();
    private static final Map<Integer, String> htmlCache = new HashMap<>();

    public WechatCrawler() {
        diffMap.put(-1, "用户信息");
        diffMap.put(-2, "最近游玩");
        diffMap.put(0, "Basic");
        diffMap.put(1, "Advanced");
        diffMap.put(2, "Expert");
        diffMap.put(3, "Master");
        diffMap.put(4, "Re:Master");
        diffMap.put(10, "U·TA·GE"); // 舞萌宴谱标识对齐后端标准
        buildHttpClient(false);
    }

    /** 根据当前游戏类型与难度索引，返回本地化标签（支持舞萌/中二区分） */
    private static String getDiffLabel(int diff) {
        if (com.noharayh.otokit.DataContext.GameType == 1) {
            String label;
            if (diff == 4) label = "ULTIMA";
            else if (diff == 5 || diff == 10) label = "U·TA·GE"; // 语义统一
            else label = diffMap.getOrDefault(diff, "难度" + diff);
            return label.toUpperCase(); // 中二难度文字全部改为大写
        }
        return diffMap.getOrDefault(diff, "难度" + diff);
    }

    private static void uploadToDivingFish(Integer diff, String htmlData, String token) {
        if (token == null || token.isEmpty()) return;

        // 特殊逻辑：仅针对舞萌的宴谱 (diff=10) 使用 Dart 侧解析及 JSON 上传方案
        // 目的是绕过官方 HTML 接口对宴谱 DOM 结构的解析错误
        if (com.noharayh.otokit.DataContext.GameType == 0 && diff == 10) {
            Map<String, Object> data = new HashMap<>();
            data.put("type", "diving_fish");
            data.put("diff", diff);
            data.put("token", token);
            data.put("html", htmlData);
            data.put("gameType", com.noharayh.otokit.DataContext.GameType);
            
            // 准备同步锁并发送日志
            CrawlerCaller.prepareDivingFishSync();
            writeLog("[HTML_DATA_SYNC]" + new org.json.JSONObject(data).toString());
            
            // 等待 Flutter 侧上传完毕反馈（限时 60s）
            if (!CrawlerCaller.waitForDivingFishSync(60000)) {
                writeLog("[ERROR] [水鱼] 上传宴谱等待超时，任务强制继续");
            }
            return;
        }

        // 常规逻辑：其余难度及游戏类型使用原始 HTML 上传方案
        String url = com.noharayh.otokit.DataContext.DfUploadUrl;
        if (url == null || url.isEmpty()) return;

        Request request = new Request.Builder()
                .url(url)
                .addHeader("Import-Token", token)
                .post(RequestBody.create(htmlData, TEXT))
                .build();

        try (Response response = client.newCall(request).execute()) {
            int code = response.code();
            boolean isSilent = diff < 0; // 用户信息(-1)和最近游玩(-2)静默
            if (code >= 200 && code < 300) {
                if (!isSilent) writeLog("[UPLOAD] [水鱼] 上传" + getDiffLabel(diff) + "成功");
            } else {
                String body = response.body() != null ? response.body().string() : "";
                writeLog("[ERROR] [水鱼] 上传" + getDiffLabel(diff) + "失败: " + code + " - " + body);
            }
        } catch (Exception e) {
            writeLog("[ERROR] [水鱼] 上传" + getDiffLabel(diff) + "失败: 异常 - " + e.getMessage());
        }
    }

    private static void uploadToLxns(Integer diff, String htmlData, String token) {
        if (token == null || token.isEmpty()) return;

        String url = com.noharayh.otokit.DataContext.LxnsUploadUrl;
        if (url == null || url.isEmpty()) return;

        Request.Builder builder = new Request.Builder().url(url);
        builder.addHeader("Authorization", "Bearer " + token);

        Request request = builder.post(RequestBody.create(htmlData, TEXT)).build();

        try (Response response = client.newCall(request).execute()) {
            int code = response.code();
            boolean isSilent = diff < 0; // 用户信息(-1)和最近游玩(-2)静默
            if (code >= 200 && code < 300) {
                if (!isSilent) writeLog("[UPLOAD] [落雪] 上传" + getDiffLabel(diff) + "成功");
            } else {
                String body = response.body() != null ? response.body().string() : "";
                writeLog("[ERROR] [落雪] 上传" + getDiffLabel(diff) + "失败: " + code + " - " + body);
            }
        } catch (Exception e) {
            writeLog("[ERROR] [落雪] 上传" + getDiffLabel(diff) + "失败: 异常 - " + e.getMessage());
        }
    }


    private static void fetchAndUploadData(String username, String password, Set<Integer> difficulties) {
        htmlCache.clear();
        writeLog("[SYSTEM] 开始获取用户成绩");

        // 基础信息抓取 (Lxns 强制要求玩家档案确立)
        fetchSingleHtmlToCache(-1);
        sleep(1000);
        fetchSingleHtmlToCache(-2);
        sleep(1000);

        for (Integer diff : difficulties) {
            if (CrawlerCaller.isStopped) {
                writeLog("[SYSTEM] 同步业务终止");
                return;
            }
            fetchSingleHtmlToCache(diff);
            sleep(1200);
        }

        if (htmlCache.isEmpty()) {
            writeLog("[ERROR] 获取成绩失败: 异常 - 未获取到有效 HTML 数据，取消上传");
            return;
        }

        writeLog("[SYSTEM] 成绩获取完毕，开始上传至目标平台...");

        if (username != null && !username.isEmpty()) {
            writeLog("[SYSTEM] 开始上传至水鱼服务器");
            for (Map.Entry<Integer, String> entry : htmlCache.entrySet()) {
                if (CrawlerCaller.isStopped) return;
                if (entry.getKey() < 0) continue;
                uploadToDivingFish(entry.getKey(), entry.getValue(), username);
            }
        }

        if (password != null && !password.isEmpty()) {
            writeLog("[SYSTEM] 开始上传至落雪服务器");
            if (htmlCache.containsKey(-1)) {
                uploadToLxns(-1, htmlCache.get(-1), password);
                sleep(1000);
            }

            for (Map.Entry<Integer, String> entry : htmlCache.entrySet()) {
                if (CrawlerCaller.isStopped) return;
                if (entry.getKey() < 0) continue;
                sleep(1000);
                uploadToLxns(entry.getKey(), entry.getValue(), password);
            }
        }

        writeLog("[SYSTEM] 同步任务执行完毕");
    }

    private static void fetchSingleHtmlToCache(Integer diff) {
        if (CrawlerCaller.isStopped) return;

        String url = com.noharayh.otokit.DataContext.FetchUrlMap.get(diff);
        if (url == null || url.isEmpty()) {
            writeLog("[ERROR] 获取失败: {异常 难度 " + diff + " 未配置爬取路径}");
            return;
        }

        String label = getDiffLabel(diff);
        Request request = new Request.Builder().url(url).build();
        try (Response response = client.newCall(request).execute()) {
            String html = Objects.requireNonNull(response.body()).string();
            htmlCache.put(diff, html);
            boolean isSilent = diff < 0; // 用户信息(-1)和最近游玩(-2)静默
            if (!isSilent) writeLog("[DOWNLOAD] 已获取" + label + "数据");
        } catch (Exception e) {
            writeLog("[ERROR] 获取" + label + "失败: 异常 - " + e.getMessage());
        }
    }

    private static void sleep(long ms) {
        try { Thread.sleep(ms); } catch (InterruptedException ignored) {}
    }

    protected String getWechatAuthUrl() throws IOException {
        this.buildHttpClient(true);

        String url = com.noharayh.otokit.DataContext.WahlapAuthUrl;
        if (url == null || url.isEmpty()) return "";

        Request request = new Request.Builder()
                .addHeader("Host", "tgk-wcaime.wahlap.com")
                .addHeader("Upgrade-Insecure-Requests", "1")
                .addHeader("User-Agent", "Mozilla/5.0 (Linux; Android 12; IN2010 Build/RKQ1.211119.001; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/86.0.4240.99 XWEB/4317 MMWEBSDK/20220903 Mobile Safari/537.36 MMWEBID/363 MicroMessenger/8.0.28.2240(0x28001C57) WeChat/arm64 Weixin NetType/WIFI Language/zh_CN ABI/arm64")
                .addHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/wxpic,image/tpg,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9")
                .addHeader("X-Requested-With", "com.tencent.mm")
                .addHeader("Sec-Fetch-Site", "none")
                .addHeader("Sec-Fetch-Mode", "navigate")
                .addHeader("Sec-Fetch-User", "?1")
                .addHeader("Sec-Fetch-Dest", "document")
                .addHeader("Accept-Encoding", "gzip, deflate")
                .addHeader("Accept-Language", "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7")
                .url(url)
                .build();

        Call call = client.newCall(request);
        Response response = call.execute();
        String redirectUrl = response.request().url().toString().replace("redirect_uri=https", "redirect_uri=http");

        Log.d(TAG, "Auth url:" + redirectUrl);
        return redirectUrl;
    }

    public void fetchAndUploadData(String username, String password, Set<Integer> difficulties, String wechatAuthUrl) throws IOException {
        if (wechatAuthUrl.startsWith("http"))
            wechatAuthUrl = wechatAuthUrl.replaceFirst("http", "https");

        jar.clearCookieStroe();

        // Login wechat
        try {
            startAuth();
            this.loginWechat(wechatAuthUrl);
            writeLog("[AUTH] 重定向完成，正在获取数据...");
        } catch (Exception error) {
            writeLog("[ERROR] 凭证已失效或未授权");
            onError(error);
            return;
        }

        // Fetch data
        try {
            this.fetchGameData(username, password, difficulties);
            finishUpdate();
        } catch (Exception error) {
            writeLog("[ERROR] 网络错误，传分业务终止");
            onError(error);
        }
    }


    private void loginWechat(String wechatAuthUrl) throws Exception {
        this.buildHttpClient(true);

        Log.d(TAG, wechatAuthUrl);

        Headers headers = new Headers.Builder()
                .add("Connection", "keep-alive")
                .add("Upgrade-Insecure-Requests", "1")
                .add("User-Agent", WX_WINDOWS_UA)
                .add(
                        "Accept",
                        "text/html,application/xhtml+xml,application/xml;q=0.9," +
                                "image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9"
                )
                .add("Sec-Fetch-Site", "none")
                .add("Sec-Fetch-Mode", "navigate")
                .add("Sec-Fetch-User", "?1")
                .add("Sec-Fetch-Dest", "document")
                .add("Accept-Encoding", "gzip, deflate, br")
                .add("Accept-Language", "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7")
                .build();

        Request request = new Request.Builder()
                .headers(headers)
                .get()
                .url(wechatAuthUrl)
                .build();

        Call call = client.newCall(request);
        Response response = call.execute();

        try {
            String responseBody = response.body().string();
            Log.d(TAG, responseBody);
        } catch (NullPointerException error) {
            onError(error);
        }

        int code = response.code();

        if (code >= 400) {
            Exception exception = new Exception("登陆时出现错误，请重试！");
            onError(exception);
            throw new Exception(exception);
        }

        // Handle redirect manually
        String location = response.headers().get("Location");
        if (response.code() >= 300 && response.code() < 400 && location != null) {
            request = new Request.Builder().url(location).get().build();
            call = client.newCall(request);
            call.execute().close();
        }
    }

    private void fetchGameData(String username, String password, Set<Integer> difficulties) throws IOException {
        this.buildHttpClient(false);
        fetchAndUploadData(username, password, difficulties);
    }

    private void buildHttpClient(boolean followRedirect) {
        OkHttpClient.Builder builder = new OkHttpClient.Builder();

        if (IGNORE_CERT) ignoreCertBuilder(builder);

        builder.connectTimeout(120, TimeUnit.SECONDS);
        builder.readTimeout(120, TimeUnit.SECONDS);
        builder.writeTimeout(120, TimeUnit.SECONDS);
        builder.followRedirects(followRedirect);
        builder.followSslRedirects(followRedirect);

        builder.cookieJar(jar);

        // No cache for http request
        builder.cache(null);
        Interceptor noCacheInterceptor = chain -> {
            Request request = chain.request();
            Request.Builder builder1 = request.newBuilder().addHeader("Cache-Control", "no-cache");
            request = builder1.build();
            return chain.proceed(request);
        };
        builder.addInterceptor(noCacheInterceptor);

        // Fix SSL handle shake error
        ConnectionSpec spec = new ConnectionSpec.Builder(ConnectionSpec.COMPATIBLE_TLS).tlsVersions(TlsVersion.TLS_1_2, TlsVersion.TLS_1_1, TlsVersion.TLS_1_0).allEnabledCipherSuites().build();
        // 兼容http接口
        ConnectionSpec spec1 = new ConnectionSpec.Builder(ConnectionSpec.CLEARTEXT).build();
        builder.connectionSpecs(Arrays.asList(spec, spec1));

        builder.pingInterval(3, TimeUnit.SECONDS);

        client = builder.build();
    }

    private void ignoreCertBuilder(OkHttpClient.Builder builder) {
        try {
            final TrustManager[] trustAllCerts = new TrustManager[]{new X509TrustManager() {
                @Override
                public void checkClientTrusted(java.security.cert.X509Certificate[] chain, String authType) throws CertificateException {
                }

                @Override
                public void checkServerTrusted(java.security.cert.X509Certificate[] chain, String authType) throws CertificateException {
                }

                @Override
                public java.security.cert.X509Certificate[] getAcceptedIssuers() {
                    return new java.security.cert.X509Certificate[]{};
                }
            }};
            final SSLContext sslContext = SSLContext.getInstance("SSL");
            sslContext.init(null, trustAllCerts, new java.security.SecureRandom());
            // Create an ssl socket factory with our all-trusting manager
            final SSLSocketFactory sslSocketFactory = sslContext.getSocketFactory();
            builder.sslSocketFactory(sslSocketFactory, (X509TrustManager) trustAllCerts[0]);
            builder.hostnameVerifier(new HostnameVerifier() {
                @Override
                public boolean verify(String hostname, SSLSession session) {
                    return true;
                }
            });
        } catch (Exception ignored) {

        }
    }
}
