package com.noharayh.otokit

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.noharayh.otokit.vpn.core.LocalVpnService
import com.noharayh.otokit.crawler.CrawlerCaller
import com.noharayh.otokit.crawler.WechatCrawlerListener
import com.noharayh.otokit.DataContext
import com.noharayh.otokit.server.HttpServerService
import android.util.Log

class MainActivity : FlutterActivity(),
    LocalVpnService.onStatusChangedListener,
    WechatCrawlerListener {

    private val CHANNEL = "com.noharayh.otokit/vpn"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        DataContext.AppContext = applicationContext
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "notifyDivingFishTaskDone" -> {
                    CrawlerCaller.notifyDivingFishTaskDone()
                    result.success(null)
                }
                "prepareVpn" -> {
                    val intent = VpnService.prepare(this)
                    if (intent != null) {
                        startActivityForResult(intent, 0)
                        result.success(false)
                    } else {
                        result.success(true)
                    }
                }
                "startVpn" -> {
                    CrawlerCaller.isStopped = false
                    DataContext.Username = call.argument<String>("username")
                    DataContext.Password = call.argument<String>("password")
                    DataContext.LxnsUploadUrl = call.argument<String>("lxnsUploadUrl") ?: ""
                    DataContext.DfUploadUrl = call.argument<String>("dfUploadUrl") ?: ""
                    DataContext.WahlapAuthUrl = call.argument<String>("wahlapAuthUrl") ?: ""
                    DataContext.GameType = call.argument<Int>("gameType") ?: 0
                    val diffs = call.argument<List<Int>>("difficulties")
                    if (diffs != null) {
                        DataContext.Difficulties = diffs
                    } else {
                        DataContext.Difficulties = listOf(0, 1, 2, 3, 4, 10)
                    }
                    val genres = call.argument<List<String>>("genreList")
                    if (genres != null) {
                        DataContext.GenreList = genres
                    }
                    val fetchUrls = call.argument<Map<*, *>>("fetchUrlMap")
                    if (fetchUrls != null) {
                        DataContext.FetchUrlMap.clear()
                        fetchUrls.forEach { (k, v) ->
                            when {
                                k is Int && v is String -> DataContext.FetchUrlMap[k] = v
                                k is Long && v is String -> DataContext.FetchUrlMap[k.toInt()] = v
                                k is String && v is String -> k.toIntOrNull()?.let { DataContext.FetchUrlMap[it] = v }
                            }
                        }
                    }
                    val fetchPostUrls = call.argument<Map<*, *>>("fetchPostUrlMap")
                    if (fetchPostUrls != null) {
                        DataContext.FetchPostUrlMap.clear()
                        fetchPostUrls.forEach { (k, v) ->
                            if (v is String) when {
                                k is Int -> DataContext.FetchPostUrlMap[k] = v
                                k is Long -> DataContext.FetchPostUrlMap[k.toInt()] = v
                                k is String -> k.toIntOrNull()?.let { DataContext.FetchPostUrlMap[it] = v }
                            }
                        }
                    } else {
                        DataContext.FetchPostUrlMap.clear()
                    }

                    startService(Intent(this, LocalVpnService::class.java))
                    startService(Intent(this, HttpServerService::class.java))
                    result.success(null)
                }
                "stopVpn" -> {
                    CrawlerCaller.isStopped = true
                    LocalVpnService.IsRunning = false
                    stopService(Intent(this, HttpServerService::class.java))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // 注册 VPN 状态监听
        LocalVpnService.addOnStatusChangedListener(this)
        // 注册 Crawler 日志监听（MD 接口）
        CrawlerCaller.setOnWechatCrawlerListener(this)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 0 && resultCode == Activity.RESULT_OK) {
            methodChannel?.invokeMethod("onVpnPrepared", true)
        }
    }

    // --- LocalVpnService.onStatusChangedListener ---

    override fun onStatusChanged(status: String?, isRunning: Boolean) {
        runOnUiThread {
            methodChannel?.invokeMethod("onStatusChanged", mapOf(
                "status" to status,
                "isRunning" to isRunning
            ))
        }
    }

    override fun onLogReceived(logString: String?) {
        runOnUiThread {
            methodChannel?.invokeMethod("onLogReceived", logString)
        }
    }

    override fun onAuthUrlReceived(authUrl: String?) {
        // 已由 CrawlerCaller 在原生侧闭环处理，此回调保留但不向 Flutter 透传
    }

    // --- WechatCrawlerListener ---

    override fun onMessageReceived(message: String) {
        runOnUiThread {
            methodChannel?.invokeMethod("onLogReceived", message)
        }
    }

    override fun onStartAuth() {
        runOnUiThread {
            methodChannel?.invokeMethod("onLogReceived", "${getString(R.string.log_tag_auth)} ${getString(R.string.log_auth_start)}")
        }
    }

    override fun onFinishUpdate() {
        runOnUiThread {
            methodChannel?.invokeMethod("onStatusChanged", mapOf(
                "status" to getString(R.string.log_sync_finish),
                "isRunning" to false
            ))
        }
    }

    override fun onError(e: Exception) {
        runOnUiThread {
            methodChannel?.invokeMethod("onLogReceived", "${getString(R.string.log_tag_error)} ${e.message}")
            methodChannel?.invokeMethod("onStatusChanged", mapOf(
                "status" to null,
                "isRunning" to false
            ))
        }
    }

    override fun onDestroy() {
        LocalVpnService.removeOnStatusChangedListener(this)
        CrawlerCaller.removeOnWechatCrawlerListener()
        super.onDestroy()
    }
}
