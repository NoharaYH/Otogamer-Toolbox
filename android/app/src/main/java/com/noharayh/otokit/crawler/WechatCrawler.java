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
        diffMap.put(5, "Utage"); // 舞萌宴谱标识，中二 WE 通过 getDiffLabel() 动态覆盖
        buildHttpClient(false);
    }

    /** 根据当前游戏类型与难度索引，返回本地化标签（支持舞萌/中二区分） */
    private static String getDiffLabel(int diff) {
        if (diff == 5 && com.noharayh.otokit.DataContext.GameType == 1) {
            return "World's End";
        }
        return diffMap.getOrDefault(diff, "难度" + diff);
    }

    private static void uploadToDivingFish(Integer diff, String htmlData, String token) {
        if (token == null || token.isEmpty()) return;
        
        String url = (com.noharayh.otokit.DataContext.GameType == 0) 
            ? "https://www.diving-fish.com/api/maimaidxprober/player/update_records_html"
            : "https://www.diving-fish.com/api/chunithmprober/player/update_records_html";

        Request request = new Request.Builder()
                .url(url)
                .addHeader("Import-Token", token)
                .post(RequestBody.create(htmlData, TEXT))
                .build();

        try (Response response = client.newCall(request).execute()) {
            int code = response.code();
            if (code >= 200 && code < 300) {
                writeLog("[UPLOAD] [水鱼] 上传" + diffMap.get(diff) + "成功 状态: " + code);
            } else {
                String body = response.body() != null ? response.body().string() : "";
                writeLog("[ERROR] [水鱼] 上传" + diffMap.get(diff) + "失败: {" + code + " " + body + "}");
            }
        } catch (Exception e) {
            writeLog("[ERROR] [水鱼] 上传" + diffMap.get(diff) + "失败: {异常 " + e.getMessage() + "}");
        }
    }

    private static void uploadToLxns(Integer diff, String htmlData, String token) {
        if (token == null || token.isEmpty()) return;

        String game = (com.noharayh.otokit.DataContext.GameType == 0) ? "maimai" : "chunithm";
        // 官方推荐路径: /api/v0/user/{game}/player/html
        String url = "https://maimai.lxns.net/api/v0/user/" + game + "/player/html";

        Request.Builder builder = new Request.Builder().url(url);
        
        // 鉴权逻辑切换: OAuth 使用 Bearer, 个人 API 使用 X-User-Token
        if (com.noharayh.otokit.DataContext.IsOAuth) {
            builder.addHeader("Authorization", "Bearer " + token);
        } else {
            builder.addHeader("X-User-Token", token);
        }

        Request request = builder.post(RequestBody.create(htmlData, TEXT)).build();

        try (Response response = client.newCall(request).execute()) {
            int code = response.code();
            if (code >= 200 && code < 300) {
                writeLog("[UPLOAD] [落雪] 上传" + diffMap.get(diff) + "成功 状态: " + code);
            } else {
                String body = response.body() != null ? response.body().string() : "";
                writeLog("[ERROR] [落雪] 上传" + diffMap.get(diff) + "失败: {" + code + " " + body + "}");
            }
        } catch (Exception e) {
            writeLog("[ERROR] [落雪] 上传" + diffMap.get(diff) + "失败: {异常 " + e.getMessage() + "}");
        }
    }


    private static void fetchAndUploadData(String username, String password, Set<Integer> difficulties) {
        htmlCache.clear();

        writeLog("[SYSTEM] 开始获取用户成绩");

        // 额外抓取项：用户信息与最近游玩（两款游戏都需要）
        fetchSingleHtmlToCache(-1); // 用户资料页（落雪规范要求上传）
        sleep(1000);
        fetchSingleHtmlToCache(-2); // 最近游玩页
        sleep(1000);

        for (Integer diff : difficulties) {
            if (CrawlerCaller.isStopped) {
                writeLog("[SYSTEM] 传分业务终止");
                return;
            }
            fetchSingleHtmlToCache(diff);
            sleep(1200); // 抓取间隔保护
        }

        // 阶段 2: 集中上传
        if (htmlCache.isEmpty()) {
            writeLog("[ERROR] 获取成绩失败: {异常 未获取到有效 HTML 数据，取消上传}");
            return;
        }

        writeLog("[SYSTEM] 成绩获取完毕，开始上传至目标平台...");

        if (username != null && !username.isEmpty()) {
            writeLog("[SYSTEM] 开始上传至水鱼服务器");
            for (Map.Entry<Integer, String> entry : htmlCache.entrySet()) {
                if (CrawlerCaller.isStopped) return;
                if (entry.getKey() < 0) continue; // 水鱼不接受内部页，跳过
                uploadToDivingFish(entry.getKey(), entry.getValue(), username);
            }
        }

        if (password != null && !password.isEmpty()) {
            writeLog("[SYSTEM] 开始上传至落雪服务器");
            for (Map.Entry<Integer, String> entry : htmlCache.entrySet()) {
                if (CrawlerCaller.isStopped) return;
                // 落雪需要用户信息页（-1），跳过最近游玩(-2)即可
                if (entry.getKey() == -2) continue;
                sleep(1000); // 防止触发落雪限流
                uploadToLxns(entry.getKey(), entry.getValue(), password);
            }
        }
    }

    private static void fetchSingleHtmlToCache(Integer diff) {
        if (CrawlerCaller.isStopped) return;

        String baseUrl = (com.noharayh.otokit.DataContext.GameType == 0)
                ? "https://maimai.wahlap.com/maimai-mobile/"
                : "https://chunithm.wahlap.com/mobile/";

        String url;
        if (com.noharayh.otokit.DataContext.GameType == 0) {
            // 舞萌 DX 抓取路径
            if (diff == -1) url = baseUrl + "friend/userFriendCode/"; // 落雪规范页：含 friendCode
            else if (diff == -2) url = baseUrl + "record/";           // 最近游玩
            else if (diff == 5) url = baseUrl + "record/musicGenre/search/?genre=99&diff=10"; // 宴谱 Utage
            else url = baseUrl + "record/musicSort/search/?search=V&sort=1&playCheck=on&diff=" + diff;
        } else {
            // 中二节奏 抓取路径
            if (diff == -1) url = baseUrl + "home/playerData";       // 落雪规范页：含玩家信息
            else if (diff == -2) url = baseUrl + "record/playlog";   // 最近游玩
            else if (diff == 5) url = baseUrl + "record/worldsEndList"; // World's End
            else url = baseUrl + "record/musicGenre?difficulty=" + diff; // BASIC~ULTIMA 按难度
        }

        String label = getDiffLabel(diff);
        Request request = new Request.Builder().url(url).build();
        try (Response response = client.newCall(request).execute()) {
            String html = Objects.requireNonNull(response.body()).string();
            if (html.length() < 1000) {
                writeLog("[WARN] " + label + " 页面响应过短，可能抓取异常");
            }
            htmlCache.put(diff, html);
            if (diff >= 0) { // 不向前端暴露内部抓取页的日志
                writeLog("[DOWNLOAD] 已获取 " + label + " 数据");
            }
        } catch (Exception e) {
            writeLog("[ERROR] 获取 " + label + " 失败: {异常 " + e.getMessage() + "}");
        }
    }

    private static void sleep(long ms) {
        try { Thread.sleep(ms); } catch (InterruptedException ignored) {}
    }

    protected String getWechatAuthUrl() throws IOException {
        this.buildHttpClient(true);

        String gamePath = (com.noharayh.otokit.DataContext.GameType == 0) ? "maimai-dx" : "chunithm";
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
                .url("https://tgk-wcaime.wahlap.com/wc_auth/oauth/authorize/" + gamePath)
                .build();

        Call call = client.newCall(request);
        Response response = call.execute();
        String url = response.request().url().toString().replace("redirect_uri=https", "redirect_uri=http");

        Log.d(TAG, "Auth url:" + url);
        return url;
    }

    public void fetchAndUploadData(String username, String password, Set<Integer> difficulties, String wechatAuthUrl) throws IOException {
        if (wechatAuthUrl.startsWith("http"))
            wechatAuthUrl = wechatAuthUrl.replaceFirst("http", "https");

        jar.clearCookieStroe();

        // Login wechat
        try {
            startAuth();
            writeLog("[AUTH] 发起微信登录授权...");
            this.loginWechat(wechatAuthUrl);
            writeLog("[AUTH] 重定向完成，正在获取数据...");
        } catch (Exception error) {
            writeLog("[ERROR] 凭证已失效或未授权");
            onError(error);
            return;
        }

        // Fetch maimai data
        try {
            this.fetchMaimaiData(username, password, difficulties);
            writeLog("[SYSTEM] 传分业务完毕");
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

    private void fetchMaimaiData(String username, String password, Set<Integer> difficulties) throws IOException {
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
