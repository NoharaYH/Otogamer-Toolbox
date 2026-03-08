package com.noharayh.otokit.crawler;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import okhttp3.Cookie;
import okhttp3.CookieJar;
import okhttp3.HttpUrl;

public class SimpleCookieJar implements CookieJar {
    private final Map<String, List<Cookie>> cookieStore = new HashMap<String, List<Cookie>>();
    private final Object lock = new Object();

    @Override
    public void saveFromResponse(HttpUrl httpUrl, List<Cookie> newCookies) {
        synchronized (lock) {
            HashMap<String, Cookie> map = new HashMap<>();
            List<Cookie> oldCookies = cookieStore.get(httpUrl.host());
            if (oldCookies != null) {
                for (Cookie cookie : oldCookies) {
                    map.put(cookie.name(), cookie);
                }
            }
            // Override old cookie with same name
            if (newCookies != null) {
                for (Cookie cookie : newCookies) {
                    map.put(cookie.name(), cookie);
                }
            }
            List<Cookie> mergedList = new ArrayList<Cookie>();
            for (Map.Entry<String, Cookie> pair : map.entrySet()) {
                mergedList.add(pair.getValue());
            }
            cookieStore.put(httpUrl.host(), mergedList);
        }
    }

    @Override
    public List<Cookie> loadForRequest(HttpUrl httpUrl) {
        synchronized (lock) {
            List<Cookie> cookies = cookieStore.get(httpUrl.host());
            return cookies != null ? cookies : new ArrayList<Cookie>();
        }
    }

    /** 获取指定 host 的 cookies，供 Chunithm POST 取 token 用（对齐 maimaidx-prober cookies[0].Value） */
    public List<Cookie> getCookiesForHost(String host) {
        synchronized (lock) {
            List<Cookie> cookies = cookieStore.get(host);
            return cookies != null ? cookies : new ArrayList<Cookie>();
        }
    }

    public void clearCookieStroe() {
        synchronized (lock) {
            this.cookieStore.clear();
        }
    }
}
