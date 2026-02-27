package com.noharayh.otokit.crawler

import com.noharayh.otokit.DataContext
import com.noharayh.otokit.Util
import com.noharayh.otokit.vpn.core.LocalVpnService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.IOException

object CrawlerCaller {
    private var listener: WechatCrawlerListener? = null

    @JvmField
    @Volatile
    var isStopped: Boolean = false



    fun getWechatAuthUrl(): String? {
        return try {
            val crawler = WechatCrawler()
            crawler.getWechatAuthUrl()
        } catch (error: IOException) {
            writeLog("[ERROR] 发起微信登录授权失败: \${error.message}")
            onError(error)
            null
        }
    }

    @JvmStatic
    fun writeLog(text: String) {
        CoroutineScope(Dispatchers.Main).launch {
            listener?.onMessageReceived(text)
        }
    }

    @JvmStatic
    fun startAuth() {
        CoroutineScope(Dispatchers.Main).launch {
            listener?.onStartAuth()
        }
    }

    @JvmStatic
    fun finishUpdate() {
        CoroutineScope(Dispatchers.Main).launch {
            listener?.onFinishUpdate()
        }
    }

    @JvmStatic
    fun onError(e: Exception) {
        CoroutineScope(Dispatchers.Main).launch {
            listener?.onError(e)
        }
    }

    fun fetchData(authUrl: String) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                Thread.sleep(3000)
                LocalVpnService.IsRunning = false
                Thread.sleep(3000)
            } catch (e: InterruptedException) {
                onError(e)
            }
            try {
                val crawler = WechatCrawler()
                crawler.fetchAndUploadData(
                    DataContext.Username,
                    DataContext.Password,
                    getDifficulties(),
                    authUrl
                )
            } catch (e: IOException) {
                onError(e)
            }
        }
    }

    fun setOnWechatCrawlerListener(listener: WechatCrawlerListener) {
        this.listener = listener
    }

    fun removeOnWechatCrawlerListener() {
        this.listener = null
    }

    private fun getDifficulties(): Set<Int> = DataContext.Difficulties.toSet()
}
