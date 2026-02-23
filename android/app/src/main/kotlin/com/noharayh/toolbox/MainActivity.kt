package com.noharayh.toolbox

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.noharayh.toolbox.vpn.core.LocalVpnService
import com.noharayh.toolbox.crawler.CrawlerCaller
import com.noharayh.toolbox.DataContext
import com.noharayh.toolbox.server.HttpServerService
import android.util.Log

class MainActivity : FlutterActivity(), LocalVpnService.onStatusChangedListener {
    private val CHANNEL = "com.nohara.otogamer/vpn"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
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
                    // Set credentials from Flutter
                    DataContext.Username = call.argument<String>("username")
                    DataContext.Password = call.argument<String>("password")
                    
                    // Difficulty settings (Map from list/map if needed)
                    // For now assume all enabled or pass individually
                    DataContext.ExpertEnabled = true
                    DataContext.MasterEnabled = true
                    DataContext.RemasterEnabled = true
                    
                    startService(Intent(this, LocalVpnService::class.java))
                    startService(Intent(this, HttpServerService::class.java))
                    result.success(null)
                }
                "stopVpn" -> {
                    LocalVpnService.IsRunning = false
                    stopService(Intent(this, HttpServerService::class.java))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        
        // Register as listener
        LocalVpnService.addOnStatusChangedListener(this)
        CrawlerCaller.listener = this
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 0 && resultCode == Activity.RESULT_OK) {
            methodChannel?.invokeMethod("onVpnPrepared", true)
        }
    }

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

    override fun onDestroy() {
        LocalVpnService.removeOnStatusChangedListener(this)
        super.onDestroy()
    }
}
