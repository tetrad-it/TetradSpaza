import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

import '../History/index.dart';

final FirebaseAnalytics analytics = new FirebaseAnalytics();

class FirebaseProfile {
  String key, name, surname, email, dob;  
  bool inOffice;  

  FirebaseProfile(this.key, this.name, this.surname, this.email, this.inOffice);

  String get getKey => key;
  String get getName => name;
  String get getSurname => surname;
  String get getEmail => email;
  bool get isInOffice => inOffice;
  String get getDOB => dob;
}

class Purchase {
  List<String> items;
  double runningBalance, total;
  String type;

  Purchase(this.items, this.runningBalance, this.total, this.type);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key key}) : super (key: key);    

  @override
  HomeScreenState createState() => new HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>{ 
  FirebaseUser fbUser; 
  String displayName = '';
  String email = '';
  String profileId;
  FirebaseAuth auth = FirebaseAuth.instance;
  DatabaseReference firebaseRef;
  FirebaseProfile fbProfile;
  var storageRef = FirebaseStorage.instance.ref();  
  var total = 0.00;
  DatabaseReference storeRef;
  StreamSubscription<Event> _storeSubscription;
  bool _anchorToBottom = false;
  bool _error;
  String profilePic = "https://upload.wikimedia.org/wikipedia/commons/7/7c/Profile_avatar_placeholder_large.png";
  String coverPic = "https://images.pexels.com/photos/547114/pexels-photo-547114.jpeg?cs=srgb&dl=adventure-alps-background-547114.jpg&fm=jpg";
  List<String> itemsBought = new List<String>();
  List<double> itemsBoughtPrice = new List<double>();
  double runningBalance = 0.00;
  var currency = new NumberFormat.simpleCurrency(locale: 'en-US', name: 'ZAR', decimalDigits: 2);

  @override
  void initState(){
    _getUserDetail();
    super.initState();
    storeRef = FirebaseDatabase.instance.reference().child('store');
    final FirebaseDatabase database = FirebaseDatabase.instance;    
    database.reference().child('store').once().then((DataSnapshot snapShot){      
    });
    database.setPersistenceEnabled(true);
    database.setPersistenceCacheSizeBytes(10000000);
    storeRef.keepSynced(true);    
    _storeSubscription = storeRef.onChildChanged.listen((Event event){
      setState(() {
        _error = false;        
      });
    },
    onError: (Object error){
      print("This is a Subscription Error: $error");
      setState(() {
        _error = true;        
      });
    });
  }  

  @override
  void dispose(){
    super.dispose();
    _storeSubscription.cancel();
  }
    
  void _getUserDetail() {
    auth.onAuthStateChanged.listen((FirebaseUser stateUser){     
      if (stateUser != null){
        setState(() {  
          if (fbUser == null){
            fbUser = stateUser;
            displayName = fbUser.email.split('.')[0] + ' ' + fbUser.email.split('.')[1].split('@')[0];
            email = fbUser.email;
            firebaseRef = FirebaseDatabase.instance.reference().child('users/' + fbUser.uid);            
            _start();    
            _getPics();        
          }                  
        });        
      }             
    });
                  
  }

  void _getPics() async{
    if (fbUser != null){
      var proPic = await storageRef.child("users/${fbUser.uid}/profile.png").getDownloadURL();
      var covPic = await storageRef.child("users/${fbUser.uid}/cover.png").getDownloadURL();
      setState(() {
        profilePic = proPic;
        covPic = coverPic;
      });
    }     
  }
  void _signOut()async {
    var result = await _onWillPop();
  }

  Future<Null> getProfileId() async{    
    try{
      var then  = await firebaseRef
      .limitToFirst(1)
      .once()
      .then((DataSnapshot snapshot)async {
        var temp = snapshot.value.toString().replaceAll('{', '');
        setState(() {
          profileId = temp.substring(0, temp.indexOf(':'));          
        });        
        var profile = await getProfile(); 
      });
    }
    catch(e){
      print(e);
    }
  }  

  Future<Null> getProfile() async{        
    var then = await firebaseRef
      .child(profileId)
      .once()
      .then((DataSnapshot snapshot){          
        setState(() {
          fbProfile = new FirebaseProfile(snapshot.key, snapshot.value['name'], snapshot.value['surname'], snapshot.value['email'], snapshot.value['inOffice']);                        
          runningBalance = snapshot.value['balance']; 
        });
      })
      .catchError((DatabaseError error){
        print('There is an error on the get user call');
      });
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

  _start() async{
    profileId = await getProfileId();        
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
            onPressed: () { 
              analytics.logEvent(name: "log_out");
              _storeSubscription.cancel();                          
              auth.signOut();
              exit(0);},
            child: new Text('Yes'),
          ),
        ],
      ),
    ) ??
    false;
  }

  Future<bool> _checkOutProceed() {
    return showDialog(
      context: context,
      child: new AlertDialog(
        title: new Text('Purchase total is ${currency.format(total)}'),
        actions: <Widget>[
          new FlatButton(
            onPressed: () {                     
              analytics.logEvent(name: 'checkout_cancelled');
              Navigator.of(context).pop(false);           
            },
            child: new Text('Cancel'),
          ),
          new FlatButton(
            onPressed: (){                    
              _checkout();
              Navigator.of(context).pop(false);
            },                             
            child: new Text('Proceed'),
          ),
        ],
      ),
    ) ??
    false;
  }

  void _removeItem(String item) async{
    var quantity = 0;    

    var itemRef = FirebaseDatabase.instance.reference().child('store/' + item);
    var anotherAgain = await itemRef.once()
      .then((DataSnapshot snap){          
          if (itemsBought.contains(item)){
            setState(() {
              
                itemsBought.removeAt(itemsBought.lastIndexOf(item));
                itemsBoughtPrice.removeAt(itemsBoughtPrice.lastIndexOf(snap.value['price'].toDouble()));
                total -= snap.value['price'];                                  
            });
            quantity = snap.value['quantity'] + 1;   
            itemRef.child('quantity').set(quantity);             
          }                  
    });    
  }

  void _addItemByTap(String item) async{
    var quantity = 0;    

    var itemRef = FirebaseDatabase.instance.reference().child('store/' + item);
    var anotherAgain = await itemRef.once()
      .then((DataSnapshot snap){
        if (snap.value['quantity'] > 0){
          quantity = snap.value['quantity'] - 1;
          setState(() {            
            itemsBought.add(item);
            itemsBoughtPrice.add(snap.value['price'].toDouble());
            total += snap.value['price'];          
          });
          itemRef.child('quantity').set(quantity.toDouble());
          analytics.logAddToCart(itemId: item, itemCategory: snap.value['category'], itemName: snap.value['name'], quantity: 1, price: snap.value['price'].toDouble(), value: snap.value['price'].toDouble(), currency: 'R');          
        }                
    });        
  }

  void _checkOut() async{
    if (total > 0){
      await _checkOutProceed();      
    }
    else{
      _errorMessage('Cart is empty', 'Checkout');
    }
  }

  void _checkout() async{    
    var now = new DateTime.now();
    var formatter = new DateFormat('ddMMyyyyHHmmss');
    var timeStamp = formatter.format(now);    
    var userRef = FirebaseDatabase.instance.reference().child('users/${fbUser.uid}/transactions/$timeStamp' );    

    userRef.set({
      'items': itemsBought.toString(),
      'runningBalance': runningBalance - total,
      'total': total,
      'type': "purchase"
    });
    analytics.logEcommercePurchase(currency: 'ZAR', value: total, origin: 'Mobile App', transactionId: timeStamp);    
    setState(() {
      runningBalance = runningBalance - total;
      total = 0.00;
      itemsBought.clear();
      itemsBoughtPrice.clear();
    });    
  }

  void _addItemByBarcode(String barcodeId) async{
    String itemName;
    var quantity = 0;
    
    var barcodeRef = FirebaseDatabase.instance.reference().child('barcode/' + barcodeId);    
    var then = await barcodeRef.once()
      .then((DataSnapshot snapshot){
        itemName = snapshot.value['name'];
    });

    var itemRef = FirebaseDatabase.instance.reference().child('store/' + itemName);
    var anotherAgain = await itemRef.once()
      .then((DataSnapshot snap){
        if (quantity = snap.value['quantity'] > 0){
          quantity = snap.value['quantity'] - 1;
          setState(() {
            total += snap.value['price'];    
            itemsBought.add(itemName);
            itemsBoughtPrice.add(snap.value['price']);      
          });
          itemRef.child('quantity').set(quantity);
          analytics.logAddToCart(itemId: itemName, itemCategory: snap.value['category'], itemName: snap.value['name'], quantity: 1);          
        }                                
    });    
  }

  Future _scan() async{
    try {
      var barcode = await BarcodeScanner.scan();
      _addItemByBarcode(barcode);      
    } 
    on PlatformException catch(e){
      if (e.code == BarcodeScanner.CameraAccessDenied){
        _errorMessage('Please grant camera access', 'Barcode Scanner');        
      }
      else{
        print('Unknown exception: $e' );
      }
    } 
    on FormatException{
      _errorMessage('Please wait for scan to complete', 'Barcode Scanner');
    }
    catch(e){
      print('Unknown exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {    
    return new WillPopScope(
      child: new Scaffold(
      appBar: new AppBar(
        title: new Text("Tetrad Spaza"),
        backgroundColor: Colors.green,
      ),
      drawer: new Drawer(
        child: new ListView(          
          children: <Widget>[                        
            new UserAccountsDrawerHeader(              
              accountName: new Text(displayName),
              accountEmail: new Text(email),
              currentAccountPicture: new GestureDetector(
                child: new CircleAvatar(
                  backgroundImage: new CachedNetworkImageProvider(profilePic),                  
                ),
                onTap: null,
              ),
              decoration: new BoxDecoration(                
                image: new DecorationImage(
                  fit:  BoxFit.fill,
                  image: new CachedNetworkImageProvider(coverPic),                               
                )
              ),
            ),
            new ListTile(
              title: new Text("History"),              
              leading: new Icon(Icons.history),  
              onTap: () => Navigator.pushReplacementNamed(context, '/history/${fbUser.uid}'),            
            ),
            
            new ListTile(
              title: new Text("Update Profile"),
              leading: new Icon(Icons.edit),
              onTap: () => Navigator.pushReplacementNamed(context, '/profile'),
            ),
            new Divider(),  
            new ListTile(
              title: new Text("Sign out"),
              leading: new Icon(Icons.power_settings_new),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      body: new Column(        
        children: <Widget>[                    
          new Flexible(
            child: new FirebaseAnimatedList(
              key: new ValueKey<bool>(_anchorToBottom),
              query: storeRef.orderByKey(),
              reverse: _anchorToBottom,
              sort: _anchorToBottom
                  ? (DataSnapshot a, DataSnapshot b) => b.key.compareTo(a.key)
                  : null,
              itemBuilder: (BuildContext context, DataSnapshot snapshot,
                  Animation<double> animation, int index) {
                return new SizeTransition(
                  sizeFactor: animation,
                  child: new ListTile(
                    leading: new CircleAvatar(
                      radius: 60.0,
                      child: new CachedNetworkImage(imageUrl: snapshot.value['image'].toString()),
                      backgroundColor: Colors.white,                      
                    ),
                    trailing: new Text(
                      '${currency.format(num.parse(snapshot.value['price'].toString()))}',
                      textAlign: TextAlign.end,
                      style: new TextStyle(
                        color: Colors.black38,
                        fontSize: 15.0,  
                      ),
                    ),                     
                    title: new DecoratedBox(
                      decoration: new BoxDecoration(
                        borderRadius: new BorderRadius.all(const Radius.circular(60.0)),
                      ),
                      child: new Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          new Container(
                            child: new Text(
                              '${snapshot.value['name'].toString()}',
                              softWrap: true,
                              overflow: TextOverflow.clip,
                              style: new TextStyle(
                                color: Colors.black,
                                fontSize: 25.0,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),                            
                            ),
                          ),                          
                      ],)                      
                    ), 
                    subtitle: new Text('Remaining: ${snapshot.value['quantity'].toString()}',
                      textAlign: TextAlign.right,
                    ),      
                    onTap: () {                       
                      _addItemByTap(snapshot.key);
                    },  
                    enabled: snapshot.value['quantity'] > 0,     
                    onLongPress: () => _removeItem(snapshot.key),  
                    
                  ),                                  
                );
              },
            ),
          ),
          new Align(
            alignment: AlignmentDirectional.bottomEnd,
            child: new FloatingActionButton(
              child: const Icon(Icons.camera_alt),
              onPressed: _scan,
            ),          
          ),
          new Divider(),
          new MaterialButton(             
            minWidth: 360.0,
            elevation: 1.5,
            color: Colors.green,  
            splashColor: Colors.lightGreenAccent,               
            onPressed: (){ 
              _checkOut();              
              analytics.logBeginCheckout(value:  total, currency: 'ZAR');              
            },
            child: new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new Icon(                  
                  Icons.add_shopping_cart,                                    
                ),
                new Text(
                  '  Checkout: ${currency.format(total)}',
                  style: new TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),          
        ],
      )
    ),
    onWillPop: () {_onWillPop();},
    );
  }
}