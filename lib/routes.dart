import 'package:flutter/material.dart';
import 'Screens/ForgotPassword/index.dart';
import 'Screens/History/index.dart';
import 'Screens/Login/index.dart';
import 'Screens/Profile/index.dart';
import 'Screens/Home/index.dart';
import 'Screens/SignUp/index.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';

class Routes {
  FirebaseAnalytics analytics = new FirebaseAnalytics();

  Routes() {
    runApp(new MaterialApp(
      title: "Tetrad Spaza",
      theme: new ThemeData(
        primarySwatch: Colors.green,              
      ),
      navigatorObservers: [
        new FirebaseAnalyticsObserver(analytics: analytics),
      ],
      debugShowCheckedModeBanner: false,
      home: new LoginScreen(),
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/login':
            return new MyCustomRoute(              
              builder: (_) => new LoginScreen(),
              settings: settings,
            );

          case '/signup':
            return new MyCustomRoute(
              builder: (_) => new SignUpScreen(),
              settings: settings,
            );
          
          case '/home':
            return new MyCustomRoute(              
              builder: (_) => new HomeScreen(),
              settings: settings,              
            );

          case '/profile':
            return new MyCustomRoute(
              builder: (_) => new ProfilePage(),
              settings: settings,
            );
          
          case '/reset':
            return new MyCustomRoute(
              builder: (_) => new ForgotPasswordScreen(),
              settings: settings,
          );
          
          default:
            var uid = settings.name.replaceAll('/history/', '').trim();
            return new MyCustomRoute(
              builder: (_) => new HistoryPage(uid),
              settings: settings,
            );
        }
      },
    ));
  }
}

class MyCustomRoute<T> extends MaterialPageRoute<T> {
  MyCustomRoute({WidgetBuilder builder, RouteSettings settings})
      : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    if (settings.isInitialRoute) return child;
    return new FadeTransition(opacity: animation, child: child);
  }
}
