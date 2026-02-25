import 'dart:io' as io;
import 'package:dio/dio.dart';

class SimpleCookieJar {
  final Map<String, List<io.Cookie>> _cookieStore = {};

  void saveFromResponse(Uri uri, List<io.Cookie> newCookies) {
    if (newCookies.isEmpty) return;

    final host = uri.host;
    final map = <String, io.Cookie>{};

    final oldCookies = _cookieStore[host];
    if (oldCookies != null) {
      for (var cookie in oldCookies) {
        map[cookie.name] = cookie;
      }
    }

    // Override old cookie with same name
    for (var cookie in newCookies) {
      map[cookie.name] = cookie;
    }

    _cookieStore[host] = map.values.toList();
  }

  List<io.Cookie> loadForRequest(Uri uri) {
    return _cookieStore[uri.host] ?? [];
  }

  void clear() {
    _cookieStore.clear();
  }
}

class SimpleCookieInterceptor extends Interceptor {
  final SimpleCookieJar jar;

  SimpleCookieInterceptor(this.jar);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final cookies = jar.loadForRequest(options.uri);
    if (cookies.isNotEmpty) {
      final cookieHeader = cookies
          .map((c) => '${c.name}=${c.value}')
          .join('; ');
      options.headers['Cookie'] = cookieHeader;
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final rawCookies = response.headers['set-cookie'];
    if (rawCookies != null) {
      final cookies = rawCookies
          .map((s) => io.Cookie.fromSetCookieValue(s))
          .toList();
      jar.saveFromResponse(response.realUri, cookies);
    }
    handler.next(response);
  }
}
