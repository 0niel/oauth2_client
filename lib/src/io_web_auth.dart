import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import 'base_web_auth.dart';

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
  @override
  Future<String> authenticate(
      {required String callbackUrlScheme,
      required String url,
      required String redirectUrl,
      Map<String, dynamic>? opts}) async {
    return await FlutterWebAuth2.authenticate(
      callbackUrlScheme: callbackUrlScheme,
      url: url,
      options: FlutterWebAuth2Options(
        preferEphemeral: (opts?['preferEphemeral'] == true),
        landingPageHtml: _defaultLandingPage,
      ),
    );
  }
}
