import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'dart:core';

class HistoryPage extends StatefulWidget {  
  final String uid;
  HistoryPage(this.uid);

  @override
  HistoryPageState createState() => new HistoryPageState(uid);
}

class HistoryPageState extends State<HistoryPage>
    with TickerProviderStateMixin {
  String userID;  
  DataSnapshot dataSnap;

  HistoryPageState(this.userID);

  @override
  void dispose(){
    super.dispose();
    dataSnap = null;
  }

  List<Widget> _getTransactions() {    
    final FirebaseDatabase transactionDatabase = FirebaseDatabase.instance; 
    var snapShot = transactionDatabase.reference().child('users/$userID/transactions').once().then((DataSnapshot snap){
      setState(() {        
        dataSnap = snap;        
      });
    });
    
    var listItems = new List<Widget>();           
    transactionDatabase.setPersistenceEnabled(true);
    transactionDatabase.setPersistenceCacheSizeBytes(10485760);

    if (dataSnap != null){
      var currency = new NumberFormat.simpleCurrency(locale: 'en-US', name: 'ZAR', decimalDigits: 2);
      List<String> transactionIds = new List<String>();
      List<String> balances = new List<String>();
      List<String> types = new List<String>();
      List<String> totals = new List<String>();
      var transactions = dataSnap.value.toString();
      var transactionList = transactions.split('},');       
      if (transactionList is List){
        for (var i = 0; i < transactionList.length; i++) {
          var transactionId = transactionList[i].substring(0, transactionList[i].indexOf(':')).replaceAll('{', '').trim();
          var balanceIndex = transactionList[i].indexOf('runningBalance: ') + 'runningBalance: '.length;
          var balanceLength = transactionList[i].length;          
          var typeIndex = transactionList[i].indexOf('type: ') + 'type: '.length;
          var typeLength = transactionList[i].indexOf(',', typeIndex);
          var totalIndex = transactionList[i].indexOf('total: ') + 'total: '.length;
          var totalLength = transactionList[i].indexOf(',', totalIndex);

          transactionIds.add(_convertDate(transactionId));
          balances.add(transactionList[i].substring(balanceIndex, balanceLength).replaceAll('}', ''));          
          types.add(transactionList[i].substring(typeIndex, typeLength));
          totals.add(transactionList[i].substring(totalIndex, totalLength));

        }
      }
      else{
        var transactionId = transactions.substring(0, transactions.indexOf(':')).replaceAll('{', '');
        transactionIds.add(_convertDate(transactionId));

        var balanceIndex = transactions.indexOf('runningBalance: ') + 'runningBalance: '.length;        
        var typeIndex = transactions.indexOf('type: ') + 'type: '.length;
        var typeLength = transactions.indexOf(',', typeIndex);
        var totalIndex = transactions.indexOf('total: ') + 'total: '.length;
        var totalLength = transactions.indexOf(',', totalIndex);

        balances.add(transactions.substring(balanceIndex, transactions.length).replaceAll('}', ''));          
        types.add(transactions.substring(typeIndex, typeLength));
        totals.add(transactions.substring(totalIndex, totalLength));
      }

      for (var i = 0; i < transactionIds.length; i++) {
        listItems.add(new ListItem(transactionType(types[i]), transactionIds[i], types[i].toUpperCase(), '${currency.format(num.parse(totals[i]))}'));
      }
    }            
    listItems.add(new ListItem(Icons.person_add, "Joined Spaza",  " ", " "));        
    
    return listItems;
  }

  IconData transactionType(String type){
    return type == 'purchase' ? Icons.shopping_cart : Icons.monetization_on;
  }

  String _convertDate(String input){
    String yyyy = input.substring(4, 8);
    var year = int.parse(yyyy);
    String mon = input.substring(2,4);
    String dd = input.substring(0,2);
    var month = mon[0] == "0" ? int.parse(mon[1]) : int.parse(mon);
    var day = dd[0] == "0" ? int.parse(dd[1]) : int.parse(dd);

    var date = new DateTime(year,  month, day);
    var formatter = new DateFormat('EEEE d MMMM');
    return formatter.format(date);    
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
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
                children: _getTransactions(),
              ),
            ),
          ],
        )
      ),
      onWillPop: () {        
        (Navigator.pushReplacementNamed(context, '/home')) 
        ?? false;
      },
    );
  }
}

class VerticalSeparator extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return new Container(
        margin: new EdgeInsets.symmetric(vertical: 4.0),
        height: 80.0,
        width: 1.0,
        color: Colors.green
    );
  }
}

class ListItem extends StatelessWidget{
  final IconData icon;
  final String header, type, amount;

  ListItem(this.icon, this.header, this.type, this.amount);    

  @override
  Widget build(BuildContext context){
    return new Padding(
      padding: new EdgeInsets.symmetric(horizontal: 10.0),
      child: new Column(
        children: <Widget>[
          new Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Container(
                width: 30.0,
                child: new Center(
                  child: new Stack(
                    children: <Widget>[
                      new Padding(
                        padding: new EdgeInsets.only(left: 12.0), 
                        child: new VerticalSeparator(),
                      ),
                      new Container(
                        padding: new EdgeInsets.only(), 
                        child: new Icon(
                          icon,
                          color: Colors.grey), 
                        decoration: new BoxDecoration( 
                          color: Colors.white,
                          shape: BoxShape.circle
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              new Expanded(
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    new Padding(
                      padding: new EdgeInsets.only(left: 15.0, top: 3.0),
                      child: new Text(
                        header,
                        style: new TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          fontSize: 18.0
                        ),
                      ),
                    ),
                    new Padding(
                      padding: new EdgeInsets.only(left: 15.0, top: 5.0),
                      child: new Text(
                        " ",
                        style: new TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          fontSize: 2.0
                        ),
                      ),
                    ),
                    new Padding(
                      padding: new EdgeInsets.only(left: 15.0, top: 5.0),
                      child: new Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          new Text(
                            type,
                            style: new TextStyle(
                              fontSize: 12.0,
                            ),
                          ),
                          new Text(
                            amount,
                          )
                        ],
                      ),                                            
                    )
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }
} 