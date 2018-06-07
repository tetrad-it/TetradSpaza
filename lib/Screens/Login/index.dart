import 'dart:async';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../Components/InputFields.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart'; 
import 'package:device_info/device_info.dart';

final TextEditingController _email = new TextEditingController();
final TextEditingController _password = new TextEditingController();
final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseAnalytics analytics = new FirebaseAnalytics();

DecorationImage backgroundImage = new DecorationImage(
  image: new ExactAssetImage('assets/images/background.jpg'),
  fit: BoxFit.cover,
);

DecorationImage tick = new DecorationImage(
  image: new ExactAssetImage('assets/images/tetrad.png'),
  fit: BoxFit.cover,
);

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key key}) : super(key: key);
  @override
  LoginScreenState createState() => new LoginScreenState();
}

class LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  FirebaseUser user;
  static final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();
  Future<Null> _signIn() async{
    if (_email.text.isNotEmpty && _password.text.isNotEmpty){
      try{
        var firebaseUser = await _auth.signInWithEmailAndPassword(email: _email.text, password: _password.text);

        if (firebaseUser == null){
          _errorMessage("Invalid credentials", "Login error");
        }

        _auth.onAuthStateChanged.handleError((Error error){        
          _errorMessage("Critical Error: " + error.toString() , "Login error");
        });

        _auth.onAuthStateChanged
          .listen((FirebaseUser stateUser) {                        
            analytics.logLogin();
            analytics.setUserId(stateUser.uid);
            setState(() {
              user = firebaseUser;         
            });
            _registerDevice();
            Navigator.pushReplacementNamed(context, '/home');
        });
      }
      catch(e){
        analytics.logEvent(name: 'incorrect_credentials');
        _errorMessage("Invalid Credentials", "Login error");
      }                        
    }
    else{
      _errorMessage("Please enter credentials", "Login error");
    }     
}

  Future<Null> _registerDevice() async{
    String name, brand, version, id, model, platform;
    try{
      if (Platform.isAndroid){
        var deviceInfo = await deviceInfoPlugin.androidInfo;
        name = deviceInfo.device;
        id = "${deviceInfo.bootloader}${deviceInfo.id}";
        model = deviceInfo.model;
        brand = deviceInfo.brand;
        version = deviceInfo.version.release;
        platform = "Android";
      }
      else if (Platform.isIOS){
        var deviceInfo = await deviceInfoPlugin.iosInfo;
        name = deviceInfo.name;
        id = deviceInfo.identifierForVendor;
        model = deviceInfo.model;
        brand = "Apple";
        version = deviceInfo.systemVersion;
        platform = "iOS";
      }

      final reference = FirebaseDatabase.instance.reference().child('users/${user.uid}/devices/$id' );   
      reference.set({
        'name': name,
        'model': model,
        'brand': brand,
        'version': version,
        'platform': platform
      });
    } on PlatformException {
      analytics.logEvent(name: 'get_device_failed');
    }
  }

  Future<Null> _errorMessage(String error, String component) async {
    return showDialog<Null>(
      context: context,
      barrierDismissible: true, // user must tap button!
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

  AnimationController _loginButtonController;
  var animationStatus = 0;
  @override
  void initState() {
    super.initState();
    _loginButtonController = new AnimationController(
        duration: new Duration(milliseconds: 3000), vsync: this);
  }

  // Future<Null> _getUserDetail() async{
  //   var currentUser = await _auth.currentUser();
  //   setState(() => user = currentUser);
  // }

  @override
  void dispose() {
    _loginButtonController.dispose();
    super.dispose();
  }

  // Future<Null> _playAnimation() async {
  //   try {
  //     await _loginButtonController.forward();
  //     await _loginButtonController.reverse();
  //   } on TickerCanceled {}
  // }


  Future<bool> _onWillPop() {
    return showDialog(
          context: context,
          child: new AlertDialog(
            title: new Text('Are you sure?'),
            actions: <Widget>[
              new FlatButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: new Text('No'),
              ),
              new FlatButton(
                onPressed: () => exit(0),
                child: new Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    timeDilation = 0.4;
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
                    )
                  ),
                  child: new ListView(
                    padding: const EdgeInsets.all(0.0),
                    children: <Widget>[
                      new Stack(
                        alignment: AlignmentDirectional.bottomCenter,
                        children: <Widget>[
                          new Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              new Tick(image: tick),
                              new FormContainer(),
                              new Divider(
                                height: 32.0,
                              ),
                              new Container(
                                width: 320.0,
                                height: 60.0,
                                alignment: FractionalOffset.center,
                                decoration: new BoxDecoration(
                                  color: const Color.fromRGBO(128, 189, 0, 1.0),
                                  borderRadius: new BorderRadius.all(const Radius.circular(30.0)),        
                                ),
                                child: new MaterialButton(
                                  height: 60.0,
                                  minWidth: 300.0,
                                  onPressed: _signIn,                                                                    
                                  child: new Text(
                                    "SIGN IN",
                                    style: new TextStyle(
                                      fontSize: 20.0,
                                    ),
                                  ),
                                ),
                              ),
                              new SignUp()
                            ],
                          ),
                          // animationStatus == 0
                          //     ? new Padding(
                          //         padding: const EdgeInsets.only(bottom: 50.0),
                          //         child: new InkWell(
                          //             onTap: () {
                          //               _signIn;
                          //               setState(() {
                          //                 animationStatus = 1;
                          //               });
                          //               _playAnimation();
                                        
                          //             },
                          //             child: new SignIn()),
                          //       )
                          //     : new StaggerAnimation(
                          //         buttonController:
                          //             _loginButtonController.view),
                        ],
                      ),
                    ],
                  ))),
        )));
  }
}

class Tick extends StatelessWidget {
  final DecorationImage image;
  Tick({this.image});
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

class FormContainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return (new Container(
      margin: new EdgeInsets.symmetric(horizontal: 20.0),
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          new Form(
              child: new Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              new InputFieldArea(
                hint: "Username",
                obscure: false,
                icon: Icons.person_outline,
                controller: _email,
              ),
              new InputFieldArea(
                hint: "Password",
                obscure: true,
                icon: Icons.lock_outline,
                controller: _password,
              ),
            ],
          )),
        ],
      ),
    ));
  }
}

class SignUp extends StatelessWidget {
  SignUp();
  @override
  Widget build(BuildContext context) {
    return (new FlatButton(
      padding: const EdgeInsets.only(
        top: 100.0,
      ),
      onPressed: () => Navigator.pushReplacementNamed(context, '/signup'),
      child: new Text(
        "Don't have an account? Sign Up",
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        softWrap: true,
        style: new TextStyle(
            fontWeight: FontWeight.w300,
            letterSpacing: 0.5,
            color: Colors.white,
            fontSize: 20.0),
      ),
    ));
  }
}

class SignIn extends StatelessWidget {
  SignIn();
  @override
  Widget build(BuildContext context) {
    return (new Container(
      width: 320.0,
      height: 60.0,
      alignment: FractionalOffset.center,
      decoration: new BoxDecoration(
        color: const Color.fromRGBO(128, 189, 0, 1.0),
        borderRadius: new BorderRadius.all(const Radius.circular(30.0)),        
      ),
      child: new Text(
        "Sign In",
        style: new TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.w300,
          letterSpacing: 0.3,
        ),
      ),
    ));
  }
}