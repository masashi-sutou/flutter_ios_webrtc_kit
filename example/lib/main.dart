import 'package:flutter/material.dart';
import 'package:flutter_ios_webrtc_kit/flutter_sky_way.dart';
import 'package:flutter_ios_webrtc_kit_example/entrance_page.dart';
import 'package:flutter_ios_webrtc_kit_example/outgoing_call_page.dart';
import 'package:flutter_ios_webrtc_kit_example/video_talk_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(
    MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', ''),
        Locale('en', ''),
      ],
      home: EntrancePage(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case OutgoingCallPage.routeName:
            return FadeTransitionRoute(
              builder: (_) => OutgoingCallPage(
                skyWay: settings.arguments as FlutterSkyWay,
              ),
            );
          case VideoTalkPage.routeName:
            return FadeTransitionRoute(
              builder: (_) => VideoTalkPage(
                skyWay: settings.arguments as FlutterSkyWay,
              ),
            );
          default:
            return _unknownRoute(
              settings: settings,
            );
        }
      },
    ),
  );
}

class FadeTransitionRoute<T> extends MaterialPageRoute<T> {
  FadeTransitionRoute({
    WidgetBuilder builder,
    RouteSettings settings,
  }) : super(
          builder: builder,
          settings: settings,
          fullscreenDialog: true,
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}

MaterialPageRoute _unknownRoute({
  RouteSettings settings,
}) {
  return MaterialPageRoute(
    builder: (context) => Scaffold(
      backgroundColor: Colors.blueGrey,
      body: Center(
        child: Text(
          '⛔️️ Not found PageRoute ⛔️️\n${settings.name}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: Theme.of(context).textTheme.subtitle1.fontSize,
          ),
        ),
      ),
    ),
  );
}
