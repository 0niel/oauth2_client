import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'base_web_auth.dart';
import 'package:flutter_web_auth_2/src/server.dart';
import 'package:flutter_web_auth_2/src/webview.dart';
import 'package:flutter_web_auth_2_platform_interface/flutter_web_auth_2_platform_interface.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_to_front/window_to_front.dart';

BaseWebAuth createWebAuth() => IoWebAuth();

const _defaultLandingPage = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Access Granted</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    html, body { margin: 0; padding: 0; }

    main {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      font-family: -apple-system,BlinkMacSystemFont,Segoe UI,Helvetica,Arial,sans-serif,Apple Color Emoji,Segoe UI Emoji,Segoe UI Symbol;
    }

    #text {
      padding: 2em;
      text-align: center;
      font-size: 2rem;
    }
  </style>
</head>
<body>
  <main>
    <div id="text">Вы можете закрыть это окно</div>
  </main>
</body>
</html>
''';

class _FlutterWebAuth2WithServerPlugin extends FlutterWebAuth2Platform {
  HttpServer? _server;
  Timer? _authTimeout;

  /// Registers the internal server implementation.
  static void registerWith() {
    FlutterWebAuth2Platform.instance = FlutterWebAuth2ServerPlugin();
  }

  @override
  Future<String> authenticate({
    required String url,
    required String callbackUrlScheme,
    required Map<String, dynamic> options,
  }) async {
    final parsedOptions = FlutterWebAuth2Options.fromJson(options);

    // Validate callback url
    final callbackUri = Uri.parse(callbackUrlScheme);

    if (callbackUri.scheme != 'http' ||
        (callbackUri.host != 'localhost' && callbackUri.host != '127.0.0.1') ||
        !callbackUri.hasPort) {
      return await FlutterWebAuth2.authenticate(
          url: url,
          callbackUrlScheme: callbackUrlScheme,
          options: parsedOptions);
    }

    await _server?.close(force: true);

    _server = await HttpServer.bind('localhost', callbackUri.port);
    String? result;

    _authTimeout?.cancel();
    _authTimeout = Timer(Duration(seconds: parsedOptions.timeout), () {
      _server?.close();
    });

    await launchUrl(Uri.parse(url));

    await _server!.listen((req) async {
      req.response.headers.add('Content-Type', 'text/html');
      // req.response.write(parsedOptions.landingPageHtml);
      await req.response.close();

      result = req.requestedUri.toString();
      await _server?.close();
      _server = null;
    }).asFuture();

    await _server?.close(force: true);
    _authTimeout?.cancel();

    if (result != null) {
      await WindowToFront.activate();
      return result!;
    }
    throw PlatformException(message: 'User canceled login', code: 'CANCELED');
  }

  @override
  Future clearAllDanglingCalls() async {
    await _server?.close(force: true);
  }
}

class IoWebAuth implements BaseWebAuth {
  final FlutterWebAuth2Platform _webviewImpl = FlutterWebAuth2WebViewPlugin();
  final FlutterWebAuth2Platform _serverImpl =
      _FlutterWebAuth2WithServerPlugin();

  @override
  Future<String> authenticate({
    required String callbackUrlScheme,
    required String redirectUrl,
    required String url,
    Map<String, dynamic>? opts,
  }) async {
    final options = opts ?? <String, dynamic>{};
    final parsedOptions = FlutterWebAuth2Options.fromJson(options);
    if (parsedOptions.useWebview) {
      return _webviewImpl.authenticate(
        url: url,
        callbackUrlScheme: callbackUrlScheme,
        options: options,
      );
    }
    return _serverImpl
        .authenticate(url: url, callbackUrlScheme: callbackUrlScheme, options: {
      'preferEphemeral': (opts?['preferEphemeral'] == true),
      'landingPageHtml': _defaultLandingPage,
    });
  }
}
