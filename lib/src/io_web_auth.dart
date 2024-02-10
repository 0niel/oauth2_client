import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'base_web_auth.dart';
import 'package:flutter_web_auth_2/src/server.dart';
import 'package:flutter_web_auth_2/src/webview.dart';
import 'package:flutter_web_auth_2_platform_interface/flutter_web_auth_2_platform_interface.dart';

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

class IoWebAuth implements BaseWebAuth {
  final FlutterWebAuth2Platform _webviewImpl = FlutterWebAuth2WebViewPlugin();
  final FlutterWebAuth2Platform _serverImpl = FlutterWebAuth2ServerPlugin();

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
