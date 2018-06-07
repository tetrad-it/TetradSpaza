import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../Components/InputFields.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_analytics/firebase_analytics.dart'; 

final FirebaseAuth _auth = FirebaseAuth.instance;
final analytics = new FirebaseAnalytics();

class SignUpScreen extends StatefulWidget{
  const SignUpScreen({Key key}) : super(key: key);
  @override
  SignUpScreenState createState() => new SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen>{  
  final TextEditingController _email = new TextEditingController();
  final TextEditingController _password = new TextEditingController();
  final TextEditingController _confirmPass = new TextEditingController();

  Future<Null> _signUp() async{
    if (_password.text.isEmpty || _confirmPass.text.isEmpty){
      _errorMessage("Please populate passwords", "Sign Up Error");
    }

    if (_email.text.isEmpty){
      _errorMessage("Please populate email", "Sign Up Error");
    }

    if (_password.text == _confirmPass.text){
      if (!_email.text.contains('@tetrad.co.za')){
        _errorMessage("Please use tetrad email account", "Sign Up Error");
      }

      var name = _email.text.split('.')[0];
      var surname = _email.text.split('.')[1].split('@')[0];

      try{
        var user = await _auth.createUserWithEmailAndPassword(email: _email.text, password: _password.text);
        analytics.logSignUp(signUpMethod: "firebase");
        assert(user != null);
        final firebaseRef = FirebaseDatabase.instance.reference().child('users/' + user.uid);

        var userUpdate = new UserUpdateInfo();        
        userUpdate.displayName = name + ' ' + surname;
        _auth.updateProfile(userUpdate);
        
        firebaseRef.push().set({
          'name': name,
          'surname': surname,
          'email': _email.text,
          'deviceID': null,
          'dob': null,
          'inOffice': false,
          'photo': null,
          'balance': 0.00
        });        
      }
      catch(error){
        _errorMessage(error.toString(), "Sign Up Error");
      }
          
      _successMessage("Profile created!", "Signup Success");            
    }
    else{
      _errorMessage("Passwords do not match!", "Password Error");
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

  Future<Null> _successMessage(String error, String component) async {
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
                onPressed: () => Navigator.of(context).pop(false),
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
                                  margin: new EdgeInsets.symmetric(horizontal: 20.0),
                                  child: new Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      new Form(
                                        child: new Column(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: <Widget>[
                                            new Logo(image: logo),
                                            new InputFieldArea(
                                              hint: "Email Address",
                                              obscure: false,
                                              icon: Icons.email,
                                              controller: _email,
                                            ),
                                            new InputFieldArea(
                                              hint: "Password",
                                              obscure: true,
                                              icon: Icons.lock_outline,
                                              controller: _password,
                                            ),
                                            new InputFieldArea(
                                              hint: "Confirm Password",
                                              obscure: true,
                                              icon: Icons.lock_outline,
                                              controller: _confirmPass,                                            
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
                                                onPressed: _signUp,                                                                    
                                                child: new Text(
                                                  "SIGN UP",
                                                  style: new TextStyle(
                                                    fontSize: 20.0,
                                                  ),
                                                ),
                                              ),
                                            ),                                             
                                          ],
                                        )
                                      ),
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
      width: 250.0,
      height: 250.0,
      alignment: Alignment.center,
      decoration: new BoxDecoration(
        image: image,
      ),
    ));
  }
}
