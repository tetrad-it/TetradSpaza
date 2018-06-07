import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  @override
  ProfilePageState createState() => new ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  TextEditingController name = new TextEditingController(text: 'Name');
  TextEditingController surname = new TextEditingController(text: 'Surname');
  String gender = '';
  double sex = 1.0;
  bool inOffice = false;
  DateTime dob;

  DateTime _date = new DateTime.now().add(-new Duration(days: 5840));
  DateFormat formatter = new DateFormat('dd/MM/yyyy');
  String dateOfBirth = new DateFormat('dd/MM/yyyy')
      .format(new DateTime.now().add(-new Duration(days: 5840)));

  Future<Null> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: new DateTime(1950),
        lastDate: _date);

    if (picked != null && picked != _date) {
      setState(() {
        dateOfBirth = formatter.format(picked);
        dob = picked;
      });
    }
  }

  void radioValueChanged(double rdbValue) {
    setState(() {
      gender = rdbValue == 1.0 ? 'Female' : 'Male';
      sex = rdbValue;
    });
  }

  void checkBoxChanged(bool cbValue){
    setState(() {
      inOffice = cbValue;      
    });
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      child: new Scaffold(
      appBar: new AppBar(
        title: new Text("Tetrad Spaza"),
        backgroundColor: Colors.green,
      ),
      body: new Column(
        children: <Widget>[
          new Flexible(
            child: new ListView(
              children: <Widget>[
                new Divider(),
                new ListTile(
                  leading: const Icon(Icons.person),
                  title: new TextField(
                    controller: name,
                    decoration: new InputDecoration(
                      hintText: name.text,
                    ),
                  ),
                ),
                new ListTile(
                  leading: const Icon(Icons.person),
                  title: new TextField(
                    controller: surname,
                    decoration: new InputDecoration(
                      hintText: surname.text,
                    ),
                  ),
                ),
                new ListTile(
                  leading: const Icon(Icons.today),
                  title: const Text('Birthday'),
                  subtitle: new Text(dateOfBirth),
                  trailing: new IconButton(
                    color: Colors.green,
                    icon: Icon(Icons.date_range),
                    onPressed: () {
                      _selectDate(context);
                    },
                  ),
                ),
                new ListTile(
                  leading: const Icon(Icons.business),
                  title: const Text('In Office'),
                  trailing: new Checkbox(
                    value: inOffice,
                    onChanged: checkBoxChanged,
                  ),
                ),
                new Divider(),
                new ListTile(
                  leading: const Icon(Icons.wc),
                  title: const Text('Gender'),
                  subtitle: new Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      new Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          new Radio(
                            key: new Key("Female"),
                            value: 1.0,
                            groupValue: sex,
                            onChanged: radioValueChanged,
                          ),
                          new Text("Female"),
                        ],
                      ),
                      new Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          new Radio(
                            key: new Key("Male"),
                            value: 0.5,
                            groupValue: sex,
                            onChanged: radioValueChanged,
                          ),
                          new Text("Male"),
                        ],
                      ),                      
                    ],
                  ),
                ),
                new ListTile(),  
                new RaisedButton(                                  
                  onPressed: buttonPressed,
                  color: Colors.green,
                  child:
                    new Text(
                      "UPDATE",
                      style: new TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16.0,
                      ),
                    ),
                )                              
              ],
            ),
          ),        
        ],
      ),
    ),
    onWillPop: () {
      (Navigator.pushReplacementNamed(context, '/home'))
      ?? false;},
    );
  }

  void buttonPressed() {    
    var age = (new DateTime.now().difference(dob).inDays) / 365;
    FirebaseAnalytics analytics = new FirebaseAnalytics();
    analytics.logEvent(name: 'update_profile');
    analytics.setUserProperty(name: 'inOffice', value: inOffice.toString());
    analytics.setUserProperty(name: 'age', value: age.toString());
    analytics.setUserProperty(name: 'gender', value: gender);    
  }
}
