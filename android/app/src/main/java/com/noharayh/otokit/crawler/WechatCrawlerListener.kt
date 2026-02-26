package com.noharayh.otokit.crawler

interface WechatCrawlerListener {
    fun onMessageReceived(message: String)
    fun onStartAuth()
    fun onFinishUpdate()
    fun onError(e: Exception)
}
