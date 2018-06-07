import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../Components/InputFields.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final analytics = new FirebaseAnalytics();

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key key}) : super(key: key);
  @override
  ForgotPasswordScreenState createState() => new ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _email = new TextEditingController();

  Future<Null> _resetPassword() async {
    if (_email.text.isEmpty) {
      _errorMessage("Please populate email", "Reset Error");
    }

    if (!_email.text.contains('@tetrad.co.za')) {
      _errorMessage("Account does not exist", "Reset Error");
    }

    try {
      await _auth.sendPasswordResetEmail(email: _email.text);
      analytics.logEvent(name: "password_reset");
    } catch (error) {
      _errorMessage(error.toString(), "Reset Error");
    }
    _successMessage("Email sent", "Reset Success");
  }

  Future<Null> _errorMessage(String error, String component) async {
    return showDialog<Null>(
      context: context,
      barrierDismissible: true,
      child: new AlertDialog(
        title: new Text(component),
        content: new SingleChildScrollView(
          child: new ListBody(
            children: <Widget>[
              new Text(error),
            ],
          ),
        ),
        actions: <Widget>[
          new FlatButton(
            child: new Text('DISMISS'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<Null> _successMessage(String error, String component) async {
    return showDialog<Null>(
      context: context,
      barrierDismissible: true,
      child: new AlertDialog(
        title: new Text(component),
        content: new SingleChildScrollView(
          child: new ListBody(
            children: <Widget>[
              new Text(error),
            ],
          ),
        ),
        actions: <Widget>[
          new FlatButton(
            child: new Text('SIGN IN'),
            onPressed: () {
              Navigator.pushReplacementNamed(context, "/login");
            },
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() {
    return showDialog(
          context: context,
          child: new AlertDialog(
            title: new Text('Are you sure?'),
            actions: <Widget>[
              new FlatButton(
                onPressed: () => Navigator.of(context).pop(),
                child: new Text('No'),
              ),
              new FlatButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, "/login"),
                child: new Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return (new WillPopScope(
        onWillPop: _onWillPop,
        child: new Scaffold(
          body: new Container(
              decoration: new BoxDecoration(
                image: backgroundImage,
              ),
              child: new Container(
                  decoration: new BoxDecoration(
                      gradient: new LinearGradient(
                    colors: <Color>[
                      const Color.fromRGBO(162, 146, 199, 0.8),
                      const Color.fromRGBO(51, 51, 63, 0.9),
                    ],
                    stops: [0.2, 1.0],
                    begin: const FractionalOffset(0.0, 0.0),
                    end: const FractionalOffset(0.0, 1.0),
                  )),
                  child: new ListView(
                    padding: const EdgeInsets.all(0.0),
                    children: <Widget>[
                      new Stack(
                        alignment: AlignmentDirectional.bottomCenter,
                        children: <Widget>[
                          new Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              new Container(
                                margin:
                                    new EdgeInsets.symmetric(horizontal: 20.0),
                                child: new Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    new Form(
                                        child: new Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: <Widget>[
                                        new Logo(image: logo),
                                        new InputFieldArea(
                                          hint: "Email Address",
                                          obscure: false,
                                          icon: Icons.email,
                                          controller: _email,
                                        ),
                                        new Container(
                                          width: 320.0,
                                          height: 60.0,
                                          alignment: FractionalOffset.center,
                                          decoration: new BoxDecoration(
                                            color: const Color.fromRGBO(
                                                128, 189, 0, 1.0),
                                            borderRadius: new BorderRadius.all(
                                                const Radius.circular(30.0)),
                                          ),
                                          child: new MaterialButton(
                                            height: 60.0,
                                            minWidth: 300.0,
                                            onPressed: _resetPassword,
                                            child: new Text(
                                              "RESET PASSWORD",
                                              style: new TextStyle(
                                                fontSize: 20.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ))),
        )));
  }
}

DecorationImage backgroundImage = new DecorationImage(
  image: new ExactAssetImage('assets/images/background.jpg'),
  fit: BoxFit.cover,
);

DecorationImage logo = new DecorationImage(
  image: new ExactAssetImage('assets/images/tetrad.png'),
  fit: BoxFit.cover,
);

class Logo extends StatelessWidget {
  final DecorationImage image;
  Logo({this.image});
  @override
  Widget build(BuildContext context) {
    return (new Container(
      width: 200.0,
      height: 200.0,
      alignment: Alignment.center,
      decoration: new BoxDecoration(
        image: image,
      ),
    ));
  }
}
